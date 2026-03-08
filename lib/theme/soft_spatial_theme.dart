import 'package:flutter/material.dart';

/// DishMark 设计系统 - 颜色系统
///
/// 基于极简、冷静、略带 iOS 风格的设计原则
/// 所有颜色值均来自 DESIGN_SYSTEM.md 设计令牌
class SoftPalette {
  // ========== 主色调 ==========
  /// 主按钮、强调元素、选中状态 (#E6884D)
  static const Color primary = Color(0xFFE6884D);

  /// Primary 上的文字颜色 (#2A170B)
  static const Color primaryDark = Color(0xFF2A170B);

  // ========== 辅助色 ==========
  /// 次要强调、标签背景 (#FFD7B8)
  static const Color secondary = Color(0xFFFFD7B8);

  // ========== 向后兼容的别名 ==========
  /// @deprecated 使用 [primary] 代替
  static const Color accentOrange = primary;

  /// @deprecated 使用 [secondary] 代替
  static const Color accentOrangeSoft = secondary;

  /// 浮层、高亮区域背景 (#FFF7EE)
  static const Color surfaceElevated = Color(0xFFFFF7EE);

  // ========== 中性色 ==========
  /// 页面背景 (#F4EFE8)
  static const Color background = Color(0xFFF4EFE8);

  /// 卡片、容器背景 (#FFFBF7)
  static const Color surface = Color(0xFFFFFBF7);

  /// 输入框背景 (#F5F5F5)
  static const Color inputBackground = Color(0xFFF5F5F5);

  // ========== 文字颜色 ==========
  /// 主标题、正文 (#3F332A)
  static const Color textPrimary = Color(0xFF3F332A);

  /// 副标题、描述文字 (#7B6B5D)
  static const Color textSecondary = Color(0xFF7B6B5D);

  /// 占位符文字 (#8A8A8A)
  static const Color textPlaceholder = Color(0xFF8A8A8A);

  // ========== 功能色 ==========
  /// 标签默认背景 (#E8DDD1)
  static const Color tagBackground = Color(0xFFE8DDD1);

  /// 标签文字 (#6F5F51)
  static const Color tagForeground = Color(0xFF6F5F51);

  /// 边框、分割线 (#DCCDBE)
  static const Color outline = Color(0xFFDCCDBE);

  /// 删除、警告操作 (#B85E4A)
  static const Color danger = Color(0xFFB85E4A);

  /// 成功状态 (#4CAF50)
  static const Color success = Color(0xFF4CAF50);

  // ========== 玻璃态效果（地图操作按钮）==========
  /// 玻璃态填充 (#60FFFFFF)
  static const Color glassFill = Color(0x60FFFFFF);

  /// 强调玻璃态填充 (#FFFFFFFF)
  static const Color glassFillEmphasized = Color(0xFFFFFFFF);

  /// 玻璃态边框 (#40FFFFFF)
  static const Color glassBorder = Color(0x40FFFFFF);

  /// 顶部高光 (#52FFFFFF)
  static const Color glassHighlightTop = Color(0x52FFFFFF);

  /// 底部高光渐变 (#00FFFFFF)
  static const Color glassHighlightBottom = Color(0x00FFFFFF);
}

/// DishMark 设计系统 - 圆角系统
///
/// 所有圆角值均来自 DESIGN_SYSTEM.md 设计令牌
class SoftRadius {
  /// 标准卡片、对话框圆角 (24px)
  static const BorderRadius card = BorderRadius.all(Radius.circular(24));

  /// 大卡片、浮层圆角 (30px)
  static const BorderRadius largeCard = BorderRadius.all(Radius.circular(30));

  /// 标签、Chip 完全圆角 (999px)
  static const BorderRadius tag = BorderRadius.all(Radius.circular(999));

  /// 输入框、搜索框圆角 (20px)
  static const BorderRadius input = BorderRadius.all(Radius.circular(20));

  /// 按钮、SnackBar 圆角 (14px)
  static const BorderRadius button = BorderRadius.all(Radius.circular(14));
}

/// DishMark 设计系统 - 间距系统
///
/// 基于 4px 作为基础单位
/// 所有间距值均来自 DESIGN_SYSTEM.md 设计令牌
class SoftSpacing {
  /// 极小间距 (4px) - 图标与文字
  static const double xxs = 4.0;

  /// 小间距 (8px) - 紧凑元素间
  static const double xs = 8.0;

  /// 中小间距 (12px)
  static const double sm = 12.0;

  /// 标准间距 (16px) - 卡片内边距
  static const double md = 16.0;

  /// 大间距 (24px) - 卡片间、页面边距
  static const double lg = 24.0;

  /// 极大间距 (32px) - 区块分隔
  static const double xl = 32.0;
}

