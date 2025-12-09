import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/models/mortgage_types.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/models/open_house_model.dart';
import 'package:getrebate/app/services/listing_service.dart';
import 'package:getrebate/app/controllers/location_controller.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class BuyerController extends GetxController {
  final LocationController _locationController = Get.find<LocationController>();

  // Search
  final searchController = TextEditingController();
  final _searchQuery = ''.obs;
  final _selectedTab =
      0.obs; // 0: Agents, 1: Homes for Sale, 2: Open Houses, 3: Loan Officers

  // Data
  final _agents = <AgentModel>[].obs;
  final _loanOfficers = <LoanOfficerModel>[].obs;
  final _listings = <Listing>[].obs;
  final _openHouses = <OpenHouseModel>[].obs;
  final _favoriteAgents = <String>[].obs;
  final _favoriteLoanOfficers = <String>[].obs;
  final _isLoading = false.obs;
  final _selectedBuyerAgent = Rxn<AgentModel>(); // Track the buyer's selected agent

  // Services
  final ListingService _listingService = InMemoryListingService();

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
    _loadMockData();
    searchController.addListener(_onSearchChanged);
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
    // Mock agents data
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
        'Experienced real estate agent specializing in luxury properties with over 10 years of experience in Manhattan and Brooklyn markets.',
        rating: 4.8,
        reviewCount: 127,
        searchesAppearedIn: 45,
        profileViews: 234,
        contacts: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        isVerified: true,
        platformRating: 4.9,
        platformReviewCount: 23,
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        expertise: [
          'Luxury Properties',
          'First-Time Buyers',
          'Investment Properties',
          'Relocation Specialist',
          'New Construction'
        ],
        websiteUrl: 'https://sarahjohnsonrealty.com',
        googleReviewsUrl: 'https://g.page/r/CdXQQQQQQQQQEBM/review',
        thirdPartyReviewsUrl: 'https://www.zillow.com/profile/sarahjohnson',
        externalReviewsUrl: 'https://www.realtor.com/agent/sarah-johnson',
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
            'First-time home buyer specialist with 10+ years experience helping young professionals find their perfect home.',
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
            'Brooklyn market expert specializing in brownstones and modern condos. Bilingual in English and Spanish.',
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
            'Queens market specialist with expertise in family homes and investment properties.',
        rating: 4.7,
        reviewCount: 156,
        searchesAppearedIn: 56,
        profileViews: 289,
        contacts: 98,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        isVerified: true,
      ),
    ];

    // Mock loan officers data
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

    // Mock listings data
    await _seedMockListings();

    // Load open houses after listings are seeded
    _loadMockOpenHouses();
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

    _openHouses.value = mockOpenHouses;
  }

  Future<void> _seedMockListings() async {
    final List<Listing> existing = await _listingService.listListings();
    if (existing.isNotEmpty) {
      _listings.value = existing;
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
    _listings.value = await _listingService.listListings();
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
      Get.snackbar('Error', 'Search failed: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> searchByZipCode(String zipCode) async {
    try {
      _isLoading.value = true;

      // Simulate API call to find agents/loan officers in specific ZIP
      await Future.delayed(const Duration(milliseconds: 800));

      // Filter agents and loan officers by ZIP code
      final zipAgents = _agents
          .where((agent) => agent.claimedZipCodes.contains(zipCode))
          .toList();

      final zipLoanOfficers = _loanOfficers
          .where((loanOfficer) => loanOfficer.claimedZipCodes.contains(zipCode))
          .toList();

      // Update the lists with ZIP-specific results
      if (zipAgents.isNotEmpty || zipLoanOfficers.isNotEmpty) {
        _agents.value = zipAgents;
        _loanOfficers.value = zipLoanOfficers;
      }

      // Filter listings by ZIP as well
      _listings.value = await _listingService.listListings(zip: zipCode);

      // Filter open houses by listings in that ZIP
      final listingIds = _listings.map((l) => l.id).toSet();
      _openHouses.value = _openHouses
          .where((oh) => listingIds.contains(oh.listingId))
          .toList();
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

  void toggleFavoriteLoanOfficer(String loanOfficerId) {
    if (_favoriteLoanOfficers.contains(loanOfficerId)) {
      _favoriteLoanOfficers.remove(loanOfficerId);
    } else {
      _favoriteLoanOfficers.add(loanOfficerId);
    }
  }

  bool isAgentFavorite(String agentId) {
    return _favoriteAgents.contains(agentId);
  }

  bool isLoanOfficerFavorite(String loanOfficerId) {
    return _favoriteLoanOfficers.contains(loanOfficerId);
  }

  void contactAgent(AgentModel agent) {
    // Navigate to contact agent screen for now
    Get.toNamed(AppPages.CONTACT_AGENT, arguments: {'agent': agent});
  }

  void contactLoanOfficer(LoanOfficerModel loanOfficer) {
    // Navigate to contact loan officer screen for now
    Get.toNamed(
      AppPages.CONTACT_LOAN_OFFICER,
      arguments: {'loanOfficer': loanOfficer},
    );
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
