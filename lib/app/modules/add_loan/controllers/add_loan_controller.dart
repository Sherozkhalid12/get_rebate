import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/loan_model.dart';
import 'package:getrebate/app/modules/loan_officer/controllers/loan_officer_controller.dart';

class AddLoanController extends GetxController {
  // Form controllers
  final borrowerNameController = TextEditingController();
  final borrowerEmailController = TextEditingController();
  final borrowerPhoneController = TextEditingController();
  final loanAmountController = TextEditingController();
  final interestRateController = TextEditingController();
  final propertyAddressController = TextEditingController();
  final notesController = TextEditingController();

  // Observable variables
  final _isLoading = false.obs;
  final _termInMonths = 360.obs;
  final _loanType = 'conventional'.obs;
  final _loanStatus = 'draft'.obs;

  // Loan types
  final List<String> loanTypes = ['conventional', 'FHA', 'VA', 'USDA', 'jumbo'];

  // Status options
  final List<String> statusOptions = [
    'draft',
    'pending',
    'approved',
    'funded',
    'closed',
  ];

  // Term options (in months)
  final List<int> termOptions = [180, 240, 300, 360, 480];

  // Getters
  bool get isLoading => _isLoading.value;
  int get termInMonths => _termInMonths.value;
  String get loanType => _loanType.value;
  String get loanStatus => _loanStatus.value;

  void updateTermInMonths(int value) {
    _termInMonths.value = value;
  }

  void updateLoanType(String value) {
    _loanType.value = value;
  }

  void updateLoanStatus(String value) {
    _loanStatus.value = value;
  }

  @override
  void onInit() {
    super.onInit();
    // Set default values
    _termInMonths.value = 360;
    _loanType.value = 'conventional';
    _loanStatus.value = 'draft';
  }

  Future<void> submitLoan() async {
    if (!_validateForm()) return;

    try {
      _isLoading.value = true;

      // Create loan model
      final loan = LoanModel(
        id: 'loan_${DateTime.now().millisecondsSinceEpoch}',
        loanOfficerId: 'loan_1', // In real app, get from auth
        borrowerName: borrowerNameController.text.trim(),
        borrowerEmail: borrowerEmailController.text.trim().isEmpty
            ? null
            : borrowerEmailController.text.trim(),
        borrowerPhone: borrowerPhoneController.text.trim().isEmpty
            ? null
            : borrowerPhoneController.text.trim(),
        loanAmount: double.parse(loanAmountController.text),
        interestRate: double.parse(interestRateController.text),
        termInMonths: _termInMonths.value,
        loanType: _loanType.value,
        status: _loanStatus.value,
        propertyAddress: propertyAddressController.text.trim().isEmpty
            ? null
            : propertyAddressController.text.trim(),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Get loan officer controller and add loan
      final loanOfficerController = Get.find<LoanOfficerController>();
      await loanOfficerController.addLoan(loan);

      // Navigate back
      Get.back();

      Get.snackbar(
        'Success',
        'Loan added successfully!',
        backgroundColor: Get.theme.primaryColor,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to add loan: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (borrowerNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter borrower name');
      return false;
    }

    if (loanAmountController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter loan amount');
      return false;
    }

    final loanAmount = double.tryParse(loanAmountController.text);
    if (loanAmount == null || loanAmount <= 0) {
      Get.snackbar('Error', 'Please enter a valid loan amount');
      return false;
    }

    if (interestRateController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter interest rate');
      return false;
    }

    final interestRate = double.tryParse(interestRateController.text);
    if (interestRate == null || interestRate < 0 || interestRate > 30) {
      Get.snackbar('Error', 'Please enter a valid interest rate (0-30)');
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    borrowerNameController.dispose();
    borrowerEmailController.dispose();
    borrowerPhoneController.dispose();
    loanAmountController.dispose();
    interestRateController.dispose();
    propertyAddressController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
