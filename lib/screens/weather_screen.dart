
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../widgets/weather_info_card.dart';
import '../widgets/hourly_forecast.dart';
import 'search_screen.dart';
import 'details_screen.dart';
import 'forecast_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  static const Color darkBlue = Color(0xFF183B66);
  static const Color backgroundColor = Color(0xFFEAF1F7);

  final WeatherService weatherService = WeatherService();

  WeatherModel? currentWeather;

  List<dynamic> forecastItems = [];

  int forecastTimezoneOffset = 0;

  bool isLoading = true;
  bool isLoadingForecast = false;
  bool isUsingCurrentLocation = true;

  String? errorMessage;
  String currentCity = '';
String? currentLocationName;
  double? selectedLatitude;
  double? selectedLongitude;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      isLoading = true;
      isLoadingForecast = true;
      errorMessage = null;
      isUsingCurrentLocation = true;
      currentWeather = null;
      forecastItems = [];
      forecastTimezoneOffset = 0;
      currentCity = '';
      currentLocationName = null;
      selectedLatitude = null;
      selectedLongitude = null;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Please turn on your phone location/GPS.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Please allow location access.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Please enable it from app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        ),
      );
String? locationName;

    try {
      final location =
          await weatherService.getLocationByCoordinates(
        position.latitude,
        position.longitude,
      );

      if (location != null) {
        final name = location['name']?.toString().trim();
        final state = location['state']?.toString().trim();
        final country = location['country']?.toString().trim();

        final parts = <String>[];

        if (name != null && name.isNotEmpty) {
          parts.add(name);
        }

        if (state != null &&
            state.isNotEmpty &&
            state.toLowerCase() != name?.toLowerCase()) {
          parts.add(state);
        }

        if (country == 'PK') {
          parts.add('Pakistan');
        } else if (country != null && country.isNotEmpty) {
          parts.add(country);
        }

        if (parts.isNotEmpty) {
          locationName = parts.join(', ');
        }
      }
    } catch (e) {
      locationName = null;
    }

    final data = await weatherService.getWeatherByCoordinates(
      position.latitude,
      position.longitude,
    );

    forecastTimezoneOffset =
        (data['timezone'] as num?)?.toInt() ?? 0;

    final weather = WeatherModel.fromJson(data);

    await _loadForecast(weather);

    if (!mounted) return;

    setState(() {
      currentWeather = weather;
      currentCity = weather.cityName;
      currentLocationName = locationName;
      isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
      isLoadingForecast = false;
      errorMessage =
          e.toString().replaceFirst('Exception: ', '');
    });
  }
}
  Future<void> _loadWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    setState(() {currentLocationName = null;
      isLoading = true;
      isLoadingForecast = true;
      errorMessage = null;
      isUsingCurrentLocation = false;
      currentWeather = null;
      forecastItems = [];
      forecastTimezoneOffset = 0;
      selectedLatitude = latitude;
      selectedLongitude = longitude;
    });

    try {
      final data = await weatherService.getWeatherByCoordinates(
        latitude,
        longitude,
      );

      forecastTimezoneOffset =
          (data['timezone'] as num?)?.toInt() ?? 0;

      final weather = WeatherModel.fromJson(data);

      await _loadForecast(weather);

      if (!mounted) return;

      setState(() {
        currentWeather = weather;
        currentCity = weather.cityName;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isLoadingForecast = false;
        errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadForecast(WeatherModel weather) async {
    try {
      final data = await weatherService.getForecastByCoordinates(
        weather.latitude,
        weather.longitude,
      );

      final rawItems = data['list'];

      if (rawItems is List) {
        forecastItems = rawItems;
      } else {
        forecastItems = [];
      }

      final cityData = data['city'];

      if (cityData is Map<String, dynamic>) {
        forecastTimezoneOffset =
            (cityData['timezone'] as num?)?.toInt() ??
                forecastTimezoneOffset;
      }
    } catch (e) {
      forecastItems = [];
    } finally {
      isLoadingForecast = false;
    }
  }

  Future<void> _openSearchScreen() async {
    final selectedLocation =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );

    if (!mounted || selectedLocation == null) return;

    final latitude = selectedLocation['lat'];
    final longitude = selectedLocation['lon'];

    if (latitude is! num || longitude is! num) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid location coordinates.'),
        ),
      );
      return;
    }

    await _loadWeatherByCoordinates(
      latitude.toDouble(),
      longitude.toDouble(),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;

      case 'clouds':
        return Icons.cloud;

      case 'rain':
      case 'drizzle':
        return Icons.grain;

      case 'thunderstorm':
        return Icons.thunderstorm;

      case 'snow':
        return Icons.ac_unit;

      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.foggy;

      default:
        return Icons.cloud_queue;
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now()
        .toUtc()
        .add(Duration(seconds: forecastTimezoneOffset));

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  void _openDetails() {
    if (currentWeather == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsScreen(
          weather: currentWeather!,
        ),
      ),
    );
  }

  void _openForecast() {
    if (currentWeather == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForecastScreen(
          weather: currentWeather!,
        ),
      ),
    );
  }

  Widget _buildForecastPreview() {
    if (isLoading && isLoadingForecast) {
      return const SizedBox(
        height: 125,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF318CE7),
          ),
        ),
      );
    }

    return HourlyForecast(
      forecastItems: forecastItems,
      timezoneOffset: forecastTimezoneOffset,
    );
  }

  Future<void> _refreshWeather() async {
    if (isLoading) return;

    if (isUsingCurrentLocation) {
      await _loadCurrentLocation();
    } else if (selectedLatitude != null &&
        selectedLongitude != null) {
      await _loadWeatherByCoordinates(
        selectedLatitude!,
        selectedLongitude!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshWeather,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weather App',
                          style: TextStyle(
                            color: darkBlue,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Check your daily weather',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: isLoading ? null : _refreshWeather,
                      icon: const Icon(
                        Icons.refresh,
                        color: darkBlue,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                InkWell(
                  onTap: _openSearchScreen,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Color(0xFF318CE7),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search any city worldwide...',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          color: Color(0xFF318CE7),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                _buildMainWeatherCard(),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weather Information',
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          currentWeather == null || isLoading
                              ? null
                              : _openDetails,
                      child: const Text('See all'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (currentWeather != null && !isLoading)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
                      WeatherInfoCard(
                        icon: Icons.thermostat,
                        title: 'Feels Like',
                        value:
                            '${currentWeather!.feelsLike.round()}°C',
                      ),
                      WeatherInfoCard(
                        icon: Icons.water_drop,
                        title: 'Humidity',
                        value: '${currentWeather!.humidity}%',
                      ),
                      WeatherInfoCard(
                        icon: Icons.air,
                        title: 'Wind Speed',
                        value:
                            '${(currentWeather!.windSpeed * 3.6).toStringAsFixed(1)} km/h',
                      ),
                      WeatherInfoCard(
                        icon: Icons.compress,
                        title: 'Pressure',
                        value: '${currentWeather!.pressure} hPa',
                      ),
                    ],
                  )
                else if (!isLoading && errorMessage != null)
                  const Center(
                    child: Text(
                      'Weather information is unavailable.',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weather Forecast',
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          currentWeather == null || isLoading
                              ? null
                              : _openForecast,
                      child: const Text('View all'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _buildForecastPreview(),

                const SizedBox(height: 25),

                if (currentWeather != null && !isLoading)
                  Center(
                    child: TextButton.icon(
                      onPressed: _loadCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use My Current Location'),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF318CE7),
            Color(0xFF91C9F5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.18),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: isLoading
          ? const SizedBox(
              height: 210,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            )
          : errorMessage != null
              ? SizedBox(
                  height: 210,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: Colors.white,
                        size: 45,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: isUsingCurrentLocation
                            ? _loadCurrentLocation
                            : () {
                                if (selectedLatitude != null &&
                                    selectedLongitude != null) {
                                  _loadWeatherByCoordinates(
                                    selectedLatitude!,
                                    selectedLongitude!,
                                  );
                                }
                              },
                        child: const Text(
                          'Try Again',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : currentWeather == null
                  ? const SizedBox(
                      height: 210,
                      child: Center(
                        child: Text(
                          'Weather not available.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                currentLocationName ??
                                '${currentWeather!.cityName}, ${currentWeather!.country}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Icon(
                          _getWeatherIcon(
                            currentWeather!.weatherCondition,
                          ),
                          color: Colors.white,
                          size: 75,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '${currentWeather!.temperature.round()}°C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          currentWeather!.weatherDescription,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _getCurrentDate(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
    );
  }
}
