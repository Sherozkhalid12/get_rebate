/// Utility class for formatting ZIP codes with city names consistently throughout the app
class ZipCodeFormatter {
  ZipCodeFormatter._();

  /// Formats a ZIP code with city name if available
  /// Returns "55044 (Lakeville)" if city is available, otherwise just "55044"
  static String formatZipWithCity({
    required String zipCode,
    String? city,
  }) {
    if (city != null && city.isNotEmpty && city.trim().isNotEmpty) {
      return '$zipCode (${city.trim()})';
    }
    return zipCode;
  }

  /// Formats a ZIP code with city and state for dropdowns
  /// Returns "55044 (Lakeville) • MN" if city is available, otherwise "55044 • MN"
  static String formatZipWithCityAndState({
    required String zipCode,
    String? city,
    required String state,
  }) {
    final zipDisplay = formatZipWithCity(zipCode: zipCode, city: city);
    return '$zipDisplay • $state';
  }
}
