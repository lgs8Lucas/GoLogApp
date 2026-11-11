import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:gologapp/preview/preview_wrapper.dart';
import 'package:gologapp/util/styles.dart';

/// Marca do GoLog desenhada em código (pin + wordmark), sem asset de imagem.
class GoLogLogo extends StatelessWidget {
  final double size;
  final bool onDark;

  const GoLogLogo({super.key, this.size = 36, this.onDark = true});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'GoLog',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size * 1.25,
            height: size * 1.25,
            decoration: BoxDecoration(
              color: Styles.COLOR_LIGHTGREEN,
              borderRadius: BorderRadius.circular(size * 0.38),
            ),
            child: Icon(
              Icons.route_rounded,
              color: Styles.COLOR_WHITE,
              size: size * 0.8,
            ),
          ),
          SizedBox(width: size * 0.3),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              children: [
                const TextSpan(
                  text: 'Go',
                  style: TextStyle(color: Styles.COLOR_LIGHTGREEN),
                ),
                TextSpan(
                  text: 'Log',
                  style: TextStyle(
                    color: onDark ? Styles.COLOR_WHITE : Styles.COLOR_BLACKBLUE,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(group: 'Componentes', name: 'Logo', wrapper: goLogPreviewWrapper)
Widget goLogLogoPreview() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        color: Styles.COLOR_BLACKBLUE,
        padding: const EdgeInsets.all(24),
        child: const GoLogLogo(),
      ),
      const Padding(
        padding: EdgeInsets.all(24),
        child: GoLogLogo(size: 24, onDark: false),
      ),
    ],
  );
}
