import 'package:flutter/widgets.dart';

/// 自适应布局断点（参考 Material 3 窗口尺寸规范）。
enum ScreenWidthType { compact, medium, expanded }

extension ScreenWidth on BuildContext {
  /// 当前屏幕宽度类型：手机 / 平板 / 大屏桌面（Windows）。
  ScreenWidthType get widthType {
    final w = MediaQuery.of(this).size.width;
    if (w >= 1240) return ScreenWidthType.expanded; // 大屏 / Windows 桌面
    if (w >= 840) return ScreenWidthType.medium; // 平板
    return ScreenWidthType.compact; // 手机
  }

  /// 内容最大宽度，保证任意尺寸屏幕都可读、不拉伸。
  double get contentMaxWidth {
    switch (widthType) {
      case ScreenWidthType.expanded:
        return 720;
      case ScreenWidthType.medium:
        return 560;
      case ScreenWidthType.compact:
        return double.infinity;
    }
  }
}
