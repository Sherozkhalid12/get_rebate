import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/services/survey_service.dart';
import 'package:getrebate/app/services/leads_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/models/lead_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:flutter/foundation.dart';

/// Model for completed professional (agent or loan officer)
class CompletedProfessional {
  final String id;
  final String name;
  final String type; // 'agent' or 'loanOfficer'
  final String? profileImage;
  final String? company;
  final String? leadId; // Reference to the completed lead
  final DateTime? completedAt;

  CompletedProfessional({
    required this.id,
    required this.name,
    required this.type,
    this.profileImage,
    this.company,
    this.leadId,
    this.completedAt,
  });
}

class PostClosingSurveyController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final SurveyService _surveyService = SurveyService();
  final LeadsService _leadsService = LeadsService();

  // Selection screen state
  final _showSelectionScreen = true.obs;
  final _completedProfessionals = <CompletedProfessional>[].obs;
  final _isLoadingProfessionals = false.obs;
  final _selectedProfessional = Rxn<CompletedProfessional>();

  // Survey state (set after selection)
  late String agentId;
  late String agentName;
  late String userId;
  late String transactionId;
  late String? loanOfficerId;
  late String? loanOfficerName;
  late bool isBuyer;
  late String surveyType; // 'agent' or 'loanOfficer'

  // Text controllers
  final rebateAmountController = TextEditingController();
  final otherTextController = TextEditingController();
  final commentsController = TextEditingController();
  final loanTypeOtherController = TextEditingController();

  // Observables
  final _currentStep = 0.obs;
  final _isLoading = false.obs;

  // Agent Survey
  final agentRebateAmount = 0.0.obs;
  final agentRebateExpected = Rxn<String>();
  final agentRebateMethod = Rxn<String>();
  final agentSignedDisclosure = Rxn<String>();
  final agentRebateEase = Rxn<String>();
  final agentRecommend = Rxn<String>();
  final agentRating = 0.5.obs; // double for slider

  // Loan Officer Survey
  final loSatisfaction = 0.5.obs;
  final loExplainedOptions = Rxn<String>();
  final loCommunication = Rxn<String>();
  final loRebateHelp = Rxn<String>();
  final loEase = Rxn<String>();
  final loProfessional = Rxn<String>();
  final loClosedOnTime = Rxn<String>();
  final loRecommend = Rxn<String>();
  final loLoanType = Rxn<String>();

  // Getters
  bool get showSelectionScreen => _showSelectionScreen.value;
  List<CompletedProfessional> get completedProfessionals => _completedProfessionals;
  bool get isLoadingProfessionals => _isLoadingProfessionals.value;
  CompletedProfessional? get selectedProfessional => _selectedProfessional.value;
  int get currentStep => _currentStep.value;
  bool get isLoading => _isLoading.value;
  bool get isAgentSurvey => surveyType == 'agent';
  int get totalSteps => isAgentSurvey ? 8 : 10;

  @override
  void onInit() {
    super.onInit();
    
    // Check if agent/LO was passed directly (backward compatibility)
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['agentId'] != null) {
      // Direct navigation with agent/LO already selected
      agentId = args['agentId'];
      agentName = args['agentName'] ?? 'Agent';
      userId = args['userId'] ?? _authController.currentUser?.id ?? '';
      transactionId = args['transactionId'] ?? '';
      isBuyer = args['isBuyer'] ?? true;
      surveyType = args['surveyType'] ?? 'agent';
      loanOfficerId = args['loanOfficerId'];
      loanOfficerName = args['loanOfficerName'];
      _showSelectionScreen.value = false;
    } else {
      // New flow: show selection screen first
      _showSelectionScreen.value = true;
      userId = _authController.currentUser?.id ?? '';
      isBuyer = true; // Default, can be determined from lead
      loadCompletedProfessionals();
    }
  }

  /// Load completed leads and extract unique agents/loan officers
  Future<void> loadCompletedProfessionals() async {
    _isLoadingProfessionals.value = true;

    try {
      final currentUser = _authController.currentUser;
      if (currentUser == null || currentUser.id.isEmpty) {
        SnackbarHelper.showError('Please login to submit a survey');
        _isLoadingProfessionals.value = false;
        return;
      }

      if (kDebugMode) {
        print('📡 Loading completed leads for user: ${currentUser.id}');
        print('   Using endpoint: ${ApiConstants.getListingsByUserIdEndpoint(currentUser.id)}');
      }

      // Fetch leads using getListingsByUserId endpoint
      final leadsResponse = await _leadsService.getLeadsByBuyerId(currentUser.id);
      
      // Filter to only completed leads
      final completedLeads = leadsResponse.leads.where((lead) {
        final isCompleted = lead.isCompleted || 
                           lead.leadStatus?.toLowerCase() == 'completed';
        return isCompleted && lead.agentId != null;
      }).toList();

      if (kDebugMode) {
        print('✅ Found ${completedLeads.length} completed leads');
      }

      // Extract unique agents/loan officers from completed leads
      final professionalsMap = <String, CompletedProfessional>{};
      
      for (final lead in completedLeads) {
        if (lead.agentId != null) {
          final agentId = lead.agentId!.id;
          final agentName = lead.agentId!.fullname ?? 'Agent';
          final profileImage = lead.agentId!.profilePic;
          final role = lead.agentId!.role?.toLowerCase() ?? 'agent';
          
          // Only add if not already added
          if (!professionalsMap.containsKey(agentId)) {
            professionalsMap[agentId] = CompletedProfessional(
              id: agentId,
              name: agentName,
              type: role == 'loan_officer' ? 'loanOfficer' : 'agent',
              profileImage: profileImage,
              company: lead.agentId!.role == 'loan_officer' 
                  ? null // Company info would need to be fetched separately if needed
                  : null, // Agent brokerage would need to be fetched separately if needed
              leadId: lead.id,
              completedAt: lead.updatedAt,
            );
          }
        }
      }

      _completedProfessionals.value = professionalsMap.values.toList();
      
      // Sort by completion date (most recent first)
      _completedProfessionals.sort((a, b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;
        return b.completedAt!.compareTo(a.completedAt!);
      });

      if (kDebugMode) {
        print('✅ Loaded ${_completedProfessionals.length} completed professionals');
        for (final prof in _completedProfessionals) {
          print('   - ${prof.name} (${prof.type})');
        }
      }

      if (_completedProfessionals.isEmpty) {
        SnackbarHelper.showInfo(
          'You don\'t have any completed transactions yet. Complete a service with an agent or loan officer to leave a review.',
          duration: const Duration(seconds: 4),
        );
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading completed professionals: $e');
      }
      SnackbarHelper.showError('Failed to load completed professionals: ${e.toString()}');
    } finally {
      _isLoadingProfessionals.value = false;
    }
  }

  /// Select a professional and start survey
  void selectProfessional(CompletedProfessional professional) {
    _selectedProfessional.value = professional;
    
    // Set survey parameters
    if (professional.type == 'agent') {
      agentId = professional.id;
      agentName = professional.name;
      surveyType = 'agent';
      loanOfficerId = null;
      loanOfficerName = null;
    } else {
      loanOfficerId = professional.id;
      loanOfficerName = professional.name;
      surveyType = 'loanOfficer';
      agentId = ''; // Not used for loan officer surveys
      agentName = '';
    }
    
    transactionId = professional.leadId ?? '';
    
    // Hide selection screen and start survey
    _showSelectionScreen.value = false;
    _currentStep.value = 0;
    
    if (kDebugMode) {
      print('✅ Selected ${professional.type}: ${professional.name}');
      print('   Starting survey for: ${professional.id}');
    }
  }

  void nextStep() {
    if (_currentStep.value < totalSteps - 1) {
      _currentStep.value++;
    }
  }

  void previousStep() {
    if (_currentStep.value > 0) {
      _currentStep.value--;
    }
  }

  bool canProceed() {
    if (isAgentSurvey) {
      return switch (currentStep) {
        0 => agentRebateAmount.value > 0,
        1 => agentRebateExpected.value != null,
        4 => agentRebateEase.value != null,
        7 => agentRating.value > 0,
        _ => true,
      };
    } else {
      return currentStep == 0 ? loSatisfaction.value > 0 : true;
    }
  }

  /// Submit survey to API
  Future<void> submitSurvey() async {
    _isLoading.value = true;

    try {
      // Map survey responses to API format
      String receivedExpectedRebate = agentRebateExpected.value ?? 'Not sure';
      String rebateAppliedAsCreditClosing = agentRebateMethod.value ?? 'Other';
      String signedRebateDisclosure = agentSignedDisclosure.value ?? 'Not sure';
      String receivingRebateEasy = agentRebateEase.value ?? 'Neutral';
      String agentRecommended = agentRecommend.value ?? 'Not sure';
      String comment = commentsController.text.trim();
      double rating = agentRating.value;

      // Handle "Other" option for rebate method
      if (agentRebateMethod.value == 'Other' && otherTextController.text.isNotEmpty) {
        rebateAppliedAsCreditClosing = otherTextController.text.trim();
      }

      if (kDebugMode) {
        print('📤 Submitting survey:');
        print('   userId: $userId');
        print('   rebateFromAgent: ${agentRebateAmount.value}');
        print('   receivedExpectedRebate: $receivedExpectedRebate');
        print('   rebateAppliedAsCreditClosing: $rebateAppliedAsCreditClosing');
        print('   signedRebateDisclosure: $signedRebateDisclosure');
        print('   receivingRebateEasy: $receivingRebateEasy');
        print('   agentRecommended: $agentRecommended');
        print('   rating: $rating');
      }

      // Submit to API
      await _surveyService.submitSurvey(
        userId: userId,
        rebateFromAgent: agentRebateAmount.value,
        receivedExpectedRebate: receivedExpectedRebate,
        rebateAppliedAsCreditClosing: rebateAppliedAsCreditClosing,
        signedRebateDisclosure: signedRebateDisclosure,
        receivingRebateEasy: receivingRebateEasy,
        agentRecommended: agentRecommended,
        comment: comment.isNotEmpty ? comment : null,
        rating: rating,
      );

      SnackbarHelper.showSuccess(
        'Thank you for your feedback! Your review has been submitted.',
        title: 'Survey Submitted',
        duration: const Duration(seconds: 3),
      );

      // Navigate back
      Navigator.pop(Get.context!);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting survey: $e');
      }
      SnackbarHelper.showError('Failed to submit survey: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  void onClose() {
    rebateAmountController.dispose();
    otherTextController.dispose();
    commentsController.dispose();
    loanTypeOtherController.dispose();
    super.onClose();
  }
}
