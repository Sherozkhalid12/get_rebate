import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/services/rebate_calculator_service.dart';

class NearbyAgentsService {
  // Mock data for demonstration - in a real app, this would come from an API
  static final List<AgentModel> _mockAgents = [
    AgentModel(
      id: 'agent_1',
      name: 'Sarah Johnson',
      email: 'sarah@premierrealty.com',
      phone: '+1 (555) 123-4567',
      brokerage: 'Premier Realty Group',
      licenseNumber: 'RE12345',
      bio:
          'Experienced real estate agent specializing in Manhattan properties.',
      rating: 4.8,
      reviewCount: 127,
      searchesAppearedIn: 45,
      createdAt: DateTime.now().subtract(const Duration(days: 365 * 3)),
      isActive: true,
      rebateOffered: true,
      rebatePercentage: 2.8, // 2.8% of BAC
      serviceZipCodes: ['10001', '10002', '10003'],
    ),
    AgentModel(
      id: 'agent_2',
      name: 'Michael Chen',
      email: 'michael@metroprop.com',
      phone: '+1 (555) 234-5678',
      brokerage: 'Metro Properties',
      licenseNumber: 'RE67890',
      bio: 'Commercial and residential expert with 12 years of experience.',
      rating: 4.9,
      reviewCount: 203,
      searchesAppearedIn: 78,
      createdAt: DateTime.now().subtract(const Duration(days: 365 * 5)),
      isActive: true,
      rebateOffered: true,
      rebatePercentage: 3.0, // 3.0% of BAC (maximum)
      serviceZipCodes: ['10001', '10002', '10004'],
    ),
    AgentModel(
      id: 'agent_3',
      name: 'Emily Rodriguez',
      email: 'emily@cityhomes.com',
      phone: '+1 (555) 345-6789',
      brokerage: 'City Homes Realty',
      licenseNumber: 'RE11111',
      bio: 'Luxury property specialist with expertise in new construction.',
      rating: 4.7,
      reviewCount: 89,
      searchesAppearedIn: 32,
      createdAt: DateTime.now().subtract(const Duration(days: 365 * 2)),
      isActive: true,
      rebateOffered: true,
      rebatePercentage: 2.6, // 2.6% of BAC
      serviceZipCodes: ['10001', '10003', '10005'],
    ),
    AgentModel(
      id: 'agent_4',
      name: 'David Thompson',
      email: 'david@manhattanre.com',
      phone: '+1 (555) 456-7890',
      brokerage: 'Manhattan Real Estate',
      licenseNumber: 'RE22222',
      bio: 'Veteran agent with deep knowledge of Manhattan real estate market.',
      rating: 4.9,
      reviewCount: 156,
      searchesAppearedIn: 67,
      createdAt: DateTime.now().subtract(const Duration(days: 365 * 6)),
      isActive: true,
      rebateOffered: false, // This agent doesn't offer rebates
      rebatePercentage: 0.0,
      serviceZipCodes: ['10001', '10002', '10003', '10004'],
    ),
  ];

  /// Finds nearby agents that offer rebates for a specific listing
  static Future<List<AgentWithRebate>> findNearbyAgentsWithRebates({
    required Listing listing,
    int maxResults = 10,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final listingZipCode = listing.address.zip;
    final listPrice = listing.priceCents / 100.0;
    final bacPercentage = listing.bacPercent / 100.0;

    // Filter agents who:
    // 1. Serve the listing's ZIP code
    // 2. Offer rebates
    // 3. Are active
    final eligibleAgents = _mockAgents.where((agent) {
      return agent.isActive &&
          agent.rebateOffered &&
          agent.serviceZipCodes.contains(listingZipCode);
    }).toList();

    // Calculate potential rebates for each agent
    final agentsWithRebates = eligibleAgents.map((agent) {
      final potentialRebate = RebateCalculatorService.calculateSpecificRebate(
        listPrice: listPrice,
        bacPercentage: bacPercentage,
      );

      return AgentWithRebate(
        agent: agent,
        potentialRebate: potentialRebate,
        rebatePercentage: agent.rebatePercentage,
        distance: _calculateMockDistance(listingZipCode, agent.serviceZipCodes),
      );
    }).toList();

    // Sort by potential rebate amount (highest first)
    agentsWithRebates.sort(
      (a, b) => b.potentialRebate.compareTo(a.potentialRebate),
    );

    return agentsWithRebates.take(maxResults).toList();
  }

  /// Calculates mock distance for demonstration
  static double _calculateMockDistance(
    String listingZip,
    List<String> agentServiceAreas,
  ) {
    // Mock distance calculation - in a real app, this would use geolocation
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return (random / 10.0).clamp(
      0.5,
      10.0,
    ); // Random distance between 0.5 and 10 miles
  }

  /// Gets agent details by ID
  static AgentModel? getAgentById(String agentId) {
    try {
      return _mockAgents.firstWhere((agent) => agent.id == agentId);
    } catch (e) {
      return null;
    }
  }
}

class AgentWithRebate {
  final AgentModel agent;
  final double potentialRebate;
  final double rebatePercentage;
  final double distance;

  AgentWithRebate({
    required this.agent,
    required this.potentialRebate,
    required this.rebatePercentage,
    required this.distance,
  });

  String get formattedPotentialRebate =>
      RebateCalculatorService.formatCurrency(potentialRebate);
  String get formattedDistance => '${distance.toStringAsFixed(1)} miles away';
}
