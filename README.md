# Weather App 🌤️

A Flutter-based Weather App that displays real-time weather information using the OpenWeatherMap REST API.

## Features

- Search weather by city name worldwide.
- Get weather using current device location.
- Display real-time temperature and weather conditions.
- View humidity, wind speed, and other weather details.
- View weather forecasts.
- Custom splash screen and app icon.

## Technologies Used

- Flutter & Dart
- OpenWeatherMap REST API
- HTTP Package
- Geolocator Package
- JSON Parsing

## API Integration
The application uses the OpenWeatherMap API.

The following API endpoints are used:
API Endpoint	Purpose
Geocoding API	Converts city names into geographic coordinates
Current Weather API	Retrieves current weather information
Forecast API	Retrieves forecast information in three-hour intervals

## Packages Used
http: Used to send HTTP requests and retrieve weather data.

geolocator: Used to access the device's current location.

flutter_native_splash: Used to generate the native splash screen.

flutter_launcher_icons: Used to generate the Android launcher icon.

## Challenges and Solutions

Challenge 1: Kotlin Incremental Compilation Error

During the release APK build, a Kotlin incremental compilation cache error occurred.

Solution: Stopped the Gradle daemon, disabled Kotlin incremental compilation in android/gradle.properties, cleaned the Flutter project, fetched dependencies again, and successfully rebuilt the APK.

Challenge 2: Deprecated Geolocator Parameter

A deprecated parameter configuration was identified during static analysis.

Solution: Updated the location settings configuration to resolve the warning.

Challenge 3: Widget Test Error

The widget test referenced an incorrect application class.

Solution: Updated the test to use the correct WeatherApp class.

## Learning Outcomes
- REST API integration
- HTTP GET requests
- JSON parsing
- Dart model classes
- Asynchronous programming
- Location services
- Flutter widgets and layouts
- Application testing
- Android APK generation

## Testing

- `flutter analyze` : No issues found.
- Release APK built successfully.
- Tested successfully on a physical Android device.