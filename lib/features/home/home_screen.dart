import 'package:flutter/material.dart';
import 'package:bsf_scale/app/adaptive.dart';
import 'package:bsf_scale/features/measure/measure_screen.dart';

/// 首页（落地页）：精简入口，直达测量。后续可在此扩展多成员切换 / 历史入口。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('体脂秤')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MeasureScreen()),
              ),
              child: const Text('去测量'),
            ),
          ),
        ),
      ),
    );
  }
}
