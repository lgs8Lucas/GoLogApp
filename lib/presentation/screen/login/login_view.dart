import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:golog/presentation/widgets/app_button.dart';
import 'package:golog/presentation/widgets/golog_logo.dart';
import 'package:golog/presentation/widgets/map_placeholder.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/styles.dart';

/// Layout puro da tela de login (sem GetX): recebe estado e callbacks, o
/// que permite renderizá-lo no Widget Previewer com dados fictícios.
class LoginView extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool keepConnected;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onToggleKeepConnected;
  final VoidCallback onSubmit;

  const LoginView({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.keepConnected,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onToggleKeepConnected,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Styles.COLOR_BACKGROUND,
        body: GestureDetector(
          // Toque fora dos campos fecha o teclado.
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                const _LoginHeader(),
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildForm(context),
                  ),
                ),
                Text(
                  'GoLog • Gestão de entregas',
                  style: Styles.CAPTION.copyWith(color: Styles.COLOR_TEXT_HINT),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Styles.SPACE_XL),
      decoration: BoxDecoration(
        color: Styles.COLOR_WHITE,
        borderRadius: BorderRadius.circular(Styles.RADIUS_XL),
        boxShadow: Styles.SHADOW_FLOATING,
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bem-vindo de volta', style: Styles.TITLE_L),
            const SizedBox(height: 4),
            const Text(
              'Entre com sua conta de motorista para ver suas rotas.',
              style: Styles.BODY,
            ),
            const SizedBox(height: Styles.SPACE_XL),
            const Text('E-mail', style: Styles.LABEL),
            const SizedBox(height: Styles.SPACE_S),
            TextFormField(
              controller: emailController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'exemplo@email.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: Styles.SPACE_L),
            const Text('Senha', style: Styles.LABEL),
            const SizedBox(height: Styles.SPACE_S),
            TextFormField(
              controller: passwordController,
              enabled: !isLoading,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: 'Digite sua senha',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
            ),
            const SizedBox(height: Styles.SPACE_S),
            InkWell(
              borderRadius: BorderRadius.circular(Styles.RADIUS_S),
              onTap: isLoading
                  ? null
                  : () => onToggleKeepConnected(!keepConnected),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: keepConnected,
                      onChanged: isLoading ? null : onToggleKeepConnected,
                    ),
                    const Text('Manter conectado', style: Styles.BODY),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Styles.SPACE_L),
            AppButton(
              label: isLoading ? 'Entrando…' : 'Entrar',
              icon: Icons.login_rounded,
              isLoading: isLoading,
              onPressed: () {
                FocusScope.of(context).unfocus();
                onSubmit();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Opacity(opacity: 0.55, child: MapIllustration(dark: true)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x661B2A47), Styles.COLOR_BLACKBLUE],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 56),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GoLogLogo(size: 38),
                    const SizedBox(height: 12),
                    Text(
                      'Suas entregas, do início ao fim.',
                      style: TextStyle(
                        color: Styles.COLOR_WHITE.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(
  group: 'Telas',
  name: 'Login',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget loginViewPreview() {
  return LoginView(
    emailController: TextEditingController(),
    passwordController: TextEditingController(),
    obscurePassword: true,
    keepConnected: true,
    isLoading: false,
    onTogglePassword: () {},
    onToggleKeepConnected: (_) {},
    onSubmit: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Login - carregando',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget loginViewLoadingPreview() {
  return LoginView(
    emailController: TextEditingController(text: 'motorista@golog.com'),
    passwordController: TextEditingController(text: '123456'),
    obscurePassword: true,
    keepConnected: false,
    isLoading: true,
    onTogglePassword: () {},
    onToggleKeepConnected: (_) {},
    onSubmit: () {},
  );
}
