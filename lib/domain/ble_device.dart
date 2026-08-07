/// 扫描发现的 BLE 设备（中性类型，不依赖具体 BLE 库）。
///
/// 用中性类型隔离 UI 与底层 BLE 实现（flutter_blue_plus），
/// 未来更换 BLE 库时只需改 [ScaleBleClient]，UI 不受影响。
class BleDevice {
  final String id; // 平台设备标识（Android=MAC/随机化，iOS=UUID，Windows=蓝牙地址）
  final String name;

  const BleDevice(this.id, this.name);

  @override
  String toString() => 'BleDevice($id, $name)';
}
