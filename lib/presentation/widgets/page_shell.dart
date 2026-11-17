import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/styles.dart';

/// Esqueleto visual comum às telas internas: cabeçalho azul-escuro com
/// título/subtítulo e ações, e o conteúdo num "cartão" claro com canto
/// arredondado. Mantém a identidade que o app já tinha, só padronizada.
class PageShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget child;
  final Widget? bottomBar;
  final EdgeInsetsGeometry contentPadding;

  const PageShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.bottomBar,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 20, 16, 0),
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Styles.COLOR_BLACKBLUE,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
                child: Row(
                  children: [
                    if (onBack != null)
                      HeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Voltar',
                        onPressed: onBack!,
                      )
                    else
                      const SizedBox(width: 8),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Styles.COLOR_WHITE,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Styles.COLOR_WHITE.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Styles.COLOR_BACKGROUND,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Styles.RADIUS_XL),
                    topRight: Radius.circular(Styles.RADIUS_XL),
                  ),
                ),
                child: Padding(padding: contentPadding, child: child),
              ),
            ),
          ],
        ),
        bottomNavigationBar: bottomBar,
      ),
    );
  }
}

/// Botão de ícone do cabeçalho, com área de toque de 44px e tooltip
/// (acessibilidade: leitores de tela anunciam o tooltip).
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Styles.COLOR_WHITE.withValues(alpha: 0.1),
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(icon, color: Styles.COLOR_LIGHTGREEN, size: 22),
    );
  }
}

/// Barra inferior fixa para a ação principal da tela.
class BottomActionBar extends StatelessWidget {
  final Widget child;

  const BottomActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Styles.COLOR_WHITE,
        boxShadow: Styles.SHADOW_FLOATING,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: child,
        ),
      ),
    );
  }
}

@Preview(
  group: 'Componentes',
  name: 'PageShell',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget pageShellPreview() {
  return PageShell(
    title: 'Rota #001',
    subtitle: 'BRA2E19 • 4 paradas',
    onBack: () {},
    actions: [
      HeaderIconButton(
        icon: Icons.logout_rounded,
        tooltip: 'Sair',
        onPressed: () {},
      ),
    ],
    child: const Center(child: Text('Conteúdo', style: Styles.BODY)),
  );
}
