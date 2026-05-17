import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "const.dart";

/*
颜色使用规范：
1. 全局背景色：surfaceContainerLowest
2. 边框都用outlineVariant颜色
3. 一般的块状都使用surfaceContainerLow 颜色（比背景深一点）
4. 需要突出的选中状态的高亮色都用primary颜色，比如按钮、tab、菜单等
*/

ThemeData defaultTheme(String theme) {
  final colorScheme = colorSchemeForTheme(theme);
  final isDark = colorScheme.brightness == Brightness.dark;
  final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
  final displayTextColor = colorScheme.onSurface;
  final bodyTextColor = colorScheme.onSurface;
  final secondaryTextColor = colorScheme.onSurfaceVariant;
  final textTheme = GoogleFonts.notoSansScTextTheme(baseTextTheme).copyWith(
    headlineSmall: GoogleFonts.notoSansSc(
      fontSize: 24,
      height: 1.24,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      color: displayTextColor,
    ),
    titleLarge: GoogleFonts.notoSansSc(
      fontSize: 22,
      height: 1.24,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      color: displayTextColor,
    ),
    titleMedium: GoogleFonts.notoSansSc(
      fontSize: 17,
      height: 1.26,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: displayTextColor,
    ),
    titleSmall: GoogleFonts.notoSansSc(
      fontSize: 15,
      height: 1.24,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: displayTextColor,
    ),
    bodyLarge: GoogleFonts.notoSansSc(
      fontSize: 15,
      height: 1.46,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: bodyTextColor,
    ),
    bodyMedium: GoogleFonts.notoSansSc(
      fontSize: 14,
      height: 1.42,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: bodyTextColor,
    ),
    bodySmall: GoogleFonts.notoSansSc(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: secondaryTextColor,
    ),
    labelLarge: GoogleFonts.notoSansSc(
      fontSize: 15,
      height: 1.22,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: displayTextColor,
    ),
    labelMedium: GoogleFonts.notoSansSc(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: secondaryTextColor,
    ),
    labelSmall: GoogleFonts.notoSansSc(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: secondaryTextColor,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.notoSansSc().fontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
    dividerColor: colorScheme.outlineVariant,
    iconTheme: IconThemeData(
      color: colorScheme.onSurfaceVariant,
      size: kIconSizeMedium,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.primaryContainer,
      selectionHandleColor: colorScheme.primary,
    ),
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.compact,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 36),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusPill)),
        textStyle: textTheme.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        backgroundColor: colorScheme.surfaceContainerLowest.withValues(alpha: isDark ? 0.08 : 0.72),
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.8 : 0.55)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusPill)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        foregroundColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusPill)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        fixedSize: const Size(36, 36),
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        foregroundColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surfaceContainerLowest.withValues(alpha: isDark ? 0.04 : 0.52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusPill)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest.withValues(alpha: isDark ? 0.06 : 0.66),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      labelStyle: textTheme.bodySmall,
      hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusLarge),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.72)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusLarge),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.72)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusLarge),
        borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.72), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusLarge),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusLarge),
        borderSide: BorderSide(color: colorScheme.error, width: 1.2),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerLowest.withValues(alpha: isDark ? 0.94 : 0.9),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusLarge),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.72)),
          ),
        ),
        elevation: const WidgetStatePropertyAll(8),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surfaceContainerLowest.withValues(alpha: isDark ? 0.96 : 0.92),
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusLarge),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.72)),
      ),
      textStyle: textTheme.bodyMedium,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerLowest.withValues(alpha: isDark ? 0.98 : 0.94),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(
        colorScheme.surfaceContainerLowest.withValues(alpha: isDark ? 0.06 : 0.66),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusPill),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.72)),
        ),
      ),
      textStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
      hintStyle: WidgetStatePropertyAll(textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
      constraints: const BoxConstraints(minHeight: 36),
    ),
  );
}

