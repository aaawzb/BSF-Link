import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bsf_scale/domain/measurement.dart';
import 'package:bsf_scale/ble/afu_packet_parser.dart';

/// 体脂秤 BLE 客户端：扫描 / 连接 / 订阅 FFB2 报文。
///
/// 传输层与平台相关（Android 走 BLE Core，Windows 走 WinRT BLE），
/// 由 flutter_reactive_ble 封装；解析层(AfuPacketParser)为跨端共享纯 Dart。
class ScaleBleClient {
  final FlutterReactiveBle _ble;

  ScaleBleClient([FlutterReactiveBle? ble])
      : _ble = ble ?? FlutterReactiveBle();

  /// 体脂秤数据特征（AFU: FFB2）。服务 UUID 在真机发现后确认，
  /// 故采用"连接后遍历服务查找 FFB2 特征"的稳健方式，避免硬编服务 UUID。
  /// AFU 数据特征 UUID（FFB2）。字符串常量用于稳定比较，避免 Uuid 相等比较不可靠。
  static const String _dataCharacteristicUuid =
      '0000ffb2-0000-1000-8000-00805f9b34fb';

  /// 扫描附近设备（不限服务）。
  Stream<DiscoveredDevice> scan() {
    return _ble.scanForDevices(
      withServices: const <Uuid>[],
      scanMode: ScanMode.lowLatency,
    );
  }

  /// 请求蓝牙 / 定位权限。
  ///
  /// Android 12+（API 31+）仅需蓝牙权限；Android 9–11 扫描必须定位权限。
  /// flutter_reactive_ble 在 31+ 自动使用 neverForLocation，无需定位即可扫描。
  ///
  /// 实现取舍（v1）：不引入 device_info_plus，定位权限「请求但不强制拦截」——
  ///   - 12+ 用户拒绝定位：BLE 仍能工作（neverForLocation）。
  ///   - 9–11 用户拒绝定位：扫描会在运行时失败，由连接错误处理器提示。
  /// 后续若需按 SDK 精确分支，可引入 device_info_plus 检测 sdkInt。
  Future<bool> ensurePermissions() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    if (!scan.isGranted || !connect.isGranted) return false;

    // 定位权限：9–11 必需；12+ 非强制（flutter_reactive_ble 已处理）。
    await Permission.locationWhenInUse.request();
    return true;
  }

  /// 连接设备并持续产出解析后的测量报文。
  Stream<RawScalePacket> connectAndListen(String deviceId) async* {
    await for (final state in _ble.connectToDevice(id: deviceId)) {
      if (state.connectionState == ConnectionState.connected) {
        // Android：申请高优先级连接，降低服务发现与订阅延迟。
        try {
          await _ble.requestConnectionPriority(
            deviceId: deviceId,
            priority: ConnectionPriority.highPerformance,
          );
        } catch (_) {
          // 非 Android 平台忽略。
        }

        final characteristic = await _findDataCharacteristic(deviceId);
        if (characteristic == null) return;

        await for (final bytes in _ble.subscribeToCharacteristic(characteristic)) {
          final packet = AfuPacketParser.parse(bytes);
          if (packet != null) yield packet;
        }
        return;
      }
    }
  }

  Future<QualifiedCharacteristic?> _findDataCharacteristic(String deviceId) async {
    try {
      final services = await _ble.discoverAllServices(deviceId);
      for (final svc in services) {
        for (final ch in svc.characteristics) {
          if (ch.characteristicId.toString().toUpperCase() ==
              _dataCharacteristicUuid.toUpperCase()) {
            return QualifiedCharacteristic(
              serviceId: svc.serviceId,
              deviceId: deviceId,
              characteristicId: ch.characteristicId,
            );
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
