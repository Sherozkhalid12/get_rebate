import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/services/lead_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart';

class SellerLeadFormController extends GetxController {
  final _leadService = LeadService();
  final _authController = Get.find<AuthController>();
  
  // Store property and agent info from arguments
  Map<String, dynamic>? _property;
  Map<String, dynamic>? _agent;
  // Form controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final propertyAddressController = TextEditingController();
  final cityController = TextEditingController();
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
    
    // Get arguments (property and agent info)
    final arguments = Get.arguments;
    if (arguments != null) {
      _property = arguments['property'] as Map<String, dynamic>?;
      _agent = arguments['agent'] as Map<String, dynamic>?;
      
      if (kDebugMode) {
        print('📋 Seller Lead Form initialized');
        print('   Property: ${_property?['id'] ?? 'N/A'}');
        print('   Agent: ${_agent?['id'] ?? 'N/A'}');
      }
    }
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
        _propertyType.value.isNotEmpty &&
        _estimatedValue.value.isNotEmpty &&
        _timeToSell.value.isNotEmpty &&
        _workingWithAgent.value.isNotEmpty &&
        _currentlyListed.value.isNotEmpty &&
        _alsoPlanningToBuy.value.isNotEmpty &&
        _motivation.value.isNotEmpty &&
        _rebateAwareness.value.isNotEmpty;
  }

  // Validate form and return specific error message
  String? validateForm() {
    if (fullNameController.text.trim().isEmpty) {
      return 'Please enter your full name';
    }

    if (emailController.text.trim().isEmpty) {
      return 'Please enter your email address';
    }

    // Email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text.trim())) {
      return 'Please enter a valid email address';
    }

    if (phoneController.text.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    // Basic phone validation (at least 10 digits)
    final phoneDigits = phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneDigits.length < 10) {
      return 'Please enter a valid phone number (at least 10 digits)';
    }

    if (propertyAddressController.text.trim().isEmpty) {
      return 'Please enter the property address';
    }

    if (cityController.text.trim().isEmpty) {
      return 'Please enter the city';
    }

    if (_propertyType.value.isEmpty) {
      return 'Please select the property type';
    }

    if (_estimatedValue.value.isEmpty) {
      return 'Please select the estimated property value';
    }

    if (_timeToSell.value.isEmpty) {
      return 'Please select when you are planning to sell';
    }

    if (_workingWithAgent.value.isEmpty) {
      return 'Please indicate if you are currently working with an agent';
    }

    if (_currentlyListed.value.isEmpty) {
      return 'Please indicate if the property is currently listed';
    }

    if (_alsoPlanningToBuy.value.isEmpty) {
      return 'Please indicate if you are also planning to buy a new home';
    }

    if (_motivation.value.isEmpty) {
      return 'Please indicate how motivated you are to sell';
    }

    if (_rebateAwareness.value.isEmpty) {
      return 'Please indicate if you know about commission rebates';
    }

    return null; // Form is valid
  }

  // Submit form
  Future<void> submitForm() async {
    if (kDebugMode) {
      print('🔘 Submit button pressed (Seller)');
    }

    // Validate form and show specific error message
    final validationError = validateForm();
    if (validationError != null) {
      if (kDebugMode) {
        print('❌ Form validation failed: $validationError');
      }
      CustomSnackbar.showValidation(validationError);
      return;
    }

    _isLoading.value = true;

    if (kDebugMode) {
      print('✅ Form validation passed, submitting...');
    }

    try {
      // Get current user
      final currentUser = _authController.currentUser;
      if (currentUser == null) {
        _isLoading.value = false;
        CustomSnackbar.showError('Please log in to submit a lead');
        return;
      }

      // Get agent ID from property or agent argument
      final agentId = _agent?['id']?.toString() ?? 
                     _property?['agent']?['id']?.toString() ?? 
                     _agent?['_id']?.toString() ??
                     _property?['agentId']?.toString();
      
      if (agentId == null || agentId.isEmpty) {
        _isLoading.value = false;
        CustomSnackbar.showError('Agent information is missing. Please try again.');
        return;
      }

      // Map form data to API format - only fields that exist in the frontend form
      final leadData = <String, dynamic>{
        'agentId': agentId,
        'currentUserId': currentUser.id,
        'leadType': 'seller', // Identify this as a seller lead
        'fullName': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'preferredContact': _preferredContactMethod.value.toLowerCase(),
      };

      // Optional fields - only add if they have values
      if (_bestTimeToReach.value.isNotEmpty) {
        leadData['bestTime'] = _bestTimeToReach.value;
      }

      // Property information
      leadData['propertyInformation'] = {
        'propertyAddress': propertyAddressController.text.trim(),
        'city': cityController.text.trim(),
      };

      if (yearBuiltController.text.trim().isNotEmpty) {
        leadData['propertyInformation']['yearBuilt'] = yearBuiltController.text.trim();
      }

      if (squareFootageController.text.trim().isNotEmpty) {
        leadData['propertyInformation']['squareFeet'] = squareFootageController.text.trim();
      }

      if (_propertyType.value.isNotEmpty) {
        leadData['propertyType'] = _propertyType.value;
      }

      if (_estimatedValue.value.isNotEmpty) {
        leadData['estimatedValue'] = _estimatedValue.value;
      }

      if (_bedrooms.value.isNotEmpty) {
        leadData['bedrooms'] = int.tryParse(_bedrooms.value.replaceAll('+', '')) ?? 0;
      }

      if (_bathrooms.value.isNotEmpty) {
        leadData['bathrooms'] = double.tryParse(_bathrooms.value.replaceAll('+', '')) ?? 0.0;
      }

      if (recentUpdatesController.text.trim().isNotEmpty) {
        leadData['renovation'] = recentUpdatesController.text.trim();
      }

      if (_timeToSell.value.isNotEmpty) {
        leadData['whenPlanningSell'] = _timeToSell.value;
      }

      if (_currentlyListed.value.isNotEmpty) {
        leadData['isPropertyListed'] = _currentlyListed.value.toLowerCase() == 'yes';
      }

      if (idealPriceController.text.trim().isNotEmpty) {
        leadData['idealSellingPrice'] = idealPriceController.text.trim();
      }

      if (_motivation.value.isNotEmpty) {
        leadData['howMotivatedToSell'] = _motivation.value;
      }

      if (_mostImportant.isNotEmpty) {
        leadData['mostImportantToYou'] = _mostImportant.join(', ');
      }

      if (_workingWithAgent.value.isNotEmpty) {
        leadData['workingWithAgent'] = _workingWithAgent.value.toLowerCase() == 'yes';
      }

      if (_rebateAwareness.value.isNotEmpty) {
        leadData['rebateAwareness'] = _rebateAwareness.value;
      }

      if (_howDidYouHear.value.isNotEmpty) {
        leadData['howHeard'] = _howDidYouHear.value;
      }

      if (commentsController.text.trim().isNotEmpty) {
        leadData['comments'] = commentsController.text.trim();
      }

      if (_showRebateCalculator.value.isNotEmpty) {
        leadData['howMuchRebateCouldBe'] = _showRebateCalculator.value;
      }

      if (_alsoPlanningToBuy.value.isNotEmpty) {
        leadData['alsoPlanningToBuy'] = _alsoPlanningToBuy.value.toLowerCase() == 'yes';
      }

      if (_currentlyLiving.value.isNotEmpty) {
        leadData['currentlyLiving'] = _currentlyLiving.value;
      }

      if (kDebugMode) {
        print('📤 Submitting seller lead...');
        print('   Agent ID: $agentId');
        print('   User ID: ${currentUser.id}');
      }

      // Submit to API - using unified createLead endpoint
      await _leadService.createLead(leadData, leadType: 'seller');

      // Reset loading state first
      _isLoading.value = false;

      // Reset form
      resetForm();

      // Navigate back first to ensure we have proper context
      Get.back();

      // Show success message after navigation (with delay to ensure context is ready)
      await Future.delayed(const Duration(milliseconds: 300));
      CustomSnackbar.showSuccess(
        'Lead Submitted Successfully!',
        'A local agent will contact you soon.',
      );
    } on DioException catch (e) {
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ DioException submitting seller lead: $e');
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
      }
      
      String errorMessage = 'Failed to submit lead form. Please try again.';
      
      if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid form data. Please check all fields and try again.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Please log in to submit a lead.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Agent not found. Please try again.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['message']?.toString() ?? 
                        errorData['error']?.toString() ?? 
                        errorMessage;
        } else if (errorData is String) {
          errorMessage = errorData;
        }
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network and try again.';
      }
      
      CustomSnackbar.showError(errorMessage);
    } catch (e) {
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ Unexpected error submitting seller lead: $e');
        print('   Error type: ${e.runtimeType}');
      }
      
      String errorMessage = 'An unexpected error occurred. Please try again.';
      if (e.toString().contains('Exception')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      CustomSnackbar.showError(errorMessage);
    }
  }


  void resetForm() {
    fullNameController.clear();
    emailController.clear();
    phoneController.clear();
    propertyAddressController.clear();
    cityController.clear();
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
    yearBuiltController.dispose();
    squareFootageController.dispose();
    recentUpdatesController.dispose();
    idealPriceController.dispose();
    commentsController.dispose();
    super.onClose();
  }
}
