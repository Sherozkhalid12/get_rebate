import 'package:getrebate/app/utils/api_constants.dart';

/// Helper class for building and processing image URLs
class ImageUrlHelper {
  /// Builds a full image URL from a path
  /// Returns null if the input is null or empty
  /// Returns the original URL if it's already a full HTTP/HTTPS URL
  /// Otherwise uses ApiConstants.getImageUrl() to process it
  static String? buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return null;
    }

    final trimmedPath = imagePath.trim();

    // If already a full URL, return as is
    if (trimmedPath.startsWith('http://') || trimmedPath.startsWith('https://')) {
      return trimmedPath;
    }

    // Use ApiConstants.getImageUrl() to process the path
    return ApiConstants.getImageUrl(trimmedPath);
  }
}
