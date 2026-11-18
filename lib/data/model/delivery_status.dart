/// Status de uma entrega, no formato usado pelo app (banco local e telas).
abstract final class DeliveryStatus {
  static const String pending = 'Pendente';
  static const String started = 'Iniciado';
  static const String finished = 'Finalizado';

  /// Converte o status do shipment vindo da API para o formato do app.
  ///
  /// A API usa `AGUARDANDO_INICIO`, `INICIADO` e `FINALIZADO` no campo
  /// `status` do shipment (o `routeStop.status` não é atualizado pelo
  /// backend e fica sempre `PENDENTE` — não deve ser usado). A comparação
  /// ignora maiúsculas, acentos de digitação e espaços para tolerar
  /// variações; valor desconhecido ou ausente vira pendente.
  static String fromApi(Object? raw) {
    final value = (raw?.toString() ?? '').trim().toUpperCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    switch (value) {
      case 'FINALIZADO':
      case 'FINALIZADA':
      case 'CONCLUIDO':
      case 'CONCLUÍDO':
      case 'ENTREGUE':
        return finished;
      case 'INICIADO':
      case 'INICIADA':
      case 'EM_ANDAMENTO':
      case 'EM_ROTA':
        return started;
      default:
        return pending;
    }
  }
}
