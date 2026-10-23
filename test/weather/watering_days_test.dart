import 'package:polypodium_core/weather.dart';
import 'package:test/test.dart';

DailyWeather _day(String date,
        {double? rain, double? probability, double? et0}) =>
    DailyWeather(
      date: date,
      precipitationSum: rain,
      precipitationProbabilityMax: probability,
      et0: et0,
    );

void main() {
  final today = DateTime.utc(2026, 10, 20);

  group('wateringDays', () {
    test('observed before today, forecast from today on', () {
      final days = wateringDays(
        today: today,
        observed: [
          _day('2026-10-19', rain: 5, probability: 10, et0: 3),
          _day('2026-10-20', rain: 99),
        ],
        forecast: [
          _day('2026-10-19', rain: 99),
          _day('2026-10-20', rain: 10, probability: 50, et0: 4),
        ],
      );
      // Observed rain already fell: its probability doesn't matter.
      expect(days['2026-10-19']!.rainMm, 5);
      expect(days['2026-10-19']!.et0, 3);
      expect(days['2026-10-20']!.rainMm, 5);
      expect(days['2026-10-20']!.et0, 4);
    });

    test('forecast rain is capped by the earlier forecast for that date', () {
      final days = wateringDays(
        today: today,
        observed: const [],
        forecast: [
          _day('2026-10-21', rain: 20, probability: 100),
          _day('2026-10-22', rain: 20, probability: 100),
        ],
        previous: [_day('2026-10-21', rain: 8, probability: 50)],
      );
      expect(days['2026-10-21']!.rainMm, 4);
      // A date the earlier forecast didn't reach isn't capped.
      expect(days['2026-10-22']!.rainMm, 20);
    });
  });

  test('likelyRain weighs rain by probability, 100% when unknown', () {
    expect(likelyRain(_day('d', rain: 10, probability: 30)), 3);
    expect(likelyRain(_day('d', rain: 10)), 10);
    expect(likelyRain(_day('d')), isNull);
  });

  test('meanEt0 skips days without ET0', () {
    expect(meanEt0(const [WeatherDay(et0: 2), WeatherDay(), WeatherDay(et0: 4)]),
        3);
    expect(meanEt0(const [WeatherDay()]), isNull);
  });

  test('wateringLocalDate keeps local times, shifts UTC ones', () {
    const offset = Duration(hours: -3);
    expect(wateringLocalDate('2026-10-20T01:00:00', offset),
        DateTime.utc(2026, 10, 20));
    expect(wateringLocalDate('2026-10-20T01:00:00Z', offset),
        DateTime.utc(2026, 10, 19));
  });

  test('latestTimestamp tolerates missing values', () {
    expect(latestTimestamp(null, null), isNull);
    expect(latestTimestamp('2026-10-01', null), '2026-10-01');
    expect(latestTimestamp('bad', '2026-10-01'), '2026-10-01');
    expect(latestTimestamp('2026-10-02', '2026-10-01'), '2026-10-02');
  });
}
