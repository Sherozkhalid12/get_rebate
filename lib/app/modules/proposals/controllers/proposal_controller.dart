import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/models/proposal_model.dart';
import 'package:getrebate/app/models/lead_model.dart';
import 'package:getrebate/app/services/proposal_service.dart';
import 'package:getrebate/app/services/report_service.dart';
import 'package:getrebate/app/services/review_service.dart';
import 'package:getrebate/app/services/leads_service.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/utils/error_handler.dart';
import 'package:getrebate/app/utils/api_constants.dart';

class ProposalController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final ProposalService _proposalService = ProposalService();
  final ReportService _reportService = ReportService();
  final ReviewService _reviewService = ReviewService();
  final LeadsService _leadsService = LeadsService();

  // Observable proposals and leads
  final _proposals = <ProposalModel>[].obs;
  final _leads = <LeadModel>[].obs;
  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _highlightedProposalId = Rxn<String>();
  final _highlightedLeadId = Rxn<String>();
  
  // Filter state
  final _selectedFilter = 'all'.obs; // all, pending, accepted, completed, reported

  List<ProposalModel> get proposals => _proposals;
  List<LeadModel> get leads => _leads;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  String? get highlightedProposalId => _highlightedProposalId.value;
  String? get highlightedLeadId => _highlightedLeadId.value;
  String get selectedFilter => _selectedFilter.value;
  
  // Combined list for display (leads converted to proposal-like format)
  List<ProposalModel> get displayItems {
    if (_selectedFilter.value == 'all') {
      return _proposals;
    }
    return _proposals.where((p) {
      switch (_selectedFilter.value) {
        case 'pending':
          return p.status == ProposalStatus.pending;
        case 'accepted':
          return p.status == ProposalStatus.accepted || p.status == ProposalStatus.inProgress;
        case 'completed':
          return p.status == ProposalStatus.completed;
        case 'reported':
          return p.status == ProposalStatus.reported;
        default:
          return true;
      }
    }).toList();
  }

  // Get filtered counts
  int get allCount => _proposals.length;
  int get pendingCount => _proposals.where((p) => p.status == ProposalStatus.pending).length;
  int get acceptedCount => _proposals.where((p) => p.status == ProposalStatus.accepted || p.status == ProposalStatus.inProgress).length;
  int get completedCount => _proposals.where((p) => p.status == ProposalStatus.completed).length;
  int get reportedCount => _proposals.where((p) => p.status == ProposalStatus.reported).length;

  // Navigation arguments handlers - using simple variables, not reactive
  String? _pendingReviewProposalId;
  String? _pendingReportProposalId;

  String? get pendingReviewProposalId => _pendingReviewProposalId;
  String? get pendingReportProposalId => _pendingReportProposalId;

  void clearDialogFlags() {
    _pendingReviewProposalId = null;
    _pendingReportProposalId = null;
  }

  void handlePendingDialogs() {
    if (_pendingReviewProposalId != null) {
      final proposalId = _pendingReviewProposalId!;
      _pendingReviewProposalId = null;
      // Trigger dialog showing via a callback mechanism
      // This will be handled in the view after data loads
      if (kDebugMode) {
        print('📝 ProposalController: Review dialog requested for: $proposalId');
      }
    }
    if (_pendingReportProposalId != null) {
      final proposalId = _pendingReportProposalId!;
      _pendingReportProposalId = null;
      if (kDebugMode) {
        print('🚩 ProposalController: Report dialog requested for: $proposalId');
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Check if proposalId or leadId was passed as argument
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args['proposalId'] != null) {
        final proposalId = args['proposalId']?.toString();
        if (proposalId != null && proposalId.isNotEmpty) {
          _highlightedProposalId.value = proposalId;
          if (kDebugMode) {
            print('🎯 ProposalController: Highlighting proposalId: $proposalId');
          }
        }
      }
      if (args['leadId'] != null) {
        final leadId = args['leadId']?.toString();
        if (leadId != null && leadId.isNotEmpty) {
          _highlightedLeadId.value = leadId;
          if (kDebugMode) {
            print('🎯 ProposalController: Highlighting leadId: $leadId');
          }
          
          // Store pending dialog requests (not reactive)
          if (args['showReview'] == true) {
            _pendingReviewProposalId = leadId;
            if (kDebugMode) {
              print('📝 ProposalController: Will show review dialog for leadId: $leadId');
            }
          }
          if (args['showReport'] == true) {
            _pendingReportProposalId = leadId;
            if (kDebugMode) {
              print('🚩 ProposalController: Will show report dialog for leadId: $leadId');
            }
          }
        }
      }
    }
    loadProposals();
  }

  /// Scroll to and highlight a specific proposal
  void highlightProposal(String proposalId) {
    _highlightedProposalId.value = proposalId;
    // Clear highlight after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_highlightedProposalId.value == proposalId) {
        _highlightedProposalId.value = null;
      }
    });
  }

  /// Scroll to and highlight a specific lead
  void highlightLead(String leadId) {
    _highlightedLeadId.value = leadId;
    // Clear highlight after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_highlightedLeadId.value == leadId) {
        _highlightedLeadId.value = null;
      }
    });
  }

  /// Load proposals and leads for current user
  Future<void> loadProposals() async {
    _isLoading.value = true;
    _error.value = null;

    try {
      final user = _authController.currentUser;
      if (user == null) {
        _error.value = 'User not logged in';
        _isLoading.value = false;
        return;
      }

      if (kDebugMode) {
        print('📋 Loading proposals and leads for user: ${user.id}');
      }

      // Load leads for buyer (user's own leads)
      try {
        if (kDebugMode) {
          print('📡 Fetching leads for buyer ID: ${user.id}');
          print('   Using endpoint: ${ApiConstants.getLeadsByBuyerIdEndpoint(user.id)}');
        }
        
        final leadsResponse = await _leadsService.getLeadsByBuyerId(user.id);
        _leads.value = leadsResponse.leads;
        
        if (kDebugMode) {
          print('✅ Loaded ${_leads.length} leads');
          print('   Response: success=${leadsResponse.success}, count=${leadsResponse.count}, total=${leadsResponse.total}');
        }

        // Convert leads to proposal-like format for display
        _proposals.value = _convertLeadsToProposals(_leads);
        
        if (kDebugMode && _proposals.isNotEmpty) {
          print('✅ Converted ${_leads.length} leads to ${_proposals.length} proposals for display');
        }
      } on LeadsServiceException catch (e) {
        if (kDebugMode) {
          print('⚠️ LeadsServiceException loading leads: ${e.message}');
          print('   Status Code: ${e.statusCode}');
        }
        // If leads fail with 404 or similar, it's okay (user might not have leads yet)
        if (e.statusCode != 404 && e.statusCode != null) {
          _error.value = e.message;
        }
        _leads.value = [];
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Unexpected error loading leads: $e');
        }
        // If leads fail, still try to load proposals
        _leads.value = [];
        if (_error.value == null) {
          _error.value = 'Failed to load leads: ${e.toString()}';
        }
      }

      // Also load actual proposals if available
      try {
        final proposalsResponse = await _proposalService.getUserProposals(user.id);
        if (proposalsResponse.isNotEmpty) {
          // Merge with leads-converted proposals (avoid duplicates)
          final existingIds = _proposals.map((p) => p.id).toSet();
          final newProposals = proposalsResponse.where((p) => !existingIds.contains(p.id)).toList();
          _proposals.addAll(newProposals);
          
          if (kDebugMode) {
            print('✅ Loaded ${newProposals.length} actual proposals');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error loading proposals (may not exist): $e');
          // If proposals endpoint doesn't exist or fails, continue with leads only
        }
      }

      // Sort by created date (newest first)
      _proposals.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (kDebugMode) {
        final proposalsCount = _proposals.length - _leads.length;
        print('✅ Total items loaded: ${_proposals.length} (${_leads.length} leads + ${proposalsCount > 0 ? proposalsCount : 0} proposals)');
      }

      // Handle highlighting - convert leadId to proposal highlighting
      if (_highlightedLeadId.value != null && _highlightedLeadId.value!.isNotEmpty) {
        // Since we use lead ID as proposal ID, we can highlight directly
        final leadId = _highlightedLeadId.value!;
        final proposalIndex = _proposals.indexWhere((p) => p.id == leadId);
        if (proposalIndex != -1) {
          if (kDebugMode) {
            print('🎯 Found proposal for leadId: $leadId at index: $proposalIndex');
          }
          highlightProposal(_proposals[proposalIndex].id);
        } else {
          if (kDebugMode) {
            print('⚠️ Proposal not found for leadId: $leadId');
          }
        }
      }
      
      // Handle proposal highlighting
      if (_highlightedProposalId.value != null && _highlightedProposalId.value!.isNotEmpty) {
        final proposalId = _highlightedProposalId.value!;
        final proposalIndex = _proposals.indexWhere((p) => p.id == proposalId);
        if (proposalIndex != -1) {
          if (kDebugMode) {
            print('🎯 Found proposal for proposalId: $proposalId at index: $proposalIndex');
          }
          highlightProposal(_proposals[proposalIndex].id);
        }
      }

      if (_proposals.isEmpty) {
        if (kDebugMode) {
          print('ℹ️ No proposals or leads found for user');
        }
      }

      // Handle pending dialogs after data is loaded
      handlePendingDialogs();

    } catch (e) {
      _error.value = e.toString();
      if (kDebugMode) {
        print('❌ Error loading proposals: $e');
        print('   Error type: ${e.runtimeType}');
      }
      
      // Only show error if leads loading failed (proposals might not exist)
      if (_leads.isEmpty) {
        ErrorHandler.handleError(e, defaultMessage: 'Unable to load leads. Please check your connection and try again.');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Set filter
  void setFilter(String filter) {
    _selectedFilter.value = filter;
    if (kDebugMode) {
      print('🔍 Filter changed to: $filter');
      print('   Displaying ${displayItems.length} items');
    }
  }

  /// Convert leads to proposal-like format for unified display
  List<ProposalModel> _convertLeadsToProposals(List<LeadModel> leads) {
    return leads.map((lead) {
      if (kDebugMode) {
        print('🔄 Converting lead to proposal: ${lead.id}');
        print('   Lead status: ${lead.leadStatus}');
        print('   Agent response: ${lead.agentResponse?.status}');
        print('   Is completed: ${lead.isCompleted}');
      }
      
      // Determine status based on leadStatus and agentResponse
      ProposalStatus status = ProposalStatus.pending;
      
      // Check leadStatus first (highest priority)
      if (lead.leadStatus != null && lead.leadStatus!.isNotEmpty) {
        final leadStatusLower = lead.leadStatus!.toLowerCase();
        switch (leadStatusLower) {
          case 'completed':
            status = ProposalStatus.completed;
            break;
          case 'reported':
            status = ProposalStatus.reported;
            break;
          case 'accepted':
            status = ProposalStatus.accepted; // Keep as accepted - don't show complete service button
            break;
          case 'pending':
            status = ProposalStatus.pending;
            break;
          default:
            // Fall through to other checks
            break;
        }
      }
      
      // If status wasn't determined by leadStatus, check other conditions
      if (status == ProposalStatus.pending) {
        if (lead.isCompleted) {
          // Lead is completed
          status = ProposalStatus.completed;
        } else if (lead.isReported) {
          // Lead is reported
          status = ProposalStatus.reported;
        } else if (lead.isAccepted) {
          // Lead is accepted (agent responded and accepted)
          status = ProposalStatus.accepted; // Keep as accepted - don't show complete service button
        } else if (lead.agentResponse != null && lead.agentResponse!.status == 'rejected') {
          // Lead was rejected
          status = ProposalStatus.rejected;
        } else if (lead.agentId != null && lead.agentId!.id.isNotEmpty) {
          // Agent is assigned but not explicitly accepted - treat as accepted/in progress
          status = ProposalStatus.accepted;
        } else {
          // Default to pending
          status = ProposalStatus.pending;
        }
      }
      
      if (kDebugMode) {
        print('   Final mapped status: ${status.label}');
      }

      // Get agent name if available
      final agentName = lead.agentId?.fullname ?? 
                       (lead.agentId != null ? 'Assigned Agent' : 'No Agent Assigned');
      
      // Get property address - prioritize propertyInformation, then planningArea
      String? propertyAddress;
      if (lead.propertyInformation != null && 
          lead.propertyInformation!.fullAddress.isNotEmpty &&
          lead.propertyInformation!.fullAddress != 'Address not provided') {
        propertyAddress = lead.propertyInformation!.fullAddress;
      } else if (lead.planningArea != null && lead.planningArea!.isNotEmpty) {
        propertyAddress = lead.planningArea!;
      }

      // Build message from lead details
      String? message;
      if (lead.comments != null && lead.comments!.isNotEmpty) {
        message = lead.comments!;
      } else if (lead.mustHaveFeatures != null && lead.mustHaveFeatures!.isNotEmpty) {
        message = 'Must have: ${lead.mustHaveFeatures!}';
      } else if (lead.buyingOrBuilding != null && lead.buyingOrBuilding!.isNotEmpty) {
        message = 'Looking for: ${lead.buyingOrBuilding!}';
      } else {
        message = 'Real estate service inquiry';
      }

      // Get price
      String? propertyPrice;
      if (lead.priceRange != null && lead.priceRange!.isNotEmpty) {
        propertyPrice = lead.priceRange!;
      } else if (lead.idealSellingPrice != null && lead.idealSellingPrice!.isNotEmpty) {
        propertyPrice = lead.idealSellingPrice!;
      }

      if (kDebugMode) {
        print('   Lead ID: ${lead.id}');
        print('   Agent: $agentName');
        print('   Status: ${status.label}');
        print('   Property: ${propertyAddress ?? "Not specified"}');
      }

      // Get accepted date from agentResponse or updatedAt
      DateTime? acceptedAt;
      if (lead.agentResponse != null && 
          lead.agentResponse!.respondedAt != null && 
          lead.agentResponse!.status == 'accepted') {
        acceptedAt = lead.agentResponse!.respondedAt;
      } else if (lead.agentId != null && lead.agentId!.id.isNotEmpty && lead.updatedAt != null) {
        acceptedAt = lead.updatedAt;
      }

      // Get completed date if marked as complete
      DateTime? completedAt;
      if (lead.isCompleted && lead.updatedAt != null) {
        completedAt = lead.updatedAt;
      }

      if (kDebugMode) {
        print('   Lead ID: ${lead.id}');
        print('   Agent: $agentName');
        print('   Lead Status: ${lead.leadStatus}');
        print('   Agent Response Status: ${lead.agentResponse?.status}');
        print('   Proposal Status: ${status.label}');
        print('   Property: ${propertyAddress ?? "Not specified"}');
      }

      return ProposalModel(
        id: lead.id, // Use lead ID as proposal ID for reference
        userId: lead.currentUserId?.id ?? '',
        userName: lead.fullName ?? lead.currentUserId?.fullname ?? 'User',
        userProfilePic: ApiConstants.getImageUrl(lead.currentUserId?.profilePic),
        professionalId: lead.agentId?.id ?? '',
        professionalName: agentName,
        professionalType: 'agent',
        status: status,
        message: message,
        propertyAddress: propertyAddress,
        propertyPrice: propertyPrice,
        createdAt: lead.createdAt ?? DateTime.now(),
        updatedAt: lead.updatedAt,
        acceptedAt: acceptedAt,
        completedAt: completedAt,
      );
    }).toList();
  }

  /// Get dummy proposals for UI preview
  List<ProposalModel> _getDummyProposals() {
    final now = DateTime.now();
    return [
      ProposalModel(
        id: 'prop_1',
        userId: 'user_1',
        userName: 'John Doe',
        professionalId: 'agent_1',
        professionalName: 'Sarah Johnson',
        professionalType: 'agent',
        message: 'I would like to work with you on finding my dream home. I\'m looking for a 3-bedroom house in the downtown area.',
        status: ProposalStatus.pending,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      ProposalModel(
        id: 'prop_2',
        userId: 'user_1',
        userName: 'John Doe',
        professionalId: 'agent_2',
        professionalName: 'Michael Chen',
        professionalType: 'agent',
        message: 'Looking for assistance with selling my property. Need help with pricing and marketing strategy.',
        status: ProposalStatus.accepted,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 3)),
        acceptedAt: now.subtract(const Duration(days: 3)),
      ),
      ProposalModel(
        id: 'prop_3',
        userId: 'user_1',
        userName: 'John Doe',
        professionalId: 'loan_1',
        professionalName: 'Emily Rodriguez',
        professionalType: 'loan_officer',
        message: 'I need help with mortgage pre-approval and finding the best loan options for my situation.',
        status: ProposalStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 4)),
        acceptedAt: now.subtract(const Duration(days: 4)),
      ),
      ProposalModel(
        id: 'prop_4',
        userId: 'user_1',
        userName: 'John Doe',
        professionalId: 'agent_3',
        professionalName: 'David Thompson',
        professionalType: 'agent',
        message: 'Interested in your services for property investment consultation.',
        status: ProposalStatus.rejected,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 8)),
        rejectionReason: 'Currently at full capacity',
      ),
      ProposalModel(
        id: 'prop_5',
        userId: 'user_1',
        userName: 'John Doe',
        professionalId: 'loan_2',
        professionalName: 'James Wilson',
        professionalType: 'loan_officer',
        message: 'Need assistance with refinancing my current mortgage.',
        status: ProposalStatus.completed,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 1)),
        acceptedAt: now.subtract(const Duration(days: 12)),
        completedAt: now.subtract(const Duration(days: 1)),
      ),
      ProposalModel(
        id: 'prop_6',
        userId: 'user_1',
        userName: 'John Doe',
        professionalId: 'agent_4',
        professionalName: 'Lisa Anderson',
        professionalType: 'agent',
        message: 'Looking for help with buying a commercial property.',
        status: ProposalStatus.reported,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 18)),
        acceptedAt: now.subtract(const Duration(days: 18)),
        reportedAt: now.subtract(const Duration(days: 18)),
        reportReason: 'Unprofessional behavior',
        reportDescription: 'Agent was unresponsive and did not follow through on commitments.',
      ),
    ];
  }

  /// Create a new proposal
  Future<ProposalModel?> createProposal({
    required String professionalId,
    required String professionalName,
    required String professionalType,
    String? message,
    String? propertyAddress,
    String? propertyPrice,
  }) async {
    final user = _authController.currentUser;
    if (user == null) {
      SnackbarHelper.showError('Please login to create a proposal');
      return null;
    }

    _isLoading.value = true;

    try {
      final proposal = await _proposalService.createProposal(
        userId: user.id,
        userName: user.name ?? 'User',
        userProfilePic: user.profileImage,
        professionalId: professionalId,
        professionalName: professionalName,
        professionalType: professionalType,
        message: message,
        propertyAddress: propertyAddress,
        propertyPrice: propertyPrice,
      );

      // Add to list
      _proposals.insert(0, proposal);
      
      SnackbarHelper.showSuccess('Proposal sent successfully');
      
      if (kDebugMode) {
        print('✅ Proposal created: ${proposal.id}');
      }

      return proposal;
    } catch (e) {
      ErrorHandler.handleError(e, defaultMessage: 'Unable to create proposal. Please try again.');
      if (kDebugMode) {
        print('❌ Error creating proposal: $e');
      }
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Accept a proposal (for agents/loan officers)
  Future<bool> acceptProposal(String proposalId) async {
    final user = _authController.currentUser;
    if (user == null) return false;

    _isLoading.value = true;

    try {
      final updatedProposal = await _proposalService.acceptProposal(
        proposalId: proposalId,
        professionalId: user.id,
      );

      // Update in list
      final index = _proposals.indexWhere((p) => p.id == proposalId);
      if (index != -1) {
        _proposals[index] = updatedProposal;
      }

      SnackbarHelper.showSuccess('Proposal accepted. Service is now in progress.');
      
      if (kDebugMode) {
        print('✅ Proposal accepted: $proposalId');
      }

      return true;
    } catch (e) {
      ErrorHandler.handleError(e, defaultMessage: 'Unable to accept proposal. Please try again.');
      if (kDebugMode) {
        print('❌ Error accepting proposal: $e');
      }
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Reject a proposal (for agents/loan officers)
  Future<bool> rejectProposal(String proposalId, {String? reason}) async {
    final user = _authController.currentUser;
    if (user == null) return false;

    _isLoading.value = true;

    try {
      final updatedProposal = await _proposalService.rejectProposal(
        proposalId: proposalId,
        professionalId: user.id,
        reason: reason,
      );

      // Update in list
      final index = _proposals.indexWhere((p) => p.id == proposalId);
      if (index != -1) {
        _proposals[index] = updatedProposal;
      }

      SnackbarHelper.showInfo('Proposal rejected');
      
      if (kDebugMode) {
        print('✅ Proposal rejected: $proposalId');
      }

      return true;
    } catch (e) {
      ErrorHandler.handleError(e, defaultMessage: 'Unable to reject proposal. Please try again.');
      if (kDebugMode) {
        print('❌ Error rejecting proposal: $e');
      }
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Complete service (either party)
  Future<bool> completeService(String proposalId) async {
    final user = _authController.currentUser;
    if (user == null) return false;

    _isLoading.value = true;

    try {
      final updatedProposal = await _proposalService.completeService(
        proposalId: proposalId,
        userId: user.id,
      );

      // Update in list
      final index = _proposals.indexWhere((p) => p.id == proposalId);
      if (index != -1) {
        _proposals[index] = updatedProposal;
      }

      SnackbarHelper.showSuccess('Service marked as completed');
      
      if (kDebugMode) {
        print('✅ Service completed: $proposalId');
      }

      return true;
    } catch (e) {
      ErrorHandler.handleError(e, defaultMessage: 'Unable to complete service. Please try again.');
      if (kDebugMode) {
        print('❌ Error completing service: $e');
      }
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Submit a review
  Future<bool> submitReview({
    required String proposalId,
    required String professionalId,
    required String professionalType,
    required int rating,
    required String review,
  }) async {
    final user = _authController.currentUser;
    if (user == null) return false;

    _isLoading.value = true;

    try {
      if (professionalType == 'agent') {
        await _reviewService.submitReview(
          currentUserId: user.id,
          agentId: professionalId,
          rating: rating,
          review: review,
        );
      } else {
        await _reviewService.submitLoanOfficerReview(
          currentUserId: user.id,
          loanOfficerId: professionalId,
          rating: rating,
          review: review,
        );
      }

      // Mark proposal as reviewed
      final index = _proposals.indexWhere((p) => p.id == proposalId);
      if (index != -1) {
        _proposals[index] = _proposals[index].copyWith(userHasReviewed: true);
      }

      SnackbarHelper.showSuccess('Review submitted successfully');
      
      if (kDebugMode) {
        print('✅ Review submitted for proposal: $proposalId');
      }

      return true;
    } catch (e) {
      ErrorHandler.handleError(e, defaultMessage: 'Unable to submit review. Please try again.');
      if (kDebugMode) {
        print('❌ Error submitting review: $e');
      }
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Submit a report
  Future<bool> submitReport({
    required String proposalId,
    required String reportedUserId,
    required String reason,
    required String description,
  }) async {
    final user = _authController.currentUser;
    if (user == null) return false;

    _isLoading.value = true;

    try {
      // Check if this is a lead (proposal ID equals lead ID)
      final leadId = _leads.any((l) => l.id == proposalId) ? proposalId : null;
      
      await _reportService.submitReport(
        reporterId: user.id,
        reportedUserId: reportedUserId,
        reason: reason,
        description: description,
        leadId: leadId ?? proposalId, // Use leadId if it's a lead, otherwise use proposalId as leadId for API
      );

      // Update proposal status to reported
      final index = _proposals.indexWhere((p) => p.id == proposalId);
      if (index != -1) {
        _proposals[index] = _proposals[index].copyWith(
          status: ProposalStatus.reported,
          reportReason: reason,
          reportDescription: description,
          reportedAt: DateTime.now(),
        );
      }

      SnackbarHelper.showSuccess('Report submitted successfully');
      
      if (kDebugMode) {
        print('✅ Report submitted for proposal: $proposalId');
      }

      return true;
    } catch (e) {
      ErrorHandler.handleError(e, defaultMessage: 'Unable to submit report. Please try again.');
      if (kDebugMode) {
        print('❌ Error submitting report: $e');
      }
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get proposal by ID
  ProposalModel? getProposal(String proposalId) {
    try {
      return _proposals.firstWhere((p) => p.id == proposalId);
    } catch (e) {
      return null;
    }
  }

  /// Get lead by ID
  LeadModel? getLead(String leadId) {
    try {
      return _leads.firstWhere((l) => l.id == leadId);
    } catch (e) {
      return null;
    }
  }

  /// Get lead for a proposal (if proposal was converted from lead)
  LeadModel? getLeadForProposal(String proposalId) {
    return getLead(proposalId); // Since we use lead ID as proposal ID
  }

  /// Get proposals by status
  List<ProposalModel> getProposalsByStatus(ProposalStatus status) {
    return _proposals.where((p) => p.status == status).toList();
  }

  /// Get active proposals (accepted or in progress)
  List<ProposalModel> get activeProposals {
    return _proposals.where((p) => p.status.isActive).toList();
  }

}

