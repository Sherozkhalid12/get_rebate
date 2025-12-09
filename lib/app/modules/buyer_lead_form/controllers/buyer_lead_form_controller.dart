import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BuyerLeadFormController extends GetxController {
  // Form controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final mustHaveFeaturesController = TextEditingController();
  final commentsController = TextEditingController();

  // Observable variables
  final _isLoading = false.obs;
  final _preferredContactMethod = 'Email'.obs;
  final _bestTimeToReach = ''.obs;
  final _lookingTo = ''.obs;
  final _currentlyLiving = ''.obs;
  final _propertyTypes = <String>[].obs;
  final _priceRange = ''.obs;
  final _bedrooms = ''.obs;
  final _bathrooms = ''.obs;
  final _timeFrame = ''.obs;
  final _workingWithAgent = ''.obs;
  final _preApproved = ''.obs;
  final _searchForLoanOfficers = ''.obs;
  final _rebateAwareness = ''.obs;
  final _howDidYouHear = ''.obs;
  final _autoMLSSearch = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get preferredContactMethod => _preferredContactMethod.value;
  String get bestTimeToReach => _bestTimeToReach.value;
  String get lookingTo => _lookingTo.value;
  String get currentlyLiving => _currentlyLiving.value;
  List<String> get propertyTypes => _propertyTypes;
  String get priceRange => _priceRange.value;
  String get bedrooms => _bedrooms.value;
  String get bathrooms => _bathrooms.value;
  String get timeFrame => _timeFrame.value;
  String get workingWithAgent => _workingWithAgent.value;
  String get preApproved => _preApproved.value;
  String get searchForLoanOfficers => _searchForLoanOfficers.value;
  String get rebateAwareness => _rebateAwareness.value;
  String get howDidYouHear => _howDidYouHear.value;
  bool get autoMLSSearch => _autoMLSSearch.value;

  // Options
  final List<String> contactMethods = ['Call', 'Text', 'Email'];
  final List<String> bestTimes = ['Morning', 'Afternoon', 'Evening'];
  final List<String> lookingToOptions = [
    'Buy existing home',
    'Build new home',
    'Both',
  ];
  final List<String> livingOptions = ['Local', 'Relocating from out of state'];
  final List<String> propertyTypeOptions = [
    'Single-family',
    'Townhome',
    'Condo',
    'Duplex',
    'Investment',
    'Vacation/2nd Home',
  ];
  final List<String> priceRanges = [
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
  final List<String> timeFrames = [
    '1-3 months',
    '3-6 months',
    '6-12 months',
    'Over a year',
  ];
  final List<String> yesNoOptions = ['Yes', 'No'];
  final List<String> preApprovedOptions = ['Yes', 'Not yet', 'Paying cash'];
  final List<String> loanOfficerOptions = ['Yes', 'Maybe later', 'No'];
  final List<String> rebateAwarenessOptions = ['Yes', 'No, tell me more'];
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
    _lookingTo.value = 'Buy existing home';
  }

  // Setters
  void setPreferredContactMethod(String method) {
    _preferredContactMethod.value = method;
  }

  void setBestTimeToReach(String time) {
    _bestTimeToReach.value = time;
  }

  void setLookingTo(String option) {
    _lookingTo.value = option;
  }

  void setCurrentlyLiving(String option) {
    _currentlyLiving.value = option;
  }

  void togglePropertyType(String type) {
    if (_propertyTypes.contains(type)) {
      _propertyTypes.remove(type);
    } else {
      _propertyTypes.add(type);
    }
  }

  void setPriceRange(String range) {
    _priceRange.value = range;
  }

  void setBedrooms(String beds) {
    _bedrooms.value = beds;
  }

  void setBathrooms(String baths) {
    _bathrooms.value = baths;
  }

  void setTimeFrame(String frame) {
    _timeFrame.value = frame;
  }

  void setWorkingWithAgent(String option) {
    _workingWithAgent.value = option;
  }

  void setPreApproved(String option) {
    _preApproved.value = option;
  }

  void setSearchForLoanOfficers(String option) {
    _searchForLoanOfficers.value = option;
  }

  void setRebateAwareness(String option) {
    _rebateAwareness.value = option;
  }

  void setHowDidYouHear(String option) {
    _howDidYouHear.value = option;
  }

  void toggleAutoMLSSearch() {
    _autoMLSSearch.value = !_autoMLSSearch.value;
  }

  // Validation
  bool isFormValid() {
    return fullNameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        locationController.text.isNotEmpty &&
        _lookingTo.value.isNotEmpty &&
        _propertyTypes.isNotEmpty &&
        _priceRange.value.isNotEmpty &&
        _timeFrame.value.isNotEmpty &&
        _workingWithAgent.value.isNotEmpty &&
        _preApproved.value.isNotEmpty &&
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
    locationController.clear();
    mustHaveFeaturesController.clear();
    commentsController.clear();

    _preferredContactMethod.value = 'Email';
    _bestTimeToReach.value = '';
    _lookingTo.value = 'Buy existing home';
    _currentlyLiving.value = '';
    _propertyTypes.clear();
    _priceRange.value = '';
    _bedrooms.value = '';
    _bathrooms.value = '';
    _timeFrame.value = '';
    _workingWithAgent.value = '';
    _preApproved.value = '';
    _searchForLoanOfficers.value = '';
    _rebateAwareness.value = '';
    _howDidYouHear.value = '';
    _autoMLSSearch.value = false;
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    mustHaveFeaturesController.dispose();
    commentsController.dispose();
    super.onClose();
  }
}
