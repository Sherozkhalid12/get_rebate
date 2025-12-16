import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class SellerController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  
  // Search
  final searchController = TextEditingController();
  final _searchQuery = ''.obs;

  // Data
  final _agents = <AgentModel>[].obs;
  final _favoriteAgents = <String>[].obs;
  final _isLoading = false.obs;
  final _togglingFavorites = <String>{}.obs; // Track which IDs are currently being toggled
  
  // Dio for API calls
  final Dio _dio = Dio();

  // Getters
  String get searchQuery => _searchQuery.value;
  List<AgentModel> get agents => _agents;
  List<String> get favoriteAgents => _favoriteAgents;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _setupDio();
    _loadMockData();
    searchController.addListener(_onSearchChanged);
    _preloadThreads();
  }
  
  void _setupDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      ...ApiConstants.ngrokHeaders,
      'Content-Type': 'application/json',
    };
  }

  /// Preloads chat threads for instant access when seller opens messages
  void _preloadThreads() {
    // Defer to next frame to avoid setState during build
    Future.microtask(() {
      try {
        if (_authController.isLoggedIn && _authController.currentUser != null) {
          // Initialize messages controller if not already registered
          // This will also initialize the socket connection for real-time messages
          if (!Get.isRegistered<MessagesController>()) {
            Get.put(MessagesController(), permanent: true);
            if (kDebugMode) {
              print('🚀 Seller: Created MessagesController - socket will be initialized');
            }
          }
          final messagesController = Get.find<MessagesController>();
          
          // Load threads in background - don't wait for it
          messagesController.refreshThreads();
          
          // Ensure socket is connected for real-time message reception
          if (kDebugMode) {
            print('🚀 Seller: Preloading chat threads and ensuring socket connection...');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Seller: Failed to preload threads: $e');
        }
        // Don't block initialization if preload fails
      }
    });
  }

  void _onSearchChanged() {
    _searchQuery.value = searchController.text;
    _searchAgents();
  }

  void _loadMockData() {
    // Mock agents data for sellers
    _agents.value = [
      AgentModel(
        id: 'agent_1',
        name: 'Sarah Johnson',
        email: 'sarah@example.com',
        phone: '+1 (555) 123-4567',
        brokerage: 'Premier Realty Group',
        licenseNumber: '123456',
        licensedStates: ['NY', 'NJ'],
        claimedZipCodes: ['10001', '10002', '10003'],
        bio:
            'Experienced real estate agent specializing in luxury properties and seller representation. Expert in Manhattan market trends and pricing strategies.',
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
        claimedZipCodes: ['10002', '10004'],
        bio:
            'Top-performing agent with expertise in market analysis and pricing strategies. Specializes in quick sales and competitive pricing.',
        rating: 4.6,
        reviewCount: 89,
        searchesAppearedIn: 32,
        profileViews: 156,
        contacts: 67,
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
        isVerified: true,
      ),
      AgentModel(
        id: 'agent_3',
        name: 'Emily Rodriguez',
        email: 'emily@example.com',
        phone: '+1 (555) 345-6789',
        brokerage: 'Brooklyn Heights Realty',
        licenseNumber: '345678',
        licensedStates: ['NY'],
        claimedZipCodes: ['11201', '11205'],
        bio:
            'Brooklyn market expert specializing in brownstones and modern condos. Expert in staging and marketing strategies.',
        rating: 4.9,
        reviewCount: 203,
        searchesAppearedIn: 78,
        profileViews: 456,
        contacts: 134,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        isVerified: true,
      ),
      AgentModel(
        id: 'agent_4',
        name: 'David Kim',
        email: 'david@example.com',
        phone: '+1 (555) 456-7890',
        brokerage: 'Queens Real Estate Partners',
        licenseNumber: '456789',
        licensedStates: ['NY'],
        claimedZipCodes: ['11375', '11377'],
        bio:
            'Queens market specialist with expertise in family homes and investment properties. Focus on maximizing property value.',
        rating: 4.7,
        reviewCount: 156,
        searchesAppearedIn: 56,
        profileViews: 289,
        contacts: 98,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        isVerified: true,
      ),
    ];
  }

  Future<void> _searchAgents() async {
    if (_searchQuery.value.isEmpty) return;

    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // In real app, this would filter based on search query and location
    } catch (e) {
      Get.snackbar('Error', 'Search failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> searchByZipCode(String zipCode) async {
    try {
      _isLoading.value = true;

      // Simulate API call to find agents in specific ZIP
      await Future.delayed(const Duration(milliseconds: 800));

      // Filter agents by ZIP code
      final zipAgents = _agents
          .where((agent) => agent.claimedZipCodes.contains(zipCode))
          .toList();

      // Update the list with ZIP-specific results
      if (zipAgents.isNotEmpty) {
        _agents.value = zipAgents;
      }
    } catch (e) {
      Get.snackbar('Error', 'Search failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> toggleFavoriteAgent(String agentId) async {
    if (_togglingFavorites.contains(agentId)) return; // Prevent multiple simultaneous calls
    
    try {
      _togglingFavorites.add(agentId);
      
      // Get current user ID
      final currentUser = _authController.currentUser;
      
      if (currentUser == null || currentUser.id.isEmpty) {
        Get.snackbar(
          'Error',
          'Please login to like agents',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
        );
        return;
      }
      
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
        print('   Current User ID: ${currentUser.id}');
      }
      
      // Make API call with currentUserId in body
      final response = await _dio.post(
        endpoint,
        data: {'currentUserId': currentUser.id},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final success = responseData['success'] ?? false;
        final isLiked = responseData['isLiked'] ?? false;
        final action = responseData['action'] ?? 'liked';
        final message = responseData['message'] ?? 'Success';
        
        if (success) {
          // Update favorite state based on API response
          if (isLiked) {
            if (!_favoriteAgents.contains(agentId)) {
              _favoriteAgents.add(agentId);
            }
          } else {
            _favoriteAgents.remove(agentId);
          }
          
          // Show snackbar with appropriate message
          Get.snackbar(
            action == 'liked' ? 'Added to Favorites' : 'Removed from Favorites',
            message.isNotEmpty 
                ? message 
                : (isLiked 
                    ? 'Agent added to your favorites' 
                    : 'Agent removed from your favorites'),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: isLiked ? AppTheme.lightGreen : AppTheme.mediumGray,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          );
          
          if (kDebugMode) {
            print('✅ Favorite toggled successfully: $isLiked');
          }
        } else {
          throw Exception(message);
        }
      } else {
        throw Exception('Failed to update favorite status');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling favorite: ${e.response?.statusCode ?? "N/A"}');
        print('   ${e.response?.data ?? e.message}');
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error toggling favorite: $e');
      }
      
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      );
    } finally {
      _togglingFavorites.remove(agentId);
    }
  }

  bool isAgentFavorite(String agentId) {
    return _favoriteAgents.contains(agentId);
  }

  void contactAgent(AgentModel agent) {
    // Navigate to contact agent screen
    Get.toNamed(
      '/contact-agent',
      arguments: {'agent': agent, 'type': 'seller'},
    );
  }

  void viewAgentProfile(AgentModel agent) {
    // Navigate to agent profile screen
    Get.toNamed('/agent-profile', arguments: {'agent': agent});
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
