import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/styles.dart';

/// Aparência de um status de entrega. Centraliza o mapeamento
/// status -> cor/ícone/rótulo, com fallback para "Pendente" quando o
/// backend não manda nada ou manda um valor desconhecido.
class StatusStyle {
  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  const StatusStyle(this.label, this.color, this.background, this.icon);

  static StatusStyle of(String? status) {
    switch ((status ?? '').trim().toLowerCase()) {
      case 'finalizado':
        return const StatusStyle(
          'Finalizado',
          Styles.COLOR_LIGHTGREEN,
          Styles.COLOR_GREEN_SOFT,
          Icons.check_circle_rounded,
        );
      case 'iniciado':
        return const StatusStyle(
          'Em andamento',
          Styles.COLOR_BLUE,
          Styles.COLOR_BLUE_SOFT,
          Icons.local_shipping_rounded,
        );
      default:
        return const StatusStyle(
          'Pendente',
          Styles.COLOR_ORANGE,
          Styles.COLOR_ORANGE_SOFT,
          Icons.schedule_rounded,
        );
    }
  }

  static const StatusStyle late = StatusStyle(
    'Atrasada',
    Styles.COLOR_RED,
    Styles.COLOR_RED_SOFT,
    Icons.warning_amber_rounded,
  );
}

class StatusBadge extends StatelessWidget {
  final StatusStyle style;
  final bool compact;

  const StatusBadge({super.key, required this.style, this.compact = false});

  factory StatusBadge.fromStatus(String? status, {bool compact = false}) =>
      StatusBadge(style: StatusStyle.of(status), compact: compact);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: compact ? 12 : 14, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(
  group: 'Componentes',
  name: 'StatusBadge',
  wrapper: goLogPreviewWrapper,
)
Widget statusBadgePreview() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StatusBadge.fromStatus('Pendente'),
        StatusBadge.fromStatus('Iniciado'),
        StatusBadge.fromStatus('Finalizado'),
        const StatusBadge(style: StatusStyle.late),
        StatusBadge.fromStatus(null, compact: true),
      ],
    ),
  );
}
