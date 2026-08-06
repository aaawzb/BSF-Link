import 'package:flutter/material.dart';

/// 构建 Material 3 Expressive 主题。
///
/// - Android：优先使用系统动态取色（monet / dynamic_color 提供）。
/// - 其他平台（Windows 等）：使用兜底种子色，后续可在设置页让用户自由设定主题色。
ThemeData buildAppTheme({ColorScheme? dynamicScheme, required bool isDark}) {
  final scheme = dynamicScheme ??
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF00696E), // 兜底种子色（青绿），Windows 端默认
        brightness: isDark ? Brightness.dark : Brightness.light,
      );

  // M3 Expressive：适度放大形状与留白，体现"表达性"，而非浮夸渐变。
  final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardTheme(
      elevation: 0,
      shape: cardShape,
      color: scheme.surfaceContainerHigh,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      scrolledUnderElevation: 0,
    ),
  );
}
