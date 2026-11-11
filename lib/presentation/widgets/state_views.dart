import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:gologapp/presentation/widgets/app_button.dart';
import 'package:gologapp/preview/preview_wrapper.dart';
import 'package:gologapp/util/styles.dart';

/// Estado vazio/erro com ilustração, título, explicação e ação opcional.
/// Usado como fallback sempre que uma lista ou dado não está disponível.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color accent;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.accent = Styles.COLOR_LIGHTGREEN,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Illustration(icon: icon, accent: accent),
          const SizedBox(height: Styles.SPACE_XL),
          Text(title, style: Styles.TITLE_M, textAlign: TextAlign.center),
          const SizedBox(height: Styles.SPACE_S),
          Text(message, style: Styles.BODY, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Styles.SPACE_XL),
            AppButton(
              label: actionLabel!,
              icon: actionIcon,
              onPressed: onAction,
              color: accent,
              variant: AppButtonVariant.outlined,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Ilustração vetorial (sem asset): ícone sobre círculos concêntricos.
class _Illustration extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _Illustration({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Styles.COLOR_WHITE,
              boxShadow: Styles.SHADOW_CARD,
            ),
            child: Icon(icon, size: 32, color: accent),
          ),
        ],
      ),
    );
  }
}

/// Bloco cinza usado em skeletons de carregamento.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, this.width, this.height = 12, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Styles.COLOR_GRAY_SOFT,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton no formato de um card de lista: comunica "carregando" e já
/// antecipa o layout, evitando o salto visual de um spinner central.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Styles.SPACE_M),
      padding: const EdgeInsets.all(Styles.SPACE_L),
      decoration: BoxDecoration(
        color: Styles.COLOR_WHITE,
        borderRadius: BorderRadius.circular(Styles.RADIUS_L),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 48, height: 48, radius: 12),
          SizedBox(width: Styles.SPACE_L),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                SkeletonBox(width: 110, height: 14),
                SkeletonBox(width: 180),
                SkeletonBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  final String message;

  const LoadingState({super.key, this.message = 'Carregando…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: Styles.SPACE_L),
          Text(message, style: Styles.BODY),
        ],
      ),
    );
  }
}

@Preview(group: 'Componentes', name: 'EmptyState', wrapper: goLogPreviewWrapper)
Widget emptyStatePreview() {
  return EmptyState(
    icon: Icons.alt_route_rounded,
    title: 'Nenhuma rota por aqui',
    message: 'Quando uma rota for atribuída a você, ela aparecerá nesta lista.',
    actionLabel: 'Atualizar',
    actionIcon: Icons.refresh_rounded,
    onAction: () {},
  );
}

@Preview(
  group: 'Componentes',
  name: 'Skeleton / Loading',
  wrapper: goLogPreviewWrapper,
)
Widget loadingPreview() {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonCard(),
        SkeletonCard(),
        SizedBox(height: 24),
        LoadingState(message: 'Buscando rotas…'),
      ],
    ),
  );
}
