import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:gologapp/data/model/action_type.dart';
import 'package:gologapp/presentation/widgets/app_button.dart';
import 'package:gologapp/presentation/widgets/page_shell.dart';
import 'package:gologapp/preview/preview_wrapper.dart';
import 'package:gologapp/util/format_utils.dart';
import 'package:gologapp/util/styles.dart';
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
    final copy = _ActionCopy.of(action);
    final bool isSignature = action == ActionType.signature;

    return PageShell(
      title: 'Rota ${FormatUtils.routeCode(routeCode)}',
      subtitle: stopLabel,
      onBack: onBack,
      bottomBar: BottomActionBar(
        child: ListenableBuilder(
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
        ),
      ),
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
