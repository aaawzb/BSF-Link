import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:bsf_scale/app/theme.dart';
import 'package:bsf_scale/features/home/home_screen.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

/// 应用根：ProviderScope（Riverpod） + DynamicColorBuilder（Android 动态取色）。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final light = buildAppTheme(dynamicScheme: lightDynamic, isDark: false);
        final dark = buildAppTheme(dynamicScheme: darkDynamic, isDark: true);
        return MaterialApp(
          title: '体脂秤',
          theme: light,
          darkTheme: dark,
          themeMode: ThemeMode.system,
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
