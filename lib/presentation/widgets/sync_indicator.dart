import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:golog/data/model/sync_status.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/styles.dart';

/// Mostra ao motorista se o que ele registrou já chegou ao servidor.
///
/// Prioridade: ocorrências (entregas, assinaturas, paradas) — é o que o
/// motorista precisa ter certeza de que foi enviado. Pontos do trajeto
/// sobem em segundo plano e só aparecem como informação secundária.
class SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onSyncNow;

  const SyncIndicator({super.key, required this.status, this.onSyncNow});

  static String _plural(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final occ = status.pendingOccurrences;
    final coords = status.pendingCoordinates;
    final occText = _plural(occ, 'ocorrência', 'ocorrências');

    final Color color;
    final Color background;
    final IconData icon;
    final String title;
    final String? subtitle;
    bool showAction = false;

    if (occ > 0 && status.isSyncing) {
      color = Styles.COLOR_BLUE;
      background = Styles.COLOR_BLUE_SOFT;
      icon = Icons.cloud_upload_rounded;
      title = 'Enviando registros…';
      subtitle = '$occText aguardando envio';
    } else if (occ > 0 && status.offline) {
      color = Styles.COLOR_ORANGE;
      background = Styles.COLOR_ORANGE_SOFT;
      icon = Icons.cloud_off_rounded;
      title = 'Sem conexão com o servidor';
      subtitle =
          '$occText ${occ == 1 ? 'salva' : 'salvas'} no aparelho. '
          'O envio é automático quando a conexão voltar.';
      showAction = true;
    } else if (occ > 0) {
      color = Styles.COLOR_ORANGE;
      background = Styles.COLOR_ORANGE_SOFT;
      icon = Icons.schedule_send_rounded;
      title = '$occText aguardando envio';
      subtitle = 'Salvas no aparelho; serão reenviadas automaticamente.';
      showAction = true;
    } else {
      color = Styles.COLOR_LIGHTGREEN;
      background = Styles.COLOR_GREEN_SOFT;
      icon = Icons.cloud_done_rounded;
      title = 'Ocorrências enviadas';
      final last = status.lastSuccessAt;
      final parts = [
        if (last != null) 'Último envio às ${_time(last)}',
        if (coords > 0)
          '${_plural(coords, 'ponto', 'pontos')} do trajeto na fila',
      ];
      subtitle = parts.isEmpty ? null : parts.join(' · ');
    }

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: Styles.SPACE_M),
        padding: EdgeInsets.fromLTRB(12, 10, showAction ? 4 : 12, 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Styles.RADIUS_M),
        ),
        child: Row(
          children: [
            if (status.isSyncing && occ > 0)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Styles.COLOR_TEXT,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Styles.COLOR_TEXT_SECONDARY,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showAction && onSyncNow != null)
              TextButton(
                onPressed: onSyncNow,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Enviar agora'),
              ),
          ],
        ),
      ),
    );
  }
}

@Preview(
  group: 'Componentes',
  name: 'Indicador de envio',
  wrapper: goLogPreviewWrapper,
)
Widget syncIndicatorPreview() {
  final now = DateTime(2026, 11, 17, 14, 32);
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SyncIndicator(status: SyncStatus(lastSuccessAt: now)),
        SyncIndicator(
          status: SyncStatus(lastSuccessAt: now, pendingCoordinates: 38),
        ),
        const SyncIndicator(
          status: SyncStatus(pendingOccurrences: 2, isSyncing: true),
        ),
        SyncIndicator(
          status: const SyncStatus(pendingOccurrences: 1),
          onSyncNow: () {},
        ),
        SyncIndicator(
          status: const SyncStatus(pendingOccurrences: 3, offline: true),
          onSyncNow: () {},
        ),
      ],
    ),
  );
}
