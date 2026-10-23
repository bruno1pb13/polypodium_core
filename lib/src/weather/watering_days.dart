import 'dart:math' as math;

import 'forecast.dart';
import 'watering_advice.dart';

/// Days before today whose average ET0 is a region's typical day.
const baselineEt0Days = 30;

/// The days [adviseWatering] sees, keyed by `YYYY-MM-DD`: [observed] before
/// [today], and from [today] on the [forecast] issued last. Forecast rain
/// is weighted by its probability and capped by what [previous] (a forecast
/// issued on an earlier day) said for the same date, so rain only the
/// newest forecast shows doesn't postpone anything yet.
Map<String, WeatherDay> wateringDays({
  required DateTime today,
  required Iterable<DailyWeather> observed,
  required Iterable<DailyWeather> forecast,
  Iterable<DailyWeather> previous = const [],
}) {
  final todayKey = dateKey(today);
  final days = <String, WeatherDay>{
    for (final d in observed)
      if (d.date.compareTo(todayKey) < 0)
        d.date: WeatherDay(rainMm: d.precipitationSum, et0: d.et0),
  };
  final before = {for (final d in previous) d.date: d};
  for (final d in forecast) {
    if (d.date.compareTo(todayKey) < 0) continue;
    var rain = likelyRain(d);
    final earlier = before[d.date];
    if (rain != null && earlier != null) {
      rain = math.min(rain, likelyRain(earlier) ?? 0);
    }
    days[d.date] = WeatherDay(rainMm: rain, et0: d.et0);
  }
  return days;
}

/// Forecast rain weighted by its probability (mm).
double? likelyRain(DailyWeather d) {
  final rain = d.precipitationSum;
  if (rain == null) return null;
  return rain * (d.precipitationProbabilityMax ?? 100).clamp(0, 100) / 100;
}

/// Average ET0 of the days that have one, or null when none has.
double? meanEt0(Iterable<WeatherDay> days) {
  final known = [for (final d in days) if (d.et0 != null) d.et0!];
  if (known.isEmpty) return null;
  return known.reduce((a, b) => a + b) / known.length;
}

/// The region-local calendar date of an ISO timestamp. The app writes local
/// wall-clock times without an offset, taken as written; a UTC or offset
/// time is shifted by the region's [utcOffset].
DateTime wateringLocalDate(String iso, Duration utcOffset) {
  var d = DateTime.parse(iso);
  if (d.isUtc) d = d.add(utcOffset);
  return DateTime.utc(d.year, d.month, d.day);
}

/// The later of two ISO timestamps, either of which may be missing or
/// unparseable.
String? latestTimestamp(String? a, String? b) {
  final da = a == null ? null : DateTime.tryParse(a);
  final db = b == null ? null : DateTime.tryParse(b);
  if (da == null) return db == null ? null : b;
  if (db == null) return a;
  return db.isAfter(da) ? b : a;
}
