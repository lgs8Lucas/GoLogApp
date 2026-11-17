import 'package:flutter/material.dart';
import 'package:golog/util/app_theme.dart';
import 'package:golog/util/styles.dart';

/// Wrapper usado em todos os `@Preview` do app: aplica o tema do GoLog e um
/// fundo neutro, para que o widget apareça igual ao app real no
/// Widget Previewer (`flutter widget-preview start`).
Widget goLogPreviewWrapper(Widget child) {
  return Theme(
    data: AppTheme.light,
    child: Material(color: Styles.COLOR_BACKGROUND, child: child),
  );
}

/// Tamanho de tela de celular usado nos previews de telas inteiras.
const Size kPhonePreviewSize = Size(390, 844);
