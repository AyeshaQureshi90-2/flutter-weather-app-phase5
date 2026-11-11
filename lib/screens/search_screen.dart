
import 'package:flutter/material.dart';

import '../services/weather_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController =
      TextEditingController();

  final WeatherService weatherService = WeatherService();

  bool isSearching = false;

  List<Map<String, dynamic>> searchResults = [];

  String? errorMessage;

  Future<void> searchCity() async {
    if (isSearching) return;

    final city = searchController.text.trim();

    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a city name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isSearching = true;
      searchResults = [];
      errorMessage = null;
    });

    try {
      final results =
          await weatherService.searchLocationsByCity(city);

      if (!mounted) return;

      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSearching = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String getCountryName(String countryCode) {
    const countryNames = {
      'PK': 'Pakistan',
      'IN': 'India',
      'US': 'United States',
      'GB': 'United Kingdom',
      'AE': 'United Arab Emirates',
      'SA': 'Saudi Arabia',
      'CA': 'Canada',
      'AU': 'Australia',
      'DE': 'Germany',
      'FR': 'France',
      'IT': 'Italy',
      'TR': 'Turkey',
      'CN': 'China',
      'JP': 'Japan',
      'BD': 'Bangladesh',
      'AF': 'Afghanistan',
      'NP': 'Nepal',
      'LK': 'Sri Lanka',
      'QA': 'Qatar',
      'KW': 'Kuwait',
      'OM': 'Oman',
    };

    return countryNames[countryCode.toUpperCase()] ??
        countryCode.toUpperCase();
  }

  void selectLocation(Map<String, dynamic> location) {
    Navigator.pop(context, location);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF1F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF318CE7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search City',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find your city',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF183B66),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search weather information for any city in the world.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 25),

            TextField(
              controller: searchController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => searchCity(),
              decoration: InputDecoration(
                hintText: 'Enter any city name...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF318CE7),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSearching ? null : searchCity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF318CE7),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF91C9F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: isSearching
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Search Weather',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 25),

            if (searchResults.isNotEmpty) ...[
              const Text(
                'Select your location',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF183B66),
                ),
              ),
              const SizedBox(height: 12),

              ...searchResults.map((location) {
                final cityName =
                    location['name']?.toString() ?? 'Unknown City';

                final state =
                    location['state']?.toString() ?? '';

                final countryCode =
                    location['country']?.toString() ?? '';

                final country = getCountryName(countryCode);

                final locationDetails = [
                  if (state.isNotEmpty) state,
                  if (country.isNotEmpty) country,
                ].join(', ');

                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEAF1F7),
                      child: Icon(
                        Icons.location_on,
                        color: Color(0xFF318CE7),
                      ),
                    ),
                    title: Text(
                      cityName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF183B66),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        locationDetails,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 17,
                      color: Color(0xFF318CE7),
                    ),
                    onTap: () => selectLocation(location),
                  ),
                );
              }),
            ],

            if (errorMessage != null) ...[
              const SizedBox(height: 15),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 45,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (searchResults.isEmpty &&
                errorMessage == null &&
                !isSearching) ...[
              const SizedBox(height: 35),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.public,
                      size: 65,
                      color: Color(0xFF318CE7),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Explore Weather Worldwide',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF183B66),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter a city name to discover its current weather information.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
