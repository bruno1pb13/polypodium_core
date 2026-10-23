import 'package:polypodium_core/weather.dart';
import 'package:test/test.dart';

void main() {
  group('distanceKm', () {
    test('is zero for the same point', () {
      expect(distanceKm(-23.5, -46.6, -23.5, -46.6), 0);
    });

    test('matches a known distance (São Paulo – Rio, ~360 km)', () {
      expect(distanceKm(-23.5505, -46.6333, -22.9068, -43.1729),
          closeTo(360, 5));
    });

    test('one hundredth of a degree of latitude is ~1.1 km', () {
      expect(distanceKm(0, 0, 0.01, 0), closeTo(1.11, 0.01));
    });
  });

  test('isValidCoordinate rejects out-of-range values', () {
    expect(isValidCoordinate(-23.5, -46.6), isTrue);
    expect(isValidCoordinate(91, 0), isFalse);
    expect(isValidCoordinate(0, -181), isFalse);
    expect(isValidCoordinate(double.nan, 0), isFalse);
  });

  test('parseOpenMeteo turns columns into rows, keeping nulls', () {
    final forecast = parseOpenMeteo({
      'timezone': 'America/Sao_Paulo',
      'elevation': 760.0,
      'utc_offset_seconds': -10800,
      'hourly': {
        'time': ['2026-10-06T00:00', '2026-10-06T01:00'],
        'temperature_2m': [18.2, null],
        'relative_humidity_2m': [80, 82],
        'precipitation': [0.0, 0.4],
        'precipitation_probability': [10, 35],
        'weather_code': [3, 61],
        'wind_speed_10m': [7.1, 6.0],
      },
      'daily': {
        'time': ['2026-10-06'],
        'weather_code': [61],
        'temperature_2m_max': [26.4],
        'temperature_2m_min': [16.9],
        'precipitation_sum': [4.2],
        'precipitation_probability_max': [70],
        'wind_speed_10m_max': [14.3],
        'et0_fao_evapotranspiration': [3.1],
      },
    });

    expect(forecast.timezone, 'America/Sao_Paulo');
    expect(forecast.elevation, 760.0);
    expect(forecast.utcOffset, const Duration(hours: -3));
    expect(forecast.hourly, hasLength(2));
    expect(forecast.hourly[1].toJson(), {
      'time': '2026-10-06T01:00',
      'temperature': null,
      'humidity': 82.0,
      'precipitation': 0.4,
      'precipitationProbability': 35.0,
      'weatherCode': 61,
      'windSpeed': 6.0,
    });
    expect(forecast.daily.single.toJson(), {
      'date': '2026-10-06',
      'weatherCode': 61,
      'temperatureMax': 26.4,
      'temperatureMin': 16.9,
      'precipitationSum': 4.2,
      'precipitationProbabilityMax': 70.0,
      'windSpeedMax': 14.3,
      'et0': 3.1,
    });
  });

  test('parseOpenMeteo tolerates missing blocks', () {
    final forecast = parseOpenMeteo({'timezone': 'UTC'});
    expect(forecast.hourly, isEmpty);
    expect(forecast.daily, isEmpty);
  });

  test('openMeteoQuery asks for local dates and can skip hourly rows', () {
    final q = openMeteoQuery(-23.55051, -46.63331,
        pastDays: 92, forecastDays: 7, hourly: false);
    expect(q['latitude'], '-23.5505');
    expect(q['timezone'], 'auto');
    expect(q['past_days'], '92');
    expect(q.containsKey('hourly'), isFalse);
    expect(q['daily'], contains('et0_fao_evapotranspiration'));
  });
}
