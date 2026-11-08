/// Un verre bu.
class WaterLog {
  const WaterLog({this.id = '', required this.drankAt, required this.ml});

  final String id;
  final DateTime drankAt;

  /// Quantité de CE verre (l'utilisateur peut changer la taille de ses
  /// verres : les anciens gardent la leur).
  final int ml;
}
