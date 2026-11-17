import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:golog/data/model/action_type.dart';
import 'package:golog/presentation/widgets/app_button.dart';
import 'package:golog/presentation/widgets/page_shell.dart';
import 'package:golog/preview/preview_wrapper.dart';
import 'package:golog/util/format_utils.dart';
import 'package:golog/util/styles.dart';
import 'package:signature/signature.dart';

/// Textos e cores de cada tipo de ação da tela de ocorrência.
class _ActionCopy {
  final String title;
  final String description;
  final String button;
  final IconData icon;
  final Color color;

  const _ActionCopy(
    this.title,
    this.description,
    this.button,
    this.icon,
    this.color,
  );

  static _ActionCopy of(ActionType type) => switch (type) {
    ActionType.signature => const _ActionCopy(
      'Assinatura do recebedor',
      'Peça para o responsável assinar no quadro abaixo para confirmar o recebimento.',
      'Registrar entrega',
      Icons.check_circle_outline_rounded,
      Styles.COLOR_LIGHTGREEN,
    ),
    ActionType.observation => const _ActionCopy(
      'Registrar ocorrência',
      'Descreva o que impediu ou atrasou a entrega (ex: destinatário ausente, endereço incorreto).',
      'Salvar ocorrência',
      Icons.report_gmailerrorred_rounded,
      Styles.COLOR_ORANGE,
    ),
    ActionType.finish => const _ActionCopy(
      'Encerrar rota',
      'Adicione uma observação sobre o encerramento, se necessário.',
      'Concluir',
      Icons.flag_outlined,
      Styles.COLOR_RED,
    ),
  };
}

/// Layout puro da tela de ocorrência (assinatura, ocorrência ou
/// encerramento). Valida a entrada: o botão só habilita com assinatura
/// desenhada (entrega) ou texto preenchido (ocorrência).
class OccurrenceView extends StatelessWidget {
  final ActionType action;
  final int? routeCode;
  final String? stopLabel;
  final SignatureController signatureController;
  final TextEditingController observationController;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const OccurrenceView({
    super.key,
    required this.action,
    required this.routeCode,
    required this.signatureController,
    required this.observationController,
    required this.onBack,
    required this.onSubmit,
    this.stopLabel,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    if (action == ActionType.signature) {
      // A tela de assinatura é exibida em paisagem (o OccurrenceScreen gira
      // o aparelho). Se por algum motivo continuar em retrato (tablet com
      // rotação travada, preview), cai no layout vertical.
      return LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth > constraints.maxHeight
            ? _buildSignatureLandscape(context)
            : _buildPortrait(context),
      );
    }
    return _buildPortrait(context);
  }

  Widget _submitButton(_ActionCopy copy) {
    final bool isSignature = action == ActionType.signature;
    return ListenableBuilder(
      listenable: isSignature ? signatureController : observationController,
      builder: (context, _) {
        final bool valid = switch (action) {
          ActionType.signature => signatureController.isNotEmpty,
          ActionType.observation =>
            observationController.text.trim().isNotEmpty,
          ActionType.finish => true,
        };
        return AppButton(
          label: copy.button,
          icon: copy.icon,
          color: copy.color,
          isLoading: isSaving,
          onPressed: valid ? onSubmit : null,
        );
      },
    );
  }

  /// Layout deitado: painel lateral estreito com título e ações, e o quadro
  /// de assinatura ocupando quase toda a largura, com a linha na horizontal.
  Widget _buildSignatureLandscape(BuildContext context) {
    final copy = _ActionCopy.of(action);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Styles.COLOR_BLACKBLUE,
        body: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: 236,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HeaderIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Voltar',
                            onPressed: onBack,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rota ${FormatUtils.routeCode(routeCode)}',
                                  style: const TextStyle(
                                    color: Styles.COLOR_WHITE,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (stopLabel != null)
                                  Text(
                                    stopLabel!,
                                    style: TextStyle(
                                      color: Styles.COLOR_WHITE.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Styles.SPACE_M),
                      Text(
                        copy.title,
                        style: const TextStyle(
                          color: Styles.COLOR_WHITE,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          'Peça para o responsável assinar sobre a linha.',
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            color: Styles.COLOR_WHITE.withValues(alpha: 0.7),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                      _submitButton(copy),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 12),
                  child: _SignaturePad(controller: signatureController),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortrait(BuildContext context) {
    final copy = _ActionCopy.of(action);
    final bool isSignature = action == ActionType.signature;

    return PageShell(
      title: 'Rota ${FormatUtils.routeCode(routeCode)}',
      subtitle: stopLabel,
      onBack: onBack,
      bottomBar: BottomActionBar(child: _submitButton(copy)),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: copy.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Styles.RADIUS_M),
                  ),
                  child: Icon(copy.icon, color: copy.color),
                ),
                const SizedBox(width: Styles.SPACE_M),
                Expanded(child: Text(copy.title, style: Styles.TITLE_L)),
              ],
            ),
            const SizedBox(height: Styles.SPACE_S),
            Text(copy.description, style: Styles.BODY),
            const SizedBox(height: Styles.SPACE_L),
            Expanded(
              child: isSignature
                  ? _SignaturePad(controller: signatureController)
                  : _ObservationField(
                      controller: observationController,
                      optional: action == ActionType.finish,
                    ),
            ),
            const SizedBox(height: Styles.SPACE_L),
          ],
        ),
      ),
    );
  }
}