ColorScheme colorSchemeForTheme(String theme) {
  return switch (theme) {
    "dark" => MaterialTheme.darkScheme(),
    "mint" => MaterialTheme.mintScheme(),
    "sunset" => MaterialTheme.sunsetScheme(),
    "lagoon" => MaterialTheme.lagoonScheme(),
    _ => MaterialTheme.lightScheme(),
  };
}

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff3e8ee8),
      surfaceTint: Color(0xff3e8ee8),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffe8f3ff),
      onPrimaryContainer: Color(0xff1b5fbf),
      secondary: Color(0xff7f6bd8),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfff0edff),
      onSecondaryContainer: Color(0xff5943bd),
      tertiary: Color(0xfff06c97),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffedf3),
      onTertiaryContainer: Color(0xffbd3f66),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff7fa),
      onSurface: Color(0xff101827),
      onSurfaceVariant: Color(0xff687389),
      outline: Color(0xffcfd7ea),
      outlineVariant: Color(0xffe7ecf8),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff252d42),
      inversePrimary: Color(0xffb9d9ff),
      primaryFixed: Color(0xffe8f3ff),
      onPrimaryFixed: Color(0xff103d83),
      primaryFixedDim: Color(0xffc7e1ff),
      onPrimaryFixedVariant: Color(0xff2f73ce),
      secondaryFixed: Color(0xfff0edff),
      onSecondaryFixed: Color(0xff39289a),
      secondaryFixedDim: Color(0xffded7ff),
      onSecondaryFixedVariant: Color(0xff6751cb),
      tertiaryFixed: Color(0xffffedf3),
      onTertiaryFixed: Color(0xff8f254d),
      tertiaryFixedDim: Color(0xffffd2e0),
      onTertiaryFixedVariant: Color(0xffcf4a73),
      surfaceDim: Color(0xffece7f1),
      surfaceBright: Color(0xffffffff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffffbfd),
      surfaceContainer: Color(0xfff6f1fb),
      surfaceContainerHigh: Color(0xffeee8f7),
      surfaceContainerHighest: Color(0xffe7e0f1),
    );
  }

  static ColorScheme mintScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff168a7a),
      surfaceTint: Color(0xff168a7a),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffd8f6ef),
      onPrimaryContainer: Color(0xff07584f),
      secondary: Color(0xff4e81bd),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffe2efff),
      onSecondaryContainer: Color(0xff24598f),
      tertiary: Color(0xffdd9635),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffefd9),
      onTertiaryContainer: Color(0xff9a5b05),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff5fbf8),
      onSurface: Color(0xff11201d),
      onSurfaceVariant: Color(0xff60756f),
      outline: Color(0xffc7d8d3),
      outlineVariant: Color(0xffe0ebe7),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff253430),
      inversePrimary: Color(0xff9de2d4),
      primaryFixed: Color(0xffd8f6ef),
      onPrimaryFixed: Color(0xff063b35),
      primaryFixedDim: Color(0xffabe7dc),
      onPrimaryFixedVariant: Color(0xff0f6f63),
      secondaryFixed: Color(0xffe2efff),
      onSecondaryFixed: Color(0xff163d66),
      secondaryFixedDim: Color(0xffc7ddf8),
      onSecondaryFixedVariant: Color(0xff376fa8),
      tertiaryFixed: Color(0xffffefd9),
      onTertiaryFixed: Color(0xff6c3d00),
      tertiaryFixedDim: Color(0xffffd49a),
      onTertiaryFixedVariant: Color(0xffb06d18),
      surfaceDim: Color(0xffe1ebe7),
      surfaceBright: Color(0xffffffff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffbfffd),
      surfaceContainer: Color(0xffeff7f4),
      surfaceContainerHigh: Color(0xffe6f1ed),
      surfaceContainerHighest: Color(0xffdce9e4),
    );
  }

  static ColorScheme sunsetScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xffd85b62),
      surfaceTint: Color(0xffd85b62),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffffe5e7),
      onPrimaryContainer: Color(0xffa93039),
      secondary: Color(0xff8266c7),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffeee8ff),
      onSecondaryContainer: Color(0xff5d43a6),
      tertiary: Color(0xffe18c34),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffedd9),
      onTertiaryContainer: Color(0xffa35607),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff7f4),
      onSurface: Color(0xff241918),
      onSurfaceVariant: Color(0xff7c6866),
      outline: Color(0xffddcbc8),
      outlineVariant: Color(0xfff0e2df),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff392d2b),
      inversePrimary: Color(0xffffb3b8),
      primaryFixed: Color(0xffffe5e7),
      onPrimaryFixed: Color(0xff7c1f28),
      primaryFixedDim: Color(0xffffc8cc),
      onPrimaryFixedVariant: Color(0xffbf444d),
      secondaryFixed: Color(0xffeee8ff),
      onSecondaryFixed: Color(0xff3f2a82),
      secondaryFixedDim: Color(0xffd9ceff),
      onSecondaryFixedVariant: Color(0xff7155b8),
      tertiaryFixed: Color(0xffffedd9),
      onTertiaryFixed: Color(0xff763b00),
      tertiaryFixedDim: Color(0xffffcf98),
      onTertiaryFixedVariant: Color(0xffbd6c14),
      surfaceDim: Color(0xfff2e4e0),
      surfaceBright: Color(0xffffffff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffffbf9),
      surfaceContainer: Color(0xfffaf0ed),
      surfaceContainerHigh: Color(0xfff4e7e3),
      surfaceContainerHighest: Color(0xffecdeda),
    );
  }

  static ColorScheme lagoonScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff2f72cf),
      surfaceTint: Color(0xff2f72cf),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffe4f0ff),
      onPrimaryContainer: Color(0xff1d55a3),
      secondary: Color(0xff1595ad),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffddf5fb),
      onSecondaryContainer: Color(0xff086276),
      tertiary: Color(0xff8a65d6),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xfff0e8ff),
      onTertiaryContainer: Color(0xff6244b0),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff6f9ff),
      onSurface: Color(0xff121b29),
      onSurfaceVariant: Color(0xff657184),
      outline: Color(0xffccd6e8),
      outlineVariant: Color(0xffe5ebf6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff273141),
      inversePrimary: Color(0xffb8d8ff),
      primaryFixed: Color(0xffe4f0ff),
      onPrimaryFixed: Color(0xff123b78),
      primaryFixedDim: Color(0xffc6ddff),
      onPrimaryFixedVariant: Color(0xff2864bc),
      secondaryFixed: Color(0xffddf5fb),
      onSecondaryFixed: Color(0xff064556),
      secondaryFixedDim: Color(0xffb7e8f2),
      onSecondaryFixedVariant: Color(0xff0e7c93),
      tertiaryFixed: Color(0xfff0e8ff),
      onTertiaryFixed: Color(0xff43298a),
      tertiaryFixedDim: Color(0xffdccdff),
      onTertiaryFixedVariant: Color(0xff7456c4),
      surfaceDim: Color(0xffe4eaf3),
      surfaceBright: Color(0xffffffff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffbfcff),
      surfaceContainer: Color(0xfff0f5fc),
      surfaceContainerHigh: Color(0xffe8eef8),
      surfaceContainerHighest: Color(0xffdfe8f3),
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff84cbd2),
      surfaceTint: Color(0xff84cbd2),
      onPrimary: Color(0xff062f36),
      primaryContainer: Color(0xff174f58),
      onPrimaryContainer: Color(0xffcbf0f4),
      secondary: Color(0xffb6c8cb),
      onSecondary: Color(0xff213235),
      secondaryContainer: Color(0xff35474a),
      onSecondaryContainer: Color(0xffd5e4e6),
      tertiary: Color(0xffddca98),
      onTertiary: Color(0xff3a2f13),
      tertiaryContainer: Color(0xff514627),
      onTertiaryContainer: Color(0xfff5e5ba),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff151d1f),
      onSurface: Color(0xffd8e4e5),
      onSurfaceVariant: Color(0xffa5b4b7),
      outline: Color(0xff67777a),
      outlineVariant: Color(0xff334245),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffd8e4e5),
      inversePrimary: Color(0xff196774),
      primaryFixed: Color(0xffcbf0f4),
      onPrimaryFixed: Color(0xff062f36),
      primaryFixedDim: Color(0xff84cbd2),
      onPrimaryFixedVariant: Color(0xff174f58),
      secondaryFixed: Color(0xffd5e4e6),
      onSecondaryFixed: Color(0xff152326),
      secondaryFixedDim: Color(0xffb6c8cb),
      onSecondaryFixedVariant: Color(0xff35474a),
      tertiaryFixed: Color(0xfff5e5ba),
      onTertiaryFixed: Color(0xff261d05),
      tertiaryFixedDim: Color(0xffddca98),
      onTertiaryFixedVariant: Color(0xff514627),
      surfaceDim: Color(0xff111719),
      surfaceBright: Color(0xff2e393c),
      surfaceContainerLowest: Color(0xff0f1517),
      surfaceContainerLow: Color(0xff172022),
      surfaceContainer: Color(0xff1d282a),
      surfaceContainerHigh: Color(0xff263235),
      surfaceContainerHighest: Color(0xff304044),
    );
  }
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
