/// Status de uma entrega. Os valores são as strings usadas pelo backend e
/// gravadas no banco local, por isso ficam como constantes de texto.
abstract final class DeliveryStatus {
  static const String pending = 'Pendente';
  static const String started = 'Iniciado';
  static const String finished = 'Finalizado';
}