/// DishMark 设计系统 - 阴影系统
///
/// 仅使用微妙的阴影，避免过度装饰
/// 两层阴影模拟真实光照效果
class SoftShadow {
  /// 浮动卡片阴影
  /// - 单层阴影：#12000000, blur: 24, offset: (0, 10)
  static const List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// 地图操作按钮阴影
  /// - 层 1: #14000000, blur: 24, offset: (0, 12)
  /// - 层 2: #08000000, blur: 8, offset: (0, 3)
  static const List<BoxShadow> mapAction = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3)),
  ];
}

/// DishMark 设计系统 - 装饰构建器
///
/// 提供常用的装饰组合，简化 UI 构建
class SoftDecorations {
  /// 浮动卡片装饰
  ///
  /// 参数:
  /// - [color]: 背景色，默认为 [SoftPalette.surface]
  /// - [borderRadius]: 圆角，默认为 [SoftRadius.card]
  static BoxDecoration floatingCard({
    Color color = SoftPalette.surface,
    BorderRadius borderRadius = SoftRadius.card,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      boxShadow: SoftShadow.floating,
    );
  }

  /// 地图操作玻璃态按钮装饰
  ///
  /// 参数:
  /// - [borderRadius]: 圆角（必需）
  /// - [emphasized]: 是否使用强调模式，默认为 false
  static BoxDecoration mapActionGlassButton({
    required BorderRadius borderRadius,
    bool emphasized = false,
  }) {
    return BoxDecoration(
      color: emphasized
          ? SoftMapActionTokens.glassFillEmphasized
          : SoftMapActionTokens.glassFill,
      borderRadius: borderRadius,
      border: Border.all(color: SoftMapActionTokens.glassBorder, width: 1),
    );
  }

  /// 地图操作按钮阴影装饰
  ///
  /// 参数:
  /// - [borderRadius]: 圆角（必需）
  static BoxDecoration mapActionShadow({required BorderRadius borderRadius}) {
    return BoxDecoration(
      borderRadius: borderRadius,
      boxShadow: SoftShadow.mapAction,
    );
  }

  /// 地图操作按钮内部高光装饰
  ///
  /// 参数:
  /// - [borderRadius]: 圆角（必需）
  static BoxDecoration mapActionInnerHighlight({
    required BorderRadius borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          SoftMapActionTokens.glassHighlightTop,
          SoftMapActionTokens.glassHighlightBottom,
        ],
      ),
    );
  }
}

/// DishMark 设计系统 - 地图操作令牌
///
/// 地图操作按钮的专用设计令牌
class SoftMapActionTokens {
  /// 侧边按钮尺寸 (56px)
  static const double sideButtonSize = 56;

  /// 中央按钮尺寸 (68px)
  static const double centerButtonSize = 68;

  /// 侧边图标尺寸 (23px)
  static const double sideIconSize = 23;

  /// 中央图标尺寸 (40px)
  static const double centerIconSize = 40;

  /// 标签间距 (8px)
  static const double labelSpacing = 8;

  /// 模糊半径 (10px)
  static const double blurSigma = 10;

  /// 玻璃态填充
  static const Color glassFill = SoftPalette.glassFill;

  /// 强调玻璃态填充
  static const Color glassFillEmphasized = SoftPalette.glassFillEmphasized;

  /// 玻璃态边框
  static const Color glassBorder = SoftPalette.glassBorder;

  /// 顶部高光
  static const Color glassHighlightTop = SoftPalette.glassHighlightTop;

  /// 底部高光渐变
  static const Color glassHighlightBottom = SoftPalette.glassHighlightBottom;
}

/// DishMark 设计系统 - 交互状态
///
/// 定义各组件的交互状态效果
class SoftStates {
  // ========== 按钮状态 ==========
  /// 按钮悬停亮度增量 (+10%)
  static const double buttonHoverBrightness = 0.1;

  /// 按钮按下亮度减量 (-10%)
  static const double buttonPressedBrightness = -0.1;

  /// 按钮按下缩放 (0.98)
  static const double buttonPressedScale = 0.98;

  /// 按钮禁用透明度 (50%)
  static const double buttonDisabledOpacity = 0.5;

  // ========== 卡片状态 ==========
  /// 卡片悬停亮度增量 (+5%)
  static const double cardHoverBrightness = 0.05;

  /// 卡片按下亮度减量 (-5%)
  static const double cardPressedBrightness = -0.05;

  /// 卡片按下缩放 (0.99)
  static const double cardPressedScale = 0.99;

  // ========== 输入框状态 ==========
  /// 输入框聚焦边框宽度 (1.2px)
  static const double inputFocusedBorderWidth = 1.2;

  /// 输入框聚焦边框颜色
  static const Color inputFocusedBorderColor = SoftPalette.primary;

