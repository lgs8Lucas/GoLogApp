import 'package:flutter/material.dart';
import 'package:gologapp/util/styles.dart';

/// Tema Material 3 central do app. Concentrar aqui o visual de inputs,
/// botões, snackbars etc. evita repetir `styleFrom` em cada tela.
class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: Styles.COLOR_BLACKBLUE,
      primary: Styles.COLOR_BLACKBLUE,
      secondary: Styles.COLOR_LIGHTGREEN,
      error: Styles.COLOR_RED,
      surface: Styles.COLOR_WHITE,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Styles.RADIUS_M),
      borderSide: const BorderSide(color: Styles.COLOR_BORDER),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Styles.COLOR_BACKGROUND,
      appBarTheme: const AppBarTheme(
        backgroundColor: Styles.COLOR_BLACKBLUE,
        foregroundColor: Styles.COLOR_WHITE,
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Styles.COLOR_LIGHTGREEN,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Styles.COLOR_WHITE,
        hintStyle: const TextStyle(color: Styles.COLOR_TEXT_HINT),
        prefixIconColor: Styles.COLOR_TEXT_SECONDARY,
        suffixIconColor: Styles.COLOR_TEXT_SECONDARY,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Styles.SPACE_L,
          vertical: Styles.SPACE_L,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: Styles.COLOR_LIGHTGREEN,
            width: 1.6,
          ),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: Styles.COLOR_RED),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Styles.COLOR_LIGHTGREEN
              : Colors.transparent,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Styles.COLOR_LIGHTGREEN,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
