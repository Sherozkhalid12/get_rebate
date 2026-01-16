import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/models/open_house_model.dart';
import 'package:getrebate/app/services/loan_officer_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/modules/buyer_v2/controllers/buyer_v2_controller.dart';

class FavoritesController extends GetxController {
  // Data
  final _favoriteAgents = <AgentModel>[].obs;
  final _favoriteLoanOfficers = <LoanOfficerModel>[].obs;
  final _favoriteListings = <Listing>[].obs; // Houses for Sale
  final _favoriteOpenHouses = <OpenHouseModel>[].obs; // Open Houses
  final _selectedTab = 0.obs; // 0: Agents, 1: Homes for Sale, 2: Open Houses, 3: Loan Officers
  final _isLoading = false.obs;
  
  // Track recently liked agents/loan officers to keep them at top
  final _recentlyLikedAgents = <String, DateTime>{}.obs;
  final _recentlyLikedLoanOfficers = <String, DateTime>{}.obs;

  // Controllers
  final AuthController _authController = Get.find<AuthController>();

  // Getters
  List<AgentModel> get favoriteAgents => _favoriteAgents;
  List<LoanOfficerModel> get favoriteLoanOfficers => _favoriteLoanOfficers;
  List<Listing> get favoriteListings => _favoriteListings; // Houses for Sale
  List<OpenHouseModel> get favoriteOpenHouses => _favoriteOpenHouses; // Open Houses
  int get selectedTab => _selectedTab.value;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
  }
  
  @override
  void onReady() {
    super.onReady();
    // Refresh favorites when screen becomes visible, with retry if data not loaded yet
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadFavorites();
    });
  }

  void setSelectedTab(int index) {
    _selectedTab.value = index;
  }

  /// Loads favorites by checking the likes array from agents/loan officers
  void _loadFavorites({int retryCount = 0}) {
    try {
      _isLoading.value = true;
      
      // Get current user ID
      final currentUser = _authController.currentUser;
      if (currentUser == null || currentUser.id.isEmpty) {
        if (kDebugMode) {
          print('⚠️ Favorites: No user logged in, showing empty favorites');
        }
        _favoriteAgents.clear();
        _favoriteLoanOfficers.clear();
        _isLoading.value = false;
        return;
      }
      
      final userId = currentUser.id;
      
      if (kDebugMode) {
        print('❤️ Loading favorites for user: $userId (attempt ${retryCount + 1})');
      }
      
      // Try to get agents and loan officers from buyer_controller
      try {
        final buyerController = Get.find<BuyerV2Controller>();
        
        final agents = buyerController.agents;
        final loanOfficers = buyerController.loanOfficers;
        
        if (kDebugMode) {
          print('   📊 Found ${agents.length} agents and ${loanOfficers.length} loan officers');
        }
        
        // If lists are empty and we haven't retried too many times, wait and retry
        // Check if either list is empty (they load independently)
        if ((agents.isEmpty || loanOfficers.isEmpty) && retryCount < 5) {
          if (kDebugMode) {
            print('⏳ Data not fully loaded yet (Agents: ${agents.length}, Loan Officers: ${loanOfficers.length}), retrying in 300ms... (attempt ${retryCount + 1}/5)');
          }
          _isLoading.value = false;
          Future.delayed(const Duration(milliseconds: 300), () {
            _loadFavorites(retryCount: retryCount + 1);
          });
          return;
        }
        
        // Even if lists are empty, still try to load (they might have been loaded but empty)
        // This ensures we don't show stale data
        
        // Filter agents where current user ID is in the likes array
        final favoritedAgents = <AgentModel>[];
        for (final agent in agents) {
          final likes = agent.likes;
          if (likes != null) {
            // Check if user ID is in the likes array
            final isLiked = likes.contains(userId);
            if (isLiked) {
              favoritedAgents.add(agent);
              if (kDebugMode) {
                print('   ✅ Agent ${agent.id} (${agent.name}) is favorited - likes: $likes contains userId: $userId');
              }
            } else if (kDebugMode && likes.isNotEmpty) {
              print('   ❌ Agent ${agent.id} (${agent.name}) NOT favorited - likes: $likes, userId: $userId');
            }
          }
        }
        
        // Sort agents by most recently liked first
        // Priority: 1) Recently liked (within 10 seconds), 2) Higher index in likes array
        favoritedAgents.sort((a, b) {
          final aLikes = a.likes ?? [];
          final bLikes = b.likes ?? [];
          final aIndex = aLikes.indexOf(userId);
          final bIndex = bLikes.indexOf(userId);
          
          // Check if agents were recently liked
          final aRecentlyLiked = _recentlyLikedAgents.containsKey(a.id);
          final bRecentlyLiked = _recentlyLikedAgents.containsKey(b.id);
          
          // If userId not found in likes, put at end
          if (aIndex == -1 && bIndex == -1) {
            // Both not found - check recently liked
            if (aRecentlyLiked && !bRecentlyLiked) return -1;
            if (bRecentlyLiked && !aRecentlyLiked) return 1;
            return 0;
          }
          if (aIndex == -1) return 1; // a goes to end
          if (bIndex == -1) return -1; // b goes to end
          
          // Priority 1: Recently liked agents come first
          if (aRecentlyLiked && !bRecentlyLiked) return -1; // a comes first
          if (bRecentlyLiked && !aRecentlyLiked) return 1; // b comes first
          
          // Priority 2: Items with userId at higher index (end of array = most recent) come first
          // So we want descending order: bIndex - aIndex
          return bIndex.compareTo(aIndex);
        });
        
        // Filter loan officers where current user ID is in the likes array
        final favoritedLoanOfficers = <LoanOfficerModel>[];
        for (final loanOfficer in loanOfficers) {
          final likes = loanOfficer.likes;
          if (likes != null) {
            // Check if user ID is in the likes array
            final isLiked = likes.contains(userId);
            if (isLiked) {
              favoritedLoanOfficers.add(loanOfficer);
              if (kDebugMode) {
                print('   ✅ Loan Officer ${loanOfficer.id} (${loanOfficer.name}) is favorited - likes: $likes contains userId: $userId');
              }
            } else if (kDebugMode && likes.isNotEmpty) {
              print('   ❌ Loan Officer ${loanOfficer.id} (${loanOfficer.name}) NOT favorited - likes: $likes, userId: $userId');
            }
          }
        }
        
        // Sort loan officers by most recently liked first
        // Priority: 1) Recently liked (within 10 seconds), 2) Higher index in likes array
        favoritedLoanOfficers.sort((a, b) {
          final aLikes = a.likes ?? [];
          final bLikes = b.likes ?? [];
          final aIndex = aLikes.indexOf(userId);
          final bIndex = bLikes.indexOf(userId);
          
          // Check if loan officers were recently liked
          final aRecentlyLiked = _recentlyLikedLoanOfficers.containsKey(a.id);
          final bRecentlyLiked = _recentlyLikedLoanOfficers.containsKey(b.id);
          
          // If userId not found in likes, put at end
          if (aIndex == -1 && bIndex == -1) {
            // Both not found - check recently liked
            if (aRecentlyLiked && !bRecentlyLiked) return -1;
            if (bRecentlyLiked && !aRecentlyLiked) return 1;
            return 0;
          }
          if (aIndex == -1) return 1; // a goes to end
          if (bIndex == -1) return -1; // b goes to end
          
          // Priority 1: Recently liked loan officers come first
          if (aRecentlyLiked && !bRecentlyLiked) return -1; // a comes first
          if (bRecentlyLiked && !aRecentlyLiked) return 1; // b comes first
          
          // Priority 2: Items with userId at higher index (end of array = most recent) come first
          // So we want descending order: bIndex - aIndex
          return bIndex.compareTo(aIndex);
        });
        
        // Clean up old recently liked entries (older than 10 seconds)
        final now = DateTime.now();
        _recentlyLikedAgents.removeWhere((id, timestamp) => 
          now.difference(timestamp).inSeconds > 10
        );
        _recentlyLikedLoanOfficers.removeWhere((id, timestamp) => 
          now.difference(timestamp).inSeconds > 10
        );
        
        // Load favorite listings - separate into "Houses for Sale" and "Open Houses"
        final listings = buyerController.listings;
        final openHouses = buyerController.openHouses;
        final favoriteListingIds = buyerController.favoriteListings;
        final favoritedListings = <Listing>[]; // Houses for Sale
        final favoritedOpenHouses = <OpenHouseModel>[]; // Open Houses
        
        // Get all listing IDs that have open houses
        final listingsWithOpenHouses = openHouses.map((oh) => oh.listingId).toSet();
        
        if (kDebugMode) {
          print('   📋 Loading favorite listings:');
          print('      Total listings: ${listings.length}');
          print('      Total open houses: ${openHouses.length}');
          print('      Favorite listing IDs: $favoriteListingIds');
        }
        
        // Preserve manually added listings (those added via addFavoriteListingToTop)
        // These take priority over auto-loaded favorites
        final preservedListingIds = <String>{};
        preservedListingIds.addAll(_favoriteListings.map((l) => l.id));
        preservedListingIds.addAll(_favoriteOpenHouses.map((oh) => oh.listingId));
        
        // Add preserved listings first (maintains order and respects manual additions)
        for (final listing in _favoriteListings) {
          favoritedListings.add(listing);
        }
        for (final openHouse in _favoriteOpenHouses) {
          favoritedOpenHouses.add(openHouse);
        }
        
        // Then add other favorites from API that aren't already preserved
        for (final listing in listings) {
          if (favoriteListingIds.contains(listing.id) && !preservedListingIds.contains(listing.id)) {
            // Check if this listing has an open house
            if (listingsWithOpenHouses.contains(listing.id)) {
              // Find the open house for this listing
              final openHouse = openHouses.firstWhere(
                (oh) => oh.listingId == listing.id,
                orElse: () => openHouses.first,
              );
              if (openHouse.listingId == listing.id && !favoritedOpenHouses.any((oh) => oh.listingId == listing.id)) {
                favoritedOpenHouses.add(openHouse);
                if (kDebugMode) {
                  print('      ✅ Found favorite open house: ${listing.id} - ${listing.address}');
                }
              }
            } else {
              // Regular listing (House for Sale)
              if (!favoritedListings.any((l) => l.id == listing.id)) {
                favoritedListings.add(listing);
                if (kDebugMode) {
                  print('      ✅ Found favorite listing: ${listing.id} - ${listing.address}');
                }
              }
            }
          }
        }
        
        _favoriteAgents.value = favoritedAgents;
        _favoriteLoanOfficers.value = favoritedLoanOfficers;
        _favoriteListings.value = favoritedListings;
        _favoriteOpenHouses.value = favoritedOpenHouses;
        
        if (kDebugMode) {
          print('✅ Loaded ${favoritedAgents.length} favorite agents, ${favoritedLoanOfficers.length} favorite loan officers, ${favoritedListings.length} favorite listings (Houses for Sale), and ${favoritedOpenHouses.length} favorite open houses');
        }
      } catch (e) {
        // BuyerV2Controller might not be available (e.g., if user is a seller)
        if (kDebugMode) {
          print('⚠️ BuyerV2Controller not available: $e');
        }
        // Fallback: clear favorites if buyer controller is not available
        _favoriteAgents.clear();
        _favoriteLoanOfficers.clear();
        _favoriteListings.clear();
        _favoriteOpenHouses.clear();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading favorites: $e');
      }
      _favoriteAgents.clear();
      _favoriteLoanOfficers.clear();
      _favoriteListings.clear();
      _favoriteOpenHouses.clear();
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Adds a newly liked agent to the top of favorites list immediately
  void addFavoriteAgentToTop(AgentModel agent) {
    try {
      final currentUser = _authController.currentUser;
      if (currentUser == null || currentUser.id.isEmpty) return;
      
      // Mark this agent as recently liked (within last 5 seconds)
      _recentlyLikedAgents[agent.id] = DateTime.now();
      
      // Remove agent if it already exists in the list
      _favoriteAgents.removeWhere((a) => a.id == agent.id);
      
      // Add to the beginning of the list (top)
      _favoriteAgents.insert(0, agent);
      
      if (kDebugMode) {
        print('✅ Added agent ${agent.id} to top of favorites list');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error adding agent to favorites: $e');
      }
    }
  }

  /// Adds a newly liked loan officer to the top of favorites list immediately
  void addFavoriteLoanOfficerToTop(LoanOfficerModel loanOfficer) {
    try {
      final currentUser = _authController.currentUser;
      if (currentUser == null || currentUser.id.isEmpty) return;
      
      // Mark this loan officer as recently liked (within last 5 seconds)
      _recentlyLikedLoanOfficers[loanOfficer.id] = DateTime.now();
      
      // Remove loan officer if it already exists in the list
      _favoriteLoanOfficers.removeWhere((lo) => lo.id == loanOfficer.id);
      
      // Add to the beginning of the list (top)
      _favoriteLoanOfficers.insert(0, loanOfficer);
      
      if (kDebugMode) {
        print('✅ Added loan officer ${loanOfficer.id} to top of favorites list');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error adding loan officer to favorites: $e');
      }
    }
  }

  /// Adds a newly liked listing to the top of favorites list immediately
  void addFavoriteListingToTop(Listing listing, {bool isFromOpenHousesTab = false}) {
    try {
      final currentUser = _authController.currentUser;
      if (currentUser == null || currentUser.id.isEmpty) return;
      
      // Remove from both lists first to avoid duplicates
      _favoriteListings.removeWhere((l) => l.id == listing.id);
      _favoriteOpenHouses.removeWhere((oh) => oh.listingId == listing.id);
      
      // Determine which list to add to based on the tab it was liked from
      if (isFromOpenHousesTab) {
        // Liked from Open Houses tab - add to Open Houses in favorites
        try {
          final buyerController = Get.find<BuyerV2Controller>();
          final openHouses = buyerController.openHouses;
          final openHouse = openHouses.firstWhere((oh) => oh.listingId == listing.id);
          _favoriteOpenHouses.insert(0, openHouse);
          
          if (kDebugMode) {
            print('✅ Added listing ${listing.id} to Open Houses in favorites (liked from Open Houses tab)');
          }
        } catch (e) {
          // If open house not found, add to Houses for Sale as fallback
          _favoriteListings.insert(0, listing);
          if (kDebugMode) {
            print('⚠️ Open house not found for listing ${listing.id}, added to Houses for Sale instead');
          }
        }
      } else {
        // Liked from Houses for Sale tab - add to Houses for Sale in favorites
        _favoriteListings.insert(0, listing);
        
        if (kDebugMode) {
          print('✅ Added listing ${listing.id} to Houses for Sale in favorites (liked from Houses for Sale tab)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error adding listing to favorites: $e');
      }
    }
  }

  /// Removes a listing from favorites immediately
  void removeFavoriteListingImmediately(String listingId) {
    try {
      _favoriteListings.removeWhere((l) => l.id == listingId);
      _favoriteOpenHouses.removeWhere((oh) => oh.listingId == listingId);
      if (kDebugMode) {
        print('✅ Removed listing $listingId from favorites list');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error removing listing from favorites: $e');
      }
    }
  }

  /// Refreshes favorites from buyer controller
  /// Also ensures agents/loan officers are loaded if needed
  Future<void> refreshFavorites() async {
    try {
      final buyerController = Get.find<BuyerV2Controller>();
      
      // Check if we need to wait for agents/loan officers/listings/open houses to load
      // Wait if any list is empty (they load independently)
      final agentsEmpty = buyerController.agents.isEmpty;
      final loanOfficersEmpty = buyerController.loanOfficers.isEmpty;
      final listingsEmpty = buyerController.listings.isEmpty;
      final openHousesEmpty = buyerController.openHouses.isEmpty;
      
      if (agentsEmpty || loanOfficersEmpty || listingsEmpty || openHousesEmpty) {
        if (kDebugMode) {
          print('🔄 Waiting for data to load - Agents: ${agentsEmpty ? "empty" : "loaded"}, Loan Officers: ${loanOfficersEmpty ? "empty" : "loaded"}, Listings: ${listingsEmpty ? "empty" : "loaded"}, Open Houses: ${openHousesEmpty ? "empty" : "loaded"}');
        }
        
        // Wait and check multiple times for data to be loaded
        // Continue waiting until all are loaded or timeout
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(milliseconds: 200));
          
          final agentsNowLoaded = buyerController.agents.isNotEmpty;
          final loanOfficersNowLoaded = buyerController.loanOfficers.isNotEmpty;
          final listingsNowLoaded = buyerController.listings.isNotEmpty;
          final openHousesNowLoaded = buyerController.openHouses.isNotEmpty;
          
          // If all are now loaded (or at least we've waited enough), proceed
          if ((agentsNowLoaded && loanOfficersNowLoaded && listingsNowLoaded && openHousesNowLoaded) || 
              (!agentsEmpty && agentsNowLoaded && !loanOfficersEmpty && loanOfficersNowLoaded && !listingsEmpty && listingsNowLoaded && !openHousesEmpty && openHousesNowLoaded)) {
            if (kDebugMode) {
              print('✅ Data loaded after ${(i + 1) * 200}ms - Agents: ${agentsNowLoaded ? "loaded" : "still empty"}, Loan Officers: ${loanOfficersNowLoaded ? "loaded" : "still empty"}, Listings: ${listingsNowLoaded ? "loaded" : "still empty"}, Open Houses: ${openHousesNowLoaded ? "loaded" : "still empty"}');
            }
            break;
          }
        }
      }
      
      // Now load favorites (will retry internally if needed)
      _loadFavorites();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not refresh buyer data: $e');
      }
      // Still try to load favorites
      _loadFavorites();
    }
  }

  void _loadMockData() {
    // Mock favorite agents
    _favoriteAgents.value = [
      AgentModel(
        id: 'agent_1',
        name: 'Sarah Johnson',
        email: 'sarah@example.com',
        phone: '+1 (555) 123-4567',
        brokerage: 'Premier Realty Group',
        licenseNumber: '123456',
        licensedStates: ['NY', 'NJ'],
        claimedZipCodes: ['10001'],
        bio: 'Experienced real estate agent specializing in luxury properties.',
        rating: 4.8,
        reviewCount: 127,
        searchesAppearedIn: 45,
        profileViews: 234,
        contacts: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        isVerified: true,
      ),
      AgentModel(
        id: 'agent_2',
        name: 'Michael Chen',
        email: 'michael@example.com',
        phone: '+1 (555) 234-5678',
        brokerage: 'Metro Properties',
        licenseNumber: '234567',
        licensedStates: ['NY', 'CT'],
        claimedZipCodes: ['10002'],
        bio: 'First-time home buyer specialist with 10+ years experience.',
        rating: 4.6,
        reviewCount: 89,
        searchesAppearedIn: 32,
        profileViews: 156,
        contacts: 67,
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
        isVerified: true,
      ),
    ];

    // Mock favorite loan officers
    _favoriteLoanOfficers.value = [
      LoanOfficerModel(
        id: 'loan_1',
        name: 'Jennifer Davis',
        email: 'jennifer@example.com',
        phone: '+1 (555) 345-6789',
        company: 'First National Bank',
        licenseNumber: 'LO123456',
        licensedStates: ['NY', 'NJ', 'CT'],
        claimedZipCodes: ['10001'],
        bio:
            'Senior loan officer with expertise in conventional and FHA loans.',
        rating: 4.9,
        reviewCount: 156,
        searchesAppearedIn: 67,
        profileViews: 289,
        contacts: 134,
        allowsRebates: true,
        mortgageApplicationUrl: 'https://www.example.com/apply/jennifer-davis',
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
        claimedZipCodes: ['10002'],
        bio: 'Specializing in jumbo loans and investment properties.',
        rating: 4.7,
        reviewCount: 98,
        searchesAppearedIn: 43,
        profileViews: 187,
        contacts: 76,
        allowsRebates: true,
        mortgageApplicationUrl: 'https://www.example.com/apply/robert-wilson',
        createdAt: DateTime.now().subtract(const Duration(days: 350)),
        isVerified: true,
      ),
    ];
  }

  void removeFavoriteAgent(String agentId) {
    // Remove from local list (will be updated when favorites refresh)
    _favoriteAgents.removeWhere((agent) => agent.id == agentId);
    
    // Try to call the API to unlike (via buyer controller if available)
    try {
      final buyerController = Get.find<BuyerV2Controller>();
      buyerController.toggleFavoriteAgent(agentId);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not toggle favorite via buyer controller: $e');
      }
    }
    
    // Refresh favorites after a short delay to get updated data
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadFavorites();
    });
  }

  void removeFavoriteLoanOfficer(String loanOfficerId) {
    // Remove from local list (will be updated when favorites refresh)
    _favoriteLoanOfficers.removeWhere(
      (loanOfficer) => loanOfficer.id == loanOfficerId,
    );
    
    // Try to call the API to unlike (via buyer controller if available)
    try {
      final buyerController = Get.find<BuyerV2Controller>();
      buyerController.toggleFavoriteLoanOfficer(loanOfficerId);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not toggle favorite via buyer controller: $e');
      }
    }
    
    // Refresh favorites after a short delay to get updated data
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadFavorites();
    });
  }

  void contactAgent(AgentModel agent) {
    Get.toNamed('/contact-agent', arguments: {'agent': agent});
  }

  void contactLoanOfficer(LoanOfficerModel loanOfficer) {
    // Record contact
    _recordLoanOfficerContact(loanOfficer.id);
    
    Get.toNamed(
      '/contact-loan-officer',
      arguments: {'loanOfficer': loanOfficer},
    );
  }
  
  /// Records a contact action for a loan officer
  Future<void> _recordLoanOfficerContact(String loanOfficerId) async {
    try {
      final loanOfficerService = LoanOfficerService();
      final response = await loanOfficerService.recordContact(loanOfficerId);
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

  void viewAgentProfile(AgentModel agent) {
    Get.toNamed('/agent-profile', arguments: {'agent': agent});
  }

  void viewLoanOfficerProfile(LoanOfficerModel loanOfficer) {
    Get.toNamed(
      '/loan-officer-profile',
      arguments: {'loanOfficer': loanOfficer},
    );
  }

  void viewListing(Listing listing) {
    Get.toNamed('/listing-detail', arguments: {'listing': listing});
  }

  void viewOpenHouse(OpenHouseModel openHouse) {
    try {
      final buyerController = Get.find<BuyerV2Controller>();
      final listing = buyerController.getListingForOpenHouse(openHouse);
      if (listing != null) {
        Get.toNamed('/listing-detail', arguments: {'listing': listing});
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not view open house: $e');
      }
    }
  }

  void removeFavoriteListing(String listingId) {
    // Remove from local lists
    _favoriteListings.removeWhere((listing) => listing.id == listingId);
    _favoriteOpenHouses.removeWhere((oh) => oh.listingId == listingId);
    
    // Try to call the API to unlike (via buyer controller if available)
    try {
      final buyerController = Get.find<BuyerV2Controller>();
      buyerController.toggleFavoriteListing(listingId);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not toggle favorite via buyer controller: $e');
      }
    }
    
    // Refresh favorites after a short delay to get updated data
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadFavorites();
    });
  }

  void clearAllFavorites() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text('Are you sure you want to remove all favorites?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(Get.context!), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(Get.context!);
              
              // Unlike all agents and loan officers via API
              try {
                final buyerController = Get.find<BuyerV2Controller>();
                
                // Unlike all favorite agents
                for (final agent in _favoriteAgents) {
                  try {
                    await buyerController.toggleFavoriteAgent(agent.id);
                  } catch (e) {
                    if (kDebugMode) {
                      print('⚠️ Error unliking agent ${agent.id}: $e');
                    }
                  }
                }
                
                // Unlike all favorite loan officers
                for (final loanOfficer in _favoriteLoanOfficers) {
                  try {
                    await buyerController.toggleFavoriteLoanOfficer(loanOfficer.id);
                  } catch (e) {
                    if (kDebugMode) {
                      print('⚠️ Error unliking loan officer ${loanOfficer.id}: $e');
                    }
                  }
                }
                
                // Unlike all favorite listings (this will handle both regular listings and open houses)
                final allFavoriteListingIds = <String>{};
                for (final listing in _favoriteListings) {
                  allFavoriteListingIds.add(listing.id);
                }
                for (final openHouse in _favoriteOpenHouses) {
                  allFavoriteListingIds.add(openHouse.listingId);
                }
                
                for (final listingId in allFavoriteListingIds) {
                  try {
                    await buyerController.toggleFavoriteListing(listingId);
                  } catch (e) {
                    if (kDebugMode) {
                      print('⚠️ Error unliking listing $listingId: $e');
                    }
                  }
                }
                
                // Refresh favorites
                Future.delayed(const Duration(milliseconds: 500), () {
                  _loadFavorites();
                });
                
                Get.snackbar('Cleared', 'All favorites removed');
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Error clearing favorites: $e');
                }
                // Still clear local lists
                _favoriteAgents.clear();
                _favoriteLoanOfficers.clear();
                _favoriteListings.clear();
                _favoriteOpenHouses.clear();
                Get.snackbar('Cleared', 'All favorites removed');
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
