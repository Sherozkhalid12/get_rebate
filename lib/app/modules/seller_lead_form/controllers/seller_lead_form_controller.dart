import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SellerLeadFormController extends GetxController {
  // Form controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final propertyAddressController = TextEditingController();
  final cityController = TextEditingController();
  final zipController = TextEditingController();
  final yearBuiltController = TextEditingController();
  final squareFootageController = TextEditingController();
  final recentUpdatesController = TextEditingController();
  final idealPriceController = TextEditingController();
  final commentsController = TextEditingController();

  // Observable variables
  final _isLoading = false.obs;
  final _preferredContactMethod = 'Email'.obs;
  final _bestTimeToReach = ''.obs;
  final _propertyType = ''.obs;
  final _estimatedValue = ''.obs;
  final _bedrooms = ''.obs;
  final _bathrooms = ''.obs;
  final _timeToSell = ''.obs;
  final _workingWithAgent = ''.obs;
  final _currentlyListed = ''.obs;
  final _alsoPlanningToBuy = ''.obs;
  final _currentlyLiving = ''.obs;
  final _motivation = ''.obs;
  final _mostImportant = <String>[].obs;
  final _rebateAwareness = ''.obs;
  final _showRebateCalculator = ''.obs;
  final _howDidYouHear = ''.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get preferredContactMethod => _preferredContactMethod.value;
  String get bestTimeToReach => _bestTimeToReach.value;
  String get propertyType => _propertyType.value;
  String get estimatedValue => _estimatedValue.value;
  String get bedrooms => _bedrooms.value;
  String get bathrooms => _bathrooms.value;
  String get timeToSell => _timeToSell.value;
  String get workingWithAgent => _workingWithAgent.value;
  String get currentlyListed => _currentlyListed.value;
  String get alsoPlanningToBuy => _alsoPlanningToBuy.value;
  String get currentlyLiving => _currentlyLiving.value;
  String get motivation => _motivation.value;
  List<String> get mostImportant => _mostImportant;
  String get rebateAwareness => _rebateAwareness.value;
  String get showRebateCalculator => _showRebateCalculator.value;
  String get howDidYouHear => _howDidYouHear.value;

  // Options
  final List<String> contactMethods = ['Call', 'Text', 'Email'];
  final List<String> bestTimes = ['Morning', 'Afternoon', 'Evening'];
  final List<String> propertyTypeOptions = [
    'Single-family',
    'Townhome',
    'Condo',
    'Duplex',
    'Land',
    'Investment Property',
  ];
  final List<String> estimatedValues = [
    'Under \$100k',
    '\$100k - \$200k',
    '\$200k - \$300k',
    '\$300k - \$400k',
    '\$400k - \$500k',
    '\$500k - \$750k',
    '\$750k - \$1M',
    'Over \$1M',
  ];
  final List<String> bedroomOptions = ['1', '2', '3', '4', '5+'];
  final List<String> bathroomOptions = [
    '1',
    '1.5',
    '2',
    '2.5',
    '3',
    '3.5',
    '4',
    '4.5',
    '5+',
  ];
  final List<String> timeToSellOptions = [
    'Immediately',
    '1-3 months',
    '3-6 months',
    '6-12 months',
    'Over a year',
  ];
  final List<String> yesNoOptions = ['Yes', 'No'];
  final List<String> alsoPlanningOptions = ['Yes', 'No', 'Not sure yet'];
  final List<String> livingOptions = [
    'Yes, owner-occupied',
    'No, vacant',
    'No, rented',
  ];
  final List<String> motivationOptions = [
    'Just curious',
    'Considering',
    'Ready to list soon',
    'Actively looking for agent',
  ];
  final List<String> mostImportantOptions = [
    'Highest price',
    'Fast sale',
    'Rebate savings',
    'Local expertise',
    'Marketing exposure',
  ];
  final List<String> rebateAwarenessOptions = ['Yes', 'No, tell me more'];
  final List<String> showRebateOptions = ['Yes', 'Not yet'];
  final List<String> howDidYouHearOptions = [
    'Google',
    'Social Media',
    'Referral',
    'Other',
  ];

  @override
  void onInit() {
    super.onInit();
    // Set default values
    _preferredContactMethod.value = 'Email';
  }

  // Setters
  void setPreferredContactMethod(String method) {
    _preferredContactMethod.value = method;
  }

  void setBestTimeToReach(String time) {
    _bestTimeToReach.value = time;
  }

  void setPropertyType(String type) {
    _propertyType.value = type;
  }

  void setEstimatedValue(String value) {
    _estimatedValue.value = value;
  }

  void setBedrooms(String beds) {
    _bedrooms.value = beds;
  }

  void setBathrooms(String baths) {
    _bathrooms.value = baths;
  }

  void setTimeToSell(String time) {
    _timeToSell.value = time;
  }

  void setWorkingWithAgent(String option) {
    _workingWithAgent.value = option;
  }

  void setCurrentlyListed(String option) {
    _currentlyListed.value = option;
  }

  void setAlsoPlanningToBuy(String option) {
    _alsoPlanningToBuy.value = option;
  }

  void setCurrentlyLiving(String option) {
    _currentlyLiving.value = option;
  }

  void setMotivation(String option) {
    _motivation.value = option;
  }

  void toggleMostImportant(String option) {
    if (_mostImportant.contains(option)) {
      _mostImportant.remove(option);
    } else {
      _mostImportant.add(option);
    }
  }

  void setRebateAwareness(String option) {
    _rebateAwareness.value = option;
  }

  void setShowRebateCalculator(String option) {
    _showRebateCalculator.value = option;
  }

  void setHowDidYouHear(String option) {
    _howDidYouHear.value = option;
  }

  // Validation
  bool isFormValid() {
    return fullNameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        propertyAddressController.text.isNotEmpty &&
        cityController.text.isNotEmpty &&
        zipController.text.isNotEmpty &&
        _propertyType.value.isNotEmpty &&
        _estimatedValue.value.isNotEmpty &&
        _timeToSell.value.isNotEmpty &&
        _workingWithAgent.value.isNotEmpty &&
        _currentlyListed.value.isNotEmpty &&
        _alsoPlanningToBuy.value.isNotEmpty &&
        _motivation.value.isNotEmpty &&
        _rebateAwareness.value.isNotEmpty;
  }

  // Submit form
  Future<void> submitForm() async {
    if (!isFormValid()) {
      Get.snackbar('Error', 'Please fill in all required fields');
      return;
    }

    _isLoading.value = true;

    try {
      // TODO: Implement API call to submit lead form
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      Get.snackbar(
        'Success',
        'Your information has been submitted successfully! A local agent will contact you soon.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Reset form
      resetForm();

      // Navigate back or to next screen
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit form. Please try again.');
    } finally {
      _isLoading.value = false;
    }
  }

  void resetForm() {
    fullNameController.clear();
    emailController.clear();
    phoneController.clear();
    propertyAddressController.clear();
    cityController.clear();
    zipController.clear();
    yearBuiltController.clear();
    squareFootageController.clear();
    recentUpdatesController.clear();
    idealPriceController.clear();
    commentsController.clear();

    _preferredContactMethod.value = 'Email';
    _bestTimeToReach.value = '';
    _propertyType.value = '';
    _estimatedValue.value = '';
    _bedrooms.value = '';
    _bathrooms.value = '';
    _timeToSell.value = '';
    _workingWithAgent.value = '';
    _currentlyListed.value = '';
    _alsoPlanningToBuy.value = '';
    _currentlyLiving.value = '';
    _motivation.value = '';
    _mostImportant.clear();
    _rebateAwareness.value = '';
    _showRebateCalculator.value = '';
    _howDidYouHear.value = '';
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    propertyAddressController.dispose();
    cityController.dispose();
    zipController.dispose();
    yearBuiltController.dispose();
    squareFootageController.dispose();
    recentUpdatesController.dispose();
    idealPriceController.dispose();
    commentsController.dispose();
    super.onClose();
  }
}
