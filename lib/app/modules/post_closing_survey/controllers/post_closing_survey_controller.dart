import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/services/survey_service.dart';
import 'package:getrebate/app/services/leads_service.dart';
import 'package:getrebate/app/services/loan_officer_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/routes/app_pages.dart';
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
  final LoanOfficerService _loanOfficerService = LoanOfficerService();

  // Selection screen state
  final _showSelectionScreen = true.obs;
  final _completedProfessionals = <CompletedProfessional>[].obs;
  final _loanOfficerProfessionals = <CompletedProfessional>[].obs;
  final _isLoadingProfessionals = false.obs;
  final _selectedProfessional = Rxn<CompletedProfessional>();
  final _agentSearchQuery = ''.obs;
  final _loanOfficerSearchQuery = ''.obs;
  final _selectedTabIndex = 0.obs; // 0 = Agents, 1 = Loan Officers

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
  List<CompletedProfessional> get allLoanOfficerProfessionals => _loanOfficerProfessionals;
  bool get isLoadingProfessionals => _isLoadingProfessionals.value;
  CompletedProfessional? get selectedProfessional => _selectedProfessional.value;
  String get agentSearchQuery => _agentSearchQuery.value;
  String get loanOfficerSearchQuery => _loanOfficerSearchQuery.value;
  int get selectedTabIndex => _selectedTabIndex.value;
  bool get hasAnyProfessionals =>
      _completedProfessionals.isNotEmpty || _loanOfficerProfessionals.isNotEmpty;
  List<CompletedProfessional> get agentProfessionals =>
      _completedProfessionals.where((p) => p.type == 'agent').toList();
  List<CompletedProfessional> get loanOfficerProfessionals =>
      _loanOfficerProfessionals;
  List<CompletedProfessional> get filteredAgentProfessionals {
    final q = _agentSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return agentProfessionals;
    return agentProfessionals
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              (p.company?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }
  List<CompletedProfessional> get filteredLoanOfficerProfessionals {
    final q = _loanOfficerSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return loanOfficerProfessionals;
    return loanOfficerProfessionals
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              (p.company?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }
  int get currentStep => _currentStep.value;
  bool get isLoading => _isLoading.value;
  bool get isAgentSurvey => surveyType == 'agent';
  int get totalSteps => isAgentSurvey ? 8 : 10;

  @override
  void onInit() {
    super.onInit();
    
    // Always show selection screen first to let user choose agent
    // Only skip selection if explicitly told to via 'skipSelection' flag
    final args = Get.arguments as Map<String, dynamic>?;
    final skipSelection = args?['skipSelection'] == true;
    
    if (skipSelection && args != null && args['agentId'] != null) {
      // Direct navigation with agent/LO already selected (backward compatibility)
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
      // New flow: ALWAYS show selection screen first
      _showSelectionScreen.value = true;
      userId = _authController.currentUser?.id ?? '';
      isBuyer = true; // Default, can be determined from lead
      loadCompletedProfessionals();
    }
  }

  /// Load completed leads and extract unique agents
  Future<void> loadCompletedProfessionals() async {
    _isLoadingProfessionals.value = true;
    _completedProfessionals.clear(); // Clear previous data
    _loanOfficerProfessionals.clear();
    _agentSearchQuery.value = '';
    _loanOfficerSearchQuery.value = '';
    _selectedTabIndex.value = 0;

    try {
      final currentUser = _authController.currentUser;
      if (currentUser == null || currentUser.id.isEmpty) {
        SnackbarHelper.showError('Please login to submit a survey');
        _isLoadingProfessionals.value = false;
        return;
      }

      if (kDebugMode) {
        print('📡 ==========================================');
        print('📡 Loading completed leads for user: ${currentUser.id}');
        print('📡 Using endpoint: ${ApiConstants.getLeadsByBuyerIdEndpoint(currentUser.id)}');
        print('📡 Full URL: ${ApiConstants.baseUrl}${ApiConstants.getLeadsByBuyerIdEndpoint(currentUser.id).replaceFirst(ApiConstants.apiBaseUrl, '')}');
      }

      // Fetch leads using getLeadsByAgentId endpoint (for buyer's own leads)
      // Endpoint: /api/v1/buyer/getLeadsByAgentId/{userId}
      final leadsResponse = await _leadsService.getLeadsByBuyerId(currentUser.id);
      
      if (kDebugMode) {
        print('📡 Total leads received: ${leadsResponse.leads.length}');
        print('📡 Response success: ${leadsResponse.success}');
        print('📡 Response count: ${leadsResponse.count}');
      }

      // Filter to only completed leads assigned to a professional.
      final completedLeads = leadsResponse.leads.where((lead) {
        // Check if lead is completed
        final leadStatusLower = lead.leadStatus?.toLowerCase() ?? '';
        final isCompletedByStatus = leadStatusLower == 'completed';
        final isCompletedByFlag = lead.isCompleted == true;
        final isCompleted = isCompletedByStatus || isCompletedByFlag;
        
        // Check if lead has an assigned professional.
        final hasAgent = lead.agentId != null;
        final professionalRole = lead.agentId?.role?.toLowerCase() ?? '';
        final isKnownProfessionalRole =
            professionalRole == 'agent' ||
            professionalRole == 'loan_officer' ||
            professionalRole == 'loanofficer';
        
        if (kDebugMode && hasAgent) {
          print(
            '   Lead ${lead.id}: status=$leadStatusLower, isCompleted=$isCompletedByFlag, role=$professionalRole, isCompleted=$isCompleted, isKnownRole=$isKnownProfessionalRole',
          );
        }
        
        return isCompleted && hasAgent && isKnownProfessionalRole;
      }).toList();

      if (kDebugMode) {
        print('✅ Found ${completedLeads.length} completed leads with professionals');
        if (completedLeads.isEmpty) {
          print('⚠️ No completed leads found. Checking all leads...');
          for (final lead in leadsResponse.leads.take(5)) {
            print('   Lead ${lead.id}: status=${lead.leadStatus}, isCompleted=${lead.isCompleted}, hasAgent=${lead.agentId != null}');
          }
        }
      }

      // Extract unique AGENTS from completed leads.
      final agentsMap = <String, CompletedProfessional>{};
      
      for (final lead in completedLeads) {
        if (lead.agentId != null) {
          final professionalId = lead.agentId!.id;
          final professionalName = lead.agentId!.fullname ?? 'Professional';
          final profileImage = lead.agentId!.profilePic;
          final role = lead.agentId!.role?.toLowerCase() ?? '';
          final isLoanOfficer = role == 'loan_officer' || role == 'loanofficer';

          // Only include explicit "agent" roles in agent selection list.
          if (isLoanOfficer || role != 'agent') {
            continue;
          }

          if (!agentsMap.containsKey(professionalId)) {
            agentsMap[professionalId] = CompletedProfessional(
              id: professionalId,
              name: professionalName,
              type: 'agent',
              profileImage: profileImage,
              company: null,
              leadId: lead.id,
              completedAt: lead.updatedAt,
            );
            
            if (kDebugMode) {
              print('   ✅ Added agent: $professionalName (ID: $professionalId)');
            }
          }
        }
      }

      _completedProfessionals.value = [
        ...agentsMap.values,
      ];

      // Loan officer tab should contain all loan officers so user can choose freely.
      await _loadAllLoanOfficers();
      
      // Sort by completion date (most recent first)
      _completedProfessionals.sort((a, b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;
        return b.completedAt!.compareTo(a.completedAt!);
      });

      if (kDebugMode) {
        print('✅ ==========================================');
        print(
          '✅ Loaded ${agentProfessionals.length} completed agents and ${loanOfficerProfessionals.length} loan officers',
        );
        for (final p in [..._completedProfessionals, ..._loanOfficerProfessionals]) {
          print('   - ${p.name} (${p.type}) (ID: ${p.id})');
        }
        print('✅ ==========================================');
      }

      if (!hasAnyProfessionals) {
        if (kDebugMode) {
          print('⚠️ No completed professionals found. Showing info message.');
        }
        SnackbarHelper.showInfo(
          'You don\'t have any completed transactions with agents or loan officers yet.',
          duration: const Duration(seconds: 4),
        );
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ ==========================================');
        print('❌ Error loading completed professionals: $e');
        print('❌ Error type: ${e.runtimeType}');
        if (e is Exception) {
          print('❌ Error message: ${e.toString()}');
        }
        print('❌ ==========================================');
      }
      SnackbarHelper.showError('Failed to load professionals: ${e.toString()}');
    } finally {
      _isLoadingProfessionals.value = false;
    }
  }

  Future<void> _loadAllLoanOfficers() async {
    try {
      final officers = await _loanOfficerService.getAllLoanOfficers();
      final map = <String, CompletedProfessional>{};

      for (final officer in officers) {
        if (officer.id.isEmpty) continue;
        map[officer.id] = CompletedProfessional(
          id: officer.id,
          name: officer.name.isNotEmpty ? officer.name : 'Loan Officer',
          type: 'loanOfficer',
          profileImage: officer.profileImage,
          company: officer.company.isNotEmpty ? officer.company : null,
          leadId: null,
          completedAt: officer.lastActiveAt ?? officer.createdAt,
        );
      }

      _loanOfficerProfessionals.value = map.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to load loan officers for survey selection: $e');
      }
    }
  }

  void setSelectedTab(int index) {
    _selectedTabIndex.value = index;
  }

  void setAgentSearchQuery(String value) {
    _agentSearchQuery.value = value;
  }

  void setLoanOfficerSearchQuery(String value) {
    _loanOfficerSearchQuery.value = value;
  }

  /// Select a professional and start corresponding survey
  void selectProfessional(CompletedProfessional professional) {
    _selectedProfessional.value = professional;
    
    // Set survey parameters by selected professional type.
    if (professional.type == 'loanOfficer') {
      surveyType = 'loanOfficer';
      loanOfficerId = professional.id;
      loanOfficerName = professional.name;
      // Keep legacy fields for backward compatibility in shared submit API.
      agentId = professional.id;
      agentName = professional.name;
    } else {
      surveyType = 'agent';
      agentId = professional.id;
      agentName = professional.name;
      loanOfficerId = null;
      loanOfficerName = null;
    }
    transactionId = professional.leadId ?? '';
    
    // Hide selection screen and start survey
    _showSelectionScreen.value = false;
    _currentStep.value = 0;
    
    if (kDebugMode) {
      print('✅ Selected professional: ${professional.name} (${professional.type})');
      print('   Starting survey for ID: ${professional.id}');
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
    String receivedExpectedRebate = agentRebateExpected.value ?? 'Not sure';
    String rebateAppliedAsCreditClosing = agentRebateMethod.value ?? 'Other';
    String signedRebateDisclosure = agentSignedDisclosure.value ?? 'Not sure';
    String receivingRebateEasy = agentRebateEase.value ?? 'Neutral';
    String agentRecommended = agentRecommend.value ?? 'Not sure';
    String comment = commentsController.text.trim();
    double rating = isAgentSurvey ? agentRating.value : loSatisfaction.value;
    final selectedId =
        selectedProfessional?.id.isNotEmpty == true
            ? selectedProfessional?.id
            : (agentId.isNotEmpty
                  ? agentId
                  : ((loanOfficerId ?? '').isNotEmpty ? loanOfficerId : null));

    Future<bool> triggerMandatoryAddReview(String reason) async {
      if (selectedId == null || selectedId.isEmpty) {
        print(
          '⚠️ addReview skipped: missing professionalId '
          '($reason). agentId=$agentId, loanOfficerId=$loanOfficerId, selectedProfessional=${selectedProfessional?.id}',
        );
        return false;
      }
      final reviewText = comment.isNotEmpty
          ? comment
          : (isAgentSurvey
              ? 'Great support and communication throughout the process.'
              : 'Excellent loan guidance and professional support.');
      print(
        '📡 Triggering mandatory addReview ($reason) '
        '(type=${isAgentSurvey ? "agent" : "loanOfficer"}, professionalId=$selectedId)',
      );
      return _surveyService.submitBuyerReviewSilently(
        currentUserId: userId,
        professionalId: selectedId,
        rating: rating,
        review: reviewText,
      );
    }

    try {
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
        rebateFromAgent: isAgentSurvey ? agentRebateAmount.value : 0,
        receivedExpectedRebate: receivedExpectedRebate,
        rebateAppliedAsCreditClosing: rebateAppliedAsCreditClosing,
        signedRebateDisclosure: signedRebateDisclosure,
        receivingRebateEasy: receivingRebateEasy,
        agentRecommended: agentRecommended,
        comment: comment.isNotEmpty ? comment : null,
        rating: rating,
        surveyType: surveyType,
        type:
            selectedProfessional?.type ??
            (isAgentSurvey ? 'agent' : 'loanOfficer'),
        professionalId: selectedId,
        professionalType:
            selectedProfessional?.type ??
            (isAgentSurvey ? 'agent' : 'loanOfficer'),
        loSatisfaction: isAgentSurvey ? null : loSatisfaction.value,
        loExplainedOptions: isAgentSurvey ? null : loExplainedOptions.value,
        loCommunication: isAgentSurvey ? null : loCommunication.value,
        loRebateHelp: isAgentSurvey ? null : loRebateHelp.value,
        loEase: isAgentSurvey ? null : loEase.value,
        loProfessional: isAgentSurvey ? null : loProfessional.value,
        loClosedOnTime: isAgentSurvey ? null : loClosedOnTime.value,
        loRecommend: isAgentSurvey ? null : loRecommend.value,
      );
      final reviewAdded = await triggerMandatoryAddReview(
        'after survey success',
      );
      if (reviewAdded) {
        // Avoid overlay teardown race: navigate first, then show snackbar.
        SnackbarHelper.dismissCurrent();
        Get.offAllNamed(AppPages.MAIN);
        Future.delayed(const Duration(milliseconds: 250), () {
          SnackbarHelper.showSuccess(
            'Thank you! Your review has been submitted successfully.',
            title: 'Review Submitted',
            duration: const Duration(seconds: 3),
          );
        });
      }
    } catch (e) {
      try {
        final reviewAdded = await triggerMandatoryAddReview(
          'after survey failure',
        );
        if (reviewAdded) {
          // Avoid overlay teardown race: navigate first, then show snackbar.
          SnackbarHelper.dismissCurrent();
          Get.offAllNamed(AppPages.MAIN);
          Future.delayed(const Duration(milliseconds: 250), () {
            SnackbarHelper.showSuccess(
              'Thank you! Your review has been submitted successfully.',
              title: 'Review Submitted',
              duration: const Duration(seconds: 3),
            );
          });
          return;
        }
      } catch (_) {}
      print('❌ Error submitting survey: $e');
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
