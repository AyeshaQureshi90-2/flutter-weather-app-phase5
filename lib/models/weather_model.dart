
class WeatherModel {
  final String cityName;
  final String country;
  final double latitude;
  final double longitude;
  final double temperature;
  final double feelsLike;
  final String weatherCondition;
  final String weatherDescription;
  final String weatherIcon;
  final int humidity;
  final double windSpeed;
  final int pressure;

  WeatherModel({
    required this.cityName,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.feelsLike,
    required this.weatherCondition,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final coordinates =
        json['coord'] as Map<String, dynamic>? ?? {};
    final system = json['sys'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};

    final weatherList = json['weather'] as List? ?? [];

    final weatherData = weatherList.isNotEmpty &&
            weatherList.first is Map<String, dynamic>
        ? weatherList.first as Map<String, dynamic>
        : <String, dynamic>{};

    return WeatherModel(
      cityName: json['name']?.toString() ?? 'Unknown City',
      country: system['country']?.toString() ?? '',
      latitude: (coordinates['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (coordinates['lon'] as num?)?.toDouble() ?? 0.0,
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0.0,
      weatherCondition: weatherData['main']?.toString() ?? 'Unknown',
      weatherDescription:
          weatherData['description']?.toString() ?? 'Not available',
      weatherIcon: weatherData['icon']?.toString() ?? '',
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      pressure: (main['pressure'] as num?)?.toInt() ?? 0,
    );
  }
}
