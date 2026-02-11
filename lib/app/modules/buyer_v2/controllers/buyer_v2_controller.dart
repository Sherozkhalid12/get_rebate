import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/models/mortgage_types.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/models/open_house_model.dart';
import 'package:getrebate/app/models/agent_listing_model.dart';
import 'package:getrebate/app/services/listing_service.dart';
import 'package:getrebate/app/services/agent_service.dart';
import 'package:getrebate/app/services/loan_officer_service.dart';
import 'package:getrebate/app/services/zip_codes_service.dart';
import 'package:getrebate/app/controllers/location_controller.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/modules/favorites/controllers/favorites_controller.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/utils/rebate_restricted_states.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class BuyerV2Controller extends GetxController {
  final LocationController _locationController = Get.find<LocationController>();
  final AuthController _authController = Get.find<AuthController>();

  // Search
  final searchController = TextEditingController();
  final _searchQuery = ''.obs;
  final _selectedTab =
      0.obs; // 0: Agents, 1: Homes for Sale, 2: Open Houses, 3: Loan Officers
  final _currentZipCode = Rxn<String>(); // Current ZIP code filter
  final _isFetchingLocation =
      false.obs; // Loading state when tapping location icon
  /// ZIP -> distance (miles) for zips within 10mi; used to filter & sort agents/LOs
  Map<String, double>? _within10MilesMap;
  final _agentsDisplayCount = 10.obs;
  final _loanOfficersDisplayCount = 10.obs;
  final _listingsDisplayCount = 10.obs;
  final _openHousesDisplayCount = 10.obs;

  // Data - Store original unfiltered data
  final _allAgents = <AgentModel>[].obs;
  final _allLoanOfficers = <LoanOfficerModel>[].obs;
  final _allListings = <Listing>[].obs;
  final _allOpenHouses = <OpenHouseModel>[].obs;

  // Filtered data (computed from originals based on ZIP code)
  final _agents = <AgentModel>[].obs;
  final _loanOfficers = <LoanOfficerModel>[].obs;
  final _listings = <Listing>[].obs;
  final _openHouses = <OpenHouseModel>[].obs;
  final _favoriteAgents = <String>[].obs;
  final _favoriteLoanOfficers = <String>[].obs;
  final _favoriteListings = <String>[].obs;
  final _isLoading = false.obs;
  final _selectedBuyerAgent =
      Rxn<AgentModel>(); // Track the buyer's selected agent
  final _togglingFavorites =
      <String>{}.obs; // Track which IDs are currently being toggled

  // Pagination for agents
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalAgents = 0.obs;
  final RxBool _isLoadingMoreAgents = false.obs;

  bool get canLoadMoreAgents => currentPage.value < totalPages.value;
  bool get isLoadingMoreAgents => _isLoadingMoreAgents.value;

  void showNext10Agents() {
    _agentsDisplayCount.value = _agentsDisplayCount.value + 10;
  }

  void showNext10LoanOfficers() {
    _loanOfficersDisplayCount.value = _loanOfficersDisplayCount.value + 10;
  }

  void showNext10Listings() {
    _listingsDisplayCount.value = _listingsDisplayCount.value + 10;
  }

  void showNext10OpenHouses() {
    _openHousesDisplayCount.value = _openHousesDisplayCount.value + 10;
  }

  // Services
  final ListingService _listingService = InMemoryListingService();
  final AgentService _agentService = AgentService();
  final LoanOfficerService _loanOfficerService = LoanOfficerService();
  final ZipCodesService _zipCodesService = ZipCodesService();

  // Dio for API calls
  final Dio _dio = Dio();

  // Getters
  String get searchQuery => _searchQuery.value;
  int get selectedTab => _selectedTab.value;
  String? get currentZipCode => _currentZipCode.value;
  List<AgentModel> get agents => _agents;
  List<LoanOfficerModel> get loanOfficers => _loanOfficers;

  /// First N agents (for "View next 10" pagination when ZIP filter active)
  List<AgentModel> get displayedAgents {
    final n = _agentsDisplayCount.value;
    if (_agents.length <= n) return _agents;
    return _agents.take(n).toList();
  }

  List<LoanOfficerModel> get displayedLoanOfficers {
    final n = _loanOfficersDisplayCount.value;
    if (_loanOfficers.length <= n) return _loanOfficers;
    return _loanOfficers.take(n).toList();
  }

  bool get canShowNext10Agents =>
      _currentZipCode.value != null &&
      _agents.length > _agentsDisplayCount.value;
  bool get canShowNext10LoanOfficers =>
      _currentZipCode.value != null &&
      _loanOfficers.length > _loanOfficersDisplayCount.value;
  List<Listing> get listings => _listings;
  List<OpenHouseModel> get openHouses => _openHouses;
  List<Listing> get displayedListings {
    final n = _listingsDisplayCount.value;
    if (_listings.length <= n) return _listings;
    return _listings.take(n).toList();
  }

  List<OpenHouseModel> get displayedOpenHouses {
    final n = _openHousesDisplayCount.value;
    if (_openHouses.length <= n) return _openHouses;
    return _openHouses.take(n).toList();
  }

  bool get canShowNext10Listings =>
      _currentZipCode.value != null &&
      _listings.length > _listingsDisplayCount.value;
  bool get canShowNext10OpenHouses =>
      _currentZipCode.value != null &&
      _openHouses.length > _openHousesDisplayCount.value;
  List<String> get favoriteAgents => _favoriteAgents;
  List<String> get favoriteLoanOfficers => _favoriteLoanOfficers;
  List<String> get favoriteListings => _favoriteListings;
  bool get isLoading => _isLoading.value;
  bool get isFetchingLocation => _isFetchingLocation.value;
  AgentModel? get selectedBuyerAgent => _selectedBuyerAgent.value;
  bool get hasSelectedAgent => _selectedBuyerAgent.value != null;

  @override
  void onInit() {
    super.onInit();
    _setupDio();
    _printUserId();
    _loadMockData();
    searchController.addListener(_onSearchChanged);
    _preloadThreads();
    _tryAutoFillFromLocation();
  }

  void _setupDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(
      seconds: 10,
    ); // Reduced from 30 to 10
    _dio.options.receiveTimeout = const Duration(
      seconds: 10,
    ); // Reduced from 30 to 10
    _dio.options.headers = {
      ...ApiConstants.ngrokHeaders,
      'Content-Type': 'application/json',
    };
  }

  /// Preloads chat threads for instant access when user opens messages
  void _preloadThreads() {
    // Defer to next frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (_authController.isLoggedIn && _authController.currentUser != null) {
          // Initialize messages controller if not already registered
          if (!Get.isRegistered<MessagesController>()) {
            Get.put(MessagesController(), permanent: true);
          }
          final messagesController = Get.find<MessagesController>();
          // Load threads in background - don't wait
          messagesController.refreshThreads();
          print('🚀 Home: Preloading chat threads in background...');
        }
      } catch (e) {
        print('⚠️ Home: Failed to preload threads: $e');
      }
    });
  }

  void _printUserId() {
    final user = _authController.currentUser;
    if (user != null) {
      print('🏠 Home Screen - User ID: ${user.id}');
      print('   Email: ${user.email}');
      print('   Name: ${user.name}');
      print('   Role: ${user.role}');
    } else {
      print('⚠️ Home Screen - No user logged in');
    }
  }

  /// Auto-fill search bar with current zip on home load. Uses cached zip from
  /// splash if available; otherwise fetches in background.
  void _tryAutoFillFromLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (searchController.text.trim().isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              '📍 Auto-fill skipped: search field already has value "${searchController.text}"',
            );
          }
          return;
        }

        // Use cached zip if already fetched (e.g. from splash)
        var zipCode = _locationController.currentZipCode;
        if (zipCode == null ||
            zipCode.length != 5 ||
            !RegExp(r'^\d+$').hasMatch(zipCode)) {
          final granted = await _locationController.isPermissionGranted();
          if (!granted) return;
          await _locationController.getCurrentLocation();
          zipCode = _locationController.currentZipCode;
        }

        if (zipCode != null &&
            zipCode.length == 5 &&
            RegExp(r'^\d+$').hasMatch(zipCode)) {
          searchController
            ..text = zipCode
            ..selection = TextSelection.collapsed(offset: zipCode.length);
          await searchByZipCode(zipCode);
          if (kDebugMode) {
            debugPrint('📍 Auto-filled search bar with current ZIP: $zipCode');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Auto-fill location failed: $e');
          debugPrintStack(label: 'auto_fill_location');
        }
      }
    });
  }

  /// Use cached current zip in search bar (called when user taps location icon).
  /// Location is pre-fetched on splash/home, so this renders instantly.
  Future<void> useCurrentLocation() async {
    if (kDebugMode) {
      debugPrint('📍 useCurrentLocation() triggered');
    }
    final zipCode = _locationController.currentZipCode;
    if (kDebugMode) {
      debugPrint('   → Cached ZIP: $zipCode');
    }
    if (zipCode != null &&
        zipCode.length == 5 &&
        RegExp(r'^\d+$').hasMatch(zipCode)) {
      searchController
        ..text = zipCode
        ..selection = TextSelection.collapsed(offset: zipCode.length);
      await searchByZipCode(zipCode);
      if (kDebugMode) {
        debugPrint('📍 Location tap populated ZIP: $zipCode');
      }
    } else {
      SnackbarHelper.showInfo(
        'Location not ready yet. Please wait a moment and try again, or enter ZIP manually.',
        title: 'Location',
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _onSearchChanged() {
    _searchQuery.value = searchController.text;
    _searchAgentsAndLoanOfficers();
  }

  void setSelectedTab(int index) {
    _selectedTab.value = index;
  }

  void _loadMockData() async {
    // Load all data in parallel for faster loading
    _isLoading.value = true;

    try {
      // Start all API calls in parallel
      final results = await Future.wait([
        _loadAgentsFromAPI(),
        _loadLoanOfficersFromAPI(),
        _loadListingsFromAPI(),
      ], eagerError: false); // Don't fail all if one fails

      // Extract open houses after listings are loaded
      _extractOpenHousesFromListings();

      if (kDebugMode) {
        print('✅ All data loaded in parallel');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Some data failed to load: $e');
      }
      // Continue with whatever data loaded successfully
    } finally {
      _isLoading.value = false;
    }
  }

  /// Loads agents from the API with pagination
  Future<void> _loadAgentsFromAPI() async {
    try {
      currentPage.value = 1; // Reset to first page

      if (kDebugMode) {
        print('📡 Fetching agents from API (page ${currentPage.value})...');
      }

      final response = await _agentService.getAllAgentsPaginated(
        page: currentPage.value,
      );

      // Store pagination metadata
      currentPage.value = response.page;
      totalPages.value = response.totalPages;
      totalAgents.value = response.totalAgents;

      // Profile images are already normalized in AgentModel.fromJson, but use helper for consistency
      final agentsWithUrls = response.agents.map((agent) {
        // Use helper to ensure normalization (models already do this, but ensure consistency)
        final profileImage = ApiConstants.getImageUrl(agent.profileImage);
        final companyLogo = ApiConstants.getImageUrl(agent.companyLogoUrl);

        return agent.copyWith(
          profileImage: profileImage,
          companyLogoUrl: companyLogo,
        );
      }).toList();

      _allAgents.value = agentsWithUrls;
      _applyZipCodeFilter(); // Apply filter after loading

      // Initialize favorite agents list based on likes array from API
      final currentUser = _authController.currentUser;
      if (currentUser != null && currentUser.id.isNotEmpty) {
        _favoriteAgents.clear();
        for (final agent in agentsWithUrls) {
          if (agent.likes != null && agent.likes!.contains(currentUser.id)) {
            if (!_favoriteAgents.contains(agent.id)) {
              _favoriteAgents.add(agent.id);
            }
          }
        }
        if (kDebugMode) {
          print(
            '✅ Initialized ${_favoriteAgents.length} favorite agents from API likes',
          );
        }
      }

      if (kDebugMode) {
        print('✅ Loaded ${agentsWithUrls.length} agents from API');
        print('   Page: ${currentPage.value}/${totalPages.value}');
        print('   Total agents: ${totalAgents.value}');
        print('   Can load more: $canLoadMoreAgents');
      }
    } catch (e) {
      print('❌ Error loading agents: $e');
      // Don't show snackbar - it causes overlay errors on initial load
      // Just log the error and keep empty list
      _allAgents.value = [];
      _applyZipCodeFilter(); // Apply filter after setting empty list
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load more agents from next page
  Future<void> loadMoreAgents() async {
    if (!canLoadMoreAgents || _isLoadingMoreAgents.value) {
      return;
    }

    _isLoadingMoreAgents.value = true;
    final nextPage = currentPage.value + 1;

    try {
      if (kDebugMode) {
        print('📡 Loading more agents (page $nextPage)...');
      }

      // Fetch next page
      final response = await _agentService.getAllAgentsPaginated(
        page: nextPage,
      );

      // Update pagination metadata
      currentPage.value = response.page;
      totalPages.value = response.totalPages;
      totalAgents.value = response.totalAgents;

      // Profile images are already normalized in AgentModel.fromJson, but use helper for consistency
      final agentsWithUrls = response.agents.map((agent) {
        // Use helper to ensure normalization (models already do this, but ensure consistency)
        final profileImage = ApiConstants.getImageUrl(agent.profileImage);
        final companyLogo = ApiConstants.getImageUrl(agent.companyLogoUrl);

        return agent.copyWith(
          profileImage: profileImage,
          companyLogoUrl: companyLogo,
        );
      }).toList();

      // Add new agents to the existing list
      final updatedAgents = List<AgentModel>.from(_allAgents.value);
      updatedAgents.addAll(agentsWithUrls);
      _allAgents.value = updatedAgents;

      // Apply ZIP code filter to updated list
      _applyZipCodeFilter();

      // Initialize favorites for new agents
      final currentUser = _authController.currentUser;
      if (currentUser != null && currentUser.id.isNotEmpty) {
        for (final agent in agentsWithUrls) {
          if (agent.likes != null && agent.likes!.contains(currentUser.id)) {
            if (!_favoriteAgents.contains(agent.id)) {
              _favoriteAgents.add(agent.id);
            }
          }
        }
      }

      if (kDebugMode) {
        print('✅ Successfully loaded ${agentsWithUrls.length} more agents');
        print('   Page: ${currentPage.value}/${totalPages.value}');
        print('   Total agents loaded: ${_allAgents.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading more agents: $e');
      }
      SnackbarHelper.showError('Failed to load more agents. Please try again.');
    } finally {
      _isLoadingMoreAgents.value = false;
    }
  }

  /// Loads loan officers from the API
  Future<void> _loadLoanOfficersFromAPI() async {
    try {
      if (kDebugMode) {
        print('📡 Fetching loan officers from API...');
      }

      final loanOfficers = await _loanOfficerService.getAllLoanOfficers();

      // Profile images are already normalized in LoanOfficerModel.fromJson, but use helper for consistency
      final loanOfficersWithUrls = loanOfficers.map((loanOfficer) {
        // Use helper to ensure normalization (models already do this, but ensure consistency)
        final profileImage = ApiConstants.getImageUrl(loanOfficer.profileImage);
        final companyLogo = ApiConstants.getImageUrl(
          loanOfficer.companyLogoUrl,
        );

        return loanOfficer.copyWith(
          profileImage: profileImage,
          companyLogoUrl: companyLogo,
        );
      }).toList();

      _allLoanOfficers.value = loanOfficersWithUrls;
      _applyZipCodeFilter(); // Apply filter after loading

      // Initialize favorite loan officers list based on likes array from API
      final currentUser = _authController.currentUser;
      if (currentUser != null && currentUser.id.isNotEmpty) {
        _favoriteLoanOfficers.clear();
        for (final loanOfficer in loanOfficersWithUrls) {
          if (loanOfficer.likes != null &&
              loanOfficer.likes!.contains(currentUser.id)) {
            if (!_favoriteLoanOfficers.contains(loanOfficer.id)) {
              _favoriteLoanOfficers.add(loanOfficer.id);
            }
          }
        }
        if (kDebugMode) {
          print(
            '✅ Initialized ${_favoriteLoanOfficers.length} favorite loan officers from API likes',
          );
        }
      }

      if (kDebugMode) {
        print('✅ Loaded ${loanOfficersWithUrls.length} loan officers from API');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading loan officers: $e');
      }
      // Don't show snackbar - it causes overlay errors on initial load
      // Just log the error and keep empty list
      _allLoanOfficers.value = [];
      _applyZipCodeFilter(); // Apply filter after setting empty list
    }
  }

  /// Loads listings from the API
  Future<void> _loadListingsFromAPI() async {
    try {
      if (kDebugMode) {
        print('📡 Fetching listings from API...');
      }

      // Setup Dio headers
      final GetStorage storage = GetStorage();
      final authToken = storage.read('auth_token');

      _dio.options.headers = {
        ...ApiConstants.ngrokHeaders,
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      // Call the API endpoint - get all listings (no agentId = all listings)
      final endpoint = ApiConstants.getAllListingsEndpoint();
      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        final List<dynamic> listingsData = responseData is List
            ? responseData
            : (responseData['listings'] as List? ??
                  responseData['data'] as List? ??
                  []);

        final List<Listing> fetchedListings = [];
        final List<OpenHouseModel> extractedOpenHouses = [];
        int openHouseIndex = 0;

        for (final listingJson in listingsData) {
          try {
            // Parse as AgentListingModel first (handles API format)
            final agentListing = AgentListingModel.fromApiJson(listingJson);

            // Process photo URLs - encode URLs with spaces and special characters
            final processedPhotoUrls = agentListing.photoUrls
                .map((url) {
                  final trimmed = url?.trim() ?? '';
                  if (trimmed.isEmpty) return null;
                  // Properly encode URLs with spaces and special characters
                  return ApiConstants.getImageUrl(trimmed);
                })
                .where((url) => url != null && url.isNotEmpty)
                .cast<String>()
                .toList();

            // Log image URLs for debugging
            if (kDebugMode && processedPhotoUrls.isNotEmpty) {
              print('\n🖼️ IMAGE URLS for Listing ${agentListing.id}:');
              print(
                '   Address: ${agentListing.address}, ${agentListing.city}, ${agentListing.state} ${agentListing.zipCode}',
              );
              print('   Total Images: ${processedPhotoUrls.length}');
              for (int i = 0; i < processedPhotoUrls.length; i++) {
                print('   [${i + 1}] ${processedPhotoUrls[i]}');
                // Check if URL is valid
                try {
                  final uri = Uri.parse(processedPhotoUrls[i]);
                  print(
                    '      ✅ Valid URI - Scheme: ${uri.scheme}, Host: ${uri.host}',
                  );
                  if (uri.path.contains(' ') ||
                      uri.path.contains('(') ||
                      uri.path.contains(')')) {
                    print(
                      '      ⚠️  Path contains unencoded characters: ${uri.path}',
                    );
                  }
                } catch (e) {
                  print('      ❌ Invalid URI: $e');
                }
              }
            }

            // Convert to Listing model
            final listing = Listing(
              id: agentListing.id,
              agentId: agentListing.agentId,
              priceCents: agentListing.priceCents,
              address: ListingAddress(
                street: agentListing.address,
                city: agentListing.city,
                state: agentListing.state,
                zip: agentListing.zipCode,
              ),
              photoUrls: processedPhotoUrls,
              bacPercent: agentListing.bacPercent,
              dualAgencyAllowed: agentListing.dualAgencyAllowed,
              dualAgencyCommissionPercent:
                  agentListing.dualAgencyCommissionPercent,
              createdAt: agentListing.createdAt,
              stats: ListingStats(
                searches: agentListing.searchCount,
                views: agentListing.viewCount,
                contacts: agentListing.contactCount,
              ),
            );

            fetchedListings.add(listing);

            // Check if listing is liked by current user (from API response)
            if (listingJson is Map<String, dynamic>) {
              final likes = listingJson['likes'] as List?;
              final currentUser = _authController.currentUser;
              if (currentUser != null && currentUser.id.isNotEmpty) {
                if (likes != null && likes.isNotEmpty) {
                  final isLiked = likes.contains(currentUser.id);
                  if (isLiked && !_favoriteListings.contains(listing.id)) {
                    _favoriteListings.add(listing.id);
                  } else if (!isLiked &&
                      _favoriteListings.contains(listing.id)) {
                    _favoriteListings.remove(listing.id);
                  }
                } else {
                  // If likes array is empty or null, ensure listing is not in favorites
                  if (_favoriteListings.contains(listing.id)) {
                    _favoriteListings.remove(listing.id);
                  }
                }
              }

              // Extract open houses from listing data
              final openHousesData = listingJson['openHouses'] as List?;
              if (openHousesData != null && openHousesData.isNotEmpty) {
                for (final ohData in openHousesData) {
                  try {
                    if (ohData is Map<String, dynamic>) {
                      // Parse open house date/time
                      DateTime? startTime;
                      DateTime? endTime;

                      // Try different date formats from API
                      final dateStr =
                          ohData['date']?.toString() ??
                          ohData['startDateTime']?.toString() ??
                          ohData['startTime']?.toString() ??
                          '';
                      final fromTimeStr =
                          ohData['fromTime']?.toString() ?? '10:00';
                      final toTimeStr = ohData['toTime']?.toString() ?? '16:00';

                      if (dateStr.isNotEmpty) {
                        try {
                          final baseDate = DateTime.parse(
                            dateStr.split('T')[0],
                          ); // Get date part
                          // Parse time strings (handle formats like "10:00 AM", "14:00", etc.)
                          startTime = _parseDateTimeWithTime(
                            baseDate,
                            fromTimeStr,
                          );
                          endTime = _parseDateTimeWithTime(baseDate, toTimeStr);
                        } catch (e) {
                          if (kDebugMode) {
                            print('⚠️ Error parsing open house date: $e');
                          }
                        }
                      }

                      // Default to future date if parsing failed
                      startTime ??= DateTime.now().add(
                        Duration(days: openHouseIndex + 1, hours: 14),
                      );
                      endTime ??= startTime!.add(const Duration(hours: 2));

                      extractedOpenHouses.add(
                        OpenHouseModel(
                          id:
                              ohData['id']?.toString() ??
                              ohData['_id']?.toString() ??
                              'oh_$openHouseIndex',
                          listingId: listing.id,
                          agentId: listing.agentId,
                          startTime: startTime!,
                          endTime: endTime,
                          notes: ohData['notes']?.toString(),
                          createdAt: ohData['createdAt'] != null
                              ? DateTime.parse(ohData['createdAt'])
                              : DateTime.now(),
                        ),
                      );
                      openHouseIndex++;
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('⚠️ Error parsing open house: $e');
                    }
                  }
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error parsing listing: $e');
            }
          }
        }

        // Deduplicate open houses by listingId and startTime
        final Map<String, OpenHouseModel> uniqueOpenHouses = {};
        int duplicateCount = 0;
        for (final openHouse in extractedOpenHouses) {
          // Create a unique key based on listingId and startTime
          final key =
              '${openHouse.listingId}_${openHouse.startTime.millisecondsSinceEpoch}';
          if (!uniqueOpenHouses.containsKey(key)) {
            uniqueOpenHouses[key] = openHouse;
          } else {
            duplicateCount++;
            if (kDebugMode) {
              print('⚠️ Duplicate open house detected and removed:');
              print('   Listing ID: ${openHouse.listingId}');
              print('   Start Time: ${openHouse.startTime}');
              print('   Open House ID: ${openHouse.id}');
            }
          }
        }

        if (kDebugMode && duplicateCount > 0) {
          print(
            '🔍 Deduplication: Removed $duplicateCount duplicate open house(s)',
          );
          print('   Before: ${extractedOpenHouses.length} open houses');
          print('   After: ${uniqueOpenHouses.length} unique open houses');
        }

        _allListings.value = fetchedListings;
        _allOpenHouses.value = uniqueOpenHouses.values.toList();

        // Refresh favorite listings to ensure UI updates
        _favoriteListings.refresh();

        _applyZipCodeFilter(); // Apply filter after loading

        if (kDebugMode) {
          print('\n' + '=' * 80);
          print('🖼️ ALL IMAGE URLS FROM LISTINGS ON HOME SCREEN');
          print('=' * 80);
          print('✅ Loaded ${fetchedListings.length} listings from API');
          print(
            '✅ Extracted ${extractedOpenHouses.length} open houses from listings',
          );

          // Print all image URLs from all listings
          for (int i = 0; i < fetchedListings.length; i++) {
            final listing = fetchedListings[i];
            print('\n📋 Listing #${i + 1} (ID: ${listing.id}):');
            print('   Address: ${listing.address}');
            print('   ZIP Code: ${listing.address.zip}');
            print('   Photo URLs (${listing.photoUrls.length}):');
            if (listing.photoUrls.isEmpty) {
              print('      ⚠️  No images available');
            } else {
              for (int j = 0; j < listing.photoUrls.length; j++) {
                final url = listing.photoUrls[j];
                print('      [${j + 1}] $url');
                // Validate URL
                try {
                  final uri = Uri.parse(url);
                  if (uri.path.contains(' ') ||
                      uri.path.contains('(') ||
                      uri.path.contains(')')) {
                    print('         ⚠️  Contains unencoded characters in path');
                  } else {
                    print('         ✅ URL appears properly formatted');
                  }
                } catch (e) {
                  print('         ❌ Invalid URL format: $e');
                }
              }
            }
          }

          // Print all homes for sale data
          print('\n' + '=' * 80);
          print('🏠 HOMES FOR SALE - FULL DATA');
          print('=' * 80);
          for (int i = 0; i < fetchedListings.length; i++) {
            final listing = fetchedListings[i];
            print('\n📋 Listing #${i + 1}:');
            print('   ID: ${listing.id}');
            print('   Agent ID: ${listing.agentId}');
            print(
              '   Price: \$${(listing.priceCents / 100).toStringAsFixed(2)} (${listing.priceCents} cents)',
            );
            print('   Address:');
            print('     Street: ${listing.address.street}');
            print('     City: ${listing.address.city}');
            print('     State: ${listing.address.state}');
            print('     ZIP: ${listing.address.zip}');
            print('     Full Address: ${listing.address.toString()}');
            print('   Photos (${listing.photoUrls.length}):');
            for (int j = 0; j < listing.photoUrls.length; j++) {
              print('     [${j + 1}] ${listing.photoUrls[j]}');
            }
            print('   BAC Percent: ${listing.bacPercent}%');
            print('   Dual Agency Allowed: ${listing.dualAgencyAllowed}');
            if (listing.dualAgencyCommissionPercent != null) {
              print(
                '   Dual Agency Commission: ${listing.dualAgencyCommissionPercent}%',
              );
            }
            print('   Created At: ${listing.createdAt}');
            print('   Stats:');
            print('     Searches: ${listing.stats.searches}');
            print('     Views: ${listing.stats.views}');
            print('     Contacts: ${listing.stats.contacts}');
            print('   JSON: ${listing.toJson()}');
            if (i < fetchedListings.length - 1) {
              print('   ' + '-' * 76);
            }
          }
          print('\n' + '=' * 80);
          print('✅ Total Listings: ${fetchedListings.length}');
          print('=' * 80 + '\n');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ No listings data in API response');
        }
        _allListings.value = [];
        _allOpenHouses.value = [];
        _applyZipCodeFilter(); // Apply filter after loading
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading listings: $e');
      }
      _allListings.value = [];
      _allOpenHouses.value = [];
      _applyZipCodeFilter(); // Apply filter after loading
    }
  }

  /// Helper method to parse date with time string
  DateTime _parseDateTimeWithTime(DateTime baseDate, String timeStr) {
    try {
      // Handle formats like "10:00 AM", "14:00", "2:00 PM", etc.
      timeStr = timeStr.trim();
      bool isPM = timeStr.toUpperCase().contains('PM');
      timeStr = timeStr
          .replaceAll(RegExp(r'[AP]M', caseSensitive: false), '')
          .trim();

      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1].split(RegExp(r'[^0-9]'))[0]);

        // Convert to 24-hour format if needed
        if (isPM && hour < 12) {
          hour += 12;
        } else if (!isPM && hour == 12) {
          hour = 0;
        }

        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          hour,
          minute,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error parsing time: $timeStr, error: $e');
      }
    }

    // Default to 10:00 if parsing fails
    return DateTime(baseDate.year, baseDate.month, baseDate.day, 10, 0);
  }

  /// Extracts open houses from listings data (kept for backward compatibility)
  /// This is now called from _loadListingsFromAPI, but kept as separate method if needed
  void _extractOpenHousesFromListings() {
    // This method is now integrated into _loadListingsFromAPI
    // Kept for backward compatibility
    if (kDebugMode) {
      print(
        'ℹ️ Open houses extraction is now integrated into _loadListingsFromAPI',
      );
    }
  }

  void _loadMockLoanOfficers_OLD() {
    // OLD MOCK DATA - REPLACED WITH API
    _loanOfficers.value = [
      LoanOfficerModel(
        id: 'loan_1',
        name: 'Jennifer Davis',
        email: 'jennifer@example.com',
        phone: '+1 (555) 345-6789',
        company: 'First National Bank',
        licenseNumber: 'LO123456',
        licensedStates: ['NY', 'NJ', 'CT'],
        claimedZipCodes: ['10001', '10002'],
        specialtyProducts: [
          MortgageTypes.fhaLoans,
          MortgageTypes.vaLoans,
          MortgageTypes.conventionalConforming,
        ],
        bio:
            'Senior loan officer with expertise in conventional and FHA loans. Over 15 years of experience helping clients secure the best rates.',
        rating: 4.9,
        reviewCount: 156,
        searchesAppearedIn: 67,
        profileViews: 289,
        contacts: 134,
        allowsRebates: true,
        mortgageApplicationUrl: 'https://www.example.com/apply/jennifer-davis',
        externalReviewsUrl:
            'https://www.google.com/search?q=jennifer+davis+loan+officer+reviews',
        platformRating: 4.8,
        platformReviewCount: 12,
        createdAt: DateTime.now().subtract(const Duration(days: 400)),
        isVerified: true,
      ),
      LoanOfficerModel(
        id: 'loan_2',
        name: 'Robert Wilson',
        email: 'robert@example.com',
        phone: '+1 (555) 456-7890',
        company: 'Chase Mortgage',
        licenseNumber: 'LO234567',
        licensedStates: ['NY', 'PA'],
        claimedZipCodes: ['10002', '10003'],
        specialtyProducts: [
          MortgageTypes.conventionalNonConforming,
          MortgageTypes.conventionalPortfolio,
          MortgageTypes.interestOnly,
        ],
        bio:
            'Specializing in jumbo loans and investment properties. Expert in complex financing scenarios.',
        rating: 4.7,
        reviewCount: 98,
        searchesAppearedIn: 43,
        profileViews: 187,
        contacts: 76,
        allowsRebates: true,
        mortgageApplicationUrl: 'https://www.example.com/apply/robert-wilson',
        externalReviewsUrl:
            'https://www.zillow.com/lender-profile/robert-wilson',
        platformRating: 0.0,
        platformReviewCount: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 350)),
        isVerified: true,
      ),
      LoanOfficerModel(
        id: 'loan_3',
        name: 'Maria Garcia',
        email: 'maria@example.com',
        phone: '+1 (555) 567-8901',
        company: 'Wells Fargo Home Mortgage',
        licenseNumber: 'LO345678',
        licensedStates: ['NY', 'NJ'],
        claimedZipCodes: ['11201', '11205'],
        bio:
            'Bilingual loan officer specializing in first-time homebuyer programs and FHA loans.',
        rating: 4.8,
        reviewCount: 124,
        searchesAppearedIn: 52,
        profileViews: 234,
        contacts: 89,
        allowsRebates: true,
        mortgageApplicationUrl: 'https://www.example.com/apply/maria-garcia',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        isVerified: true,
      ),
      LoanOfficerModel(
        id: 'loan_4',
        name: 'James Thompson',
        email: 'james@example.com',
        phone: '+1 (555) 678-9012',
        company: 'Bank of America',
        licenseNumber: 'LO456789',
        licensedStates: ['NY', 'CT', 'NJ'],
        claimedZipCodes: ['11375', '11377'],
        bio:
            'VA loan specialist with extensive experience helping veterans and active military members secure home financing.',
        rating: 4.9,
        reviewCount: 187,
        searchesAppearedIn: 71,
        profileViews: 312,
        contacts: 145,
        allowsRebates: true,
        mortgageApplicationUrl: 'https://www.example.com/apply/james-thompson',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        isVerified: true,
      ),
    ];
  }

  void _loadMockOpenHouses() {
    // Create mock open houses for the listings - only if we have listings with IDs
    if (_listings.isEmpty) return;

    final now = DateTime.now();
    final List<OpenHouseModel> mockOpenHouses = [];

    // Get listings that have valid IDs (not empty string)
    final listingsWithIds = _listings.where((l) => l.id.isNotEmpty).toList();

    if (listingsWithIds.isNotEmpty) {
      mockOpenHouses.add(
        OpenHouseModel(
          id: 'oh_1',
          listingId: listingsWithIds[0].id,
          agentId: listingsWithIds[0].agentId,
          startTime: now.add(
            const Duration(days: 2, hours: 14),
          ), // Saturday 2pm
          endTime: now.add(const Duration(days: 2, hours: 16)), // Saturday 4pm
          notes: 'Refreshments will be served',
          createdAt: now,
        ),
      );
    }

    if (listingsWithIds.length > 1) {
      mockOpenHouses.add(
        OpenHouseModel(
          id: 'oh_2',
          listingId: listingsWithIds[1].id,
          agentId: listingsWithIds[1].agentId,
          startTime: now.add(const Duration(days: 3, hours: 12)), // Sunday 12pm
          endTime: now.add(const Duration(days: 3, hours: 15)), // Sunday 3pm
          notes: null,
          createdAt: now,
        ),
      );
    }

    if (listingsWithIds.length > 2) {
      mockOpenHouses.add(
        OpenHouseModel(
          id: 'oh_3',
          listingId: listingsWithIds[2].id,
          agentId: listingsWithIds[2].agentId,
          startTime: now.add(
            const Duration(days: 7, hours: 10),
          ), // Next Saturday 10am
          endTime: now.add(
            const Duration(days: 7, hours: 13),
          ), // Next Saturday 1pm
          notes: 'Open house event',
          createdAt: now,
        ),
      );
    }

    if (listingsWithIds.length > 3) {
      mockOpenHouses.add(
        OpenHouseModel(
          id: 'oh_4',
          listingId: listingsWithIds[3].id,
          agentId: listingsWithIds[3].agentId,
          startTime: now.add(
            const Duration(days: 1, hours: 11),
          ), // Tomorrow 11am
          endTime: now.add(const Duration(days: 1, hours: 14)), // Tomorrow 2pm
          notes: 'Private viewing available by appointment',
          createdAt: now,
        ),
      );
    }

    if (listingsWithIds.length > 4) {
      mockOpenHouses.add(
        OpenHouseModel(
          id: 'oh_5',
          listingId: listingsWithIds[4].id,
          agentId: listingsWithIds[4].agentId,
          startTime: now.add(
            const Duration(days: 4, hours: 13),
          ), // Thursday 1pm
          endTime: now.add(const Duration(days: 4, hours: 17)), // Thursday 5pm
          notes: 'Afternoon viewing, parking available',
          createdAt: now,
        ),
      );
    }

    if (listingsWithIds.length > 5) {
      mockOpenHouses.add(
        OpenHouseModel(
          id: 'oh_6',
          listingId: listingsWithIds[5].id,
          agentId: listingsWithIds[5].agentId,
          startTime: now.add(
            const Duration(days: 8, hours: 9),
          ), // Next Sunday 9am
          endTime: now.add(
            const Duration(days: 8, hours: 12),
          ), // Next Sunday 12pm
          notes: 'Early morning viewing, coffee provided',
          createdAt: now,
        ),
      );
    }

    if (listingsWithIds.length > 6) {
      mockOpenHouses.add(
        OpenHouseModel(
          id: 'oh_7',
          listingId: listingsWithIds[6].id,
          agentId: listingsWithIds[6].agentId,
          startTime: now.add(const Duration(days: 5, hours: 15)), // Friday 3pm
          endTime: now.add(const Duration(days: 5, hours: 18)), // Friday 6pm
          notes: 'Evening viewing with refreshments',
          createdAt: now,
        ),
      );
    }

    _allOpenHouses.value = mockOpenHouses;
    _applyZipCodeFilter(); // Apply filter after setting mock data
  }

  Future<void> _seedMockListings() async {
    final List<Listing> existing = await _listingService.listListings();
    if (existing.isNotEmpty) {
      _allListings.value = existing;
      _applyZipCodeFilter(); // Apply filter after setting existing listings
      return;
    }

    final List<Listing> seeds = [
      Listing(
        id: '',
        agentId: 'agent_1',
        priceCents: 79900000,
        address: const ListingAddress(
          street: '123 Main St',
          city: 'New York',
          state: 'NY',
          zip: '10001',
        ),
        photoUrls: const <String>[
          'https://images.unsplash.com/photo-1560185008-b033106af2fb?q=80&w=1200&auto=format&fit=crop',
        ],
        bacPercent: 2.5,
        dualAgencyAllowed: true,
        createdAt: DateTime.now(),
      ),
      Listing(
        id: '',
        agentId: 'agent_2',
        priceCents: 125000000,
        address: const ListingAddress(
          street: '45 Park Ave #12B',
          city: 'New York',
          state: 'NY',
          zip: '10002',
        ),
        photoUrls: const <String>[
          'https://images.unsplash.com/photo-1501183638710-841dd1904471?q=80&w=1200&auto=format&fit=crop',
        ],
        bacPercent: 3.0,
        dualAgencyAllowed: false,
        createdAt: DateTime.now(),
      ),
      Listing(
        id: '',
        agentId: 'agent_3',
        priceCents: 56900000,
        address: const ListingAddress(
          street: '77 Sands St',
          city: 'Brooklyn',
          state: 'NY',
          zip: '11201',
        ),
        photoUrls: const <String>[
          'https://images.unsplash.com/photo-1505691938895-1758d7feb511?q=80&w=1200&auto=format&fit=crop',
        ],
        bacPercent: 2.0,
        dualAgencyAllowed: true,
        createdAt: DateTime.now(),
      ),
      Listing(
        id: '',
        agentId: 'agent_1',
        priceCents: 95000000,
        address: const ListingAddress(
          street: '200 Central Park South',
          city: 'New York',
          state: 'NY',
          zip: '10019',
        ),
        photoUrls: const <String>[
          'https://images.unsplash.com/photo-1560448075-cbc16ba4ae9f?q=80&w=1200&auto=format&fit=crop',
        ],
        bacPercent: 2.5,
        dualAgencyAllowed: true,
        createdAt: DateTime.now(),
      ),
      Listing(
        id: '',
        agentId: 'agent_2',
        priceCents: 42500000,
        address: const ListingAddress(
          street: '88 Park Place',
          city: 'Brooklyn',
          state: 'NY',
          zip: '11217',
        ),
        photoUrls: const <String>[
          'https://images.unsplash.com/photo-1505843513577-22bb7d21e455?q=80&w=1200&auto=format&fit=crop',
        ],
        bacPercent: 2.5,
        dualAgencyAllowed: false,
        createdAt: DateTime.now(),
      ),
      Listing(
        id: '',
        agentId: 'agent_3',
        priceCents: 135000000,
        address: const ListingAddress(
          street: '150 Riverside Blvd',
          city: 'New York',
          state: 'NY',
          zip: '10069',
        ),
        photoUrls: const <String>[
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?q=80&w=1200&auto=format&fit=crop',
        ],
        bacPercent: 3.0,
        dualAgencyAllowed: true,
        createdAt: DateTime.now(),
      ),
      Listing(
        id: '',
        agentId: 'agent_4',
        priceCents: 67500000,
        address: const ListingAddress(
          street: '350 West 50th St',
          city: 'New York',
          state: 'NY',
          zip: '10019',
        ),
        photoUrls: const <String>[
          'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?q=80&w=1200&auto=format&fit=crop',
        ],
        bacPercent: 2.0,
        dualAgencyAllowed: true,
        createdAt: DateTime.now(),
      ),
    ];

    for (final Listing l in seeds) {
      await _listingService.createListing(l);
    }
    _allListings.value = await _listingService.listListings();
    _applyZipCodeFilter(); // Apply filter after loading listings

    // Print all mock listings data
    if (kDebugMode) {
      print('\n' + '=' * 80);
      print('🏠 HOMES FOR SALE (MOCK DATA) - FULL DATA');
      print('=' * 80);
      for (int i = 0; i < _allListings.length; i++) {
        final listing = _allListings[i];
        print('\n📋 Listing #${i + 1}:');
        print('   ID: ${listing.id}');
        print('   Agent ID: ${listing.agentId}');
        print(
          '   Price: \$${(listing.priceCents / 100).toStringAsFixed(2)} (${listing.priceCents} cents)',
        );
        print('   Address:');
        print('     Street: ${listing.address.street}');
        print('     City: ${listing.address.city}');
        print('     State: ${listing.address.state}');
        print('     ZIP: ${listing.address.zip}');
        print('     Full Address: ${listing.address.toString()}');
        print('   Photos (${listing.photoUrls.length}):');
        for (int j = 0; j < listing.photoUrls.length; j++) {
          print('     [${j + 1}] ${listing.photoUrls[j]}');
        }
        print('   BAC Percent: ${listing.bacPercent}%');
        print('   Dual Agency Allowed: ${listing.dualAgencyAllowed}');
        if (listing.dualAgencyCommissionPercent != null) {
          print(
            '   Dual Agency Commission: ${listing.dualAgencyCommissionPercent}%',
          );
        }
        print('   Created At: ${listing.createdAt}');
        print('   Stats:');
        print('     Searches: ${listing.stats.searches}');
        print('     Views: ${listing.stats.views}');
        print('     Contacts: ${listing.stats.contacts}');
        print('   JSON: ${listing.toJson()}');
        if (i < _allListings.length - 1) {
          print('   ' + '-' * 76);
        }
      }
      print('\n' + '=' * 80);
      print('✅ Total Mock Listings: ${_allListings.length}');
      print('=' * 80 + '\n');
    }
  }

  Future<void> _searchAgentsAndLoanOfficers() async {
    if (_searchQuery.value.isEmpty) return;

    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // In real app, this would filter based on search query and location
      // For now, we'll just show all agents/loan officers
    } catch (e) {
      SnackbarHelper.showError('Search failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Applies ZIP code filter to all data
  void _applyZipCodeFilter() {
    final zipCode = _currentZipCode.value;

    if (zipCode == null || zipCode.isEmpty) {
      _agents.value = List.from(_allAgents);
      _loanOfficers.value = List.from(_allLoanOfficers);
      _listings.value = List.from(_allListings);
      _openHouses.value = List.from(_allOpenHouses);
      _agents.refresh();
      _loanOfficers.refresh();
      _listings.refresh();
      _openHouses.refresh();
      if (kDebugMode) print('📋 Showing all data (no filter)');
      return;
    }

    final normalizedZipCode = zipCode.trim();
    final map = _within10MilesMap;
    final useWithin10 = map != null && map.isNotEmpty;

    if (useWithin10) {
      final mapNorm = map.map((k, v) => MapEntry(k.trim(), v));
      final zipSet = mapNorm.keys.toSet();

      double minDistAgent(AgentModel a) {
        double best = double.infinity;
        for (final z in [...a.claimedZipCodes, ...a.serviceZipCodes]) {
          final t = z.trim();
          if (zipSet.contains(t)) {
            final d = mapNorm[t] ?? double.infinity;
            if (d < best) best = d;
          }
        }
        for (final z in a.serviceAreas ?? []) {
          final t = z.trim();
          if (zipSet.contains(t)) {
            final d = mapNorm[t] ?? double.infinity;
            if (d < best) best = d;
          }
        }
        for (final l in _allListings) {
          if (l.agentId != a.id) continue;
          final t = (l.address.zip ?? '').trim();
          if (zipSet.contains(t)) {
            final d = mapNorm[t] ?? double.infinity;
            if (d < best) best = d;
          }
        }
        return best;
      }

      double minDistLO(LoanOfficerModel lo) {
        double best = double.infinity;
        for (final z in lo.claimedZipCodes) {
          final t = z.trim();
          if (zipSet.contains(t)) {
            final d = mapNorm[t] ?? double.infinity;
            if (d < best) best = d;
          }
        }
        return best;
      }

      final agentList = _allAgents
          .where((a) => minDistAgent(a) < double.infinity)
          .toList();
      agentList.sort((a, b) => minDistAgent(a).compareTo(minDistAgent(b)));
      _agents.value = agentList;

      final loList = _allLoanOfficers
          .where((lo) => minDistLO(lo) < double.infinity)
          .toList();
      loList.sort((a, b) => minDistLO(a).compareTo(minDistLO(b)));
      _loanOfficers.value = loList;

      final listingList = _allListings
          .where((l) => zipSet.contains((l.address.zip ?? '').trim()))
          .toList();
      listingList.sort((a, b) {
        final za = (a.address.zip ?? '').trim();
        final zb = (b.address.zip ?? '').trim();
        final da = mapNorm[za] ?? double.infinity;
        final db = mapNorm[zb] ?? double.infinity;
        return da.compareTo(db);
      });
      _listings.value = listingList;

      final listingIdToDist = <String, double>{};
      for (final l in listingList) {
        final z = (l.address.zip ?? '').trim();
        listingIdToDist[l.id] = mapNorm[z] ?? double.infinity;
      }
      final listingIds = listingIdToDist.keys.toSet();
      final ohList = _allOpenHouses
          .where((oh) => listingIds.contains(oh.listingId))
          .toList();
      ohList.sort((a, b) {
        final da = listingIdToDist[a.listingId] ?? double.infinity;
        final db = listingIdToDist[b.listingId] ?? double.infinity;
        return da.compareTo(db);
      });
      _openHouses.value = ohList;
    } else {
      _agents.value = _allAgents.where((agent) {
        final hasClaimed = agent.claimedZipCodes.any(
          (z) => z.trim() == normalizedZipCode,
        );
        final hasService = agent.serviceZipCodes.any(
          (z) => z.trim() == normalizedZipCode,
        );
        final hasArea =
            agent.serviceAreas?.any((z) => z.trim() == normalizedZipCode) ??
            false;
        final hasListing = _allListings.any(
          (l) =>
              l.agentId == agent.id &&
              (l.address.zip ?? '').trim() == normalizedZipCode,
        );
        return hasClaimed || hasService || hasArea || hasListing;
      }).toList();
      _loanOfficers.value = _allLoanOfficers
          .where(
            (lo) =>
                lo.claimedZipCodes.any((z) => z.trim() == normalizedZipCode),
          )
          .toList();
      final filteredIds = _allListings
          .where((l) => (l.address.zip ?? '').trim() == normalizedZipCode)
          .where((l) => !RebateRestrictedStates.isRestricted(l.address.state ?? ''))
          .map((l) => l.id)
          .toSet();
      _listings.value = _allListings
          .where((l) => filteredIds.contains(l.id))
          .toList();
      _openHouses.value = _allOpenHouses
          .where((oh) => filteredIds.contains(oh.listingId))
          .toList();
    }

    if (kDebugMode) {
      print('🔍 ZIP filter: $normalizedZipCode (within10mi: $useWithin10)');
      print('   Agents: ${_agents.length} | LOs: ${_loanOfficers.length}');
    }

    // Force refresh to ensure UI updates for all tabs
    _agents.refresh();
    _loanOfficers.refresh();
    _listings.refresh();
    _openHouses.refresh();

    // Record search for all displayed agents and loan officers
    _recordSearchesForDisplayedAgents();
    _recordSearchesForDisplayedLoanOfficers();
  }

  /// Records search tracking for all currently displayed agents
  Future<void> _recordSearchesForDisplayedAgents() async {
    if (_currentZipCode.value == null || _currentZipCode.value!.isEmpty) {
      return; // Only track when there's an active search/filter
    }

    // Record search for each displayed agent (fire and forget)
    // Pass agent name to the API as it expects name, not ID
    for (final agent in _agents) {
      _recordSearch(agent.id, agentName: agent.name);
    }
  }

  /// Records search tracking for all currently displayed loan officers
  Future<void> _recordSearchesForDisplayedLoanOfficers() async {
    if (_currentZipCode.value == null || _currentZipCode.value!.isEmpty) {
      return; // Only track when there's an active search/filter
    }

    // Record search for each displayed loan officer (fire and forget)
    // Pass loan officer name to the API as it expects name, not ID
    for (final loanOfficer in _loanOfficers) {
      _recordLoanOfficerSearch(
        loanOfficer.id,
        loanOfficerName: loanOfficer.name,
      );
    }
  }

  /// Records a search for an agent
  Future<void> _recordSearch(String agentId, {String? agentName}) async {
    try {
      final response = await _agentService.recordSearch(
        agentId,
        agentName: agentName,
      );
      if (response != null && kDebugMode) {
        print('📊 Search Response for agent $agentId:');
        print('   Message: ${response['message'] ?? 'N/A'}');
        print('   Searches: ${response['searches'] ?? 'N/A'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error recording search: $e');
      }
      // Don't show error to user - tracking is silent
    }
  }

  /// Records a contact action for an agent
  Future<void> _recordContact(String agentId) async {
    try {
      final response = await _agentService.recordContact(agentId);
      if (response != null && kDebugMode) {
        print('📞 Contact Response for agent $agentId:');
        print('   Message: ${response['message'] ?? 'N/A'}');
        print('   Contacts: ${response['contacts'] ?? 'N/A'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error recording contact: $e');
      }
      // Don't show error to user - tracking is silent
    }
  }

  /// Records a search for a loan officer
  Future<void> _recordLoanOfficerSearch(
    String loanOfficerId, {
    String? loanOfficerName,
  }) async {
    try {
      final response = await _loanOfficerService.recordSearch(
        loanOfficerId,
        loanOfficerName: loanOfficerName,
      );
      if (response != null && kDebugMode) {
        print('📊 Search Response for loan officer $loanOfficerId:');
        print('   Message: ${response['message'] ?? 'N/A'}');
        print('   Searches: ${response['searches'] ?? 'N/A'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error recording loan officer search: $e');
      }
      // Don't show error to user - tracking is silent
    }
  }

  /// Records a contact action for a loan officer
  Future<void> _recordLoanOfficerContact(String loanOfficerId) async {
    try {
      final response = await _loanOfficerService.recordContact(loanOfficerId);
      if (response != null && kDebugMode) {
        print('📞 Contact Response for loan officer $loanOfficerId:');
        print('   Message: ${response['message'] ?? 'N/A'}');
        print('   Contacts: ${response['contacts'] ?? 'N/A'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error recording loan officer contact: $e');
      }
      // Don't show error to user - tracking is silent
    }
  }

  Future<void> searchByZipCode(String zipCode) async {
    try {
      final trimmedZipCode = zipCode.trim();
      if (trimmedZipCode.length != 5 ||
          !RegExp(r'^\d+$').hasMatch(trimmedZipCode)) {
        SnackbarHelper.showError(
          'Please enter a valid 5-digit ZIP code',
          title: 'Invalid ZIP Code',
          duration: const Duration(seconds: 2),
        );
        return;
      }

      _currentZipCode.value = trimmedZipCode;
      _agentsDisplayCount.value = 10;
      _loanOfficersDisplayCount.value = 10;
      _listingsDisplayCount.value = 10;
      _openHousesDisplayCount.value = 10;

      try {
        _within10MilesMap = await _zipCodesService.getZipCodesWithinMiles(
          zipcode: trimmedZipCode,
          miles: 10,
        );
      } on ZipCodesServiceException catch (e) {
        if (kDebugMode) print('❌ within10miles API: ${e.message}');
        SnackbarHelper.showError(e.message);
        _within10MilesMap = null;
      } catch (e) {
        if (kDebugMode) print('❌ within10miles API: $e');
        SnackbarHelper.showError(
          'Failed to fetch nearby ZIP codes: ${e.toString()}',
        );
        _within10MilesMap = null;
      }

      _applyZipCodeFilter();

      if (kDebugMode) {
        print('🔍 Filtered by ZIP $trimmedZipCode (within 10mi)');
        print(
          '   Agents: ${_agents.length} | Loan Officers: ${_loanOfficers.length}',
        );
      }

      final totalResults =
          _agents.length +
          _loanOfficers.length +
          _listings.length +
          _openHouses.length;
      if (totalResults > 0) {
        SnackbarHelper.showSuccess(
          'Found $totalResults results for ZIP $trimmedZipCode',
          duration: const Duration(seconds: 2),
        );
      } else {
        SnackbarHelper.showInfo(
          'No results found for ZIP $trimmedZipCode',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error filtering by ZIP code: $e');
        print('   Stack trace: ${StackTrace.current}');
      }
      SnackbarHelper.showError('Search failed: ${e.toString()}');
    }
  }

  /// Clears the ZIP code filter
  void clearZipCodeFilter() {
    _currentZipCode.value = null;
    _within10MilesMap = null;
    _agentsDisplayCount.value = 10;
    _loanOfficersDisplayCount.value = 10;
    _listingsDisplayCount.value = 10;
    _openHousesDisplayCount.value = 10;
    _applyZipCodeFilter();
    if (kDebugMode) print('🧹 Cleared ZIP filter');
  }

  Future<void> toggleFavoriteAgent(String agentId) async {
    if (_togglingFavorites.contains(agentId))
      return; // Prevent multiple simultaneous calls

    // Optimistic update - update UI immediately before API call
    final currentUser = _authController.currentUser;
    if (currentUser == null || currentUser.id.isEmpty) {
      try {
        SnackbarHelper.showError(
          'Please login to like agents',
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not show snackbar: $e');
        }
      }
      return;
    }

    // Optimistically update UI immediately (save original state for rollback)
    int agentIndex = -1;
    AgentModel? originalAgent;
    bool originalIsLiked = false;

    agentIndex = _agents.indexWhere((agent) => agent.id == agentId);
    if (agentIndex != -1) {
      originalAgent = _agents[agentIndex];
      final currentLikes = List<String>.from(originalAgent.likes ?? []);
      originalIsLiked = currentLikes.contains(currentUser.id);
      final willBeLiked = !originalIsLiked;

      // Update UI immediately
      if (willBeLiked) {
        currentLikes.add(currentUser.id);
        if (!_favoriteAgents.contains(agentId)) {
          _favoriteAgents.add(agentId);
        }
      } else {
        currentLikes.remove(currentUser.id);
        _favoriteAgents.remove(agentId);
      }

      _agents[agentIndex] = originalAgent.copyWith(likes: currentLikes);
      _agents.refresh();

      // Don't refresh here - will refresh after API call completes to avoid duplicate calls
    }

    try {
      _togglingFavorites.add(agentId);

      // Get current user ID (already validated above)
      final userId = currentUser.id;

      final endpoint = ApiConstants.getLikeAgentEndpoint(agentId);

      // Get auth token
      final GetStorage storage = GetStorage();
      final authToken = storage.read('auth_token');

      // Setup Dio headers
      _dio.options.headers = {
        ...ApiConstants.ngrokHeaders,
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      if (kDebugMode) {
        print('❤️ Toggling favorite for agent: $agentId');
        print('   Endpoint: $endpoint');
        print('   Current User ID: $userId');
      }

      // Make API call with currentUserId in body
      final response = await _dio.post(
        endpoint,
        data: {'currentUserId': userId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final success = responseData['success'] ?? false;
        final isLiked = responseData['isLiked'] ?? false;
        final action = responseData['action'] ?? 'liked';
        final message = responseData['message'] ?? 'Success';

        if (success) {
          // UI already updated optimistically, just sync if API response differs
          if (agentIndex != -1) {
            final agent = _agents[agentIndex];
            final currentLikes = List<String>.from(agent.likes ?? []);
            final apiMatchesOptimistic =
                isLiked == currentLikes.contains(userId);

            // Always update the agent's likes array to match API response
            // This ensures the likes array is in sync with the server
            if (isLiked) {
              // Ensure userId is at the END of the array (most recent = highest index)
              currentLikes.remove(userId); // Remove if exists anywhere
              currentLikes.add(userId); // Add at the end (most recent)
              if (!_favoriteAgents.contains(agentId)) {
                _favoriteAgents.add(agentId);
              }
            } else {
              currentLikes.remove(userId);
              _favoriteAgents.remove(agentId);
            }
            // Always update the agent to ensure likes array is correct
            _agents[agentIndex] = agent.copyWith(likes: currentLikes);
            _agents.refresh();
          }

          // Show snackbar with appropriate message (safely with delay to avoid overlay issues)
          Future.delayed(const Duration(milliseconds: 200), () {
            try {
              SnackbarHelper.showSuccess(
                message.isNotEmpty
                    ? message
                    : (isLiked
                          ? 'Agent added to your favorites'
                          : 'Agent removed from your favorites'),
                title: action == 'liked'
                    ? 'Added to Favorites'
                    : 'Removed from Favorites',
                duration: const Duration(seconds: 2),
              );
            } catch (e) {
              // If snackbar fails, just print to console (overlay might not be available)
              if (kDebugMode) {
                print('⚠️ Could not show snackbar: $e');
              }
            }
          });

          if (kDebugMode) {
            print('✅ Favorite toggled successfully: $isLiked');
          }

          // Notify favorites controller to add agent to top immediately, then refresh
          try {
            final favoritesController = Get.find<FavoritesController>();
            if (isLiked && agentIndex != -1) {
              // Get the agent - it should already have updated likes array from above
              final agent = _agents[agentIndex];

              // Immediately add to top of favorites list for instant feedback
              favoritesController.addFavoriteAgentToTop(agent);

              if (kDebugMode) {
                print(
                  '✅ Added agent ${agent.id} to top of favorites. Likes: ${agent.likes}',
                );
              }

              // Delay refresh to allow immediate addition to be visible
              // The agent already has userId at the end of likes array, so sorting will work correctly
              Future.delayed(const Duration(milliseconds: 2000), () {
                try {
                  favoritesController.refreshFavorites();
                } catch (e) {
                  if (kDebugMode) {
                    print('⚠️ Error refreshing favorites: $e');
                  }
                }
              });
            } else if (!isLiked) {
              // If unliked, refresh immediately
              favoritesController.refreshFavorites();
            }
          } catch (e) {
            // Favorites controller might not be initialized yet, that's okay
            if (kDebugMode) {
              print('ℹ️ Favorites controller not found, skipping refresh: $e');
            }
          }
        } else {
          throw Exception(message);
        }
      } else {
        throw Exception('Failed to update favorite status');
      }
    } on DioException catch (e) {
      // Revert optimistic update on error
      if (agentIndex != -1 && originalAgent != null) {
        _agents[agentIndex] = originalAgent!;
        _agents.refresh();
        if (originalIsLiked) {
          if (!_favoriteAgents.contains(agentId)) {
            _favoriteAgents.add(agentId);
          }
        } else {
          _favoriteAgents.remove(agentId);
        }
      }

      if (kDebugMode) {
        print('❌ Error toggling favorite: ${e.response?.statusCode ?? "N/A"}');
        print('   ${e.response?.data ?? e.message}');
      }

      // Don't show snackbar for 404 errors (endpoint not implemented yet)
      // Just log the error and revert optimistic update
      if (e.response?.statusCode != 404) {
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            if (Get.isSnackbarOpen) {
              Get.closeCurrentSnackbar();
            }
            Get.snackbar(
              'Error',
              e.response?.data['message']?.toString() ??
                  'Failed to update favorite. Please try again.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(16),
            );
          } catch (err) {
            if (kDebugMode) {
              print('⚠️ Could not show error snackbar: $err');
            }
          }
        });
      } else {
        if (kDebugMode) {
          print(
            '⚠️ Loan officer like endpoint not available yet (404). Feature coming soon.',
          );
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      if (agentIndex != -1 && originalAgent != null) {
        _agents[agentIndex] = originalAgent!;
        _agents.refresh();
        if (originalIsLiked) {
          if (!_favoriteAgents.contains(agentId)) {
            _favoriteAgents.add(agentId);
          }
        } else {
          _favoriteAgents.remove(agentId);
        }
      }

      if (kDebugMode) {
        print('❌ Unexpected error toggling favorite: $e');
      }

      try {
        SnackbarHelper.showError(
          'An unexpected error occurred. Please try again.',
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not show error snackbar: $e');
        }
      }
    } finally {
      _togglingFavorites.remove(agentId);
    }
  }

  Future<void> toggleFavoriteLoanOfficer(String loanOfficerId) async {
    if (_togglingFavorites.contains(loanOfficerId))
      return; // Prevent multiple simultaneous calls

    // Optimistic update - update UI immediately before API call
    final currentUser = _authController.currentUser;
    if (currentUser == null || currentUser.id.isEmpty) {
      try {
        SnackbarHelper.showError(
          'Please login to like loan officers',
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not show snackbar: $e');
        }
      }
      return;
    }

    // Optimistically update UI immediately (save original state for rollback)
    int loanOfficerIndex = -1;
    LoanOfficerModel? originalLoanOfficer;
    bool originalIsLiked = false;
    final userId = currentUser.id;

    loanOfficerIndex = _loanOfficers.indexWhere((lo) => lo.id == loanOfficerId);
    if (loanOfficerIndex != -1) {
      originalLoanOfficer = _loanOfficers[loanOfficerIndex];
      final currentLikes = List<String>.from(originalLoanOfficer.likes ?? []);
      originalIsLiked = currentLikes.contains(userId);
      final willBeLiked = !originalIsLiked;

      // Update UI immediately
      if (willBeLiked) {
        currentLikes.add(userId);
        if (!_favoriteLoanOfficers.contains(loanOfficerId)) {
          _favoriteLoanOfficers.add(loanOfficerId);
        }
      } else {
        currentLikes.remove(userId);
        _favoriteLoanOfficers.remove(loanOfficerId);
      }

      _loanOfficers[loanOfficerIndex] = originalLoanOfficer.copyWith(
        likes: currentLikes,
      );
      _loanOfficers.refresh();

      // Don't refresh here - will refresh after API call completes to avoid duplicate calls
    }

    try {
      _togglingFavorites.add(loanOfficerId);

      // Get current user ID (already validated above)
      final currentUser = _authController.currentUser;
      if (currentUser == null || currentUser.id.isEmpty) {
        return; // Already handled in optimistic update
      }

      final endpoint = ApiConstants.getLikeLoanOfficerEndpoint(loanOfficerId);

      // Get auth token
      final GetStorage storage = GetStorage();
      final authToken = storage.read('auth_token');

      // Setup Dio headers
      _dio.options.headers = {
        ...ApiConstants.ngrokHeaders,
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      if (kDebugMode) {
        print('❤️ Toggling favorite for loan officer: $loanOfficerId');
        print('   Endpoint: $endpoint');
        print('   Current User ID: $userId');
      }

      // Make API call with currentUserId in body
      final response = await _dio.post(
        endpoint,
        data: {'currentUserId': userId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final success = responseData['success'] ?? false;
        final isLiked = responseData['isLiked'] ?? false;
        final action = responseData['action'] ?? 'liked';
        final message = responseData['message'] ?? 'Success';

        if (success) {
          // UI already updated optimistically, just sync if API response differs
          if (loanOfficerIndex != -1) {
            final loanOfficer = _loanOfficers[loanOfficerIndex];
            final currentLikes = List<String>.from(loanOfficer.likes ?? []);
            final apiMatchesOptimistic =
                isLiked == currentLikes.contains(userId);

            // Only update if API response differs from optimistic update
            if (!apiMatchesOptimistic) {
              if (isLiked) {
                if (!currentLikes.contains(userId)) {
                  currentLikes.add(userId);
                }
                if (!_favoriteLoanOfficers.contains(loanOfficerId)) {
                  _favoriteLoanOfficers.add(loanOfficerId);
                }
              } else {
                currentLikes.remove(userId);
                _favoriteLoanOfficers.remove(loanOfficerId);
              }
              _loanOfficers[loanOfficerIndex] = loanOfficer.copyWith(
                likes: currentLikes,
              );
              _loanOfficers.refresh();
            }
          }

          // Show snackbar with appropriate message
          Future.delayed(const Duration(milliseconds: 200), () {
            SnackbarHelper.showSuccess(
              message.isNotEmpty
                  ? message
                  : (isLiked
                        ? 'Loan officer added to your favorites'
                        : 'Loan officer removed from your favorites'),
              title: action == 'liked'
                  ? 'Added to Favorites'
                  : 'Removed from Favorites',
              duration: const Duration(seconds: 2),
            );
          });

          if (kDebugMode) {
            print('✅ Favorite toggled successfully: $isLiked');
          }

          // Notify favorites controller to add loan officer to top immediately, then refresh
          if (Get.isRegistered<FavoritesController>()) {
            try {
              final favoritesController = Get.find<FavoritesController>();
              if (isLiked) {
                // Find the loan officer in the list
                final loanOfficerIndex = _loanOfficers.indexWhere(
                  (lo) => lo.id == loanOfficerId,
                );
                if (loanOfficerIndex != -1) {
                  var loanOfficer = _loanOfficers[loanOfficerIndex];

                  // Ensure the loan officer's likes array includes userId at the end
                  final currentLikes = List<String>.from(
                    loanOfficer.likes ?? [],
                  );
                  if (!currentLikes.contains(userId)) {
                    currentLikes.add(userId);
                    // Update the loan officer in the list
                    try {
                      _loanOfficers[loanOfficerIndex] = loanOfficer.copyWith(
                        likes: currentLikes,
                      );
                      _loanOfficers.refresh();
                      loanOfficer =
                          _loanOfficers[loanOfficerIndex]; // Get updated loan officer
                    } catch (e) {
                      // copyWith might not exist, that's okay
                      if (kDebugMode) {
                        print('⚠️ Could not update loan officer likes: $e');
                      }
                    }
                  }

                  // Immediately add to top of favorites list for instant feedback
                  favoritesController.addFavoriteLoanOfficerToTop(loanOfficer);

                  // Delay refresh significantly to allow immediate addition to be visible
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    try {
                      favoritesController.refreshFavorites();
                    } catch (e) {
                      // Silently fail if refresh fails
                    }
                  });
                }
              } else {
                // If unliked, refresh immediately
                Future.delayed(const Duration(milliseconds: 300), () {
                  try {
                    favoritesController.refreshFavorites();
                  } catch (e) {
                    // Silently fail if refresh fails
                  }
                });
              }
            } catch (e) {
              // Silently fail if favorites controller not available
            }
          }
        } else {
          throw Exception(message);
        }
      } else {
        throw Exception('Failed to update favorite status');
      }
    } on DioException catch (e) {
      // Revert optimistic update on error
      if (loanOfficerIndex != -1 && originalLoanOfficer != null) {
        _loanOfficers[loanOfficerIndex] = originalLoanOfficer!;
        _loanOfficers.refresh();
        if (originalIsLiked) {
          if (!_favoriteLoanOfficers.contains(loanOfficerId)) {
            _favoriteLoanOfficers.add(loanOfficerId);
          }
        } else {
          _favoriteLoanOfficers.remove(loanOfficerId);
        }
      }

      if (kDebugMode) {
        print('❌ Error toggling favorite: ${e.response?.statusCode ?? "N/A"}');
        print('   ${e.response?.data ?? e.message}');
      }

      // Don't show snackbar for 404 errors (endpoint not implemented yet)
      // Just log the error and revert optimistic update
      if (e.response?.statusCode != 404) {
        Future.delayed(const Duration(milliseconds: 200), () {
          SnackbarHelper.showError(
            e.response?.data['message']?.toString() ??
                'Failed to update favorite. Please try again.',
            duration: const Duration(seconds: 3),
          );
        });
      } else {
        if (kDebugMode) {
          print(
            '⚠️ Loan officer like endpoint not available yet (404). Feature coming soon.',
          );
          print(
            '   Backend needs to implement: POST /api/v1/buyer/likeLoanOfficer/{loanOfficerId}',
          );
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      if (loanOfficerIndex != -1 && originalLoanOfficer != null) {
        _loanOfficers[loanOfficerIndex] = originalLoanOfficer!;
        _loanOfficers.refresh();
        if (originalIsLiked) {
          if (!_favoriteLoanOfficers.contains(loanOfficerId)) {
            _favoriteLoanOfficers.add(loanOfficerId);
          }
        } else {
          _favoriteLoanOfficers.remove(loanOfficerId);
        }
      }

      if (kDebugMode) {
        print('❌ Unexpected error toggling favorite: $e');
      }

      try {
        SnackbarHelper.showError(
          'An unexpected error occurred. Please try again.',
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not show error snackbar: $e');
        }
      }
    } finally {
      _togglingFavorites.remove(loanOfficerId);
    }
  }

  bool isAgentFavorite(String agentId) {
    // First check the cached list (fastest)
    if (_favoriteAgents.contains(agentId)) {
      return true;
    }

    // Also check the agent's likes array (more reliable, null-safe)
    try {
      final agent = _agents.firstWhere((a) => a.id == agentId);
      final likes = agent.likes;
      if (likes != null && likes.isNotEmpty) {
        final currentUser = _authController.currentUser;
        if (currentUser != null && currentUser.id.isNotEmpty) {
          return likes.contains(currentUser.id);
        }
      }
    } catch (e) {
      // Agent not found, return false
    }

    return false;
  }

  bool isLoanOfficerFavorite(String loanOfficerId) {
    // First check the cached list (fastest)
    if (_favoriteLoanOfficers.contains(loanOfficerId)) {
      return true;
    }

    // Also check the loan officer's likes array (more reliable, null-safe)
    try {
      final loanOfficer = _loanOfficers.firstWhere(
        (lo) => lo.id == loanOfficerId,
      );
      final likes = loanOfficer.likes;
      if (likes != null && likes.isNotEmpty) {
        final currentUser = _authController.currentUser;
        if (currentUser != null && currentUser.id.isNotEmpty) {
          return likes.contains(currentUser.id);
        }
      }
    } catch (e) {
      // Loan officer not found, return false
    }

    return false;
  }

  Future<void> contactAgent(AgentModel agent) async {
    // Record contact action
    _recordContact(agent.id);

    // Check if conversation exists with this agent
    final messagesController = Get.find<MessagesController>();

    // Wait for threads to load if needed
    if (messagesController.allConversations.isEmpty &&
        !messagesController.isLoadingThreads) {
      await messagesController.loadThreads();
    }

    // Wait a bit for threads to load
    int retries = 0;
    while (messagesController.allConversations.isEmpty &&
        messagesController.isLoadingThreads &&
        retries < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      retries++;
    }

    // Check if conversation exists
    ConversationModel? existingConversation;
    try {
      existingConversation = messagesController.allConversations.firstWhere(
        (conv) => conv.senderId == agent.id,
      );
    } catch (e) {
      existingConversation = null;
    }

    if (existingConversation != null) {
      // Conversation exists - go directly to chat
      messagesController.selectConversation(existingConversation);
      // Navigate to main navigation and switch to messages tab (index 2)
      if (Get.isRegistered<MainNavigationController>()) {
        try {
          final mainNavController = Get.find<MainNavigationController>();
          mainNavController.changeIndex(2); // Messages is at index 2
          // Navigate to main if not already there
          if (Get.currentRoute != AppPages.MAIN) {
            Get.offAllNamed(AppPages.MAIN);
          }
        } catch (e) {
          // Fallback to route navigation if controller not found
          Get.toNamed('/messages');
        }
      } else {
        Get.toNamed('/messages');
      }
    } else {
      // No conversation - show Start Chat screen
      Get.toNamed(
        '/contact',
        arguments: {
          'userId': agent.id,
          'userName': agent.name,
          'userProfilePic': agent.profileImage,
          'userRole': 'agent',
          'agent': agent,
        },
      );
    }
  }

  Future<void> contactLoanOfficer(LoanOfficerModel loanOfficer) async {
    // Record contact
    _recordLoanOfficerContact(loanOfficer.id);

    // Check if conversation exists with this loan officer
    final messagesController = Get.find<MessagesController>();

    // Wait for threads to load if needed
    if (messagesController.allConversations.isEmpty &&
        !messagesController.isLoadingThreads) {
      await messagesController.loadThreads();
    }

    // Wait a bit for threads to load
    int retries = 0;
    while (messagesController.allConversations.isEmpty &&
        messagesController.isLoadingThreads &&
        retries < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      retries++;
    }

    // Check if conversation exists
    ConversationModel? existingConversation;
    try {
      existingConversation = messagesController.allConversations.firstWhere(
        (conv) => conv.senderId == loanOfficer.id,
      );
    } catch (e) {
      existingConversation = null;
    }

    if (existingConversation != null) {
      // Conversation exists - go directly to chat
      messagesController.selectConversation(existingConversation);
      // Navigate to main navigation and switch to messages tab (index 2)
      if (Get.isRegistered<MainNavigationController>()) {
        try {
          final mainNavController = Get.find<MainNavigationController>();
          mainNavController.changeIndex(2); // Messages is at index 2
          // Navigate to main if not already there
          if (Get.currentRoute != AppPages.MAIN) {
            Get.offAllNamed(AppPages.MAIN);
          }
        } catch (e) {
          // Fallback to route navigation if controller not found
          Get.toNamed('/messages');
        }
      } else {
        Get.toNamed('/messages');
      }
    } else {
      // No conversation - show Start Chat screen
      Get.toNamed(
        '/contact',
        arguments: {
          'userId': loanOfficer.id,
          'userName': loanOfficer.name,
          'userProfilePic': loanOfficer.profileImage,
          'userRole': 'loan_officer',
          'loanOfficer': loanOfficer,
        },
      );
    }
  }

  void viewAgentProfile(AgentModel agent) {
    // Navigate to agent profile screen
    Get.toNamed('/agent-profile', arguments: {'agent': agent});
  }

  /// Sets the buyer's selected agent to work with
  void selectBuyerAgent(AgentModel agent) {
    _selectedBuyerAgent.value = agent;
    Get.snackbar(
      'Agent Selected',
      'You are now working with ${agent.name}. They will represent you in all property transactions.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.lightGreen,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Clears the selected buyer agent
  void clearSelectedBuyerAgent() {
    _selectedBuyerAgent.value = null;
  }

  /// Checks if buyer should be warned about contacting listing agent directly
  bool shouldWarnAboutListingAgent(String? listingAgentId) {
    if (!hasSelectedAgent || listingAgentId == null) return false;
    // Warn if they have a selected agent and are trying to contact a different agent (listing agent)
    return _selectedBuyerAgent.value!.id != listingAgentId;
  }

  void viewLoanOfficerProfile(LoanOfficerModel loanOfficer) {
    // Navigate to loan officer profile screen
    Get.toNamed(
      '/loan-officer-profile',
      arguments: {'loanOfficer': loanOfficer},
    );
  }

  void viewListing(Listing listing) {
    Get.toNamed('/listing-detail', arguments: {'listing': listing});
  }

  void viewOpenHouse(OpenHouseModel openHouse) {
    // Find the associated listing
    final listing = _listings.firstWhere(
      (l) => l.id == openHouse.listingId,
      orElse: () => _listings.first,
    );
    Get.toNamed('/listing-detail', arguments: {'listing': listing});
  }

  Listing? getListingForOpenHouse(OpenHouseModel openHouse) {
    try {
      return _listings.firstWhere((l) => l.id == openHouse.listingId);
    } catch (e) {
      return null;
    }
  }

  bool isListingFavorite(String listingId) {
    return _favoriteListings.contains(listingId);
  }

  Future<void> toggleFavoriteListing(String listingId) async {
    if (_togglingFavorites.contains(listingId)) return;

    final currentUser = _authController.currentUser;
    if (currentUser == null || currentUser.id.isEmpty) {
      SnackbarHelper.showError(
        'Please login to like listings',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Optimistic update
    final isCurrentlyLiked = _favoriteListings.contains(listingId);
    if (isCurrentlyLiked) {
      _favoriteListings.remove(listingId);
    } else {
      _favoriteListings.add(listingId);
    }
    _favoriteListings.refresh(); // Force UI update immediately

    // Immediately update favorites screen if available
    if (Get.isRegistered<FavoritesController>()) {
      try {
        final favoritesController = Get.find<FavoritesController>();
        if (isCurrentlyLiked) {
          // Remove from favorites immediately
          favoritesController.removeFavoriteListingImmediately(listingId);
        } else {
          // Find the listing and add to top immediately
          // Determine which tab the listing is from based on current context
          final isFromOpenHousesTab =
              _selectedTab.value == 2; // Open Houses tab
          try {
            final listing = _listings.firstWhere((l) => l.id == listingId);
            favoritesController.addFavoriteListingToTop(
              listing,
              isFromOpenHousesTab: isFromOpenHousesTab,
            );
          } catch (e) {
            // Try from all listings
            try {
              final listing = _allListings.firstWhere((l) => l.id == listingId);
              favoritesController.addFavoriteListingToTop(
                listing,
                isFromOpenHousesTab: isFromOpenHousesTab,
              );
            } catch (e2) {
              if (kDebugMode) {
                print(
                  '⚠️ Could not find listing $listingId to add to favorites: $e2',
                );
              }
              // Still refresh to get it from API
              favoritesController.refreshFavorites();
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not update favorites controller immediately: $e');
        }
      }
    }

    try {
      _togglingFavorites.add(listingId);

      final userId = currentUser.id;
      final endpoint = ApiConstants.likeListingEndpoint;

      final GetStorage storage = GetStorage();
      final authToken = storage.read('auth_token');

      _dio.options.headers = {
        ...ApiConstants.ngrokHeaders,
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      if (kDebugMode) {
        print('❤️ Toggling favorite for listing: $listingId');
        print('   Endpoint: $endpoint');
        print('   User ID: $userId');
      }

      // Temporarily increase timeout for this request
      final originalConnectTimeout = _dio.options.connectTimeout;
      final originalReceiveTimeout = _dio.options.receiveTimeout;
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 30);

      try {
        final response = await _dio.post(
          endpoint,
          data: {'listingId': listingId, 'userId': userId},
        );

        // Restore original timeouts
        _dio.options.connectTimeout = originalConnectTimeout;
        _dio.options.receiveTimeout = originalReceiveTimeout;

        if (kDebugMode) {
          print('📥 Like Listing API Response:');
          print('   Status Code: ${response.statusCode}');
          print('   Response Data: ${response.data}');
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = response.data;
          final success = responseData['success'] ?? false;

          // Check if user ID is in the likes array (more reliable than isLiked field)
          final likes = responseData['likes'] as List?;
          final isLiked = likes != null && likes.contains(userId);

          if (kDebugMode) {
            print('   Success: $success');
            print('   Likes array: $likes');
            print('   User ID: $userId');
            print('   Is Liked (from likes array): $isLiked');
          }

          if (success) {
            // Update the listing's likes array if we can find it
            try {
              final listingIndex = _listings.indexWhere(
                (l) => l.id == listingId,
              );
              if (listingIndex != -1 && likes != null) {
                // Update the listing model with the new likes array
                // Note: This assumes Listing model has a way to update likes
                // For now, we'll just sync the favoriteListings
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Could not update listing likes: $e');
              }
            }

            // Sync with API response - ensure state matches API
            if (isLiked) {
              if (!_favoriteListings.contains(listingId)) {
                _favoriteListings.add(listingId);
              }
            } else {
              _favoriteListings.remove(listingId);
            }
            _favoriteListings.refresh(); // Force UI update

            // Update favorites controller to sync with API response
            if (Get.isRegistered<FavoritesController>()) {
              try {
                final favoritesController = Get.find<FavoritesController>();
                if (isLiked) {
                  // Ensure listing is in favorites (might have been added optimistically)
                  // Determine which tab based on current context
                  final isFromOpenHousesTab = _selectedTab.value == 2;
                  try {
                    final listing = _listings.firstWhere(
                      (l) => l.id == listingId,
                    );
                    favoritesController.addFavoriteListingToTop(
                      listing,
                      isFromOpenHousesTab: isFromOpenHousesTab,
                    );
                  } catch (e) {
                    // Try from all listings
                    try {
                      final listing = _allListings.firstWhere(
                        (l) => l.id == listingId,
                      );
                      favoritesController.addFavoriteListingToTop(
                        listing,
                        isFromOpenHousesTab: isFromOpenHousesTab,
                      );
                    } catch (e2) {
                      // Refresh to get from API
                      favoritesController.refreshFavorites();
                    }
                  }
                } else {
                  // Remove from favorites
                  favoritesController.removeFavoriteListingImmediately(
                    listingId,
                  );
                }
              } catch (e) {
                if (kDebugMode) {
                  print('⚠️ Could not update favorites controller: $e');
                }
              }
            }

            if (kDebugMode) {
              print(
                '   ✅ Updated favorite listings: ${_favoriteListings.length} total',
              );
              print('   Current favorites: $_favoriteListings');
            }

            Future.delayed(const Duration(milliseconds: 200), () {
              SnackbarHelper.showSuccess(
                isLiked
                    ? 'Listing added to your favorites'
                    : 'Listing removed from your favorites',
                duration: const Duration(seconds: 2),
              );
            });
          } else {
            // API returned success: false - revert optimistic update
            if (kDebugMode) {
              print(
                '   ⚠️ API returned success: false, reverting optimistic update',
              );
            }

            // Revert to previous state (opposite of what we optimistically set)
            final wasLikedBeforeToggle = !isCurrentlyLiked;
            if (wasLikedBeforeToggle) {
              // We optimistically removed it, but API failed - add it back
              if (!_favoriteListings.contains(listingId)) {
                _favoriteListings.add(listingId);
              }
            } else {
              // We optimistically added it, but API failed - remove it
              _favoriteListings.remove(listingId);
            }
            _favoriteListings.refresh();

            // Update favorites controller to match reverted state
            if (Get.isRegistered<FavoritesController>()) {
              try {
                final favoritesController = Get.find<FavoritesController>();
                if (wasLikedBeforeToggle) {
                  final isFromOpenHousesTab = _selectedTab.value == 2;
                  try {
                    final listing = _listings.firstWhere(
                      (l) => l.id == listingId,
                    );
                    favoritesController.addFavoriteListingToTop(
                      listing,
                      isFromOpenHousesTab: isFromOpenHousesTab,
                    );
                  } catch (e) {
                    try {
                      final listing = _allListings.firstWhere(
                        (l) => l.id == listingId,
                      );
                      favoritesController.addFavoriteListingToTop(
                        listing,
                        isFromOpenHousesTab: isFromOpenHousesTab,
                      );
                    } catch (e2) {
                      favoritesController.refreshFavorites();
                    }
                  }
                } else {
                  favoritesController.removeFavoriteListingImmediately(
                    listingId,
                  );
                }
              } catch (e) {
                if (kDebugMode) {
                  print('⚠️ Could not update favorites controller: $e');
                }
              }
            }

            SnackbarHelper.showError(
              'Failed to update favorite status. Please try again.',
              duration: const Duration(seconds: 2),
            );
          }
        } else {
          if (kDebugMode) {
            print('   ⚠️ Unexpected status code: ${response.statusCode}');
          }
        }
      } catch (requestError) {
        // Restore original timeouts before rethrowing
        _dio.options.connectTimeout = originalConnectTimeout;
        _dio.options.receiveTimeout = originalReceiveTimeout;
        rethrow;
      }
    } catch (e) {
      // On error, rollback optimistic update
      if (kDebugMode) {
        print('❌ Error toggling favorite listing: $e');
        if (e is DioException) {
          print('   Error Type: ${e.type}');
          print('   Status Code: ${e.response?.statusCode}');
          print('   Response: ${e.response?.data}');
          print('   Request Path: ${e.requestOptions.path}');
          print('   Request Data: ${e.requestOptions.data}');
        }
      }

      // Rollback optimistic update - revert to previous state
      final wasLikedBeforeToggle =
          !isCurrentlyLiked; // Opposite of optimistic state
      if (wasLikedBeforeToggle) {
        // Was liked before, we optimistically removed it - add it back
        if (!_favoriteListings.contains(listingId)) {
          _favoriteListings.add(listingId);
        }
      } else {
        // Was not liked before, we optimistically added it - remove it
        _favoriteListings.remove(listingId);
      }
      _favoriteListings.refresh();

      // Update favorites controller to match rolled back state
      if (Get.isRegistered<FavoritesController>()) {
        try {
          final favoritesController = Get.find<FavoritesController>();
          if (wasLikedBeforeToggle) {
            final isFromOpenHousesTab = _selectedTab.value == 2;
            try {
              final listing = _listings.firstWhere((l) => l.id == listingId);
              favoritesController.addFavoriteListingToTop(
                listing,
                isFromOpenHousesTab: isFromOpenHousesTab,
              );
            } catch (e2) {
              try {
                final listing = _allListings.firstWhere(
                  (l) => l.id == listingId,
                );
                favoritesController.addFavoriteListingToTop(
                  listing,
                  isFromOpenHousesTab: isFromOpenHousesTab,
                );
              } catch (e3) {
                favoritesController.refreshFavorites();
              }
            }
          } else {
            favoritesController.removeFavoriteListingImmediately(listingId);
          }
        } catch (e2) {
          if (kDebugMode) {
            print('⚠️ Could not update favorites controller on rollback: $e2');
          }
        }
      }

      String errorMessage = 'Failed to update favorite listing';
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          errorMessage = 'Like endpoint not found. Please contact support.';
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Request timed out. Please check your connection.';
        } else if (e.response?.statusCode != null) {
          errorMessage =
              'Server error (${e.response?.statusCode}). Please try again.';
        }
      }

      SnackbarHelper.showError(
        errorMessage,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _togglingFavorites.remove(listingId);
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
