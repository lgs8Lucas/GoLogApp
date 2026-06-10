extension DateTimeDisplay on DateTime {
  /// Formata a data para o padrão dd/MM/yyyy HH:mm
  String toDisplayFormat() {
    final String dayStr = day.toString().padLeft(2, '0');
    final String monthStr = month.toString().padLeft(2, '0');
    final String hourStr = hour.toString().padLeft(2, '0');
    final String minuteStr = minute.toString().padLeft(2, '0');
    return '$dayStr/$monthStr/$year $hourStr:$minuteStr';
  }
}