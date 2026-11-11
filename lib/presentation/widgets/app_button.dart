import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:gologapp/preview/preview_wrapper.dart';
import 'package:gologapp/util/styles.dart';

enum AppButtonVariant { filled, outlined, text }

/// Botão padrão do app: altura mínima de 52px (alvo de toque confortável
/// para quem está dirigindo/de luvas), ícone opcional, estado de loading
/// que bloqueia toques duplos e estado desabilitado consistente.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = Styles.COLOR_LIGHTGREEN,
    this.variant = AppButtonVariant.filled,
    this.isLoading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;
    final Color fg = variant == AppButtonVariant.filled
        ? Styles.COLOR_WHITE
        : color;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        if (isLoading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Styles.RADIUS_M),
    );
    const minSize = Size(0, 52);
    final VoidCallback? action = enabled ? onPressed : null;

    final Widget button = switch (variant) {
      AppButtonVariant.filled => ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: fg,
          disabledBackgroundColor: isLoading
              ? color.withValues(alpha: 0.8)
              : Styles.COLOR_GRAY_SOFT,
          disabledForegroundColor: isLoading
              ? Styles.COLOR_WHITE
              : Styles.COLOR_TEXT_HINT,
          elevation: 0,
          minimumSize: minSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: shape,
        ),
        child: content,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: Styles.COLOR_WHITE,
          side: BorderSide(color: color, width: 1.5),
          minimumSize: minSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: shape,
        ),
        child: content,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: action,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: minSize,
          shape: shape,
        ),
        child: content,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

@Preview(group: 'Componentes', name: 'AppButton', wrapper: goLogPreviewWrapper)
Widget appButtonPreview() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        AppButton(
          label: 'Registrar entrega',
          icon: Icons.check_circle_outline_rounded,
          onPressed: () {},
        ),
        AppButton(
          label: 'Registrar ocorrência',
          icon: Icons.report_gmailerrorred_rounded,
          color: Styles.COLOR_ORANGE,
          variant: AppButtonVariant.outlined,
          onPressed: () {},
        ),
        AppButton(
          label: 'Encerrar rota',
          icon: Icons.flag_outlined,
          color: Styles.COLOR_RED,
          variant: AppButtonVariant.text,
          onPressed: () {},
        ),
        AppButton(label: 'Entrando…', isLoading: true, onPressed: () {}),
        const AppButton(label: 'Desabilitado', onPressed: null),
      ],
    ),
  );
}
