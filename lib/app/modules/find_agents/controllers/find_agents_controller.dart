import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/services/agent_service.dart';

class FindAgentsController extends GetxController {
  final RxList<AgentModel> agents = <AgentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedZipCode = ''.obs;
  final Rx<Listing?> listing = Rx<Listing?>(null);
  final TextEditingController searchController = TextEditingController();
  
  // Store all loaded agents for filtering
  final List<AgentModel> _allLoadedAgents = [];
  
  // Services
  final AgentService _agentService = AgentService();

  @override
  void onInit() {
    super.onInit();
    _loadArguments();
    _loadAgents();
    
    // Note: Search is handled by onChanged callback in the view
    // No need for listener here to avoid duplicate calls
  }
  
  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      // PRIORITY 1: Get ZIP code directly from 'zip' argument
      String zipCode = args['zip']?.toString().trim() ?? '';
      
      // PRIORITY 2: If no ZIP in args, get it from listing's address
      if (zipCode.isEmpty && args['listing'] != null) {
        final listingArg = args['listing'] as Listing?;
        if (listingArg != null && listingArg.address.zip.isNotEmpty) {
          zipCode = listingArg.address.zip.trim();
        }
      }
      
      // Ensure ZIP code is valid (5 digits)
      if (zipCode.isNotEmpty && !RegExp(r'^\d{5}$').hasMatch(zipCode)) {
        if (kDebugMode) {
          print('⚠️ Invalid ZIP code format: $zipCode');
        }
        zipCode = ''; // Clear invalid ZIP
      }
      
      selectedZipCode.value = zipCode;
      listing.value = args['listing'] as Listing?;
      
