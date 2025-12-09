import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostClosingSurveyController extends GetxController {
  late final String agentId, agentName, userId, transactionId;
  late final String? loanOfficerId, loanOfficerName;
  late final bool isBuyer;
  late final String surveyType; // 'agent' or 'loanOfficer'

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

  int get currentStep => _currentStep.value;
  bool get isLoading => _isLoading.value;
  bool get isAgentSurvey => surveyType == 'agent';
  int get totalSteps => isAgentSurvey ? 8 : 10;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    agentId = args['agentId'];
    agentName = args['agentName'];
    userId = args['userId'];
    transactionId = args['transactionId'];
    isBuyer = args['isBuyer'] ?? true;
    surveyType = args['surveyType'] ?? 'agent';
    loanOfficerId = args['loanOfficerId'];
    loanOfficerName = args['loanOfficerName'];
  }

  void nextStep() {
    if (_currentStep.value < totalSteps - 1) {
      _currentStep.value++; // Now works!
    }
  }

  void previousStep() {
    if (_currentStep.value > 0) {
      _currentStep.value--; // Now works!
    }
  }


  bool canProceed() {
    if (isAgentSurvey) {
      return switch (currentStep) {
        0 => agentRebateAmount > 0,
        1 => agentRebateExpected.value != null,
        4 => agentRebateEase.value != null,
        7 => agentRating > 0,
        _ => true,
      };
    } else {
      return currentStep == 0 ? loSatisfaction > 0 : true;
    }
  }

  Future<void> submitSurvey() async {
    _isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2));

    Get.snackbar('Thank You!', 'Your feedback was saved!',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green.shade700);

    Get.back();
    _isLoading.value = false;
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