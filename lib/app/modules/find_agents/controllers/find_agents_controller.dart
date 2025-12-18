import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/utils/api_constants.dart';
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
  final Dio _dio = Dio();

  @override
  void onInit() {
    super.onInit();
    _setupDio();
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
  
  void _setupDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      selectedZipCode.value = args['zip'] ?? '';
      listing.value = args['listing'] as Listing?;
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
      final endpoint = ApiConstants.getAgentsByZipCodeEndpoint(selectedZipCode.value);
      
      if (kDebugMode) {
        print('📡 Fetching agents by ZIP code: ${selectedZipCode.value}');
        print('   URL: $endpoint');
      }

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Agents response received');
          print('   Status Code: ${response.statusCode}');
          print('   Response Type: ${response.data.runtimeType}');
        }

        final responseData = response.data;
        
        // Handle different response formats
        List<dynamic> agentsData = [];
        
        if (responseData is Map<String, dynamic>) {
          // Try different possible keys
          if (responseData['agents'] != null) {
            agentsData = responseData['agents'] as List<dynamic>? ?? [];
          } else if (responseData['data'] != null) {
            agentsData = responseData['data'] as List<dynamic>? ?? [];
          } else if (responseData['results'] != null) {
            agentsData = responseData['results'] as List<dynamic>? ?? [];
          } else if (responseData['agentList'] != null) {
            agentsData = responseData['agentList'] as List<dynamic>? ?? [];
          }
        } else if (responseData is List) {
          agentsData = responseData;
        }

        if (kDebugMode) {
          print('   Found ${agentsData.length} agents in response');
          if (agentsData.isNotEmpty) {
            print('   Sample agent data: ${agentsData[0]}');
          }
        }

        // Parse agents from API response
        final fetchedAgents = <AgentModel>[];
        for (int i = 0; i < agentsData.length; i++) {
          try {
            final agentData = agentsData[i];
            if (agentData is Map<String, dynamic>) {
              // Build full profile image URL if needed
              final agentJson = Map<String, dynamic>.from(agentData);
              if (agentJson['profilePic'] != null && 
                  agentJson['profilePic'].toString().isNotEmpty &&
                  !agentJson['profilePic'].toString().startsWith('http')) {
                final baseUrl = ApiConstants.baseUrl.endsWith('/') 
                    ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
                    : ApiConstants.baseUrl;
                final profilePic = agentJson['profilePic'].toString().replaceAll('\\', '/');
                final cleanPic = profilePic.startsWith('/') ? profilePic.substring(1) : profilePic;
                agentJson['profilePic'] = '$baseUrl/$cleanPic';
              }
              
              final agent = AgentModel.fromJson(agentJson);
              fetchedAgents.add(agent);
              
              if (kDebugMode && i == 0) {
                print('   ✅ Successfully parsed first agent: ${agent.name}');
              }
            } else {
              if (kDebugMode) {
                print('⚠️ Agent at index $i is not a Map: ${agentData.runtimeType}');
              }
            }
          } catch (e, stackTrace) {
            if (kDebugMode) {
              print('⚠️ Error parsing agent at index $i: $e');
              print('   Stack trace: $stackTrace');
              print('   Agent data: ${agentsData[i]}');
            }
          }
        }

        _allLoadedAgents.clear();
        _allLoadedAgents.addAll(fetchedAgents);
        agents.value = List.from(_allLoadedAgents);
        
        if (kDebugMode) {
          print('✅ Successfully loaded ${agents.length} agents from API');
        }
        
        if (fetchedAgents.isEmpty && agentsData.isNotEmpty) {
          // If we got data but couldn't parse it, show error
          Get.snackbar(
            'Warning',
            'Received agent data but could not parse it. Please check the API response format.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Unexpected status code: ${response.statusCode}');
          print('   Response: ${response.data}');
        }
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException fetching agents:');
        print('   Type: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.data}');
        print('   Status Code: ${e.response?.statusCode}');
      }
      
      String errorMessage = 'Could not load agents from server.';
      if (e.response?.statusCode == 404) {
        errorMessage = 'No agents found for this ZIP code.';
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot connect to server. Please ensure the server is running.';
      }
      
      // Only show fallback mock data if it's not a 404 (no agents found)
      if (e.response?.statusCode != 404) {
        final mockAgents = _getMockAgents();
        _allLoadedAgents.clear();
        _allLoadedAgents.addAll(mockAgents);
        agents.value = List.from(_allLoadedAgents);
        Get.snackbar(
          'Warning',
          '$errorMessage Showing sample data.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      } else {
        _allLoadedAgents.clear();
        agents.value = [];
        Get.snackbar(
          'Info',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error fetching agents: $e');
        print('   Stack trace: $stackTrace');
      }
      // Fallback to mock data on error
      final mockAgents = _getMockAgents();
      _allLoadedAgents.clear();
      _allLoadedAgents.addAll(mockAgents);
      agents.value = List.from(_allLoadedAgents);
      Get.snackbar(
        'Warning',
        'Could not load agents from server. Showing sample data.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
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
    final searchTerm = query.trim().toLowerCase();
    
    if (searchTerm.isEmpty) {
      // Show all loaded agents (already filtered by ZIP code)
      agents.value = List.from(_allLoadedAgents);
      if (kDebugMode) {
        print('🔍 Search cleared. Showing all ${_allLoadedAgents.length} agents');
      }
    } else {
      // Filter loaded agents by search query - search in multiple fields
      final filteredAgents = _allLoadedAgents.where((agent) {
        // Search in name
        final nameMatch = agent.name.toLowerCase().contains(searchTerm);
        
        // Search in brokerage
        final brokerageMatch = agent.brokerage.toLowerCase().contains(searchTerm);
        
        // Search in email
        final emailMatch = agent.email.toLowerCase().contains(searchTerm);
        
        // Search in bio if available
        final bioMatch = agent.bio != null && 
                        agent.bio!.toLowerCase().contains(searchTerm);
        
        // Search in license number
        final licenseMatch = agent.licenseNumber.toLowerCase().contains(searchTerm);
        
        // Search in licensed states
        final statesMatch = agent.licensedStates.any(
          (state) => state.toLowerCase().contains(searchTerm)
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
    }
  }

  void contactAgent(AgentModel agent) {
    // Navigate directly to messages screen with agent context
    Get.toNamed(
      '/messages',
      arguments: {
        'agent': agent,
        'userId': agent.id,
        'userName': agent.name,
        'userProfilePic': agent.profileImage,
        'userRole': 'agent',
        'listing': listing.value,
        'propertyAddress': listing.value?.address.toString(),
      },
    );
  }

  void viewAgentProfile(AgentModel agent) {
    Get.toNamed('/agent-profile', arguments: {'agent': agent});
  }
}

