import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/controllers/location_controller.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/utils/error_handler.dart';
import 'package:getrebate/app/services/agent_service.dart';
import 'package:getrebate/app/services/zip_codes_service.dart';

class FindAgentsController extends GetxController {
  final LocationController _locationController = Get.find<LocationController>();
  final ZipCodesService _zipCodesService = ZipCodesService();
  final RxList<AgentModel> agents = <AgentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedZipCode = ''.obs;
  final Rx<Listing?> listing = Rx<Listing?>(null);
  final TextEditingController searchController = TextEditingController();
  final TextEditingController zipSearchController = TextEditingController();
  /// Map of postalCode -> distanceMiles from within10miles API (same as home page)
  Map<String, double>? _within10MilesMap;
  
  // Store all loaded agents for filtering
  final List<AgentModel> _allLoadedAgents = [];
  
  // Store filtered and sorted agents (before pagination)
  final List<AgentModel> _filteredAndSortedAgents = [];
  
  // Server-side pagination (reactive) - MAKE THEM PUBLIC SO OBX CAN TRACK THEM
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalAgents = 0.obs;
  final RxBool _isLoadingMore = false.obs;
  
  // Services
  final AgentService _agentService = AgentService();
  
  // Reactive total count
  final RxInt _totalFilteredCount = 0.obs;
  
  // Computed reactive value for canLoadMore
  bool get canLoadMore => currentPage.value < totalPages.value;
  
  bool get isLoadingMore => _isLoadingMore.value;
  int get totalFilteredCount => _totalFilteredCount.value;

  @override
  void onInit() {
    super.onInit();
    _loadArguments();
    _loadAgents();
    
    // Note: Search is handled by onChanged callback in the view
    // No need for listener here to avoid duplicate calls
  }
  
  /// Uses cached current location zip for the ZIP search field (instant, no fetch on tap).
  void useCurrentLocationForZip() {
    final zipCode = _locationController.currentZipCode;
    if (zipCode != null &&
        zipCode.length == 5 &&
        RegExp(r'^\d+$').hasMatch(zipCode)) {
      zipSearchController.text = zipCode;
      zipSearchController.selection = TextSelection.collapsed(offset: zipCode.length);
      searchByZipCode(zipCode);
    } else {
      SnackbarHelper.showInfo(
        'Location not ready yet. Please wait a moment and try again, or enter ZIP manually.',
        title: 'Location',
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Search by ZIP code using same API as home page (within10miles).
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

      selectedZipCode.value = trimmedZipCode;

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
          'Unable to load nearby ZIP codes. Please check your connection and try again.',
        );
        _within10MilesMap = null;
      }

      await _loadAgents();

      final count = agents.length;
      if (count > 0) {
        SnackbarHelper.showSuccess(
          'Found $count agents for ZIP $trimmedZipCode',
          duration: const Duration(seconds: 2),
        );
      } else {
        SnackbarHelper.showInfo(
          'No agents found for ZIP $trimmedZipCode',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching by ZIP: $e');
      }
      SnackbarHelper.showError('Search failed: ${e.toString()}');
    }
  }

  /// Clears the ZIP code filter.
  void clearZipCodeFilter() {
    selectedZipCode.value = '';
    _within10MilesMap = null;
    zipSearchController.clear();
    _loadAgents();
    if (kDebugMode) print('🧹 Find Agents: Cleared ZIP filter');
  }

