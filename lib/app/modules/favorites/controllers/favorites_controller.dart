import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/modules/buyer/controllers/buyer_controller.dart';

class FavoritesController extends GetxController {
  // Data
  final _favoriteAgents = <AgentModel>[].obs;
  final _favoriteLoanOfficers = <LoanOfficerModel>[].obs;
  final _selectedTab = 0.obs; // 0: Agents, 1: Loan Officers
  final _isLoading = false.obs;

  // Controllers
  final AuthController _authController = Get.find<AuthController>();

  // Getters
  List<AgentModel> get favoriteAgents => _favoriteAgents;
  List<LoanOfficerModel> get favoriteLoanOfficers => _favoriteLoanOfficers;
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
        final buyerController = Get.find<BuyerController>();
        
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
        
        // Sort agents by most recently liked first (userId at end of likes array = most recent)
        favoritedAgents.sort((a, b) {
          final aLikes = a.likes ?? [];
          final bLikes = b.likes ?? [];
          final aIndex = aLikes.indexOf(userId);
          final bIndex = bLikes.indexOf(userId);
          // Items with userId at higher index (end of array) come first
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
        
        // Sort loan officers by most recently liked first (userId at end of likes array = most recent)
        favoritedLoanOfficers.sort((a, b) {
          final aLikes = a.likes ?? [];
          final bLikes = b.likes ?? [];
          final aIndex = aLikes.indexOf(userId);
          final bIndex = bLikes.indexOf(userId);
          // Items with userId at higher index (end of array) come first
          return bIndex.compareTo(aIndex);
        });
        
        _favoriteAgents.value = favoritedAgents;
        _favoriteLoanOfficers.value = favoritedLoanOfficers;
        
        if (kDebugMode) {
          print('✅ Loaded ${favoritedAgents.length} favorite agents and ${favoritedLoanOfficers.length} favorite loan officers');
        }
      } catch (e) {
        // BuyerController might not be available (e.g., if user is a seller)
        if (kDebugMode) {
          print('⚠️ BuyerController not available: $e');
        }
        // Fallback: clear favorites if buyer controller is not available
        _favoriteAgents.clear();
        _favoriteLoanOfficers.clear();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading favorites: $e');
      }
      _favoriteAgents.clear();
      _favoriteLoanOfficers.clear();
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Refreshes favorites from buyer controller
  /// Also ensures agents/loan officers are loaded if needed
  Future<void> refreshFavorites() async {
    try {
      final buyerController = Get.find<BuyerController>();
      
      // Check if we need to wait for agents/loan officers to load
      // Wait if either list is empty (they load independently)
      final agentsEmpty = buyerController.agents.isEmpty;
      final loanOfficersEmpty = buyerController.loanOfficers.isEmpty;
      
      if (agentsEmpty || loanOfficersEmpty) {
        if (kDebugMode) {
          print('🔄 Waiting for data to load - Agents: ${agentsEmpty ? "empty" : "loaded"}, Loan Officers: ${loanOfficersEmpty ? "empty" : "loaded"}');
        }
        
        // Wait and check multiple times for data to be loaded
        // Continue waiting until both are loaded or timeout
        for (int i = 0; i < 15; i++) {
          await Future.delayed(const Duration(milliseconds: 200));
          
          final agentsNowLoaded = buyerController.agents.isNotEmpty;
          final loanOfficersNowLoaded = buyerController.loanOfficers.isNotEmpty;
          
          // If both are now loaded (or at least we've waited enough), proceed
          if ((agentsNowLoaded && loanOfficersNowLoaded) || 
              (!agentsEmpty && agentsNowLoaded && !loanOfficersEmpty) ||
              (!loanOfficersEmpty && loanOfficersNowLoaded && !agentsEmpty)) {
            if (kDebugMode) {
              print('✅ Data loaded after ${(i + 1) * 200}ms - Agents: ${agentsNowLoaded ? "loaded" : "still empty"}, Loan Officers: ${loanOfficersNowLoaded ? "loaded" : "still empty"}');
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
      final buyerController = Get.find<BuyerController>();
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
      final buyerController = Get.find<BuyerController>();
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
    Get.toNamed(
      '/contact-loan-officer',
      arguments: {'loanOfficer': loanOfficer},
    );
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

  void clearAllFavorites() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text('Are you sure you want to remove all favorites?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              
              // Unlike all agents and loan officers via API
              try {
                final buyerController = Get.find<BuyerController>();
                
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
                
                // Refresh favorites
                Future.delayed(const Duration(milliseconds: 500), () {
                  _loadFavorites();
                });
                
                Get.snackbar('Cleared', 'All favorites removed');
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Error clearing favorites: $e');
                }
                // Still clear local list
                _favoriteAgents.clear();
                _favoriteLoanOfficers.clear();
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
