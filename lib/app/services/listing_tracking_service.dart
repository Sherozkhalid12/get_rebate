import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:get_storage/get_storage.dart';

/// Service for recording listing analytics (view, search, contact)
class ListingTrackingService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final Map<String, DateTime> _viewCallCache = {};
  final Map<String, DateTime> _searchCallCache = {};
  final Map<String, DateTime> _contactCallCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Record listing view - call when user opens listing detail
  Future<void> recordListingView(String listingId) async {
    if (listingId.isEmpty) return;
    if (_shouldSkipCall(_viewCallCache, listingId)) return;
    _viewCallCache[listingId] = DateTime.now();
    await _callGet(ApiConstants.getAddListingViewEndpoint(listingId), 'view', listingId);
  }

  /// Record listing search - call when listing appears in search results
  Future<void> recordListingSearch(String listingId) async {
    if (listingId.isEmpty) return;
    if (_shouldSkipCall(_searchCallCache, listingId)) return;
    _searchCallCache[listingId] = DateTime.now();
    await _callGet(ApiConstants.getAddListingSearchEndpoint(listingId), 'search', listingId);
  }

  /// Record listing contact - call when user taps contact on listing
  Future<void> recordListingContact(String listingId) async {
    if (listingId.isEmpty) return;
    if (_shouldSkipCall(_contactCallCache, listingId)) return;
    _contactCallCache[listingId] = DateTime.now();
    await _callGet(ApiConstants.getAddListingContactEndpoint(listingId), 'contact', listingId);
  }

  bool _shouldSkipCall(Map<String, DateTime> cache, String key) {
    final last = cache[key];
    if (last == null) return false;
    return DateTime.now().difference(last) < _cacheDuration;
  }

  Future<void> _callGet(String endpoint, String action, String listingId) async {
    try {
      final storage = GetStorage();
      final token = storage.read<String>('auth_token');
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            ...ApiConstants.ngrokHeaders,
            if (token != null) 'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => true,
        ),
      );
      if (kDebugMode) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Listing $action recorded for $listingId');
        } else {
          print('⚠️ Listing $action failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error recording listing $action: $e');
      }
    }
  }
}
