import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:gologapp/preview/preview_wrapper.dart';
import 'package:gologapp/util/styles.dart';

/// Ilustração de mapa desenhada em código (ruas, quadras, rota e pinos).
/// Serve de imagem decorativa e de fallback quando o mapa real não pode ser
/// exibido (sem coordenadas, sem GPS ou no Widget Previewer).
class MapIllustration extends StatelessWidget {
  final bool dark;

  const MapIllustration({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPainter(dark: dark),
      size: Size.infinite,
    );
  }
}

class _MapPainter extends CustomPainter {
  final bool dark;

  _MapPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = dark ? Styles.COLOR_BLACKBLUE : const Color(0xFFE8ECF1);
    final block = dark ? Styles.COLOR_BLACKBLUE_LIGHT : const Color(0xFFF6F8FA);
    final street = dark
        ? Styles.COLOR_WHITE.withValues(alpha: 0.06)
        : Styles.COLOR_WHITE;

    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    // Quadras
    final blockPaint = Paint()..color = block;
    const cell = 64.0;
    for (double x = -20; x < size.width; x += cell) {
      for (double y = -10; y < size.height; y += cell) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 8, y + 8, cell - 16, cell - 16),
            const Radius.circular(6),
          ),
          blockPaint,
        );
      }
    }

    // Avenidas diagonais
    final streetPaint = Paint()
      ..color = street
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.15),
      streetPaint,
    );

    // Rota tracejada
    final routePath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.78)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.35,
        size.width * 0.6,
        size.height * 0.9,
        size.width * 0.85,
        size.height * 0.28,
      );
    final routePaint = Paint()
      ..color = Styles.COLOR_LIGHTGREEN
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final metric in routePath.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 10), routePaint);
        d += 16;
      }
    }

    _pin(
      canvas,
      Offset(size.width * 0.15, size.height * 0.78),
      Styles.COLOR_LIGHTGREEN,
    );
    _pin(
      canvas,
      Offset(size.width * 0.85, size.height * 0.28),
      Styles.COLOR_ORANGE,
    );
  }

  void _pin(Canvas canvas, Offset c, Color color) {
    canvas.drawCircle(c, 11, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(c, 7, Paint()..color = color);
    canvas.drawCircle(c, 3, Paint()..color = Styles.COLOR_WHITE);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.dark != dark;
}

/// Mapa "de mentira" com uma mensagem central. Fallback visual para quando
/// o Google Maps não tem o que mostrar.
class MapPlaceholder extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool loading;
  final double? height;

  const MapPlaceholder({
    super.key,
    this.message = 'Mapa indisponível',
    this.icon = Icons.map_outlined,
    this.loading = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const MapIllustration(),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Styles.COLOR_WHITE,
                borderRadius: BorderRadius.circular(999),
                boxShadow: Styles.SHADOW_CARD,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(icon, size: 18, color: Styles.COLOR_TEXT_SECONDARY),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      style: Styles.LABEL,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(
  group: 'Componentes',
  name: 'MapPlaceholder',
  wrapper: goLogPreviewWrapper,
)
Widget mapPlaceholderPreview() {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        MapPlaceholder(height: 180, message: 'Rota sem coordenadas'),
        MapPlaceholder(
          height: 180,
          loading: true,
          message: 'Obtendo sua localização…',
        ),
      ],
    ),
  );
}
