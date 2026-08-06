import 'dart:math';
import 'package:bsf_scale/domain/measurement.dart';

/// BIA 身体指标算法（精确移植自开源项目 maoziban/smart-body-scale-android 的 BodyAlgorithm.kt）。
///
/// 原公式（sex: 1=男, 0=女）：
///   bmi        = weight / (heightM^2)
///   fallbackFat = 1.20*bmi + 0.23*age + (男? -10.8 : 0) - 5.4
///   biaFat(男) = 0.18*bmi + 0.012*age + 0.018*impedance - 3.2
///   biaFat(女) = 0.26*bmi + 0.011*age + 0.020*impedance - 2.5
///   fat = (impedance > 0 ? biaFat : fallbackFat) 钳制 [5.0, 55.0]
///   water = (69.7 - fat*0.55) 钳制 [35.0, 75.0]
///   bone = weight * (男? 0.047 : 0.040) 钳制 [1.5, 5.5]
///   protein = (16.0 + (water-50.0)*0.12) 钳制 [10.0, 24.0]
///   muscle = max(weight*(1 - fat/100) - bone, 0)
///
/// 说明：开源算法本身不含"内脏脂肪等级"，该字段以 BMI 近似分级得到（见 _estimateVisceraFat），
/// 仅供结果页展示参考，非开源真值。
class BodyAlgorithm {
  static BodyMetrics compute({
    required RawScalePacket packet,
    required UserProfile profile,
  }) {
    final heightM = profile.heightCm / 100.0;
    final bmi = heightM > 0 ? packet.weightKg / (heightM * heightM) : 0.0;
    final age = profile.age.clamp(1, 120);
    final isMale = profile.gender == 1;

    final sexOffset = isMale ? -10.8 : 0.0;
    final fallbackFat = 1.20 * bmi + 0.23 * age + sexOffset - 5.4;
    final biaFat = isMale
        ? (0.18 * bmi + 0.012 * age + 0.018 * packet.impedanceOhm - 3.2)
        : (0.26 * bmi + 0.011 * age + 0.020 * packet.impedanceOhm - 2.5);

    final fat = (packet.impedanceOhm > 0 ? biaFat : fallbackFat)
        .clamp(5.0, 55.0);
    final water = (69.7 - fat * 0.55).clamp(35.0, 75.0);
    final bone = (packet.weightKg * (isMale ? 0.047 : 0.040)).clamp(1.5, 5.5);
    final protein = (16.0 + (water - 50.0) * 0.12).clamp(10.0, 24.0);
    final muscle = max(packet.weightKg * (1 - fat / 100.0) - bone, 0.0);

    final estimated = packet.impedanceOhm <= 0;

    return BodyMetrics(
      weightKg: packet.weightKg,
      bmi: bmi,
      bodyFatRate: fat,
      waterRate: water,
      muscleKg: muscle,
      proteinRate: protein,
      boneKg: bone,
      visceraFatLevel: _estimateVisceraFat(bmi, isMale),
      estimated: estimated,
    );
  }

  /// 内脏脂肪等级近似（开源算法未直接给出；以 BMI 分级，仅供展示参考）。
  static double _estimateVisceraFat(double bmi, bool isMale) {
    final base = (bmi - 18.5) * 0.9 + (isMale ? 4.0 : 3.0);
    return base.clamp(1.0, 12.0);
  }
}
