import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';

class FavoritesController extends GetxController {
  // Data
  final _favoriteAgents = <AgentModel>[].obs;
  final _favoriteLoanOfficers = <LoanOfficerModel>[].obs;
  final _selectedTab = 0.obs; // 0: Agents, 1: Loan Officers

  // Getters
  List<AgentModel> get favoriteAgents => _favoriteAgents;
  List<LoanOfficerModel> get favoriteLoanOfficers => _favoriteLoanOfficers;
  int get selectedTab => _selectedTab.value;

  @override
  void onInit() {
    super.onInit();
    _loadMockData();
  }

  void setSelectedTab(int index) {
    _selectedTab.value = index;
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
    _favoriteAgents.removeWhere((agent) => agent.id == agentId);
    Get.snackbar('Removed', 'Agent removed from favorites');
  }

  void removeFavoriteLoanOfficer(String loanOfficerId) {
    _favoriteLoanOfficers.removeWhere(
      (loanOfficer) => loanOfficer.id == loanOfficerId,
    );
    Get.snackbar('Removed', 'Loan officer removed from favorites');
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
            onPressed: () {
              Get.back();
              _favoriteAgents.clear();
              _favoriteLoanOfficers.clear();
              Get.snackbar('Cleared', 'All favorites removed');
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
