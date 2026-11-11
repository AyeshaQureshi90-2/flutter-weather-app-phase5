
import 'package:flutter/material.dart';

import '../models/weather_model.dart';
import '../services/weather_service.dart';

class ForecastScreen extends StatefulWidget {
  final WeatherModel weather;

  const ForecastScreen({
    super.key,
    required this.weather,
  });

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  static const Color darkBlue = Color(0xFF183B66);
  static const Color backgroundColor = Color(0xFFEAF1F7);

  final WeatherService weatherService = WeatherService();

  List<Map<String, dynamic>> dailyForecast = [];

  bool isLoading = true;
  String? errorMessage;

  int timezoneOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      dailyForecast = [];
    });

    try {
      final data = await weatherService.getForecastByCoordinates(
        widget.weather.latitude,
        widget.weather.longitude,
      );

      final List<dynamic> forecastList = data['list'] ?? [];

      timezoneOffset =
          (data['city']?['timezone'] as num?)?.toInt() ?? 0;

      if (forecastList.isEmpty) {
        throw Exception('Forecast information is unavailable.');
      }

      final Map<String, List<dynamic>> groupedForecast = {};

      for (final item in forecastList) {
        final timestamp = (item['dt'] as num).toInt();

        final localDate = DateTime.fromMillisecondsSinceEpoch(
          timestamp * 1000,
          isUtc: true,
        ).add(Duration(seconds: timezoneOffset));

        final dateKey =
            '${localDate.year}-${localDate.month}-${localDate.day}';

        groupedForecast.putIfAbsent(dateKey, () => []);
        groupedForecast[dateKey]!.add(item);
      }

      final List<Map<String, dynamic>> result = [];

      for (final entry in groupedForecast.entries) {
        final items = entry.value;

        double minTemperature = double.infinity;
        double maxTemperature = double.negativeInfinity;

        dynamic selectedItem;
        int smallestDifference = 24;

        for (final item in items) {
          final main = item['main'];

          final minTemp = (main['temp_min'] as num).toDouble();
          final maxTemp = (main['temp_max'] as num).toDouble();

          if (minTemp < minTemperature) {
            minTemperature = minTemp;
          }

          if (maxTemp > maxTemperature) {
            maxTemperature = maxTemp;
          }

          final timestamp = (item['dt'] as num).toInt();

          final localDateTime =
              DateTime.fromMillisecondsSinceEpoch(
            timestamp * 1000,
            isUtc: true,
          ).add(Duration(seconds: timezoneOffset));

          final difference = (localDateTime.hour - 12).abs();

          if (difference < smallestDifference) {
            smallestDifference = difference;
            selectedItem = item;
          }
        }

        result.add({
          'date': entry.key,
          'min': minTemperature,
          'max': maxTemperature,
          'weather': selectedItem ?? items.first,
        });
      }

      result.sort((a, b) {
        return a['date'].compareTo(b['date']);
      });

      if (!mounted) return;

      setState(() {
        dailyForecast = result.take(5).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  DateTime _getCityDate() {
    return DateTime.now()
        .toUtc()
        .add(Duration(seconds: timezoneOffset));
  }

  String _getDayName(String dateKey) {
    final parts = dateKey.split('-');

    final forecastDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final today = _getCityDate();

    final todayDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final difference = forecastDate.difference(todayDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return weekdays[forecastDate.weekday - 1];
  }

  String _getDate(String dateKey) {
    final parts = dateKey.split('-');

    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
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

  Widget _buildForecastCard(Map<String, dynamic> item) {
    final weatherData = item['weather'];
    final condition =
        weatherData['weather'][0]['main'] ?? '';

    final description =
        weatherData['weather'][0]['description'] ?? '';

    final minTemp = (item['min'] as double).round();
    final maxTemp = (item['max'] as double).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDayName(item['date']),
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _getDate(item['date']),
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Column(
              children: [
                Icon(
                  _getWeatherIcon(condition),
                  color: const Color(0xFF318CE7),
                  size: 34,
                ),
                const SizedBox(height: 4),
                Text(
                  description.toString(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$maxTemp°C',
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$minTemp°C',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '5-Day Forecast',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF318CE7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadForecast,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${widget.weather.cityName}, ${widget.weather.country}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkBlue,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Weather forecast for the next 5 days',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(45),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF318CE7),
                  ),
                ),
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 55,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _loadForecast,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            else if (dailyForecast.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No forecast information available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey),
                ),
              )
            else
              ...dailyForecast.map(_buildForecastCard),

            const SizedBox(height: 15),

            const Text(
              'Note: Forecast temperatures are estimates based on available API data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
