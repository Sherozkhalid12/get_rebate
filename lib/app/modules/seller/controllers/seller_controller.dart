import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/agent_model.dart';

class SellerController extends GetxController {
  // Search
  final searchController = TextEditingController();
  final _searchQuery = ''.obs;

  // Data
  final _agents = <AgentModel>[].obs;
  final _favoriteAgents = <String>[].obs;
  final _isLoading = false.obs;

  // Getters
  String get searchQuery => _searchQuery.value;
  List<AgentModel> get agents => _agents;
  List<String> get favoriteAgents => _favoriteAgents;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _loadMockData();
    searchController.addListener(_onSearchChanged);
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

  void toggleFavoriteAgent(String agentId) {
    if (_favoriteAgents.contains(agentId)) {
      _favoriteAgents.remove(agentId);
    } else {
      _favoriteAgents.add(agentId);
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
