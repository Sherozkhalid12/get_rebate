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
import 'package:getrebate/app/controllers/location_controller.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/modules/favorites/controllers/favorites_controller.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class BuyerController extends GetxController {
  final LocationController _locationController = Get.find<LocationController>();
  final AuthController _authController = Get.find<AuthController>();

  // Search
  final searchController = TextEditingController();
  final _searchQuery = ''.obs;
  final _selectedTab =
      0.obs; // 0: Agents, 1: Homes for Sale, 2: Open Houses, 3: Loan Officers
  final _currentZipCode = Rxn<String>(); // Current ZIP code filter

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
  final _isLoading = false.obs;
  final _selectedBuyerAgent = Rxn<AgentModel>(); // Track the buyer's selected agent
  final _togglingFavorites = <String>{}.obs; // Track which IDs are currently being toggled

  // Services
  final ListingService _listingService = InMemoryListingService();
  final AgentService _agentService = AgentService();
  final LoanOfficerService _loanOfficerService = LoanOfficerService();
  
  // Dio for API calls
  final Dio _dio = Dio();

  // Getters
  String get searchQuery => _searchQuery.value;
  int get selectedTab => _selectedTab.value;
  List<AgentModel> get agents => _agents;
  List<LoanOfficerModel> get loanOfficers => _loanOfficers;
  List<Listing> get listings => _listings;
  List<OpenHouseModel> get openHouses => _openHouses;
  List<String> get favoriteAgents => _favoriteAgents;
  List<String> get favoriteLoanOfficers => _favoriteLoanOfficers;
  bool get isLoading => _isLoading.value;
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
  }
  
  void _setupDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10); // Reduced from 30 to 10
    _dio.options.receiveTimeout = const Duration(seconds: 10); // Reduced from 30 to 10
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

  Future<void> useCurrentLocation() async {
    await _locationController.getCurrentLocation();

    // After getting location, update search field and search
    final zipCode = _locationController.currentZipCode;
    if (zipCode != null && zipCode.isNotEmpty) {
      searchController.text = zipCode;
      searchByZipCode(zipCode);
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

  /// Loads agents from the API
  Future<void> _loadAgentsFromAPI() async {
    try {
      if (kDebugMode) {
        print('📡 Fetching agents from API...');
      }
      final agents = await _agentService.getAllAgents();
      
      // Build full URLs for profile pictures
      final agentsWithUrls = agents.map((agent) {
        String? profileImage = agent.profileImage;
        if (profileImage != null && profileImage.isNotEmpty) {
          if (!profileImage.startsWith('http://') && !profileImage.startsWith('https://')) {
            profileImage = '${ApiConstants.baseUrl}/$profileImage';
          }
        }
        
        String? companyLogo = agent.companyLogoUrl;
        if (companyLogo != null && companyLogo.isNotEmpty) {
          if (!companyLogo.startsWith('http://') && !companyLogo.startsWith('https://')) {
            companyLogo = '${ApiConstants.baseUrl}/$companyLogo';
          }
        }
        
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
          print('✅ Initialized ${_favoriteAgents.length} favorite agents from API likes');
        }
      }
      
      print('✅ Loaded ${agentsWithUrls.length} agents from API');
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

  /// Loads loan officers from the API
  Future<void> _loadLoanOfficersFromAPI() async {
    try {
      if (kDebugMode) {
        print('📡 Fetching loan officers from API...');
      }
      
      final loanOfficers = await _loanOfficerService.getAllLoanOfficers();
      
      // Build full URLs for profile pictures and company logos
      final loanOfficersWithUrls = loanOfficers.map((loanOfficer) {
        String? profileImage = loanOfficer.profileImage;
        if (profileImage != null && profileImage.isNotEmpty) {
          if (!profileImage.startsWith('http://') && !profileImage.startsWith('https://')) {
            profileImage = '${ApiConstants.baseUrl}/$profileImage';
          }
        }
        
        String? companyLogo = loanOfficer.companyLogoUrl;
        if (companyLogo != null && companyLogo.isNotEmpty) {
          if (!companyLogo.startsWith('http://') && !companyLogo.startsWith('https://')) {
            companyLogo = '${ApiConstants.baseUrl}/$companyLogo';
          }
        }
        
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
          if (loanOfficer.likes != null && loanOfficer.likes!.contains(currentUser.id)) {
            if (!_favoriteLoanOfficers.contains(loanOfficer.id)) {
              _favoriteLoanOfficers.add(loanOfficer.id);
            }
          }
        }
        if (kDebugMode) {
          print('✅ Initialized ${_favoriteLoanOfficers.length} favorite loan officers from API likes');
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
              photoUrls: agentListing.photoUrls.map((url) {
                // Build full URL if relative - handle leading slashes
                if (url.isNotEmpty && !url.startsWith('http://') && !url.startsWith('https://')) {
                  final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
                  final baseUrl = ApiConstants.baseUrl.endsWith('/') 
                      ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1) 
                      : ApiConstants.baseUrl;
                  return '$baseUrl/$cleanUrl';
                }
                return url;
              }).toList(),
              bacPercent: agentListing.bacPercent,
              dualAgencyAllowed: agentListing.dualAgencyAllowed,
              dualAgencyCommissionPercent: agentListing.dualAgencyCommissionPercent,
              createdAt: agentListing.createdAt,
              stats: ListingStats(
                searches: agentListing.searchCount,
                views: agentListing.viewCount,
                contacts: agentListing.contactCount,
              ),
            );
            
            fetchedListings.add(listing);
            
            // Extract open houses from listing data
            if (listingJson is Map<String, dynamic>) {
              final openHousesData = listingJson['openHouses'] as List?;
              if (openHousesData != null && openHousesData.isNotEmpty) {
                for (final ohData in openHousesData) {
                  try {
                    if (ohData is Map<String, dynamic>) {
                      // Parse open house date/time
                      DateTime? startTime;
                      DateTime? endTime;
                      
                      // Try different date formats from API
                      final dateStr = ohData['date']?.toString() ?? 
                                     ohData['startDateTime']?.toString() ?? 
                                     ohData['startTime']?.toString() ?? '';
                      final fromTimeStr = ohData['fromTime']?.toString() ?? '10:00';
                      final toTimeStr = ohData['toTime']?.toString() ?? '16:00';
                      
                      if (dateStr.isNotEmpty) {
                        try {
                          final baseDate = DateTime.parse(dateStr.split('T')[0]); // Get date part
                          // Parse time strings (handle formats like "10:00 AM", "14:00", etc.)
                          startTime = _parseDateTimeWithTime(baseDate, fromTimeStr);
                          endTime = _parseDateTimeWithTime(baseDate, toTimeStr);
                        } catch (e) {
                          if (kDebugMode) {
                            print('⚠️ Error parsing open house date: $e');
                          }
                        }
                      }
                      
                      // Default to future date if parsing failed
                      startTime ??= DateTime.now().add(Duration(days: openHouseIndex + 1, hours: 14));
                      endTime ??= startTime!.add(const Duration(hours: 2));
                      
                      extractedOpenHouses.add(
                        OpenHouseModel(
                          id: ohData['id']?.toString() ?? ohData['_id']?.toString() ?? 'oh_$openHouseIndex',
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
        
        _allListings.value = fetchedListings;
        _allOpenHouses.value = extractedOpenHouses;
        _applyZipCodeFilter(); // Apply filter after loading
        
        if (kDebugMode) {
          print('✅ Loaded ${fetchedListings.length} listings from API');
          print('✅ Extracted ${extractedOpenHouses.length} open houses from listings');
          
          // Print all homes for sale data
          print('\n' + '='*80);
          print('🏠 HOMES FOR SALE - FULL DATA');
          print('='*80);
          for (int i = 0; i < fetchedListings.length; i++) {
            final listing = fetchedListings[i];
            print('\n📋 Listing #${i + 1}:');
            print('   ID: ${listing.id}');
            print('   Agent ID: ${listing.agentId}');
            print('   Price: \$${(listing.priceCents / 100).toStringAsFixed(2)} (${listing.priceCents} cents)');
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
              print('   Dual Agency Commission: ${listing.dualAgencyCommissionPercent}%');
            }
            print('   Created At: ${listing.createdAt}');
            print('   Stats:');
            print('     Searches: ${listing.stats.searches}');
            print('     Views: ${listing.stats.views}');
            print('     Contacts: ${listing.stats.contacts}');
            print('   JSON: ${listing.toJson()}');
            if (i < fetchedListings.length - 1) {
              print('   ' + '-'*76);
            }
          }
          print('\n' + '='*80);
          print('✅ Total Listings: ${fetchedListings.length}');
          print('='*80 + '\n');
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
      timeStr = timeStr.replaceAll(RegExp(r'[AP]M', caseSensitive: false), '').trim();
      
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
        
        return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
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
      print('ℹ️ Open houses extraction is now integrated into _loadListingsFromAPI');
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
      print('\n' + '='*80);
      print('🏠 HOMES FOR SALE (MOCK DATA) - FULL DATA');
      print('='*80);
      for (int i = 0; i < _allListings.length; i++) {
        final listing = _allListings[i];
        print('\n📋 Listing #${i + 1}:');
        print('   ID: ${listing.id}');
        print('   Agent ID: ${listing.agentId}');
        print('   Price: \$${(listing.priceCents / 100).toStringAsFixed(2)} (${listing.priceCents} cents)');
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
          print('   Dual Agency Commission: ${listing.dualAgencyCommissionPercent}%');
        }
        print('   Created At: ${listing.createdAt}');
        print('   Stats:');
        print('     Searches: ${listing.stats.searches}');
        print('     Views: ${listing.stats.views}');
        print('     Contacts: ${listing.stats.contacts}');
        print('   JSON: ${listing.toJson()}');
        if (i < _allListings.length - 1) {
          print('   ' + '-'*76);
        }
      }
      print('\n' + '='*80);
      print('✅ Total Mock Listings: ${_allListings.length}');
      print('='*80 + '\n');
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
      // No filter - show all data from original lists
      // Use refresh() to ensure UI updates
      _agents.value = List.from(_allAgents);
      _loanOfficers.value = List.from(_allLoanOfficers);
      _listings.value = List.from(_allListings);
      _openHouses.value = List.from(_allOpenHouses);
      
      // Force refresh to ensure UI updates
      _agents.refresh();
      _loanOfficers.refresh();
      _listings.refresh();
      _openHouses.refresh();
      
      if (kDebugMode) {
        print('📋 Showing all data (no filter)');
        print('   All Agents: ${_allAgents.length}');
        print('   All Loan Officers: ${_allLoanOfficers.length}');
        print('   All Listings: ${_allListings.length}');
        print('   All Open Houses: ${_allOpenHouses.length}');
      }
      return;
    }
    
    // Filter agents by ZIP code (comprehensive check like FindAgentsController)
    _agents.value = _allAgents.where((agent) {
      // Check 1: claimedZipCodes (array of strings - extracted from postalCode objects)
      final hasClaimedZip = agent.claimedZipCodes.contains(zipCode);
      
      // Check 2: serviceZipCodes (array of strings)
      final hasServiceZip = agent.serviceZipCodes.contains(zipCode);
      
      // Check 3: serviceAreas (array of strings - can contain ZIP codes)
      final hasServiceArea = agent.serviceAreas?.contains(zipCode) ?? false;
      
      // Check 4: Check if agent has any listings with this ZIP code
      final hasListingZip = _allListings.any((listing) => 
        listing.agentId == agent.id && listing.address.zip == zipCode
      );
      
      final matches = hasClaimedZip || hasServiceZip || hasServiceArea || hasListingZip;
      
      if (kDebugMode && matches) {
        print('   ✅ Agent "${agent.name}" matches ZIP $zipCode');
        print('      claimedZipCodes: ${agent.claimedZipCodes}');
        print('      serviceZipCodes: ${agent.serviceZipCodes}');
        print('      serviceAreas: ${agent.serviceAreas}');
        print('      hasListingZip: $hasListingZip');
      }
      
      return matches;
    }).toList();
    
    // Filter loan officers by ZIP code
    _loanOfficers.value = _allLoanOfficers.where((loanOfficer) {
      return loanOfficer.claimedZipCodes.contains(zipCode);
    }).toList();
    
    // Filter listings by ZIP code
    _listings.value = _allListings.where((listing) {
      return listing.address.zip == zipCode;
    }).toList();
    
    // Filter open houses by listings in that ZIP code
    // Open houses are linked to listings, so filter by listing ZIP codes
    final listingIds = _listings.map((l) => l.id).toSet();
    _openHouses.value = _allOpenHouses.where((oh) {
      final matches = listingIds.contains(oh.listingId);
      
      if (kDebugMode && matches) {
        final listing = _allListings.firstWhere(
          (l) => l.id == oh.listingId,
          orElse: () => Listing(
            id: '',
            agentId: '',
            priceCents: 0,
            address: const ListingAddress(street: '', city: '', state: '', zip: ''),
            photoUrls: const [],
            bacPercent: 0,
            dualAgencyAllowed: false,
            createdAt: DateTime.now(),
          ),
        );
        if (listing.id.isNotEmpty) {
          print('   ✅ Open House matches ZIP $zipCode (Listing: ${listing.address.zip})');
        }
      }
      
      return matches;
    }).toList();
    
    if (kDebugMode) {
      print('🔍 Applied ZIP code filter: $zipCode');
      print('   Filtered Agents: ${_agents.length} / ${_allAgents.length}');
      print('   Filtered Loan Officers: ${_loanOfficers.length} / ${_allLoanOfficers.length}');
      print('   Filtered Listings: ${_listings.length} / ${_allListings.length}');
      print('   Filtered Open Houses: ${_openHouses.length} / ${_allOpenHouses.length}');
    }
    
    // Record search for all displayed agents
    _recordSearchesForDisplayedAgents();
  }
  
  /// Records search tracking for all currently displayed agents
  Future<void> _recordSearchesForDisplayedAgents() async {
    if (_currentZipCode.value == null || _currentZipCode.value!.isEmpty) {
      return; // Only track when there's an active search/filter
    }
    
    // Record search for each displayed agent (fire and forget)
    for (final agent in _agents) {
      _recordSearch(agent.id);
    }
  }
  
  /// Records a search for an agent
  Future<void> _recordSearch(String agentId) async {
    try {
      final response = await _agentService.recordSearch(agentId);
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

  Future<void> searchByZipCode(String zipCode) async {
    try {
      // Validate ZIP code format (5 digits)
      if (zipCode.length != 5 || !RegExp(r'^\d+$').hasMatch(zipCode)) {
        // Don't set loading state for invalid input
        SnackbarHelper.showError(
          'Please enter a valid 5-digit ZIP code',
          title: 'Invalid ZIP Code',
          duration: const Duration(seconds: 2),
        );
        return;
      }
      
      _isLoading.value = true;
      
      // Set the ZIP code filter
      _currentZipCode.value = zipCode;
      
      // Apply filter to all data
      _applyZipCodeFilter();
      
      if (kDebugMode) {
        print('🔍 Filtered by ZIP code: $zipCode');
        print('   Agents: ${_agents.length}');
        print('   Loan Officers: ${_loanOfficers.length}');
        print('   Listings: ${_listings.length}');
        print('   Open Houses: ${_openHouses.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error filtering by ZIP code: $e');
      }
      Get.snackbar('Error', 'Search failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Clears the ZIP code filter
  void clearZipCodeFilter() {
    if (kDebugMode) {
      print('🧹 Clearing ZIP code filter');
      print('   Current ZIP: ${_currentZipCode.value}');
      print('   All Agents count: ${_allAgents.length}');
      print('   All Loan Officers count: ${_allLoanOfficers.length}');
      print('   All Listings count: ${_allListings.length}');
      print('   All Open Houses count: ${_allOpenHouses.length}');
    }
    
    // Clear the ZIP code filter
    _currentZipCode.value = null;
    
    // Immediately apply filter (which will show all data since zipCode is null)
    _applyZipCodeFilter();
    
    if (kDebugMode) {
      print('✅ Filter cleared - showing all data');
      print('   Agents: ${_agents.length}');
      print('   Loan Officers: ${_loanOfficers.length}');
      print('   Listings: ${_listings.length}');
      print('   Open Houses: ${_openHouses.length}');
    }
  }

  Future<void> toggleFavoriteAgent(String agentId) async {
    if (_togglingFavorites.contains(agentId)) return; // Prevent multiple simultaneous calls
    
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
            final apiMatchesOptimistic = isLiked == currentLikes.contains(userId);
            
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
                title: action == 'liked' ? 'Added to Favorites' : 'Removed from Favorites',
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
                print('✅ Added agent ${agent.id} to top of favorites. Likes: ${agent.likes}');
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
              e.response?.data['message']?.toString() ?? 'Failed to update favorite. Please try again.',
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
          print('⚠️ Loan officer like endpoint not available yet (404). Feature coming soon.');
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
    if (_togglingFavorites.contains(loanOfficerId)) return; // Prevent multiple simultaneous calls
    
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
      
      _loanOfficers[loanOfficerIndex] = originalLoanOfficer.copyWith(likes: currentLikes);
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
            final apiMatchesOptimistic = isLiked == currentLikes.contains(userId);
            
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
              _loanOfficers[loanOfficerIndex] = loanOfficer.copyWith(likes: currentLikes);
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
              title: action == 'liked' ? 'Added to Favorites' : 'Removed from Favorites',
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
                final loanOfficerIndex = _loanOfficers.indexWhere((lo) => lo.id == loanOfficerId);
                if (loanOfficerIndex != -1) {
                  var loanOfficer = _loanOfficers[loanOfficerIndex];
                  
                  // Ensure the loan officer's likes array includes userId at the end
                  final currentLikes = List<String>.from(loanOfficer.likes ?? []);
                  if (!currentLikes.contains(userId)) {
                    currentLikes.add(userId);
                    // Update the loan officer in the list
                    try {
                      _loanOfficers[loanOfficerIndex] = loanOfficer.copyWith(likes: currentLikes);
                      _loanOfficers.refresh();
                      loanOfficer = _loanOfficers[loanOfficerIndex]; // Get updated loan officer
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
            e.response?.data['message']?.toString() ?? 'Failed to update favorite. Please try again.',
            duration: const Duration(seconds: 3),
          );
        });
      } else {
        if (kDebugMode) {
          print('⚠️ Loan officer like endpoint not available yet (404). Feature coming soon.');
          print('   Backend needs to implement: POST /api/v1/buyer/likeLoanOfficer/{loanOfficerId}');
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
      final loanOfficer = _loanOfficers.firstWhere((lo) => lo.id == loanOfficerId);
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
    if (messagesController.allConversations.isEmpty && !messagesController.isLoadingThreads) {
      await messagesController.loadThreads();
    }
    
    // Wait a bit for threads to load
    int retries = 0;
    while (messagesController.allConversations.isEmpty && messagesController.isLoadingThreads && retries < 10) {
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
      Get.toNamed('/contact', arguments: {
        'userId': agent.id,
        'userName': agent.name,
        'userProfilePic': agent.profileImage,
        'userRole': 'agent',
        'agent': agent,
      });
    }
  }

  Future<void> contactLoanOfficer(LoanOfficerModel loanOfficer) async {
    // Check if conversation exists with this loan officer
    final messagesController = Get.find<MessagesController>();
    
    // Wait for threads to load if needed
    if (messagesController.allConversations.isEmpty && !messagesController.isLoadingThreads) {
      await messagesController.loadThreads();
    }
    
    // Wait a bit for threads to load
    int retries = 0;
    while (messagesController.allConversations.isEmpty && messagesController.isLoadingThreads && retries < 10) {
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
      Get.toNamed('/contact', arguments: {
        'userId': loanOfficer.id,
        'userName': loanOfficer.name,
        'userProfilePic': loanOfficer.profileImage,
        'userRole': 'loan_officer',
        'loanOfficer': loanOfficer,
      });
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

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
