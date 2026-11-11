import 'package:flutter/material.dart';

class HourlyForecast extends StatelessWidget {
  final List<dynamic> forecastItems;
  final int timezoneOffset;

  const HourlyForecast({
    super.key,
    required this.forecastItems,
    required this.timezoneOffset,
  });

  String _getTime(dynamic timestamp) {
    if (timestamp is! num) return '--';

    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp.toInt() * 1000,
      isUtc: true,
    ).add(Duration(seconds: timezoneOffset));

    final hour = date.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour $period';
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

  @override
  Widget build(BuildContext context) {
    final items = forecastItems
        .whereType<Map<String, dynamic>>()
        .take(8)
        .toList();

    if (items.isEmpty) {
      return const SizedBox(
        height: 125,
        child: Center(
          child: Text(
            'Hourly forecast is unavailable.',
            style: TextStyle(color: Colors.blueGrey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          final mainData = item['main'] is Map<String, dynamic>
              ? item['main'] as Map<String, dynamic>
              : <String, dynamic>{};

          final weatherList =
              item['weather'] is List ? item['weather'] as List : [];

          final weatherData = weatherList.isNotEmpty &&
                  weatherList.first is Map<String, dynamic>
              ? weatherList.first as Map<String, dynamic>
              : <String, dynamic>{};

          final condition =
              weatherData['main']?.toString() ?? 'Clouds';

          final temperature = mainData['temp'] is num
              ? (mainData['temp'] as num).round()
              : null;

          return Container(
            width: 78,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  _getTime(item['dt']),
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                  ),
                ),
                Icon(
                  _getWeatherIcon(condition),
                  color: const Color(0xFF318CE7),
                  size: 25,
                ),
                Text(
                  temperature == null ? '--' : '$temperature°C',
                  style: const TextStyle(
                    color: Color(0xFF183B66),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}