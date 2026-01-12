import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/models/mortgage_types.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/services/loan_officer_service.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/controllers/current_loan_officer_controller.dart';
import 'package:getrebate/app/modules/proposals/controllers/proposal_controller.dart';

class LoanOfficerProfileController extends GetxController {
  // Data
  final _loanOfficer = Rxn<LoanOfficerModel>();
  final _isFavorite = false.obs;
  final _isLoading = false.obs;
  final _isTogglingFavorite = false.obs;
  final _selectedTab = 0.obs; // 0: Overview, 1: Reviews, 2: Loan Programs
  
  // Dio for API calls
  final Dio _dio = Dio();
  final LoanOfficerService _loanOfficerService = LoanOfficerService();

  // Getters
  LoanOfficerModel? get loanOfficer => _loanOfficer.value;
  bool get isFavorite => _isFavorite.value;
  bool get isLoading => _isLoading.value;
  int get selectedTab => _selectedTab.value;

  @override
  void onInit() {
    super.onInit();
    _setupDio();
    _loadLoanOfficerData();
    // Record profile view after data is loaded
    Future.microtask(() => _recordProfileView());
  }
  
  void _setupDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      ...ApiConstants.ngrokHeaders,
      'Content-Type': 'application/json',
    };
  }

  void _loadLoanOfficerData() {
    final args = Get.arguments;

    // 1) If a specific loan officer was passed in (e.g. from a search result),
    // use that as the source of truth.
    if (args != null && args['loanOfficer'] != null) {
      _loanOfficer.value = args['loanOfficer'] as LoanOfficerModel;
      debugPrint(
          '✅ LoanOfficerProfileController: Loaded loan officer from Get.arguments (id=${_loanOfficer.value?.id}).');
      return;
    }

    // 2) Otherwise, fall back to the currently authenticated loan officer
    // from the global CurrentLoanOfficerController.
    try {
      final currentLoanOfficerController =
          Get.isRegistered<CurrentLoanOfficerController>()
              ? Get.find<CurrentLoanOfficerController>()
              : null;

      if (currentLoanOfficerController != null &&
          currentLoanOfficerController.currentLoanOfficer.value != null) {
        _loanOfficer.value =
            currentLoanOfficerController.currentLoanOfficer.value;
        debugPrint(
            '✅ LoanOfficerProfileController: Loaded current authenticated loan officer from CurrentLoanOfficerController (id=${_loanOfficer.value?.id}).');
        return;
      } else {
        debugPrint(
            '⚠️ LoanOfficerProfileController: CurrentLoanOfficerController not available or currentLoanOfficer is null. Falling back to mock data.');
      }
    } catch (e) {
      debugPrint(
          '⚠️ LoanOfficerProfileController: Error accessing CurrentLoanOfficerController: $e');
    }

    // 3) Final fallback to mock data so the UI still works in isolation,
    // but this should not happen in production if API + auth are wired correctly.
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

    debugPrint(
        'ℹ️ LoanOfficerProfileController: Using mock loan officer data as a last resort.');
  }

  void setSelectedTab(int index) {
    _selectedTab.value = index;
  }

  Future<void> toggleFavorite() async {
    if (_loanOfficer.value == null) return;
    if (_isTogglingFavorite.value) return; // Prevent multiple simultaneous calls
    
    try {
      _isTogglingFavorite.value = true;
      
      // Get current user ID
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser;
      
      if (currentUser == null || currentUser.id.isEmpty) {
        SnackbarHelper.showError(
          'Please login to like loan officers',
          duration: const Duration(seconds: 2),
        );
        return;
      }
      
      final loanOfficerId = _loanOfficer.value!.id;
      // Use the same endpoint pattern - assuming loan officers can be liked via the agent endpoint
      // If there's a separate endpoint, update ApiConstants.getLikeLoanOfficerEndpoint
      final endpoint = ApiConstants.getLikeLoanOfficerEndpoint(loanOfficerId);
      
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
        print('❤️ Toggling favorite for loan officer: $loanOfficerId');
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
          SnackbarHelper.showSuccess(
            message.isNotEmpty 
                ? message 
                : (isLiked 
                    ? 'Loan officer added to your favorites' 
                    : 'Loan officer removed from your favorites'),
            title: action == 'liked' ? 'Added to Favorites' : 'Removed from Favorites',
            duration: const Duration(seconds: 2),
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

  /// Records a profile view for the loan officer
  Future<void> _recordProfileView() async {
    if (_loanOfficer.value == null) return;
    
    try {
      final response = await _loanOfficerService.recordProfileView(_loanOfficer.value!.id);
      if (response != null && kDebugMode) {
        print('👁️ Profile View Response for loan officer ${_loanOfficer.value!.id}:');
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

  /// Records a contact action for the loan officer
  Future<void> _recordContact(String loanOfficerId) async {
    try {
      final response = await _loanOfficerService.recordContact(loanOfficerId);
      if (response != null && kDebugMode) {
        print('📞 Contact Response for loan officer $loanOfficerId:');
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

  void contactLoanOfficer() {
    if (_loanOfficer.value == null) return;
    
    // Record contact
    _recordContact(_loanOfficer.value!.id);

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
                Navigator.pop(Get.context!);
                SnackbarHelper.showInfo('Opening phone dialer...', title: 'Calling');
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: AppTheme.lightGreen),
              title: const Text('Email'),
              subtitle: Text(_loanOfficer.value!.email),
              onTap: () {
                Navigator.pop(Get.context!);
                SnackbarHelper.showInfo('Opening email client...', title: 'Emailing');
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: AppTheme.lightGreen),
              title: const Text('Message'),
              subtitle: const Text('Send a message'),
              onTap: () {
                Navigator.pop(Get.context!);
                Get.toNamed('/messages');
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(Get.context!), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> startChat() async {
    if (_loanOfficer.value == null) {
      SnackbarHelper.showError('Loan officer information not available');
      return;
    }

    // Record contact
    _recordContact(_loanOfficer.value!.id);

    // Check if conversation exists with this loan officer
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
        (conv) => conv.senderId == _loanOfficer.value!.id,
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
        'userId': _loanOfficer.value!.id,
        'userName': _loanOfficer.value!.name,
        'userProfilePic': _loanOfficer.value!.profileImage,
        'userRole': 'loan_officer',
        'loanOfficer': _loanOfficer.value,
      });
    }
  }

  void viewLoanPrograms() {
    SnackbarHelper.showInfo('Loan program details coming soon!', title: 'Loan Programs');
  }

  void shareProfile() {
    SnackbarHelper.showInfo('Profile sharing feature coming soon!', title: 'Share');
  }

  /// Returns dynamic reviews from loan officer data
  List<Map<String, dynamic>> getReviews() {
    if (_loanOfficer.value == null || _loanOfficer.value!.reviews == null) {
      return [];
    }

    return _loanOfficer.value!.reviews!.map((review) {
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
  
  /// OLD MOCK DATA - REPLACED
  List<Map<String, dynamic>> _getMockReviews() {
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

  /// Create a proposal for this loan officer
  Future<void> createProposal(BuildContext context) async {
    if (_loanOfficer.value == null) {
      SnackbarHelper.showError('Loan officer information not available');
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
                        color: AppTheme.lightGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppTheme.lightGreen,
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
                            'Send a proposal to ${_loanOfficer.value!.name}',
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
                      borderSide: const BorderSide(color: AppTheme.lightGreen, width: 2),
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
                      borderSide: const BorderSide(color: AppTheme.lightGreen, width: 2),
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
                      borderSide: const BorderSide(color: AppTheme.lightGreen, width: 2),
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
                                      professionalId: _loanOfficer.value!.id,
                                      professionalName: _loanOfficer.value!.name,
                                      professionalType: 'loan_officer',
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
                              backgroundColor: AppTheme.lightGreen,
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
}
