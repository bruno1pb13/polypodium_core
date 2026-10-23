import 'dart:math' as math;

/// One forecast as returned by a provider for a single point. Times are the
/// point's local wall-clock time (`2026-10-06T13:00`), dates are local dates
/// (`2026-10-06`), so they're stored and served exactly as received.
class WeatherForecast {
  const WeatherForecast({
    required this.timezone,
    required this.elevation,
    required this.hourly,
    required this.daily,
    this.utcOffset,
  });

  final String? timezone;
  final double? elevation;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  /// The point's offset from UTC when the forecast was issued.
  final Duration? utcOffset;
}

class HourlyWeather {
  const HourlyWeather({
    required this.time,
    this.temperature,
    this.humidity,
    this.precipitation,
    this.precipitationProbability,
    this.weatherCode,
    this.windSpeed,
  });

  final String time;
  final double? temperature;
  final double? humidity;
  final double? precipitation;
  final double? precipitationProbability;
  final int? weatherCode;
  final double? windSpeed;

  Map<String, Object?> toJson() => {
        'time': time,
        'temperature': temperature,
        'humidity': humidity,
        'precipitation': precipitation,
        'precipitationProbability': precipitationProbability,
        'weatherCode': weatherCode,
        'windSpeed': windSpeed,
      };
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    this.weatherCode,
    this.temperatureMax,
    this.temperatureMin,
    this.precipitationSum,
    this.precipitationProbabilityMax,
    this.windSpeedMax,
    this.et0,
  });

  final String date;
  final int? weatherCode;
  final double? temperatureMax;
  final double? temperatureMin;
  final double? precipitationSum;
  final double? precipitationProbabilityMax;
  final double? windSpeedMax;

  /// Reference evapotranspiration (FAO-56), in mm.
  final double? et0;

  factory DailyWeather.fromJson(Map<String, dynamic> json) => DailyWeather(
        date: json['date'] as String,
        weatherCode: (json['weatherCode'] as num?)?.toInt(),
        temperatureMax: (json['temperatureMax'] as num?)?.toDouble(),
        temperatureMin: (json['temperatureMin'] as num?)?.toDouble(),
        precipitationSum: (json['precipitationSum'] as num?)?.toDouble(),
        precipitationProbabilityMax:
            (json['precipitationProbabilityMax'] as num?)?.toDouble(),
        windSpeedMax: (json['windSpeedMax'] as num?)?.toDouble(),
        et0: (json['et0'] as num?)?.toDouble(),
      );

  Map<String, Object?> toJson() => {
        'date': date,
        'weatherCode': weatherCode,
        'temperatureMax': temperatureMax,
        'temperatureMin': temperatureMin,
        'precipitationSum': precipitationSum,
        'precipitationProbabilityMax': precipitationProbabilityMax,
        'windSpeedMax': windSpeedMax,
        'et0': et0,
      };
}

/// Open-Meteo's public forecast endpoint (free, no key).
const openMeteoForecastUrl = 'https://api.open-meteo.com/v1/forecast';

const openMeteoHourly = [
  'temperature_2m',
  'relative_humidity_2m',
  'precipitation',
  'precipitation_probability',
  'weather_code',
  'wind_speed_10m',
];

const openMeteoDaily = [
  'weather_code',
  'temperature_2m_max',
  'temperature_2m_min',
  'precipitation_sum',
  'precipitation_probability_max',
  'wind_speed_10m_max',
  'et0_fao_evapotranspiration',
];

/// Query parameters of an Open-Meteo forecast request for one point, in the
/// point's own timezone. [hourly] false asks for the daily rows only.
Map<String, String> openMeteoQuery(
  double latitude,
  double longitude, {
  required int pastDays,
  required int forecastDays,
  bool hourly = true,
}) =>
    {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'timezone': 'auto',
      'past_days': '$pastDays',
      'forecast_days': '$forecastDays',
      if (hourly) 'hourly': openMeteoHourly.join(','),
      'daily': openMeteoDaily.join(','),
    };

/// Converts Open-Meteo's column-oriented response into rows.
WeatherForecast parseOpenMeteo(Map<String, dynamic> json) {
  List<Object?> col(Map<String, dynamic>? block, String key) =>
      (block?[key] as List?) ?? const [];
  double? num_(List<Object?> list, int i) =>
      i < list.length ? (list[i] as num?)?.toDouble() : null;
  int? int_(List<Object?> list, int i) =>
      i < list.length ? (list[i] as num?)?.toInt() : null;

  final hourly = json['hourly'] as Map<String, dynamic>?;
  final hTime = col(hourly, 'time');
  final hTemp = col(hourly, 'temperature_2m');
  final hHum = col(hourly, 'relative_humidity_2m');
  final hPrec = col(hourly, 'precipitation');
  final hProb = col(hourly, 'precipitation_probability');
  final hCode = col(hourly, 'weather_code');
  final hWind = col(hourly, 'wind_speed_10m');

  final daily = json['daily'] as Map<String, dynamic>?;
  final dTime = col(daily, 'time');
  final dCode = col(daily, 'weather_code');
  final dMax = col(daily, 'temperature_2m_max');
  final dMin = col(daily, 'temperature_2m_min');
  final dPrec = col(daily, 'precipitation_sum');
  final dProb = col(daily, 'precipitation_probability_max');
  final dWind = col(daily, 'wind_speed_10m_max');
  final dEt0 = col(daily, 'et0_fao_evapotranspiration');

  final offset = json['utc_offset_seconds'];
  return WeatherForecast(
    timezone: json['timezone'] as String?,
    elevation: (json['elevation'] as num?)?.toDouble(),
    utcOffset: offset is num ? Duration(seconds: offset.toInt()) : null,
    hourly: [
      for (var i = 0; i < hTime.length; i++)
        if (hTime[i] is String)
          HourlyWeather(
            time: hTime[i] as String,
            temperature: num_(hTemp, i),
            humidity: num_(hHum, i),
            precipitation: num_(hPrec, i),
            precipitationProbability: num_(hProb, i),
            weatherCode: int_(hCode, i),
            windSpeed: num_(hWind, i),
          ),
    ],
    daily: [
      for (var i = 0; i < dTime.length; i++)
        if (dTime[i] is String)
          DailyWeather(
            date: dTime[i] as String,
            weatherCode: int_(dCode, i),
            temperatureMax: num_(dMax, i),
            temperatureMin: num_(dMin, i),
            precipitationSum: num_(dPrec, i),
            precipitationProbabilityMax: num_(dProb, i),
            windSpeedMax: num_(dWind, i),
            et0: num_(dEt0, i),
          ),
    ],
  );
}

/// Great-circle distance between two coordinates, in km.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
}

bool isValidCoordinate(double lat, double lon) =>
    lat.isFinite &&
    lon.isFinite &&
    lat >= -90 &&
    lat <= 90 &&
    lon >= -180 &&
    lon <= 180;
