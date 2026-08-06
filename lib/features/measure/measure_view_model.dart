import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsf_scale/domain/measurement.dart';
import 'package:bsf_scale/domain/body_algorithm.dart';
import 'package:bsf_scale/ble/scale_ble_client.dart';

/// BLE 客户端单例（后续可注入多实例 / 测试替身）。
final scaleBleClientProvider =
    Provider<ScaleBleClient>((ref) => ScaleBleClient());

/// 测量页状态。
class MeasurementState {
  final MeasurementPhase phase;
  final String? statusText;
  final double? liveWeightKg;
  final RawScalePacket? lastPacket;
  final BodyMetrics? metrics;
  final String? error;

  const MeasurementState({
    this.phase = MeasurementPhase.idle,
    this.statusText,
    this.liveWeightKg,
    this.lastPacket,
    this.metrics,
    this.error,
  });

  MeasurementState copyWith({
    MeasurementPhase? phase,
    String? statusText,
    double? liveWeightKg,
    bool clearLiveWeight = false,
    RawScalePacket? lastPacket,
    BodyMetrics? metrics,
    String? error,
    bool clearError = false,
  }) {
    return MeasurementState(
      phase: phase ?? this.phase,
      statusText: statusText ?? this.statusText,
      liveWeightKg: clearLiveWeight ? null : (liveWeightKg ?? this.liveWeightKg),
      lastPacket: lastPacket ?? this.lastPacket,
      metrics: metrics ?? this.metrics,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 测量流程状态机（Riverpod StateNotifier）。
class MeasurementNotifier extends StateNotifier<MeasurementState> {
  final ScaleBleClient _client;
  StreamSubscription? _sub;

  MeasurementNotifier(this._client) : super(const MeasurementState());

  /// 连接指定设备并监听解析后的报文，实时更新指标。
  Future<void> start(String deviceId, UserProfile profile) async {
    // 重入保护：取消上一次可能仍在运行的连接/订阅，避免叠加。
    _sub?.cancel();
    state = state.copyWith(
      phase: MeasurementPhase.connecting,
      statusText: '连接中…',
      clearError: true,
    );

    final ok = await _client.ensurePermissions();
    if (!ok) {
      state = state.copyWith(
        phase: MeasurementPhase.error,
        error: '蓝牙 / 定位权限被拒绝',
      );
      return;
    }

    _sub = _client.connectAndListen(deviceId).listen(
      (packet) {
        final metrics = BodyAlgorithm.compute(packet: packet, profile: profile);
        state = state.copyWith(
          phase: packet.isStable ? MeasurementPhase.stable : MeasurementPhase.measuring,
          liveWeightKg: packet.weightKg,
          lastPacket: packet,
          metrics: metrics,
          statusText: packet.isStable ? '测量完成' : '测量中…',
        );
      },
      onError: (e) {
        state = state.copyWith(
          phase: MeasurementPhase.error,
          error: e.toString(),
        );
      },
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    state = const MeasurementState();
  }

  /// 进入扫描阶段（由 UI 触发，避免在 Widget 中直接写 state）。
  void markScanning() {
    state = state.copyWith(
      phase: MeasurementPhase.scanning,
      statusText: '搜索体脂秤…',
      clearError: true,
    );
  }

  /// 扫描超时：若仍处于 scanning 则置为错误。
  void markScanTimeout() {
    if (state.phase == MeasurementPhase.scanning) {
      state = state.copyWith(
        phase: MeasurementPhase.error,
        error: '未找到体脂秤，请站上秤再试',
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final measurementProvider =
    StateNotifierProvider<MeasurementNotifier, MeasurementState>(
  (ref) => MeasurementNotifier(ref.watch(scaleBleClientProvider)),
);
