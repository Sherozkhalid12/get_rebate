class ImageUrlHelper {
  /// Returns the image URL/path directly from the API without modification
  ///
  /// The API should return full URLs or paths that can be used directly.
  /// This method only validates and normalizes the path, but does NOT prepend base URL.
  ///
  /// Examples:
  /// - 'http://98.93.16.113:3001/uploads/image.jpg' -> 'http://98.93.16.113:3001/uploads/image.jpg' (unchanged)
  /// - '/uploads/image.jpg' -> '/uploads/image.jpg' (unchanged, use as-is)
  /// - 'uploads/image.jpg' -> 'uploads/image.jpg' (unchanged, use as-is)
  static String? buildImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    // Trim whitespace
    String url = imageUrl.trim();

    // Skip file:// URLs
    if (url.startsWith('file://')) {
      return null;
    }

    // Normalize path separators (replace backslashes with forward slashes)
    url = url.replaceAll('\\', '/');

    // Return the path as-is from the API - don't prepend base URL
    // The API should return full URLs or paths that work directly
    return url;
  }

  /// Builds a list of full image URLs from a list of relative paths
  static List<String> buildImageUrls(List<dynamic>? imagePaths) {
    if (imagePaths == null || imagePaths.isEmpty) {
      return [];
    }

    return imagePaths
        .map((path) => buildImageUrl(path?.toString()))
        .where((url) => url != null)
        .cast<String>()
        .toList();
  }
}
