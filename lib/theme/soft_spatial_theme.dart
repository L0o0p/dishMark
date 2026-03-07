import 'package:flutter/material.dart';

class SoftPalette {
  static const Color background = Color(0xFFF4EFE8);
  static const Color surface = Color(0xFFFFFBF7);
  static const Color surfaceElevated = Color(0xFFFFF7EE);
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF3F332A);
  static const Color textSecondary = Color(0xFF7B6B5D);
  static const Color textPlaceholder = Color(0xFF8A8A8A);
  static const Color tagBackground = Color(0xFFE8DDD1);
  static const Color tagForeground = Color(0xFF6F5F51);
  static const Color accentOrange = Color(0xFFE6884D);
  static const Color accentOrangeSoft = Color(0xFFFFD7B8);
  static const Color outline = Color(0xFFDCCDBE);
  static const Color danger = Color(0xFFB85E4A);
}

class SoftRadius {
  static const BorderRadius card = BorderRadius.all(Radius.circular(24));
  static const BorderRadius largeCard = BorderRadius.all(Radius.circular(30));
  static const BorderRadius tag = BorderRadius.all(Radius.circular(999));
  static const BorderRadius input = BorderRadius.all(Radius.circular(20));
}

class SoftMapActionTokens {
  static const double sideButtonSize = 56;
  static const double centerButtonSize = 68;
  static const double sideIconSize = 23;
  static const double centerIconSize = 40;
  static const double labelSpacing = 8;
  static const double blurSigma = 10;
  static const Color glassFill = Color(0x60FFFFFF);
  static const Color glassFillEmphasized = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0x40FFFFFF);
  static const Color glassHighlightTop = Color(0x52FFFFFF);
  static const Color glassHighlightBottom = Color(0x00FFFFFF);
}

class SoftShadow {
  static const List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> mapAction = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3)),
  ];
}

class SoftDecorations {
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

  static BoxDecoration mapActionShadow({required BorderRadius borderRadius}) {
    return BoxDecoration(
      borderRadius: borderRadius,
      boxShadow: SoftShadow.mapAction,
    );
  }

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

class SoftSpatialTheme {
  static ThemeData build() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: SoftPalette.accentOrange,
      brightness: Brightness.light,
      surface: SoftPalette.surface,
      onSurface: SoftPalette.textPrimary,
      primary: SoftPalette.accentOrange,
      onPrimary: const Color(0xFF2A170B),
      secondary: SoftPalette.accentOrangeSoft,
      onSecondary: SoftPalette.textPrimary,
      outline: SoftPalette.outline,
    );

    const String? fontFamily = null;
    const List<String> fallbackFonts = <String>[
      'SF Pro Rounded',
      'PingFang SC',
      'Hiragino Sans GB',
      'Noto Sans CJK SC',
      'Source Han Sans SC',
      'Segoe UI',
      'sans-serif',
    ];

    const TextTheme textTheme = TextTheme(
      titleLarge: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.24,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.42,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: SoftPalette.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: SoftPalette.surface,
        shape: RoundedRectangleBorder(borderRadius: SoftRadius.card),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SoftPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: SoftRadius.card),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        showDragHandle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SoftPalette.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
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
          borderSide: BorderSide(color: SoftPalette.accentOrange, width: 1.2),
        ),
        hintStyle: const TextStyle(color: SoftPalette.textPlaceholder),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SoftPalette.tagBackground,
        selectedColor: SoftPalette.accentOrangeSoft,
        shape: RoundedRectangleBorder(borderRadius: SoftRadius.tag),
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: SoftPalette.tagForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: SoftPalette.textPrimary,
        backgroundColor: SoftPalette.surface,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SoftPalette.textPrimary,
        contentTextStyle: const TextStyle(color: SoftPalette.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerColor: SoftPalette.outline.withValues(alpha: 0.5),
    );
  }
}