  /// 输入框错误边框颜色
  static const Color inputErrorBorderColor = SoftPalette.danger;

  // ========== 可点击区域 ==========
  /// 最小点击区域尺寸 (44x44px - iOS 标准)
  static const double minTapSize = 44.0;

  /// 推荐点击区域尺寸 (48x48px)
  static const double recommendedTapSize = 48.0;
}

/// DishMark 设计系统 - Flutter 主题构建器
///
/// 将设计令牌转换为 Flutter Material 3 主题
///
/// 使用示例:
/// ```dart
/// void main() {
///   runApp(
///     MaterialApp(
///       theme: SoftSpatialTheme.build(),
///       home: const HomePage(),
///     ),
///   );
/// }
/// ```
class SoftSpatialTheme {
  /// 构建 Material 3 主题
  ///
  /// 返回配置好的 [ThemeData]，包含所有设计系统规范
  static ThemeData build() {
    // 构建 ColorScheme
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: SoftPalette.primary,
      brightness: Brightness.light,
      surface: SoftPalette.surface,
      onSurface: SoftPalette.textPrimary,
      primary: SoftPalette.primary,
      onPrimary: SoftPalette.primaryDark,
      secondary: SoftPalette.secondary,
      onSecondary: SoftPalette.textPrimary,
      outline: SoftPalette.outline,
    );

    // 字体栈配置
    // 首选 SF Pro Rounded（iOS 风格圆角字体）
    // 后续为各平台回退字体
    const String? fontFamily = null;
    const List<String> fallbackFonts = <String>[
      'SF Pro Rounded', // 首选：iOS 风格圆角字体
      'PingFang SC', // 苹方（iOS 中文）
      'Hiragino Sans GB', // 冬青黑体
      'Noto Sans CJK SC', // 思源黑体
      'Source Han Sans SC', // 思源黑体
      'Segoe UI', // Windows 回退
      'sans-serif', // 通用回退
    ];

    // 排版系统配置
    // 所有规格均来自 DESIGN_SYSTEM.md
    const TextTheme textTheme = TextTheme(
      /// 页面主标题 (23sp, 700, 1.2)
      titleLarge: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),

      /// 卡片标题、副标题 (18sp, 600, 1.24)
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.24,
      ),

      /// 主要正文内容 (16sp, 500, 1.45)
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),

      /// 次要正文、列表项 (14sp, 500, 1.42)
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.42,
      ),

      /// 辅助说明、时间戳 (12sp, 500, 1.35)
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),

      /// 按钮文字、标签 (14sp, 600, 0.1px)
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: SoftPalette.background,
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      textTheme: textTheme.apply(
        bodyColor: SoftPalette.textPrimary,
        displayColor: SoftPalette.textPrimary,
      ),

      // AppBar 配置 - 透明背景，无阴影
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: SoftPalette.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),

      // 卡片配置 - 使用 surface 背景和 card 圆角
      cardTheme: CardThemeData(
        color: SoftPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: SoftRadius.card),
        elevation: 0,
      ),

      // 对话框配置 - 使用 surface 背景和 card 圆角
      dialogTheme: DialogThemeData(
        backgroundColor: SoftPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: SoftRadius.card),
      ),

      // 底部工作表配置 - 透明背景
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        showDragHandle: false,
      ),

      // 输入框配置 - 使用 inputBackground 和 input 圆角
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SoftPalette.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, // spaceMd
          vertical: 14,
        ),
        border: const OutlineInputBorder(
          borderRadius: SoftRadius.input,
          borderSide: BorderSide(color: Colors.transparent),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: SoftRadius.input,
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: SoftRadius.input,
          borderSide: BorderSide(color: SoftPalette.primary, width: 1.2),
        ),
        hintStyle: const TextStyle(color: SoftPalette.textPlaceholder),
      ),

      // Chip/标签配置 - 使用 tagBackground 和 tag 圆角
      chipTheme: ChipThemeData(
        backgroundColor: SoftPalette.tagBackground,
        selectedColor: SoftPalette.secondary,
        shape: RoundedRectangleBorder(borderRadius: SoftRadius.tag),
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: SoftPalette.tagForeground,
          fontWeight: FontWeight.w600,
        ),
      ),

      // 浮动操作按钮配置
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: SoftPalette.textPrimary,
        backgroundColor: SoftPalette.surface,
        elevation: 0,
      ),

      // SnackBar 配置 - 使用 button 圆角 (14px)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SoftPalette.textPrimary,
        contentTextStyle: const TextStyle(color: SoftPalette.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: SoftRadius.button),
      ),

      // 分割线颜色 - outline with alpha 0.5
      dividerColor: SoftPalette.outline.withValues(alpha: 0.5),
    );
  }
}
