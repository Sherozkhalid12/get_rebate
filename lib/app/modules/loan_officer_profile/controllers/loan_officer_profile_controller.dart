import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/models/mortgage_types.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class LoanOfficerProfileController extends GetxController {
  // Data
  final _loanOfficer = Rxn<LoanOfficerModel>();
  final _isFavorite = false.obs;
  final _isLoading = false.obs;
  final _selectedTab = 0.obs; // 0: Overview, 1: Reviews, 2: Loan Programs

  // Getters
  LoanOfficerModel? get loanOfficer => _loanOfficer.value;
  bool get isFavorite => _isFavorite.value;
  bool get isLoading => _isLoading.value;
  int get selectedTab => _selectedTab.value;

  @override
  void onInit() {
    super.onInit();
    _loadLoanOfficerData();
  }

  void _loadLoanOfficerData() {
    final args = Get.arguments;
    if (args != null && args['loanOfficer'] != null) {
      _loanOfficer.value = args['loanOfficer'] as LoanOfficerModel;
    } else {
      // Fallback to mock data
      _loanOfficer.value = LoanOfficerModel(
        id: 'loan_1',
        name: 'Jennifer Davis',
        email: 'jennifer@example.com',
        phone: '+1 (555) 345-6789',
        profileImage: 'https://i.pravatar.cc/150?img=2',
        companyLogoUrl:
            'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=400',
        company: 'First National Bank',
        licenseNumber: 'LO123456',
        licensedStates: ['NY', 'NJ', 'CT'],
        claimedZipCodes: ['10001', '10002'],
        specialtyProducts: [
          MortgageTypes.fhaLoans,
          MortgageTypes.vaLoans,
          MortgageTypes.conventionalConforming,
          MortgageTypes.fthbPrograms,
        ],
        bio:
            'Senior loan officer with over 15 years of experience in mortgage lending. I specialize in conventional, FHA, and VA loans, helping clients secure the best rates and terms for their home financing needs.',
        rating: 4.9,
        reviewCount: 156,
        searchesAppearedIn: 67,
        profileViews: 289,
        contacts: 134,
        allowsRebates: true,
        mortgageApplicationUrl: 'https://www.example.com/apply/jennifer-davis',
        createdAt: DateTime.now().subtract(const Duration(days: 400)),
        isVerified: true,
      );
    }
  }

  void setSelectedTab(int index) {
    _selectedTab.value = index;
  }

  void toggleFavorite() {
    _isFavorite.value = !_isFavorite.value;
    Get.snackbar(
      _isFavorite.value ? 'Added to Favorites' : 'Removed from Favorites',
      _isFavorite.value
          ? 'Loan officer added to your favorites'
          : 'Loan officer removed from your favorites',
    );
  }

  void contactLoanOfficer() {
    if (_loanOfficer.value == null) return;

    Get.dialog(
      AlertDialog(
        title: Text('Contact ${_loanOfficer.value!.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.lightGreen),
              title: const Text('Call'),
              subtitle: Text(_loanOfficer.value!.phone ?? 'No phone number'),
              onTap: () {
                Get.back();
                Get.snackbar('Calling', 'Opening phone dialer...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: AppTheme.lightGreen),
              title: const Text('Email'),
              subtitle: Text(_loanOfficer.value!.email),
              onTap: () {
                Get.back();
                Get.snackbar('Emailing', 'Opening email client...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: AppTheme.lightGreen),
              title: const Text('Message'),
              subtitle: const Text('Send a message'),
              onTap: () {
                Get.back();
                Get.toNamed('/messages');
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> startChat() async {
    if (_loanOfficer.value == null) {
      Get.snackbar('Error', 'Loan officer information not available');
      return;
    }

    // Navigate to contact screen first
    Get.toNamed('/contact', arguments: {
      'userId': _loanOfficer.value!.id,
      'userName': _loanOfficer.value!.name,
      'userProfilePic': _loanOfficer.value!.profileImage,
      'userRole': 'loan_officer',
    });
  }

  void viewLoanPrograms() {
    Get.snackbar('Loan Programs', 'Loan program details coming soon!');
  }

  void shareProfile() {
    Get.snackbar('Share', 'Profile sharing feature coming soon!');
  }

  List<Map<String, dynamic>> getReviews() {
    return [
      {
        'name': 'David Miller',
        'rating': 5.0,
        'date': '1 week ago',
        'comment':
            'Jennifer made our home buying process incredibly smooth. Her expertise and attention to detail helped us secure an amazing rate.',
      },
      {
        'name': 'Sarah Thompson',
        'rating': 5.0,
        'date': '2 weeks ago',
        'comment':
            'Outstanding service! Jennifer was always available to answer questions and guided us through every step of the loan process.',
      },
      {
        'name': 'Robert Garcia',
        'rating': 4.0,
        'date': '1 month ago',
        'comment':
            'Professional and knowledgeable. Jennifer helped us understand all our options and found the best loan for our situation.',
      },
      {
        'name': 'Lisa Anderson',
        'rating': 5.0,
        'date': '2 months ago',
        'comment':
            'Jennifer\'s expertise in VA loans was exactly what we needed. She made the entire process stress-free and efficient.',
      },
    ];
  }

  List<Map<String, dynamic>> getLoanPrograms() {
    final loanOfficer = _loanOfficer.value;
    if (loanOfficer == null || loanOfficer.specialtyProducts.isEmpty) {
      // Return empty list if no specialty products are specified
      return [];
    }

    // Import the mortgage types helper
    final descriptions = MortgageTypes.getDescriptions();

    // Build list of loan programs from the loan officer's specialty products
    return loanOfficer.specialtyProducts.map((type) {
      return {
        'name': type,
        'description': descriptions[type] ?? 'Specialized loan product',
      };
    }).toList();
  }
}
