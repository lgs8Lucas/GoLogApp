import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:gologapp/data/model/transport.dart';
import 'package:gologapp/presentation/screen/route/widgets/route_item.dart';
import 'package:gologapp/presentation/widgets/error_banner.dart';
import 'package:gologapp/presentation/widgets/page_shell.dart';
import 'package:gologapp/presentation/widgets/state_views.dart';
import 'package:gologapp/preview/preview_data.dart';
import 'package:gologapp/preview/preview_wrapper.dart';
import 'package:gologapp/util/styles.dart';

/// Layout puro da listagem de rotas.
class RouteListView extends StatelessWidget {
  final List<Transport> transports;
  final bool isLoading;
  final String errorMessage;
  final VoidCallback? onDismissError;
  final Future<void> Function() onRefresh;
  final ValueChanged<Transport> onTapTransport;
  final VoidCallback onLogout;

  const RouteListView({
    super.key,
    required this.transports,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onTapTransport,
    required this.onLogout,
    this.onDismissError,
  });

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Minhas rotas',
      subtitle: isLoading
          ? 'Atualizando…'
          : '${transports.length} ${transports.length == 1 ? 'rota disponível' : 'rotas disponíveis'}',
      actions: [
        HeaderIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Sair',
          onPressed: () => _confirmLogout(context),
        ),
        const SizedBox(width: 4),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBanner(message: errorMessage, onDismiss: onDismissError),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: Styles.COLOR_RED),
        title: const Text('Sair da conta?'),
        content: const Text(
          'Ocorrências ainda não sincronizadas continuam salvas no aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Styles.COLOR_RED),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true) onLogout();
  }

  Widget _buildBody() {
    if (isLoading && transports.isEmpty) {
      return ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: const [SkeletonCard(), SkeletonCard(), SkeletonCard()],
      );
    }

    return RefreshIndicator(
      color: Styles.COLOR_BLACKBLUE,
      onRefresh: onRefresh,
      child: transports.isEmpty
          // Estado vazio dentro de uma lista rolável para o "puxar para
          // atualizar" continuar funcionando.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyState(
                  icon: errorMessage.isNotEmpty
                      ? Icons.cloud_off_rounded
                      : Icons.alt_route_rounded,
                  accent: errorMessage.isNotEmpty
                      ? Styles.COLOR_ORANGE
                      : Styles.COLOR_LIGHTGREEN,
                  title: errorMessage.isNotEmpty
                      ? 'Não foi possível carregar'
                      : 'Nenhuma rota por aqui',
                  message: errorMessage.isNotEmpty
                      ? 'Verifique sua conexão e tente novamente.'
                      : 'Quando uma rota for atribuída a você, ela aparecerá nesta lista.',
                  actionLabel: 'Tentar novamente',
                  actionIcon: Icons.refresh_rounded,
                  onAction: onRefresh,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: transports.length,
              itemBuilder: (context, index) {
                final transport = transports[index];
                return RouteItemWidget(
                  transport: transport,
                  onTap: () => onTapTransport(transport),
                );
              },
            ),
    );
  }
}

@Preview(
  group: 'Telas',
  name: 'Rotas - lista',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget routeListPreview() {
  return RouteListView(
    transports: PreviewData.transports(),
    isLoading: false,
    errorMessage: '',
    onRefresh: () async {},
    onTapTransport: (_) {},
    onLogout: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Rotas - carregando',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget routeListLoadingPreview() {
  return RouteListView(
    transports: const [],
    isLoading: true,
    errorMessage: '',
    onRefresh: () async {},
    onTapTransport: (_) {},
    onLogout: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Rotas - vazio',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget routeListEmptyPreview() {
  return RouteListView(
    transports: const [],
    isLoading: false,
    errorMessage: '',
    onRefresh: () async {},
    onTapTransport: (_) {},
    onLogout: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Rotas - erro de rede',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget routeListErrorPreview() {
  return RouteListView(
    transports: const [],
    isLoading: false,
    errorMessage: 'Erro ao buscar transportes: SocketException',
    onDismissError: () {},
    onRefresh: () async {},
    onTapTransport: (_) {},
    onLogout: () {},
  );
}
