import 'package:intl/intl.dart';

/// Formats d'affichage communs, en français.
abstract final class Formatters {
  static String _two(int n) => n.toString().padLeft(2, '0');

  /// « 08h00 » : heure affichée dans les listes.
  static String hour(int hour, int minute) => '${_two(hour)}h${_two(minute)}';

  /// « 08:00 » : heure affichée dans les formulaires et l'alarme.
  static String clock(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

  /// « 1 », « 0,5 », « 1,5 » : quantité sans zéro inutile.
  static String quantity(double value) => NumberFormat.decimalPatternDigits(
    locale: 'fr_FR',
    decimalDigits: value == value.roundToDouble() ? 0 : 1,
  ).format(value);

  /// « 12 nov. »
  static String shortDate(DateTime date) =>
      DateFormat('d MMM', 'fr_FR').format(date);

  /// « 12 novembre 2026 »
  static String longDate(DateTime date) =>
      DateFormat('d MMMM y', 'fr_FR').format(date);

  /// « Dimanche 8 novembre »
  static String dayTitle(DateTime date) =>
      _capitalize(DateFormat('EEEE d MMMM', 'fr_FR').format(date));

  /// « Samedi »
  static String weekday(DateTime date) =>
      _capitalize(DateFormat('EEEE', 'fr_FR').format(date));

  /// « Ven » (jour abrégé, sans point).
  static String shortWeekday(DateTime date) =>
      _capitalize(DateFormat('EEE', 'fr_FR').format(date).replaceAll('.', ''));

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
