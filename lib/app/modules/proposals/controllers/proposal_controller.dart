import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/models/proposal_model.dart';
import 'package:getrebate/app/services/proposal_service.dart';
import 'package:getrebate/app/services/report_service.dart';
import 'package:getrebate/app/services/review_service.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

class ProposalController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final ProposalService _proposalService = ProposalService();
  final ReportService _reportService = ReportService();
  final ReviewService _reviewService = ReviewService();

  // Observable proposals
  final _proposals = <ProposalModel>[].obs;
  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _highlightedProposalId = Rxn<String>();

  List<ProposalModel> get proposals => _proposals;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  String? get highlightedProposalId => _highlightedProposalId.value;

  @override
  void onInit() {
    super.onInit();
    // Check if proposalId was passed as argument
    final args = Get.arguments;
    if (args != null && args is Map && args['proposalId'] != null) {
      _highlightedProposalId.value = args['proposalId'] as String;
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

  /// Load proposals for current user - using dummy data for preview
  Future<void> loadProposals() async {
    _isLoading.value = true;
    _error.value = null;

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Load dummy data to show UI preview
      _proposals.value = _getDummyProposals();
      
      if (kDebugMode) {
        print('✅ Loaded ${_proposals.length} dummy proposals for preview');
      }
    } catch (e) {
      _error.value = e.toString();
      if (kDebugMode) {
        print('❌ Error loading proposals: $e');
      }
    } finally {
      _isLoading.value = false;
    }
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
      SnackbarHelper.showError('Failed to create proposal: ${e.toString()}');
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
      SnackbarHelper.showError('Failed to accept proposal: ${e.toString()}');
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
      SnackbarHelper.showError('Failed to reject proposal: ${e.toString()}');
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
      SnackbarHelper.showError('Failed to complete service: ${e.toString()}');
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
          proposalId: proposalId,
        );
      } else {
        await _reviewService.submitLoanOfficerReview(
          currentUserId: user.id,
          loanOfficerId: professionalId,
          rating: rating,
          review: review,
          proposalId: proposalId,
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
      SnackbarHelper.showError('Failed to submit review: ${e.toString()}');
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
      await _reportService.submitReport(
        reporterId: user.id,
        reportedUserId: reportedUserId,
        reason: reason,
        description: description,
        proposalId: proposalId,
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
      SnackbarHelper.showError('Failed to submit report: ${e.toString()}');
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

  /// Get proposals by status
  List<ProposalModel> getProposalsByStatus(ProposalStatus status) {
    return _proposals.where((p) => p.status == status).toList();
  }

  /// Get active proposals (accepted or in progress)
  List<ProposalModel> get activeProposals {
    return _proposals.where((p) => p.status.isActive).toList();
  }

}

