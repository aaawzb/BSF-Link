import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsf_scale/domain/measurement.dart';
import 'package:bsf_scale/app/adaptive.dart';
import 'package:bsf_scale/features/measure/measure_view_model.dart';

/// 测量页：聚焦"测量 → 结果"。自适应布局，任意屏幕尺寸可用。
class MeasureScreen extends ConsumerStatefulWidget {
  const MeasureScreen({super.key});

  @override
  ConsumerState<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends ConsumerState<MeasureScreen> {
  // TODO(M3)：从多成员档案读取当前成员；M1 先用固定示例档案。
  final _profile = const UserProfile(heightCm: 170, age: 30, gender: 1);
  StreamSubscription? _scanSub;

  @override
  void dispose() {
    _scanSub?.cancel();
    // 释放 BLE 连接与订阅，避免离开页面后后台仍在监听秤数据。
    ref.read(measurementProvider.notifier).stop();
    super.dispose();
  }

  Future<void> _startMeasurement() async {
    // 防重入：扫描中/测量中不再接受重复触发。
    final current = ref.read(measurementProvider).phase;
    if (current != MeasurementPhase.idle && current != MeasurementPhase.error) {
      return;
    }

    final client = ref.read(scaleBleClientProvider);
    final notifier = ref.read(measurementProvider.notifier);
    notifier.markScanning();

    _scanSub = client.scan().listen((device) async {
      // 命中 AFU 设备即连接（名称含 "AFU"）。可按需改为以 MAC 白名单匹配。
      if (device.name.toUpperCase().contains('AFU')) {
        await _scanSub?.cancel();
        _scanSub = null;
        client.stopScan();
        await notifier.start(device.id, _profile);
      }
    });

    // 超时保护：8 秒未命中则提示。
    await Future.delayed(const Duration(seconds: 8));
    await _scanSub?.cancel();
    _scanSub = null;
    client.stopScan();
    ref.read(measurementProvider.notifier).markScanTimeout();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(measurementProvider);
    final maxW = context.contentMaxWidth;

    return Scaffold(
      appBar: AppBar(title: const Text('测量')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.liveWeightKg != null)
                  Text(
                    '${state.liveWeightKg!.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.displayLarge,
                  )
                else
                  const Text('站上体脂秤开始测量',
                      style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                if (state.metrics != null) _MetricsGrid(metrics: state.metrics!),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: state.phase == MeasurementPhase.scanning
                      ? null
                      : _startMeasurement,
                  icon: const Icon(Icons.bolt),
                  label: Text(state.phase == MeasurementPhase.scanning
                      ? '搜索中…'
                      : '开始测量'),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final BodyMetrics metrics;
  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('体重', '${metrics.weightKg.toStringAsFixed(1)} kg'),
      ('BMI', metrics.bmi.toStringAsFixed(1)),
      ('体脂率', '${metrics.bodyFatRate.toStringAsFixed(1)} %'),
      ('水分', '${metrics.waterRate.toStringAsFixed(1)} %'),
      ('肌肉', '${metrics.muscleKg.toStringAsFixed(1)} kg'),
      ('蛋白质', '${metrics.proteinRate.toStringAsFixed(1)} %'),
      ('骨量', '${metrics.boneKg.toStringAsFixed(1)} kg'),
      ('内脏脂肪', metrics.visceraFatLevel.toStringAsFixed(0)),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: items
          .map((e) => _MetricCard(label: e.$1, value: e.$2))
          .toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