      if (kDebugMode) {
        print('📍 FindAgents - Loaded Arguments:');
        print('   ZIP code from args[\'zip\']: ${args['zip']}');
        print('   ZIP code from listing.address.zip: ${listing.value?.address.zip}');
        print('   Final selected ZIP code: ${selectedZipCode.value}');
        if (listing.value != null) {
          print('   Listing ID: ${listing.value!.id}');
          print('   Listing Address: ${listing.value!.address.toString()}');
        }
      }
    } else {
      if (kDebugMode) {
        print('⚠️ No arguments provided to FindAgentsView');
      }
    }
  }

  Future<void> _loadAgents() async {
    if (selectedZipCode.value.isEmpty) {
      if (kDebugMode) {
        print('⚠️ No ZIP code provided for agent search');
      }
      agents.value = [];
      isLoading.value = false;
      return;
    }

    isLoading.value = true;

    try {
      if (kDebugMode) {
        print('📡 Fetching all agents from API...');
        print('   Will filter by ZIP code: ${selectedZipCode.value}');
      }

      // Use getAllAgents endpoint (which actually exists)
      final allAgents = await _agentService.getAllAgents();

      if (kDebugMode) {
        print('✅ Successfully fetched ${allAgents.length} agents from API');
      }

      // Also fetch raw agent data to check listings
      final rawAgentsData = await _fetchRawAgentsData();

      // Filter agents by ZIP code
      final targetZip = selectedZipCode.value;
      final filteredAgents = allAgents.where((agent) {
        // Check 1: claimedZipCodes (array of strings - extracted from postalCode objects)
        final hasClaimedZip = agent.claimedZipCodes.contains(targetZip);
        
        // Check 2: serviceZipCodes (array of strings)
        final hasServiceZip = agent.serviceZipCodes.contains(targetZip);
        
        // Check 3: serviceAreas (array of strings - can contain ZIP codes)
        final hasServiceArea = agent.serviceAreas?.contains(targetZip) ?? false;
        
        // Check 4: Check if agent has any listings with this ZIP code
        final hasListingZip = _checkAgentListingsForZip(agent.id, targetZip, rawAgentsData);
        
        final matches = hasClaimedZip || hasServiceZip || hasServiceArea || hasListingZip;
        
        if (kDebugMode && matches) {
          print('   ✅ Agent "${agent.name}" matches ZIP $targetZip');
          print('      claimedZipCodes: ${agent.claimedZipCodes}');
          print('      serviceZipCodes: ${agent.serviceZipCodes}');
          print('      serviceAreas: ${agent.serviceAreas}');
          print('      hasListingZip: $hasListingZip');
        }
        
        return matches;
      }).toList();

      if (kDebugMode) {
        print('📍 Filtered to ${filteredAgents.length} agents for ZIP code: $targetZip');
        if (filteredAgents.isEmpty) {
          print('   No agents found for ZIP code $targetZip');
        } else {
          print('   Found agents: ${filteredAgents.map((a) => a.name).join(", ")}');
        }
      }

      _allLoadedAgents.clear();
      _allLoadedAgents.addAll(filteredAgents);
      agents.value = List.from(_allLoadedAgents);
      
      // Record search for all displayed agents
      _recordSearchesForDisplayedAgents();
    } on AgentServiceException catch (e) {
      if (kDebugMode) {
        print('❌ AgentServiceException: ${e.message}');
        print('   Status Code: ${e.statusCode}');
      }
      
      String errorMessage = 'Could not load agents from server.';
      if (e.statusCode == 404) {
        errorMessage = 'No agents found.';
      } else if (e.statusCode == 408) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      }
      
      // Show fallback mock data filtered by ZIP code
      final mockAgents = _getMockAgents();
      _allLoadedAgents.clear();
      _allLoadedAgents.addAll(mockAgents);
      agents.value = List.from(_allLoadedAgents);
      
      if (agents.isEmpty) {
        SnackbarHelper.showInfo(
          'No agents found for ZIP code ${selectedZipCode.value}.',
          title: 'Info',
          duration: const Duration(seconds: 3),
        );
      } else {
        SnackbarHelper.showWarning(
          '$errorMessage Showing sample data.',
          title: 'Warning',
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error fetching agents: $e');
        print('   Stack trace: $stackTrace');
      }
      // Fallback to mock data on error (filtered by ZIP code)
      final mockAgents = _getMockAgents();
      _allLoadedAgents.clear();
      _allLoadedAgents.addAll(mockAgents);
      agents.value = List.from(_allLoadedAgents);
      
      if (agents.isEmpty) {
        SnackbarHelper.showInfo(
          'No agents found for ZIP code ${selectedZipCode.value}.',
          title: 'Info',
          duration: const Duration(seconds: 3),
        );
      } else {
        SnackbarHelper.showWarning(
          'Could not load agents from server. Showing sample data.',
          title: 'Warning',
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Refresh agents list
  Future<void> refreshAgents() async {
    // Clear search when refreshing
    searchController.clear();
    searchQuery.value = '';
    await _loadAgents();
  }

  List<AgentModel> _getMockAgents() {
    return [
      AgentModel(
        id: '1',
        name: 'Sarah Johnson',
        email: 'sarah.johnson@premierrealty.com',
        phone: '+1 (555) 123-4567',
        profileImage:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
        brokerage: 'Premier Realty Group',
        licenseNumber: 'RE123456',
        licensedStates: ['CA', 'NY'],
        claimedZipCodes: [selectedZipCode.value],
        bio:
            'Experienced real estate agent with 10+ years in the market. Specializing in luxury homes and first-time buyers.',
        rating: 4.8,
        reviewCount: 127,
        searchesAppearedIn: 45,
        profileViews: 234,
        contacts: 89,
        serviceZipCodes: [selectedZipCode.value, '10002', '10003'],
        featuredListings: [],
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
        isVerified: true,
        isActive: true,
      ),
      AgentModel(
        id: '2',
        name: 'Michael Chen',
        email: 'michael.chen@cityhomes.com',
        phone: '+1 (555) 234-5678',
        profileImage:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        brokerage: 'City Homes Realty',
        licenseNumber: 'RE789012',
        licensedStates: ['CA', 'NY', 'FL'],
        claimedZipCodes: [selectedZipCode.value],
        bio:
            'Top-performing agent with expertise in urban properties and investment opportunities.',
        rating: 4.9,
        reviewCount: 203,
        searchesAppearedIn: 67,
        profileViews: 456,
        contacts: 134,
        serviceZipCodes: [selectedZipCode.value, '10004', '10005'],
        featuredListings: [],
        createdAt: DateTime.now().subtract(const Duration(days: 500)),
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isVerified: true,
        isActive: true,
      ),
      AgentModel(
        id: '3',
        name: 'Emily Rodriguez',
        email: 'emily.rodriguez@metrorealty.com',
        phone: '+1 (555) 345-6789',
        profileImage:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        brokerage: 'Metro Realty Partners',
        licenseNumber: 'RE345678',
        licensedStates: ['CA', 'NY'],
        claimedZipCodes: [selectedZipCode.value],
        bio:
            'Dedicated agent focused on helping families find their perfect home. Bilingual in English and Spanish.',
        rating: 4.7,
        reviewCount: 89,
        searchesAppearedIn: 23,
        profileViews: 156,
        contacts: 45,
        serviceZipCodes: [selectedZipCode.value, '10006'],
        featuredListings: [],
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 1)),
        isVerified: true,
        isActive: true,
      ),
      AgentModel(
        id: '4',
        name: 'David Thompson',
        email: 'david.thompson@eliterealty.com',
        phone: '+1 (555) 456-7890',
        profileImage:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        brokerage: 'Elite Realty Group',
        licenseNumber: 'RE901234',
        licensedStates: ['CA', 'NY', 'CT'],
        claimedZipCodes: [selectedZipCode.value],
        bio:
            'Luxury real estate specialist with over 15 years of experience in high-end properties.',
        rating: 4.9,
        reviewCount: 156,
        searchesAppearedIn: 34,
        profileViews: 289,
        contacts: 78,
        serviceZipCodes: [selectedZipCode.value, '10007', '10008'],
        featuredListings: [],
        createdAt: DateTime.now().subtract(const Duration(days: 800)),
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isVerified: true,
        isActive: true,
      ),
    ];
  }

  void searchAgents(String query) {
    searchQuery.value = query;
    final searchTerm = query.trim();
    
    // Check if the search term is a ZIP code (5 digits)
    final isZipCode = RegExp(r'^\d{5}$').hasMatch(searchTerm);
    
    if (isZipCode && searchTerm != selectedZipCode.value) {
      // User entered a new ZIP code - reload agents for that ZIP
      if (kDebugMode) {
        print('📍 New ZIP code detected: $searchTerm');
        print('   Previous ZIP: ${selectedZipCode.value}');
      }
      selectedZipCode.value = searchTerm;
      _loadAgents();
      return;
    }
    
    // Regular text search - filter by name and other fields
    final searchLower = searchTerm.toLowerCase();
    
    if (searchLower.isEmpty) {
      // Show all loaded agents (already filtered by ZIP code)
      agents.value = List.from(_allLoadedAgents);
      if (kDebugMode) {
        print('🔍 Search cleared. Showing all ${_allLoadedAgents.length} agents');
      }
      // Record search for all displayed agents
      _recordSearchesForDisplayedAgents();
    } else {
      // Filter loaded agents by search query - search in multiple fields
      final filteredAgents = _allLoadedAgents.where((agent) {
        // Search in name
        final nameMatch = agent.name.toLowerCase().contains(searchLower);
        
        // Search in brokerage
        final brokerageMatch = agent.brokerage.toLowerCase().contains(searchLower);
        
        // Search in email
        final emailMatch = agent.email.toLowerCase().contains(searchLower);
        
        // Search in bio if available
        final bioMatch = agent.bio != null && 
                        agent.bio!.toLowerCase().contains(searchLower);
        
        // Search in license number
        final licenseMatch = agent.licenseNumber.toLowerCase().contains(searchLower);
        
        // Search in licensed states
        final statesMatch = agent.licensedStates.any(
          (state) => state.toLowerCase().contains(searchLower)
        );
        
        // Return true if any field matches
        return nameMatch || 
               brokerageMatch || 
               emailMatch || 
               bioMatch || 
               licenseMatch || 
               statesMatch;
      }).toList();
      
      agents.value = filteredAgents;
      
      if (kDebugMode) {
        print('🔍 Search: "$query"');
        print('   Found ${filteredAgents.length} matching agents out of ${_allLoadedAgents.length}');
        if (filteredAgents.isNotEmpty) {
          print('   Matching agents: ${filteredAgents.map((a) => a.name).join(", ")}');
        }
      }
      
      // Record search for all displayed agents
      _recordSearchesForDisplayedAgents();
    }
  }
  
  /// Records search tracking for all currently displayed agents
  Future<void> _recordSearchesForDisplayedAgents() async {
    // Record search for each displayed agent (fire and forget)
    for (final agent in agents) {
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
    dynamic existingConversation;
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
      Get.toNamed('/messages');
    } else {
      // No conversation - show Start Chat screen
      Get.toNamed('/contact', arguments: {
        'userId': agent.id,
        'userName': agent.name,
        'userProfilePic': agent.profileImage,
        'userRole': 'agent',
        'agent': agent,
        'listing': listing.value,
        'propertyAddress': listing.value?.address.toString(),
      });
    }
  }

  void viewAgentProfile(AgentModel agent) {
    Get.toNamed('/agent-profile', arguments: {'agent': agent});
  }

  /// Fetch raw agents data to check listings
  Future<List<dynamic>> _fetchRawAgentsData() async {
    try {
      final dio = Dio();
      dio.options.baseUrl = ApiConstants.baseUrl;
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.headers = {
        'ngrok-skip-browser-warning': 'true',
        'Content-Type': 'application/json',
      };

      final response = await dio.get(
        '${ApiConstants.apiBaseUrl}/agent/getAllAgents',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        List<dynamic> agentsData = [];
        
        if (responseData is Map<String, dynamic>) {
          if (responseData['agents'] != null) {
            agentsData = responseData['agents'] as List<dynamic>? ?? [];
          } else if (responseData['data'] != null) {
            agentsData = responseData['data'] as List<dynamic>? ?? [];
          }
        } else if (responseData is List) {
          agentsData = responseData;
        }
        
        return agentsData;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error fetching raw agents data: $e');
      }
      return [];
    }
  }

  /// Check if agent has any listings with the target ZIP code
  bool _checkAgentListingsForZip(String agentId, String targetZip, List<dynamic> rawAgentsData) {
    try {
      // Find the agent in raw data
      final agentData = rawAgentsData.firstWhere(
        (agent) => (agent['_id']?.toString() ?? agent['id']?.toString()) == agentId,
        orElse: () => null,
      );
      
      if (agentData == null) return false;
      
      // Check listings array
      final listings = agentData['listings'];
      if (listings != null && listings is List) {
        for (var listing in listings) {
          if (listing is Map) {
            final listingZip = listing['zipCode']?.toString();
            if (listingZip == targetZip) {
              return true;
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error checking agent listings: $e');
      }
      return false;
    }
  }
}