  @override
  void onClose() {
    searchController.dispose();
    zipSearchController.dispose();
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
      zipSearchController.text = zipCode;
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
    isLoading.value = true;
    currentPage.value = 1; // Reset to first page

    try {
      if (selectedZipCode.value.isNotEmpty) {
        // Fetch within10miles map if not already loaded (same API as home page)
        if (_within10MilesMap == null) {
          try {
            _within10MilesMap = await _zipCodesService.getZipCodesWithinMiles(
              zipcode: selectedZipCode.value.trim(),
              miles: 10,
            );
          } on ZipCodesServiceException catch (e) {
            if (kDebugMode) print('⚠️ within10miles: ${e.message}');
            _within10MilesMap = null;
          } catch (e) {
            if (kDebugMode) print('⚠️ within10miles: $e');
            _within10MilesMap = null;
          }
        }

        // FILTER MODE: Fetch ALL agents to ensure client-side filtering works correctly
        if (kDebugMode) {
          print('📡 ZIP filter active (${selectedZipCode.value}) - Fetching ALL agents...');
        }
        
        // This method iterates all pages until it has all agents
        final allAgents = await _agentService.getAllAgents();
        
        if (kDebugMode) {
          print('✅ Successfully fetched ${allAgents.length} total agents for filtering');
        }

        // Set pagination to show everything as one page since we have all data
        currentPage.value = 1;
        totalPages.value = 1;
        totalAgents.value = allAgents.length;
        
        _allLoadedAgents.clear();
        _allLoadedAgents.addAll(allAgents);
      } else {
        // NORMAL MODE: Paginated fetch (only first page initially)
        if (kDebugMode) {
          print('📡 Fetching agents from API (page ${currentPage.value})...');
        }

        // Use paginated endpoint to get first page of agents
        final response = await _agentService.getAllAgentsPaginated(page: currentPage.value);

        if (kDebugMode) {
          print('✅ Successfully fetched ${response.agents.length} agents from API');
          print('   Page: ${response.page}/${response.totalPages}');
          print('   Total agents: ${response.totalAgents}');
        }

        // Store pagination metadata (reactive)
        currentPage.value = response.page;
        totalPages.value = response.totalPages;
        totalAgents.value = response.totalAgents;
        
        _allLoadedAgents.clear();
        _allLoadedAgents.addAll(response.agents);
      }
      
      // Apply ZIP code filtering and sorting
      _applyZipCodeFilterAndSort();
      
      // Update UI
      if (searchQuery.value.isEmpty) {
        _updateDisplayedAgents();
      } else {
        searchAgents(searchQuery.value);
      }
      
      _recordSearchesForDisplayedAgents();
    } on AgentServiceException catch (e) {
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
      
      // Show fallback mock data (all agents, no filtering)
      final mockAgents = _getMockAgents();
      _allLoadedAgents.clear();
      _allLoadedAgents.addAll(mockAgents);
      
      // Apply ZIP code filtering and sorting if ZIP code is provided
      _applyZipCodeFilterAndSort();
      
      // Apply search if there's a query
      if (searchQuery.value.isEmpty) {
        _updateDisplayedAgents();
      } else {
        searchAgents(searchQuery.value);
      }
      
      SnackbarHelper.showWarning(
        '$errorMessage Showing sample data.',
        title: 'Warning',
        duration: const Duration(seconds: 4),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error fetching agents: $e');
        print('   Stack trace: $stackTrace');
      }
      // Fallback to mock data on error (all agents, no filtering)
      final mockAgents = _getMockAgents();
      _allLoadedAgents.clear();
      _allLoadedAgents.addAll(mockAgents);
      
      // Apply ZIP code filtering and sorting if ZIP code is provided
      _applyZipCodeFilterAndSort();
      
      // Apply search if there's a query
      if (searchQuery.value.isEmpty) {
        _updateDisplayedAgents();
      } else {
        searchAgents(searchQuery.value);
      }
      
      SnackbarHelper.showWarning(
        'Could not load agents from server. Showing sample data.',
        title: 'Warning',
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
  
  /// Load more agents from next page
  Future<void> loadMoreAgents() async {
    if (!canLoadMore || _isLoadingMore.value) {
      return;
    }

    _isLoadingMore.value = true;
    final nextPage = currentPage.value + 1;

    try {
      if (kDebugMode) {
        print('📡 Loading more agents (page $nextPage)...');
      }

      // Fetch next page
      final response = await _agentService.getAllAgentsPaginated(page: nextPage);

      if (kDebugMode) {
        print('✅ Successfully fetched ${response.agents.length} more agents');
        print('   Page: ${response.page}/${response.totalPages}');
      }

      // Update pagination metadata (reactive) - DIRECTLY UPDATE PUBLIC OBSERVABLES
      currentPage.value = response.page;
      totalPages.value = response.totalPages;
      totalAgents.value = response.totalAgents;

      // Add new agents to the list
      _allLoadedAgents.addAll(response.agents);
      
      // Apply ZIP code filtering and sorting if ZIP code is provided
      _applyZipCodeFilterAndSort();
      
      // Update displayed agents
      if (searchQuery.value.isEmpty) {
        _updateDisplayedAgents();
      } else {
        // If there's a search query, apply it
        searchAgents(searchQuery.value);
      }
      
      // Record search for newly loaded agents
      _recordSearchesForDisplayedAgents();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading more agents: $e');
      }
      ErrorHandler.handleError(e, defaultMessage: 'Unable to load more agents. Please check your connection and try again.');
    } finally {
      _isLoadingMore.value = false;
    }
  }
  
  /// Applies ZIP code filtering and proximity-based sorting.
  /// Uses within10miles API (same as home page) when available.
  void _applyZipCodeFilterAndSort() {
    if (selectedZipCode.value.isEmpty) {
      _within10MilesMap = null;
      _filteredAndSortedAgents.clear();
      _filteredAndSortedAgents.addAll(_allLoadedAgents);
      _totalFilteredCount.value = _filteredAndSortedAgents.length;
      return;
    }

    final zipCode = selectedZipCode.value.trim();
    final map = _within10MilesMap;
    final useWithin10 = map != null && map.isNotEmpty;

    List<AgentModel> matchingAgents;

    if (useWithin10) {
      // Same logic as home page: include agents whose ZIPs are in the within10miles map
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
        for (final z in a.activeListingZipCodes) {
          final t = z.trim();
          if (zipSet.contains(t)) {
            final d = mapNorm[t] ?? double.infinity;
            if (d < best) best = d;
          }
        }
        return best;
      }

      matchingAgents = _allLoadedAgents
          .where((a) => minDistAgent(a) < double.infinity)
          .toList();
      matchingAgents.sort((a, b) => minDistAgent(a).compareTo(minDistAgent(b)));
    } else {
      // Fallback: exact ZIP match only
      matchingAgents = _allLoadedAgents.where((agent) {
        final hasClaimedZip = agent.claimedZipCodes.any(
            (claimedZip) => claimedZip.trim() == zipCode);
        final hasServiceZip = agent.serviceZipCodes.any(
            (serviceZip) => serviceZip.trim() == zipCode);
        final hasServiceArea = agent.serviceAreas
                ?.any((area) => area.trim() == zipCode) ??
            false;
        final hasListingZip = agent.activeListingZipCodes.any(
            (listingZip) => listingZip.trim() == zipCode);
        return hasClaimedZip || hasServiceZip || hasServiceArea || hasListingZip;
      }).toList();

      matchingAgents.sort((a, b) {
        final aIsLocal = a.claimedZipCodes.any((z) => z.trim() == zipCode) ||
            a.activeListingZipCodes.any((z) => z.trim() == zipCode);
        final bIsLocal = b.claimedZipCodes.any((z) => z.trim() == zipCode) ||
            b.activeListingZipCodes.any((z) => z.trim() == zipCode);
        if (aIsLocal && !bIsLocal) return -1;
        if (!aIsLocal && bIsLocal) return 1;
        final aProximity = _calculateZipCodeProximity(zipCode, a);
        final bProximity = _calculateZipCodeProximity(zipCode, b);
        return aProximity.compareTo(bProximity);
      });
    }

    if (kDebugMode && matchingAgents.isEmpty) {
      print('⚠️ No agents matched ZIP $zipCode (within10mi: $useWithin10)');
    }

    _filteredAndSortedAgents.clear();
    _filteredAndSortedAgents.addAll(matchingAgents);
    _totalFilteredCount.value = _filteredAndSortedAgents.length;

    if (kDebugMode) {
      print('📍 Filtered by ZIP: $zipCode (within10mi: $useWithin10)');
      print('   Total matching agents: ${_filteredAndSortedAgents.length}');
    }
  }
  
  /// Calculates proximity score between a ZIP code and an agent
  /// Lower score = closer proximity
  /// Uses numeric difference between ZIP codes as a proxy for distance
  int _calculateZipCodeProximity(String targetZip, AgentModel agent) {
    try {
      final targetZipNum = int.tryParse(targetZip) ?? 0;
      if (targetZipNum == 0) return 999999; // Invalid ZIP
      
      int minDistance = 999999;
      
      // Check claimed ZIP codes first (these are most important)
      for (final zip in agent.claimedZipCodes) {
        final zipNum = int.tryParse(zip) ?? 0;
        if (zipNum > 0) {
          final distance = (targetZipNum - zipNum).abs();
          if (distance < minDistance) {
            minDistance = distance;
          }
        }
      }
      
      // Check service ZIP codes
      for (final zip in agent.serviceZipCodes) {
        final zipNum = int.tryParse(zip) ?? 0;
        if (zipNum > 0) {
          final distance = (targetZipNum - zipNum).abs();
          if (distance < minDistance) {
            minDistance = distance;
          }
        }
      }
      
      // Check active listing ZIP codes
      for (final zip in agent.activeListingZipCodes) {
        final zipNum = int.tryParse(zip) ?? 0;
        if (zipNum > 0) {
          final distance = (targetZipNum - zipNum).abs();
          if (distance < minDistance) {
            minDistance = distance;
          }
        }
      }
      
      return minDistance;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error calculating ZIP proximity: $e');
      }
      return 999999; // Default to far away
    }
  }
  
