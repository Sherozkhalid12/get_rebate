import 'package:get/get.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/models/listing.dart';

class FindAgentsController extends GetxController {
  final RxList<AgentModel> agents = <AgentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedZipCode = ''.obs;
  final Rx<Listing?> listing = Rx<Listing?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadArguments();
    _loadAgents();
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      selectedZipCode.value = args['zip'] ?? '';
      listing.value = args['listing'] as Listing?;
    }
  }

  void _loadAgents() {
    isLoading.value = true;

    // Simulate API call - in real app, this would fetch from backend
    Future.delayed(const Duration(seconds: 1), () {
      agents.value = _getMockAgents();
      isLoading.value = false;
    });
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
    if (query.isEmpty) {
      _loadAgents();
    } else {
      agents.value = _getMockAgents()
          .where(
            (agent) =>
                agent.name.toLowerCase().contains(query.toLowerCase()) ||
                agent.brokerage.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  void contactAgent(AgentModel agent) {
    // Navigate to messages with agent and listing context
    Get.toNamed(
      '/messages',
      arguments: {
        'agent': agent,
        'listing': listing.value,
        'propertyAddress': listing.value?.address.toString(),
      },
    );
  }

  void viewAgentProfile(AgentModel agent) {
    Get.toNamed('/agent-profile', arguments: {'agent': agent});
  }
}

