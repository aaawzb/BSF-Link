import 'package:bsf_scale/domain/measurement.dart';

/// 蚂蚁阿福(AFU)体脂秤蓝牙报文解析（跨端共享纯 Dart 层）。
///
/// 协议：订阅 FFB2 特征，20 字节原始报文，魔数 0xAC 开头。
/// 字节布局（参考开源项目文档）：
///   第 0 字节  报文头  = 0xAC（魔数）
///   第 1–5 字节 MAC 地址
///   第 6 字节  稳定标志位 0x02 = 体重锁定稳定
///   第 3–5 字节 体重(kg) = ((raw[3]-0x68)*65536 + raw[4]*256 + raw[5]) / 1000
///   第 8–9 字节 电阻抗 Big Endian（Ω）
class AfuPacketParser {
  static const int _magic = 0xAC;

  /// 解析原始字节；返回 null 表示非有效报文（魔数不匹配 / 长度不足 / 体重异常）。
  static RawScalePacket? parse(List<int> raw) {
    if (raw.length < 10) return null;
    if (raw[0] != _magic) return null;

    final weight = ((raw[3] - 0x68) * 65536 + raw[4] * 256 + raw[5]) / 1000.0;
    if (weight <= 0) return null;

    final isStable = raw[6] == 0x02;

    // 电阻抗 Big Endian（字节 8–9）。
    final impedance = (raw[8] << 8) | (raw[9] & 0xFF);

    // MAC 取报文头后的 5 字节。开源文档中"1–6 字节 MAC"与"第 6 字节稳定位"
    // 描述有重叠，实际 MAC 为索引 1..5；如需严格校验设备可在此微调。
    final mac = List<int>.from(raw.sublist(1, 6));

    return RawScalePacket(
      mac: mac,
      weightKg: weight,
      isStable: isStable,
      impedanceOhm: impedance,
      receivedAt: DateTime.now(),
    );
  }
}
