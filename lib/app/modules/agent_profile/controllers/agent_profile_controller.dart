import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/modules/buyer/controllers/buyer_controller.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/services/agent_service.dart';
import 'package:getrebate/app/modules/proposals/controllers/proposal_controller.dart';

class AgentProfileController extends GetxController {
  // Data
  final _agent = Rxn<AgentModel>();
  final _isFavorite = false.obs;
  final _isLoading = false.obs;
  final _isLoadingProperties = false.obs;
  final _isTogglingFavorite = false.obs;
  final _selectedTab = 0.obs; // 0: Overview, 1: Reviews, 2: Properties
  final _properties = <Map<String, dynamic>>[].obs;
  
  // Dio for API calls
  final Dio _dio = Dio();
  
  // Agent service for tracking
  final AgentService _agentService = AgentService();

  // Getters
  AgentModel? get agent => _agent.value;
  bool get isFavorite => _isFavorite.value;
  bool get isLoading => _isLoading.value;
  bool get isLoadingProperties => _isLoadingProperties.value;
  int get selectedTab => _selectedTab.value;
  List<Map<String, dynamic>> get properties => _properties;

  @override
  void onInit() {
    super.onInit();
    _setupDio();
    _loadAgentData();
  }
  
  void _setupDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };
  }

  void _loadAgentData() {
    final args = Get.arguments;
    if (args != null && args['agent'] != null) {
      _agent.value = args['agent'] as AgentModel;
      
      if (kDebugMode) {
        print('👤 Agent Profile Loaded:');
        print('   Agent ID: ${_agent.value!.id}');
        print('   Name: ${_agent.value!.name}');
        print('   Email: ${_agent.value!.email}');
        print('   Brokerage: ${_agent.value!.brokerage}');
        print('   Rating: ${_agent.value!.rating}');
        print('   Review Count: ${_agent.value!.reviewCount}');
      }
      
      // Load properties for this agent
      _loadAgentProperties();
      
      // Record profile view
      _recordProfileView();
    } else {
      // Fallback to mock data
      _agent.value = AgentModel(
        id: 'agent_1',
        name: 'Sarah Johnson',
        email: 'sarah@example.com',
        phone: '+1 (555) 123-4567',
        profileImage: 'https://i.pravatar.cc/150?img=1',
        companyLogoUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=400',
        brokerage: 'Premier Realty Group',
        licenseNumber: '123456',
        licensedStates: ['NY', 'NJ'],
        claimedZipCodes: ['10001', '10002'],
        bio:
            'Experienced real estate agent specializing in luxury properties with over 10 years of experience in the New York market. I help clients navigate the complex real estate landscape with personalized service and expert guidance.',
        rating: 4.8,
        reviewCount: 127,
        searchesAppearedIn: 45,
        profileViews: 234,
        contacts: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        isVerified: true,
      );
    }
  }
  
  /// Fetches agent's properties from the API
  Future<void> _loadAgentProperties() async {
    if (_agent.value == null || _agent.value!.id.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Cannot load properties: Agent ID not available');
      }
      return;
    }

    try {
      _isLoadingProperties.value = true;
      
      final agentId = _agent.value!.id;
      final endpoint = ApiConstants.getAgentListingsEndpoint(agentId);
      
      if (kDebugMode) {
        print('📡 Fetching agent properties...');
        print('   Agent ID: $agentId');
        print('   URL: $endpoint');
      }

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Properties response received');
          print('   Status Code: ${response.statusCode}');
          print('📥 Full Response Data:');
          print(response.data);
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }

        final responseData = response.data;
        final success = responseData['success'] ?? false;
        final listingsData = responseData['listings'] as List<dynamic>? ?? [];

        if (kDebugMode) {
          print('   Success: $success');
          print('   Listings count: ${listingsData.length}');
        }

        if (success && listingsData.isNotEmpty) {
          // Parse listings
          final properties = <Map<String, dynamic>>[];
          
          for (int i = 0; i < listingsData.length; i++) {
            try {
              final listing = listingsData[i] as Map<String, dynamic>;
              if (kDebugMode) {
                print('📦 Parsing listing $i:');
                print('   ID: ${listing['_id']}');
                print('   Title: ${listing['propertyTitle']}');
                print('   Price: ${listing['price']}');
                print('   Photos: ${(listing['propertyPhotos'] as List?)?.length ?? 0}');
              }
              
              final property = _parseListingToProperty(listing);
              properties.add(property);
              
              if (kDebugMode) {
                print('   ✅ Parsed successfully');
              }
            } catch (e) {
              if (kDebugMode) {
                print('   ❌ Error parsing listing $i: $e');
              }
            }
          }

          _properties.value = properties;
          
          if (kDebugMode) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('✅ Loaded ${properties.length} properties for agent');
            print('   Properties list updated: ${_properties.length}');
          }
        } else {
          _properties.value = [];
          if (kDebugMode) {
            print('ℹ️ No properties found for this agent');
            print('   Success: $success');
            print('   Listings data empty: ${listingsData.isEmpty}');
          }
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Unexpected status code: ${response.statusCode}');
        }
        _properties.value = [];
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error loading properties: ${e.response?.statusCode ?? "N/A"}');
        print('   ${e.response?.data ?? e.message}');
      }
      
      // Don't show error to user - just keep empty list
      _properties.value = [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error loading properties: $e');
      }
      _properties.value = [];
    } finally {
      _isLoadingProperties.value = false;
    }
  }
  
  /// Records a profile view for the current agent
  Future<void> _recordProfileView() async {
    if (_agent.value == null || _agent.value!.id.isEmpty) {
      return;
    }
    
    try {
      final response = await _agentService.recordProfileView(_agent.value!.id);
      if (response != null && kDebugMode) {
        print('📊 Profile View Response:');
        print('   Message: ${response['message'] ?? 'N/A'}');
        print('   Views: ${response['views'] ?? 'N/A'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error recording profile view: $e');
      }
      // Don't show error to user - tracking is silent
    }
  }
  
  /// Parses API listing format to property format for display
  Map<String, dynamic> _parseListingToProperty(Map<String, dynamic> listing) {
    if (kDebugMode) {
      print('🔄 Parsing listing to property format...');
    }
    
    // Parse property photos - build full URLs
    final propertyPhotos = listing['propertyPhotos'] as List<dynamic>? ?? [];
    if (kDebugMode) {
      print('   Raw photos: $propertyPhotos');
    }
    
    final images = propertyPhotos
        .map((photo) {
          final photoPath = photo.toString();
          if (photoPath.isEmpty) return null;
          
          // If already full URL, return as is
          if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
            return photoPath;
          }
          
          // Build full URL
          String path = photoPath;
          if (path.startsWith('/')) {
            path = path.substring(1);
          }
          final baseUrl = ApiConstants.baseUrl.endsWith('/') 
              ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
              : ApiConstants.baseUrl;
          final fullUrl = '$baseUrl/$path';
          
          if (kDebugMode) {
            print('   Built photo URL: $fullUrl');
          }
          return fullUrl;
        })
        .where((photo) => photo != null)
        .cast<String>()
        .toList();
    
    if (kDebugMode) {
      print('   Final images count: ${images.length}');
    }
    
    // Parse property details
    final propertyDetails = listing['propertyDetails'] as Map<String, dynamic>? ?? {};
    final beds = int.tryParse(propertyDetails['bedrooms']?.toString() ?? '0') ?? 0;
    final baths = double.tryParse(propertyDetails['bathrooms']?.toString() ?? '0') ?? 0.0;
    final sqft = int.tryParse(propertyDetails['squareFeet']?.toString() ?? '0') ?? 0;
    
    if (kDebugMode) {
      print('   Property details: beds=$beds, baths=$baths, sqft=$sqft');
    }
    
    // Parse open houses - convert API format to display format
    final openHousesData = listing['openHouses'] as List<dynamic>? ?? [];
    final openHouses = openHousesData.map((oh) {
      // Parse date and times
      final dateStr = oh['date']?.toString() ?? '';
      final fromTime = oh['fromTime']?.toString() ?? '10:00 AM';
      final toTime = oh['toTime']?.toString() ?? '2:00 PM';
      final notes = oh['specialNote']?.toString() ?? oh['notes']?.toString() ?? '';
      
      // Try to parse the date
      DateTime? date;
      try {
        if (dateStr.isNotEmpty) {
          date = DateTime.parse(dateStr);
        }
      } catch (e) {
        if (kDebugMode) {
          print('   ⚠️ Error parsing date: $dateStr');
        }
      }
      
      // Build startDateTime and endDateTime strings
      String? startDateTime;
      String? endDateTime;
      if (date != null) {
        // Use the date with times
        startDateTime = date.toIso8601String();
        endDateTime = date.toIso8601String();
      }
      
      return {
        'date': dateStr,
        'fromTime': fromTime,
        'toTime': toTime,
        'notes': notes,
        'startDateTime': startDateTime,
        'endDateTime': endDateTime,
      };
    }).toList();
    
    if (kDebugMode) {
      print('   Open houses count: ${openHouses.length}');
      if (openHouses.isNotEmpty) {
        print('   First open house: ${openHouses[0]}');
      }
    }
    
    // Parse price
    final priceString = listing['price']?.toString() ?? '0';
    final priceDouble = double.tryParse(priceString) ?? 0.0;
    final formattedPrice = '\$${priceDouble.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
    
    if (kDebugMode) {
      print('   Price: $priceString → $formattedPrice');
    }
    
    // Parse BAC percentage
    final bacPercent = double.tryParse(listing['BACPercentage']?.toString() ?? '0') ?? 0.0;
    
    // Parse status - Check status field first, then active field
    String status = 'For Sale';
    final listingStatus = listing['status']?.toString().toLowerCase() ?? 'draft';
    final active = listing['active'] ?? (listingStatus == 'active'); // Fallback to status check
    
    // If status is 'active', it's for sale regardless of active field
    if (listingStatus == 'active') {
      status = 'For Sale';
    } else if (listingStatus == 'draft' || (!active && listingStatus != 'active')) {
      status = 'Pending Approval';
    } else if (listingStatus == 'sold') {
      status = 'Sold';
    } else if (listingStatus == 'pending') {
      status = 'Pending Approval';
    }
    
    if (kDebugMode) {
      print('   Status: ${listing['status']} (active: $active) → Display: $status');
    }
    
    // Build full address
    final streetAddress = listing['streetAddress']?.toString() ?? '';
    final city = listing['city']?.toString() ?? '';
    final state = listing['state']?.toString() ?? '';
    final zipCode = listing['zipCode']?.toString() ?? '';
    final fullAddress = '$streetAddress, $city, $state $zipCode';
    
    if (kDebugMode) {
      print('   Address: $fullAddress');
    }
    
    // Build agent info object for property detail view
    final agent = _agent.value;
    final agentInfo = agent != null ? {
      'id': agent.id,
      'name': agent.name,
      'company': agent.brokerage,
      'profileImage': agent.profileImage,
      'isDualAgencyAllowedInState': agent.isDualAgencyAllowedInState ?? false,
      'isDualAgencyAllowedAtBrokerage': agent.isDualAgencyAllowedAtBrokerage ?? false,
      'rating': agent.rating,
      'phone': agent.phone,
      'email': agent.email,
    } : null;
    
    final parsedProperty = {
      'id': listing['_id']?.toString() ?? '',
      'address': fullAddress,
      'price': formattedPrice,
      'beds': beds,
      'baths': baths,
      'sqft': sqft,
      'lotSize': 'N/A', // Not in API
      'yearBuilt': null, // Not in API
      'image': images.isNotEmpty ? images[0] : null,
      'images': images,
      'status': status,
      'rawStatus': listing['status']?.toString() ?? 'draft', // Include raw status for checking 'active'
      'isActive': listingStatus == 'active' || active, // Include active flag - true if status is 'active'
      'bacPercent': bacPercent,
      'city': city,
      'state': state,
      'zip': zipCode,
      'description': listing['description']?.toString() ?? '',
      'openHouses': openHouses,
      'views': listing['views'] is int ? listing['views'] : 0,
      'contacts': listing['contacts'] is int ? listing['contacts'] : 0,
      'searches': listing['searches'] is int ? listing['searches'] : 0,
      'dualAgencyAllowed': listing['dualAgencyAllowed'] ?? false,
      'listingAgent': listing['listingAgent'] ?? true,
      'agent': agentInfo, // Add agent information for property detail view
      'agentId': listing['id']?.toString() ?? '', // The agent ID from listing
    };
    
    if (kDebugMode) {
      print('   ✅ Property parsed successfully');
      print('   Final property: ${parsedProperty['id']} - ${parsedProperty['address']}');
      print('   Agent info included: ${agentInfo != null}');
    }
    
    return parsedProperty;
  }

  void setSelectedTab(int index) {
    _selectedTab.value = index;
    
    // Load properties when switching to properties tab
    if (index == 2 && _properties.isEmpty && !_isLoadingProperties.value) {
      _loadAgentProperties();
    }
  }

  Future<void> toggleFavorite() async {
    if (_agent.value == null) return;
    if (_isTogglingFavorite.value) return; // Prevent multiple simultaneous calls
    
    try {
      _isTogglingFavorite.value = true;
      
      // Get current user ID
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser;
      
      if (currentUser == null || currentUser.id.isEmpty) {
        SnackbarHelper.showError(
          'Please login to like agents',
          duration: const Duration(seconds: 2),
        );
        return;
      }
      
      final agentId = _agent.value!.id;
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
          _isFavorite.value = isLiked;
          
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
      
      SnackbarHelper.showError(
        e.response?.data['message']?.toString() ?? 'Failed to update favorite. Please try again.',
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error toggling favorite: $e');
      }
      
      SnackbarHelper.showError(
        'An unexpected error occurred. Please try again.',
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isTogglingFavorite.value = false;
    }
  }

  void contactAgent() {
    if (_agent.value == null) return;

    Get.dialog(
      AlertDialog(
        title: Text('Contact ${_agent.value!.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.primaryBlue),
              title: const Text('Call'),
              subtitle: Text(_agent.value!.phone ?? 'No phone number'),
              onTap: () {
                Navigator.pop(Get.context!);
                // Record contact when user taps to call
                _recordContact(_agent.value!.id);
                SnackbarHelper.showInfo('Opening phone dialer...', title: 'Calling');
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: AppTheme.primaryBlue),
              title: const Text('Email'),
              subtitle: Text(_agent.value!.email),
              onTap: () {
                Navigator.pop(Get.context!);
                SnackbarHelper.showInfo('Opening email client...', title: 'Emailing');
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: AppTheme.primaryBlue),
              title: const Text('Message'),
              subtitle: const Text('Send a message'),
              onTap: () {
                Navigator.pop(Get.context!);
                // Record contact when user taps to message
                _recordContact(_agent.value!.id);
                // Start chat which will navigate to messages
                startChat();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }

  Future<void> startChat() async {
    if (_agent.value == null) {
      SnackbarHelper.showError('Agent information not available');
      return;
    }

    // Record contact action
    _recordContact(_agent.value!.id);

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
        (conv) => conv.senderId == _agent.value!.id,
      );
    } catch (e) {
      existingConversation = null;
    }
    
    if (existingConversation != null) {
      // Conversation exists - go directly to chat
      messagesController.selectConversation(existingConversation);
      Get.toNamed('/messages');
    } else {
      // No conversation - show Start Chat screen
      Get.toNamed('/contact', arguments: {
        'userId': _agent.value!.id,
        'userName': _agent.value!.name,
        'userProfilePic': _agent.value!.profileImage,
        'userRole': 'agent',
        'agent': _agent.value,
      });
    }
  }
  
  /// Records a contact action for the current agent
  Future<void> _recordContact(String agentId) async {
    try {
      final response = await _agentService.recordContact(agentId);
      if (response != null && kDebugMode) {
        print('📞 Contact Response:');
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
  
  Future<void> _oldStartChat() async {
    if (_agent.value == null) {
      SnackbarHelper.showError('Agent information not available');
      return;
    }

    // Navigate directly to messages screen
    Get.toNamed('/messages', arguments: {
      'agent': _agent.value,
      'userId': _agent.value!.id,
      'userName': _agent.value!.name,
      'userProfilePic': _agent.value!.profileImage,
      'userRole': 'agent',
    });
  }

  void viewProperties() {
    SnackbarHelper.showInfo('Property listings coming soon!', title: 'Properties');
  }

  void shareProfile() {
    SnackbarHelper.showInfo('Profile sharing feature coming soon!', title: 'Share');
  }

  void selectAsMyAgent() {
    if (_agent.value == null) return;

    try {
      final buyerController = Get.find<BuyerController>();
      buyerController.selectBuyerAgent(_agent.value!);
      Navigator.pop(Get.context!); // Go back to previous screen after selection
    } catch (e) {
      // BuyerController might not be available if user is not a buyer
      Get.snackbar(
        'Selection Complete',
        'You are now working with ${_agent.value!.name}. They will represent you in all property transactions.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.lightGreen,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Returns dynamic reviews from agent data
  List<Map<String, dynamic>> getReviews() {
    if (_agent.value == null || _agent.value!.reviews == null) {
      return [];
    }

    return _agent.value!.reviews!.map((review) {
      // Calculate time ago
      final now = DateTime.now();
      final difference = now.difference(review.createdAt);
      String timeAgo;
      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        timeAgo = '$years ${years == 1 ? "year" : "years"} ago';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        timeAgo = '$months ${months == 1 ? "month" : "months"} ago';
      } else if (difference.inDays > 0) {
        timeAgo = '${difference.inDays} ${difference.inDays == 1 ? "day" : "days"} ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours} ${difference.inHours == 1 ? "hour" : "hours"} ago';
      } else {
        timeAgo = 'Just now';
      }

      return {
        'id': review.id,
        'reviewerId': review.reviewerId,
        'name': review.reviewerName,
        'profilePic': review.reviewerProfile,
        'rating': review.rating,
        'date': timeAgo,
        'createdAt': review.createdAt.toIso8601String(),
        'comment': review.comment,
      };
    }).toList();
  }

  /// Returns dynamic properties from API
  List<Map<String, dynamic>> getProperties() {
    return _properties;
  }
  
  /// OLD MOCK DATA - REMOVED
  List<Map<String, dynamic>> _getMockProperties() {
    return [
      // === $2.5M LUXURY PENTHOUSE – $1M+ RULES APPLY ===
      {
        'id': 'luxury_001',
        'address': '123 Park Avenue, Penthouse 50A, New York, NY 10022',
        'price': '\$2,500,000',
        'beds': 3,
        'baths': 3.5,
        'sqft': 3200,
        'lotSize': 'N/A',
        'yearBuilt': 2020,
        'image':
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&h=600&fit=crop',
        'images': [
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800&h=600&fit=crop',
        ],
        'status': 'For Sale',
        'bacPercent': 2.7, // 2.7% buyer agent commission
        'city': 'New York',
        'state': 'NY',
        'zip': '10022',
        'agentId': 'sarah_johnson',
        'agent': {
          'name': 'Sarah Johnson',
          'company': 'Premier Realty Group',
          'profileImage': 'https://i.pravatar.cc/300?img=1',
          'isDualAgencyAllowedInState': true,
          'isDualAgencyAllowedAtBrokerage': true,
        },
        'description':
        'Unparalleled luxury penthouse with 360° city views. Private elevator, 12-ft ceilings, Crestron smart home, and 1,200 sqft terrace. The pinnacle of Manhattan living.',
        'openHouses': [
          {
            'startDateTime': DateTime.now().add(const Duration(days: 3)).copyWith(hour: 13, minute: 0).toIso8601String(),
            'endDateTime': DateTime.now().add(const Duration(days: 3)).copyWith(hour: 15, minute: 0).toIso8601String(),
            'notes': 'Champagne & caviar served. Valet parking included.',
          },
          {
            'startDateTime': DateTime.now().add(const Duration(days: 7)).copyWith(hour: 11, minute: 0).toIso8601String(),
            'endDateTime': DateTime.now().add(const Duration(days: 7)).copyWith(hour: 14, minute: 0).toIso8601String(),
            'notes': 'Private showing for qualified buyers only.',
          },
        ],
      },

      // === $1.8M CLASSIC CO-OP – STANDARD REBATE ===
      {
        'id': 'classic_002',
        'address': '456 Central Park West, Apt 12B, New York, NY 10025',
        'price': '\$1,800,000',
        'beds': 2,
        'baths': 2,
        'sqft': 1800,
        'lotSize': 'N/A',
        'yearBuilt': 1929,
        'image':
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&h=600&fit=crop',
        'images': [
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&h=600&fit=crop',
        ],
        'status': 'For Sale',
        'bacPercent': 2.5,
        'city': 'New York',
        'state': 'NY',
        'zip': '10025',
        'agentId': 'mike_chen',
        'agent': {
          'name': 'Mike Chen',
          'company': 'Elite Manhattan Brokers',
          'profileImage': 'https://i.pravatar.cc/300?img=3',
          'isDualAgencyAllowedInState': true,
          'isDualAgencyAllowedAtBrokerage': false, // NO DUAL AGENCY
        },
        'description':
        'Pre-war masterpiece with herringbone floors, beamed ceilings, and wood-burning fireplace. Renovated kitchen with Sub-Zero and Wolf appliances.',
        'openHouses': [
          {
            'startDateTime': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
            'endDateTime': DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
            'notes': 'OPEN HOUSE TODAY! Fresh flowers & coffee.',
          },
        ],
      },

      // === $3.2M TOWNHOUSE – DUAL AGENCY + $1M+ REBATE ===
      {
        'id': 'townhouse_003',
        'address': '789 Madison Avenue, Townhouse, New York, NY 10065',
        'price': '\$3,200,000',
        'beds': 4,
        'baths': 4.5,
        'sqft': 4200,
        'lotSize': '20x100',
        'yearBuilt': 1899,
        'image':
        'https://images.unsplash.com/photo-1600607687644-c7171b42498b?w=800&h=600&fit=crop',
        'images': [
          'https://images.unsplash.com/photo-1600607687644-c7171b42498b?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800&h=600&fit=crop',
        ],
        'status': 'For Sale',
        'bacPercent': 2.8,
        'city': 'New York',
        'state': 'NY',
        'zip': '10065',
        'agentId': 'lisa_wong',
        'agent': {
          'name': 'Lisa Wong',
          'company': 'Madison Luxury Homes',
          'profileImage': 'https://i.pravatar.cc/300?img=5',
          'isDualAgencyAllowedInState': true,
          'isDualAgencyAllowedAtBrokerage': true,
        },
        'description':
        'Fully renovated 1899 limestone townhouse. 7 fireplaces, wine cellar, rooftop deck, and private garage. The ultimate trophy home.',
        'openHouses': [
          {
            'startDateTime': DateTime.now().add(const Duration(days: 1)).copyWith(hour: 12, minute: 0).toIso8601String(),
            'endDateTime': DateTime.now().add(const Duration(days: 1)).copyWith(hour: 15, minute: 0).toIso8601String(),
            'notes': 'Catered brunch. Bring your architect!',
          },
        ],
      },
    ];
  }

  List<String> getRebateChecklistForBuying() {
    return [
      'Confirm State Eligibility: Verify that the buyer is purchasing or building in a state that allows real estate rebates. These 10 states currently do not allow real estate rebates: Alabama, Alaska, Kansas, Louisiana, Mississippi, Missouri, Oklahoma, Oregon, Tennessee, and Iowa.',
      'Prepare a Buyer Representation Agreement as you normally would and include the addendum below (or a similar version approved by your broker). (See attached sample form.)',
      'Verify Loan Officer and Lender Participation: Ensure the buyer is pre-approved with a loan officer whose lender allows real estate rebates. (Agents and buyers can search this site for a list of confirmed loan officers.)',
      'Coordinate Seller Concessions and Rebate Limits: Confirm with the buyer\'s loan officer whether "seller concessions" will be requested in the offer. Determine the maximum amount allowed, including the rebate, to ensure the buyer receives the full benefit. Some lenders handle seller concessions and rebates separately—clarify how the lender manages this. It\'s often helpful to review the numbers with the loan officer before submitting the offer.',
      'Review Special Financing Programs: If the buyer is using special financing programs (e.g., first-time homebuyer grants, state or city programs), note that some may restrict or prohibit rebates. Buyers must work with programs and lenders that allow rebates. Make sure buyers understand how their financing decisions may affect rebate eligibility.',
      'For New Construction Purchases: Confirm with the builder that rebates are allowed. Most builders permit them, but some may restrict or prohibit them. If an issue arises, contact us for alternative ideas to try.',
      'Notify the Title or Closing Company Early: Inform the title or closing company that the transaction will include a rebate. Experienced closers will know how to properly document this, though some may need to confirm internal procedures. The rebate should appear on the settlement statement as a credit to the buyer.',
      'Calculate and Verify the Rebate Amount: Use the Rebate Calculator on the site to determine the rebate amount. Buyers also have access to this tool. Because the rebate may change during negotiations, confirm the final amount once the offer is accepted and all contingencies are removed.',
      'Include Rebate Disclosure and Commission Split in the Offer: When submitting an offer, include the rebate disclosure and commission split language (or broker-approved equivalent).',
      'After Closing: Encourage the Buyer to leave feedback on your GetaRebate.com profile — this helps build your reputation and visibility. If a rebate was given, the actual rebate amount will be on the settlement statement and the closer should point it out to the Buyer. Make sure Buyer knows how much money they saved working with you from the rebate so they can refer you to family and friends!',
    ];
  }

  /// Returns the rebate addendum wording for the Buyer Representation Agreement (Step #2)
  String getRebateAddendumForBuyerRepresentation() {
    return '''The rebate is typically based only on the total Buyer Agent Commission (BAC) negotiated/ paid by the seller or builder. BAC is now negotiated on a property-by-property basis. Real Estate commission is 100% negotiable.

REBATE TIERS (Based on Total Commission received by Agent/Broker)

Use the Estimated Calculator tab on GetaRebate.com or the mobile app before writing an offer, and the Actual Calculator tab once price and BAC are known to calculate rebate amounts. If Dual Agency applies the rebate is then determined by the total commission received "Buyer Agent Commission" (BAC) plus "Listing Agent Commission" (LAC). Dual Agency is when the same agent who has the property listed for sale, also works with the Buyer.

Tier 1: If total commission received is 4.0% or higher of the purchase price, rebate amount is 40% of the total commission received. Tier 2: 3.01 to 3.99% = 35%, Tier 3: 2.5% to 3.0% = 30%, Tier 4: 2.0% to 2.49% = 25%, Tier 5: 1.5% to 1.99% = 20%, Tier 6: .25% to 1.49% = 10%, Tier 7: 0% to .24% = 0% (Higher commission equals higher rebate)

For sales prices of \$700,000 or higher, tiers 5 and 6 do not apply and only tiers 1, 2, 3, 4 or 7 apply.

Rebate appears as a credit on the Closing Disclosure/Settlement Statement, subject to lender approval.

REQUIREMENTS & LIMITATIONS

1. Lender Approval: Buyer must choose a lender/program that allows rebates. (All loan officers on GetaRebate.com have confirmed their lender permits rebates, but Buyer must verify final approval.)

2. State Restrictions: Rebates are currently allowed in 40 states. Buyer must purchase in a rebate-allowed state.

3. Builder Restrictions: Some builders prohibit or limit rebates. If so, Buyer may: Choose a different builder, or Negotiate upgrades/concessions in exchange for lowering the BAC.

4. Not Guaranteed: Despite best efforts, a rebate may be reduced or disallowed due to lender, builder, or state law restrictions.

BUYER AGENT AND BUYER RESPONSIBILITIES

Buyer Agent and Buyer agree to:

Follow the Buying/Building Checklists on GetaRebate.com/app.

Disclose the rebate to all parties.

Confirm rebate eligibility with their lender. And follow all necessary steps.

REBATE ELECTION

Buyer elects to participate in the rebate program:

Yes No''';
  }

  /// Returns the rebate disclosure wording for the Purchase Offer (Step #9)
  String getRebateDisclosureForPurchaseOffer() {
    return '''Real Estate Commission Rebate and Commission Split Disclosure:
Buyer, Seller, and Listing Brokerage acknowledge and agree that the total real estate commission shall be split between the Listing Brokerage and the Buyer's Brokerage at closing, allowing the Buyer's Brokerage to provide a rebate to the Buyer as a credit on the settlement statement.

Buyer and Seller acknowledge that Buyer's Agent has agreed to provide a real estate commission rebate to Buyer in the amount of \$____, or as otherwise agreed upon in writing, subject to approval and acceptance by Buyer's lender of choice. Said rebate shall generally be applied as a credit to Buyer's allowable closing costs on the final settlement statement, provided such credit is permitted by applicable lending guidelines and closing instructions.

The final rebate amount may be adjusted based on negotiated terms of the Purchase Agreement, lender requirements, and applicable state or federal laws. All parties acknowledge that the real estate commission is fully negotiable and that this rebate has been properly disclosed in accordance with state law, lender policy, and the terms of Buyer's agency agreement.''';
  }

  List<String> getRebateChecklistForSelling() {
    return [
      'Confirm Rebate Eligibility: Verify that the property is located in a state that allows real estate rebates. Currently, 11 states do not allow rebates when selling: Alabama, Alaska, Kansas, Louisiana, Mississippi, Missouri, Oklahoma, Oregon, Tennessee, New Jersey, and Iowa.',
      'Complete your listing agreement as you normally would. Then, include and complete a Listing Agent Rebate Disclosure Addendum/Amendment to document the rebate option you and the Seller have selected. (You may use the sample document provided below or your own broker-approved language.) Be sure that both you and the Seller(s) sign the Rebate Addendum/Amendment and that it is included with the signed listing agreement.',
      'Notify the Title/Closing Company: Contact the title or closing company early to let them know a rebate will be part of the transaction. Confirm any special documentation or instructions they may require. The rebate should appear on the settlement statement as a credit to the Seller if the rebate option is chosen.',
      'Confirm Final Rebate or Fee Reduction Amount: Use the Seller Rebate Conversion Calculator on GetaRebate.com to determine the correct amount or fee. Adjust the amount if the final commission or negotiated terms change.',
      'After Closing: Encourage the Seller to leave feedback on your GetaRebate.com profile — this helps build your reputation and visibility. If a rebate was given, the actual rebate amount will show on the settlement statement and the closer should point it out to the Seller at closing. If you used the lower listing fee option, use the calculator to show what that savings equates to. It\'s best that the seller knows the dollar amount they ended up saving so they can tell friends to refer you to!',
    ];
  }

  /// Returns the rebate disclosure wording for Seller Listing Agreement (Step #2)
  String getRebateDisclosureForListingAgreement() {
    return '''Listing/Selling Commission Rebate Addendum/Amendment

This Listing/Selling Commission Rebate Addendum/Amendment ("Addendum") is attached to and made part of the Listing Agreement between Seller and Listing Broker/Agent for the property located at: __________________________________________.

The rebate options described below are based solely on the original listing fee/commission stated on Line ____ of the attached Listing Agreement ("Original Commission"). The rebate applies only to the commission paid to the Listing Agent/Broker.

REBATE OPTIONS (Both give identical savings/rebate amount)

Option 1 – Reduced Listing Fee (Available in All 50 States) Preferred option

Seller elects to receive a reduced listing fee in lieu of receiving a rebate at closing.

1. The reduced listing fee shall be calculated using the Seller Conversion Calculator provided on GetaRebate.com or the mobile app.

2. The calculator will use the Original Commission percentage and sales price to determine the Reduced Commission percentage.

3. To determine the savings/rebate, take Original Commission minus Reduced Commission (example 3.0% - 2.1% = .9%) times the sales price.

4. No monetary rebate will appear on the Closing Disclosure/Settlement Statement under this option.

Seller elects Option 1: Yes No

If yes, enter Original Commission percentage_________% ,and Reduced Commission percentage_________%.

Option 2 – Commission Rebate at Closing (currently Available in 39 States)

Seller elects to receive a commission rebate paid as a credit on the Closing Disclosure/Settlement Statement.

1. The rebate amount shall be calculated using the Estimated and Actual Calculator tabs on GetaRebate.com or the mobile app.

2. All rebates must meet lender guidelines (if applicable) and be disclosed to all parties.

3. Let title company or closer know that rebate is to be shown as a credit to Seller at closing on the Settlement Statement.

Seller elects Option 2: Yes No

ADDITIONAL TERMS

1. This Addendum supersedes any conflicting terms in the Listing Agreement regarding commission rebates or listing fee adjustments.

2. All rebate calculations are estimates until final commission and sales price amounts are determined.

3. The rebate will be applied only to the commission paid to the Listing Agent/Broker ("LAC").

4. If another brokerage represents the buyer, that brokerage will receive the Buyer Agent Commission ("BAC"), and no portion of that commission is included in this rebate calculation. For option 1 or 2.

5. In the event the Listing Agent enters into a Dual Agency situation, the rebate shall be based on the total commission received (combined LAC + BAC). For option 1 or 2.

6. A higher total commission results in a higher rebate/savings.

7. The Seller acknowledges that rebate availability and limitations may vary based on state law, lender restrictions, and transaction structure.

8. The Listing Agent/Broker makes no guarantee that a lender will approve the rebate, if applicable.''';
  }
  
  /// Create a proposal for this agent
  Future<void> createProposal(BuildContext context) async {
    if (_agent.value == null) {
      SnackbarHelper.showError('Agent information not available');
      return;
    }

    // Get or create proposal controller
    if (!Get.isRegistered<ProposalController>()) {
      Get.put(ProposalController(), permanent: true);
    }
    final proposalController = Get.find<ProposalController>();

    // Show proposal creation dialog
    _showCreateProposalDialog(context, proposalController);
  }

  void _showCreateProposalDialog(
    BuildContext context,
    ProposalController proposalController,
  ) {
    final messageController = TextEditingController();
    final propertyAddressController = TextEditingController();
    final propertyPriceController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Proposal',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Send a proposal to ${_agent.value!.name}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mediumGray,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Message field
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Message (Optional)',
                    hintText: 'Add a message to your proposal...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Property address (optional)
                TextField(
                  controller: propertyAddressController,
                  decoration: InputDecoration(
                    labelText: 'Property Address (Optional)',
                    hintText: 'e.g., 123 Main St, City, State',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Property price (optional)
                TextField(
                  controller: propertyPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Property Price (Optional)',
                    hintText: 'e.g., 500000',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                            onPressed: proposalController.isLoading
                                ? null
                                : () async {
                                    Get.back();
                                    final proposal = await proposalController.createProposal(
                                      professionalId: _agent.value!.id,
                                      professionalName: _agent.value!.name,
                                      professionalType: 'agent',
                                      message: messageController.text.trim().isEmpty
                                          ? null
                                          : messageController.text.trim(),
                                      propertyAddress: propertyAddressController.text.trim().isEmpty
                                          ? null
                                          : propertyAddressController.text.trim(),
                                      propertyPrice: propertyPriceController.text.trim().isEmpty
                                          ? null
                                          : propertyPriceController.text.trim(),
                                    );
                                    if (proposal != null) {
                                      // Navigate to proposals view
                                      Get.toNamed('/proposals');
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: AppTheme.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: proposalController.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.white,
                                    ),
                                  )
                                : const Text('Send Proposal'),
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  void onClose() {
    _dio.close();
    super.onClose();
  }
}
