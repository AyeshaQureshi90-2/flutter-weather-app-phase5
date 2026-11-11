
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
  );

  static const String baseUrl = 'api.openweathermap.org';

  static const Duration requestTimeout = Duration(seconds: 15);

  void _checkApiKey() {
    if (apiKey.isEmpty) {
      throw Exception(
        'Weather API key is not configured. Please restart the app with the API key.',
      );
    }
  }

  Future<Map<String, dynamic>> _getData(Uri url) async {
    try {
      final response = await http.get(url).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        if (decodedData is Map<String, dynamic>) {
          return decodedData;
        }

        throw Exception(
          'Unexpected data received from weather server.',
        );
      }

      if (response.statusCode == 400) {
        throw Exception('Invalid request. Please check your input.');
      }

      if (response.statusCode == 401) {
        throw Exception(
          'Invalid API key or API key is not activated yet.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception(
          'Requested weather information was not found.',
        );
      }

      if (response.statusCode == 429) {
        throw Exception(
          'Too many API requests. Please try again later.',
        );
      }

      if (response.statusCode >= 500) {
        throw Exception(
          'Weather server is temporarily unavailable. Please try again.',
        );
      }

      throw Exception(
        'Weather request failed. Error code: ${response.statusCode}',
      );
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw Exception(
        'Request timed out. Please try again.',
      );
    } on FormatException {
      throw Exception(
        'Invalid data received from weather server.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> searchLocationsByCity(
    String city,
  ) async {
    _checkApiKey();

    final cleanedCity = city.trim();

    if (cleanedCity.isEmpty) {
      throw Exception('Please enter a city name.');
    }

    final geoUri = Uri.https(
      baseUrl,
      '/geo/1.0/direct',
      {
        'q': cleanedCity,
        'limit': '5',
        'appid': apiKey,
      },
    );

    try {
      final response = await http.get(geoUri).timeout(requestTimeout);

      if (response.statusCode == 401) {
        throw Exception(
          'Invalid API key or API key is not activated yet.',
        );
      }

      if (response.statusCode == 429) {
        throw Exception(
          'Too many API requests. Please try again later.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Unable to search this city. Please try again.',
        );
      }

      final decodedData = jsonDecode(response.body);

      if (decodedData is! List) {
        throw Exception(
          'Invalid location information received from server.',
        );
      }

      final locations = decodedData
          .whereType<Map<String, dynamic>>()
          .where(
            (location) =>
                location['lat'] is num &&
                location['lon'] is num,
          )
          .toList();

      if (locations.isEmpty) {
        throw Exception(
          'City not found. Please check the spelling.',
        );
      }

      return locations;
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw Exception(
        'City search timed out. Please try again.',
      );
    } on FormatException {
      throw Exception(
        'Invalid city information received from server.',
      );
    }
  }

  // Finds the location name using GPS coordinates.
  Future<Map<String, dynamic>?> getLocationByCoordinates(
    double latitude,
    double longitude,
  ) async {
    _checkApiKey();

    final uri = Uri.https(
      baseUrl,
      '/geo/1.0/reverse',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'limit': '1',
        'appid': apiKey,
      },
    );

    try {
      final response = await http.get(uri).timeout(requestTimeout);

      if (response.statusCode == 401) {
        throw Exception(
          'Invalid API key or API key is not activated yet.',
        );
      }

      if (response.statusCode == 429) {
        throw Exception(
          'Too many API requests. Please try again later.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Unable to find your current location name.',
        );
      }

      final decodedData = jsonDecode(response.body);

      if (decodedData is! List || decodedData.isEmpty) {
        return null;
      }

      final location = decodedData.first;

      if (location is Map<String, dynamic>) {
        return location;
      }

      return null;
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw Exception(
        'Location search timed out. Please try again.',
      );
    } on FormatException {
      throw Exception(
        'Invalid location information received from server.',
      );
    }
  }

  Future<Map<String, dynamic>> getWeatherByCity(
    String city,
  ) async {
    final locations = await searchLocationsByCity(city);

    final location = locations.first;

    final latitude = (location['lat'] as num).toDouble();
    final longitude = (location['lon'] as num).toDouble();

    return getWeatherByCoordinates(latitude, longitude);
  }

  Future<Map<String, dynamic>> getWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    _checkApiKey();

    final uri = Uri.https(
      baseUrl,
      '/data/2.5/weather',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'appid': apiKey,
        'units': 'metric',
      },
    );

    return _getData(uri);
  }

  Future<Map<String, dynamic>> getForecastByCoordinates(
    double latitude,
    double longitude,
  ) async {
    _checkApiKey();

    final uri = Uri.https(
      baseUrl,
      '/data/2.5/forecast',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'appid': apiKey,
        'units': 'metric',
      },
    );

    return _getData(uri);
  }
}