class _SignaturePad extends StatelessWidget {
  final SignatureController controller;

  const _SignaturePad({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Styles.COLOR_WHITE,
        borderRadius: BorderRadius.circular(Styles.RADIUS_L),
        border: Border.all(color: Styles.COLOR_BORDER),
        boxShadow: Styles.SHADOW_CARD,
      ),
      child: Stack(
        children: [
          // Linha de base + legenda, como num canhoto de papel.
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: Column(
              children: [
                Container(height: 1.2, color: Styles.COLOR_TEXT_HINT),
                const SizedBox(height: 6),
                const Text('Assinatura do responsável', style: Styles.CAPTION),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gesture_rounded,
                          size: 40,
                          color: Styles.COLOR_TEXT_HINT.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Assine aqui',
                          style: Styles.BODY.copyWith(
                            color: Styles.COLOR_TEXT_HINT,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Positioned.fill(
            child: Signature(
              controller: controller,
              backgroundColor: Colors.transparent,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => AnimatedOpacity(
                opacity: controller.isEmpty ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: TextButton.icon(
                  onPressed: controller.isEmpty ? null : controller.clear,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Limpar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Styles.COLOR_TEXT_SECONDARY,
                    backgroundColor: Styles.COLOR_GRAY_SOFT,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObservationField extends StatelessWidget {
  final TextEditingController controller;
  final bool optional;

  const _ObservationField({required this.controller, required this.optional});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          optional ? 'Observação (opcional)' : 'Observação',
          style: Styles.LABEL,
        ),
        const SizedBox(height: Styles.SPACE_S),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Digite os detalhes aqui…',
              alignLabelWithHint: true,
            ),
          ),
        ),
      ],
    );
  }
}

@Preview(
  group: 'Telas',
  name: 'Ocorrência - assinatura',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget occurrenceSignaturePreview() {
  return OccurrenceView(
    action: ActionType.signature,
    routeCode: 1,
    stopLabel: 'Entrega #002',
    signatureController: SignatureController(penStrokeWidth: 3),
    observationController: TextEditingController(),
    onBack: () {},
    onSubmit: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Ocorrência - observação',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget occurrenceObservationPreview() {
  return OccurrenceView(
    action: ActionType.observation,
    routeCode: 1,
    stopLabel: 'Entrega #002',
    signatureController: SignatureController(),
    observationController: TextEditingController(
      text: 'Destinatário ausente, portaria não autorizou o recebimento.',
    ),
    onBack: () {},
    onSubmit: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Ocorrência - encerrar rota',
  size: kPhonePreviewSize,
  wrapper: goLogPreviewWrapper,
)
Widget occurrenceFinishPreview() {
  return OccurrenceView(
    action: ActionType.finish,
    routeCode: 1,
    signatureController: SignatureController(),
    observationController: TextEditingController(),
    isSaving: true,
    onBack: () {},
    onSubmit: () {},
  );
}

@Preview(
  group: 'Telas',
  name: 'Ocorrência - assinatura (paisagem)',
  size: Size(844, 390),
  wrapper: goLogPreviewWrapper,
)
Widget occurrenceSignatureLandscapePreview() {
  return OccurrenceView(
    action: ActionType.signature,
    routeCode: 1,
    stopLabel: 'Entrega #002',
    signatureController: SignatureController(penStrokeWidth: 3),
    observationController: TextEditingController(),
    onBack: () {},
    onSubmit: () {},
  );
}
