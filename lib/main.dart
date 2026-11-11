
import 'package:flutter/material.dart';
import 'screens/weather_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFEAF1F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF318CE7),
        ),
      ),
      home: const WeatherScreen(),
    );
  }
}