  /// Updates the displayed agents list based on current filters
  void _updateDisplayedAgents() {
    // Show all filtered and sorted agents (server-side pagination handles the rest)
    agents.value = List.from(_filteredAndSortedAgents);
    
    // Ensure total count is updated
    _totalFilteredCount.value = _filteredAndSortedAgents.length;
    
    if (kDebugMode) {
      print('📋 Updated displayed agents: ${agents.length}');
      print('   canLoadMore: $canLoadMore');
      print('   Current page: ${currentPage.value}/${totalPages.value}');
      print('   Total agents: ${totalAgents.value}');
    }
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
    final searchLower = searchTerm.toLowerCase();
    
    // Start with ZIP-filtered agents (or all if no ZIP)
    final baseAgents = selectedZipCode.value.isNotEmpty 
        ? List<AgentModel>.from(_filteredAndSortedAgents)
        : List<AgentModel>.from(_allLoadedAgents);
    
    if (searchLower.isEmpty) {
      // No search query - use ZIP-filtered and sorted agents
      _updateDisplayedAgents();
      if (kDebugMode) {
        print('🔍 Search cleared. Showing ${agents.length} agents');
      }
      // Record search for all displayed agents
      _recordSearchesForDisplayedAgents();
    } else {
      // Filter by search query - search in multiple fields
      final filteredAgents = baseAgents.where((agent) {
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
        
        // Search in ZIP codes (claimedZipCodes, serviceZipCodes)
        final zipMatch = agent.claimedZipCodes.any(
          (zip) => zip.contains(searchTerm)
        ) || agent.serviceZipCodes.any(
          (zip) => zip.contains(searchTerm)
        );
        
        // Return true if any field matches
        return nameMatch || 
               brokerageMatch || 
               emailMatch || 
               bioMatch || 
               licenseMatch || 
               statesMatch ||
               zipMatch;
      }).toList();
      
      // Update filtered and sorted list for search results
      _filteredAndSortedAgents.clear();
      _filteredAndSortedAgents.addAll(filteredAgents);
      _totalFilteredCount.value = _filteredAndSortedAgents.length;
      
      // Reset displayed count when search changes
      
      // Update displayed agents
      _updateDisplayedAgents();
      
      if (kDebugMode) {
        print('🔍 Search: "$query"');
        print('   Found ${filteredAgents.length} matching agents');
        if (filteredAgents.isNotEmpty) {
          print('   Matching agents: ${filteredAgents.take(5).map((a) => a.name).join(", ")}${filteredAgents.length > 5 ? "..." : ""}');
        }
      }
      
      // Record search for all displayed agents
      _recordSearchesForDisplayedAgents();
    }
  }
  
  /// Records search tracking for all currently displayed agents
  Future<void> _recordSearchesForDisplayedAgents() async {
    // Record search for each displayed agent (fire and forget)
    // Pass agent name to the API as it expects name, not ID
    for (final agent in agents) {
      _recordSearch(agent.id, agentName: agent.name);
    }
  }
  
  /// Records a search for an agent
  Future<void> _recordSearch(String agentId, {String? agentName}) async {
    try {
      final response = await _agentService.recordSearch(agentId, agentName: agentName);
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

