import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:golog/presentation/widgets/golog_logo.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/styles.dart';

/// Splash exibida enquanto verifica a sessão salva.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Styles.COLOR_BLACKBLUE,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GoLogLogo(size: 40),
            SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(
  group: 'Telas',
  name: 'Splash',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget splashPreview() => const SplashView();
