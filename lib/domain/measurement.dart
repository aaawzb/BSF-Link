/// 体脂秤测量领域模型（与 UI / 存储解耦的纯数据层，跨端共享）。
library;

/// 一次原始蓝牙报文解析后的结果。
class RawScalePacket {
  final List<int> mac; // 体脂秤 MAC 地址字节
  final double weightKg; // 体重（kg）
  final bool isStable; // 体重是否锁定稳定
  final int impedanceOhm; // 生物电阻抗（Ω），0 表示未测到（如穿袜子）
  final DateTime receivedAt;

  const RawScalePacket({
    required this.mac,
    required this.weightKg,
    required this.isStable,
    required this.impedanceOhm,
    required this.receivedAt,
  });
}

/// 计算后的完整身体指标（约 8 项）。
class BodyMetrics {
  final double weightKg;
  final double bmi;
  final double bodyFatRate; // 体脂率 %
  final double waterRate; // 水分率 %
  final double muscleKg; // 肌肉量 kg
  final double proteinRate; // 蛋白质率 %
  final double boneKg; // 骨量 kg
  final double visceraFatLevel; // 内脏脂肪等级
  final bool estimated; // true=估算降级（无阻抗），false=BIA 实测

  const BodyMetrics({
    required this.weightKg,
    required this.bmi,
    required this.bodyFatRate,
    required this.waterRate,
    required this.muscleKg,
    required this.proteinRate,
    required this.boneKg,
    required this.visceraFatLevel,
    required this.estimated,
  });
}

/// 用户档案（BIA 算法输入）。
class UserProfile {
  final double heightCm;
  final int age;
  final int gender; // 1=男, 0=女（与开源协议一致）

  const UserProfile({
    required this.heightCm,
    required this.age,
    required this.gender,
  });
}

/// 测量流程阶段。
enum MeasurementPhase { idle, scanning, connecting, measuring, stable, error }
