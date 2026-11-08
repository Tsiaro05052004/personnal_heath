/// Heure de prise dans la journée (ex. 08:00), sans date.
class DoseTime implements Comparable<DoseTime> {
  const DoseTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// À partir du nombre de minutes depuis minuit (format de stockage).
  const DoseTime.fromMinuteOfDay(int minuteOfDay)
    : this(minuteOfDay ~/ 60, minuteOfDay % 60);

  final int hour;
  final int minute;

  int get minuteOfDay => hour * 60 + minute;

  /// Cette heure le jour [day] (heure locale).
  DateTime on(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  @override
  int compareTo(DoseTime other) => minuteOfDay.compareTo(other.minuteOfDay);

  @override
  bool operator ==(Object other) =>
      other is DoseTime && other.minuteOfDay == minuteOfDay;

  @override
  int get hashCode => minuteOfDay.hashCode;

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
