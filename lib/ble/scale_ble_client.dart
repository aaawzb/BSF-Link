import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bsf_scale/domain/measurement.dart';
import 'package:bsf_scale/domain/ble_device.dart';
import 'package:bsf_scale/ble/afu_packet_parser.dart';

/// 体脂秤 BLE 客户端：扫描 / 连接 / 订阅 FFB2 报文。
///
/// 传输层由 flutter_blue_plus 封装（Android BLE Core / Windows WinRT BLE /
/// macOS / Linux 等），解析层(AfuPacketParser)为跨端共享纯 Dart。
/// 扫描结果用中性 [BleDevice] 暴露给 UI，避免 UI 耦合具体 BLE 库。
class ScaleBleClient {
  /// AFU 数据特征 UUID（FFB2）。字符串常量用于稳定比较，避免 Uuid 相等比较不可靠。
  static const String _dataCharacteristicUuid =
      '0000ffb2-0000-1000-8000-00805f9b34fb';

  /// 请求蓝牙 / 定位权限。
  ///
  /// Android 12+（API 31+）仅需蓝牙权限；Android 9–11 扫描必须定位权限。
  /// flutter_blue_plus 在 31+ 自动使用 neverForLocation，无需定位即可扫描。
  Future<bool> ensurePermissions() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    if (!scan.isGranted || !connect.isGranted) return false;

    // 定位权限：9–11 必需；12+ 非强制（flutter_blue_plus 已处理）。
    await Permission.locationWhenInUse.request();
    return true;
  }

  /// 停止正在进行的扫描（连接命中或超时后调用，避免后台持续扫描）。
  void stopScan() => FlutterBluePlus.stopScan();

  /// 扫描附近设备，逐个以中性 [BleDevice] 形式产出。
  ///
  /// flutter_blue_plus 的 onScanResults 每次推送当前结果列表；这里展开为
  /// 单设备事件流，保持与原 "每发现一台设备触发一次" 的行为一致。
  Stream<BleDevice> scan() {
    // 启动扫描（自带 8s 超时）；结果通过 onScanResults 流出。
    final _ = FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    return FlutterBluePlus.onScanResults.expand(
      (results) => results.map(
        (r) => BleDevice(r.device.remoteId.str, r.device.platformName),
      ),
    );
  }

  /// 连接设备并持续产出解析后的测量报文。
  Stream<RawScalePacket> connectAndListen(String deviceId) async* {
    // flutter_blue_plus：凭 remoteId 构造设备对象即可连接（无需先扫描到）。
    final device = BluetoothDevice.fromId(deviceId);

    await device.connect();

    // 等待连接真正建立（必要时在 Windows 上也同样适用）。
    await device.connectionState
        .where((s) => s == BluetoothConnectionState.connected)
        .first;

    final services = await device.discoverServices();
    BluetoothCharacteristic? target;
    for (final svc in services) {
      for (final ch in svc.characteristics) {
        if (ch.uuid.toString().toUpperCase() ==
            _dataCharacteristicUuid.toUpperCase()) {
          target = ch;
          break;
        }
      }
      if (target != null) break;
    }
    if (target == null) return;

    // 开启通知（CCCD），监听特征值变化即为秤的实时报文。
    await target.setNotifyValue(true);
    await for (final bytes in target.onValueReceived) {
      final packet = AfuPacketParser.parse(bytes);
      if (packet != null) yield packet;
    }
  }
}
