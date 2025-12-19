import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/services/lead_service.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:flutter/foundation.dart';

class BuyerLeadFormController extends GetxController {
  final _leadService = LeadService();
  final _authController = Get.find<AuthController>();
  
  // Store property and agent info from arguments
  Map<String, dynamic>? _property;
  Map<String, dynamic>? _agent;
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
    
    // Get arguments (property and agent info)
    final arguments = Get.arguments;
    if (arguments != null) {
      _property = arguments['property'] as Map<String, dynamic>?;
      _agent = arguments['agent'] as Map<String, dynamic>?;
      
      if (kDebugMode) {
        print('📋 Buyer Lead Form initialized');
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

    if (locationController.text.trim().isEmpty) {
      return 'Please enter where you are planning to buy or build';
    }

    if (_lookingTo.value.isEmpty) {
      return 'Please select whether you are buying or building';
    }

    if (_propertyTypes.isEmpty) {
      return 'Please select at least one property type';
    }

    if (_priceRange.value.isEmpty) {
      return 'Please select your price range';
    }

    if (_timeFrame.value.isEmpty) {
      return 'Please select your time frame to buy/build';
    }

    if (_workingWithAgent.value.isEmpty) {
      return 'Please indicate if you are currently working with an agent';
    }

    if (_preApproved.value.isEmpty) {
      return 'Please indicate if you have been pre-approved for a mortgage';
    }

    if (_rebateAwareness.value.isEmpty) {
      return 'Please indicate if you know about commission rebates';
    }

    return null; // Form is valid
  }

  // Submit form
  Future<void> submitForm() async {
    if (kDebugMode) {
      print('🔘 Submit button pressed');
    }

    // Validate form and show specific error message
    final validationError = validateForm();
    if (validationError != null) {
      if (kDebugMode) {
        print('❌ Form validation failed: $validationError');
      }
      SnackbarHelper.showValidation(validationError);
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
        SnackbarHelper.showError('Please log in to submit a lead');
        return;
      }

      // Get agent ID from property or agent argument
      final agentId = _agent?['id']?.toString() ?? 
                     _property?['agent']?['id']?.toString() ?? 
                     _agent?['_id']?.toString() ??
                     _property?['agentId']?.toString();
      
      if (agentId == null || agentId.isEmpty) {
        _isLoading.value = false;
        SnackbarHelper.showError('Agent information is missing. Please try again.');
        return;
      }

      // Map form data to API format - only fields that exist in the frontend form
      final leadData = <String, dynamic>{
        'agentId': agentId,
        'currentUserId': currentUser.id,
        'leadType': 'buyer', // Identify this as a buyer lead
        'fullName': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'preferredContact': _preferredContactMethod.value.toLowerCase(),
      };

      // Optional fields - only add if they have values
      if (_bestTimeToReach.value.isNotEmpty) {
        leadData['bestTime'] = _bestTimeToReach.value;
      }

      if (_lookingTo.value.isNotEmpty) {
        leadData['buyingOrBuilding'] = _lookingTo.value.toLowerCase().contains('build') 
            ? 'building' 
            : 'buying';
      }

      if (_propertyTypes.isNotEmpty) {
        leadData['propertyType'] = _propertyTypes.join(', ');
      }

      if (_priceRange.value.isNotEmpty) {
        leadData['priceRange'] = _priceRange.value;
      }

      if (_bedrooms.value.isNotEmpty) {
        leadData['bedrooms'] = int.tryParse(_bedrooms.value.replaceAll('+', '')) ?? 0;
      }

      if (_bathrooms.value.isNotEmpty) {
        leadData['bathrooms'] = double.tryParse(_bathrooms.value.replaceAll('+', '')) ?? 0.0;
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

      // Comments - combine if both exist
      final comments = <String>[];
      if (commentsController.text.trim().isNotEmpty) {
        comments.add(commentsController.text.trim());
      }
      if (mustHaveFeaturesController.text.trim().isNotEmpty) {
        comments.add('Must have features: ${mustHaveFeaturesController.text.trim()}');
      }
      if (comments.isNotEmpty) {
        leadData['comments'] = comments.join(' | ');
      }

      // Currently living
      if (_currentlyLiving.value.isNotEmpty) {
        leadData['currentlyLiving'] = _currentlyLiving.value;
      }

      // Time frame
      if (_timeFrame.value.isNotEmpty) {
        leadData['timeFrame'] = _timeFrame.value;
      }

      // Pre-approved
      if (_preApproved.value.isNotEmpty) {
        leadData['preApproved'] = _preApproved.value;
      }

      // Search for loan officers
      if (_searchForLoanOfficers.value.isNotEmpty) {
        leadData['searchForLoanOfficers'] = _searchForLoanOfficers.value;
      }

      // Add property information if available
      if (_property != null) {
        leadData['propertyInformation'] = {
          'propertyAddress': _property!['address']?.toString() ?? locationController.text.trim(),
          'city': _property!['city']?.toString() ?? '',
          'zipCode': _property!['zip']?.toString() ?? '',
          'yearBuilt': _property!['yearBuilt']?.toString() ?? '',
          'squareFeet': _property!['sqft']?.toString() ?? '',
        };
      } else if (locationController.text.trim().isNotEmpty) {
        // If no property but location is provided
        leadData['propertyInformation'] = {
          'propertyAddress': locationController.text.trim(),
          'city': '',
          'zipCode': '',
          'yearBuilt': '',
          'squareFeet': '',
        };
      }

      if (kDebugMode) {
        print('📤 Submitting buyer lead...');
        print('   Agent ID: $agentId');
        print('   User ID: ${currentUser.id}');
      }

      // Submit to API - using unified createLead endpoint
      await _leadService.createLead(leadData, leadType: 'buyer');

      // Reset loading state first
      _isLoading.value = false;

      // Reset form
      resetForm();

      // Navigate back first to ensure we have proper context
      Navigator.pop(Get.context!);

      // Show success message after navigation (with delay to ensure context is ready)
      await Future.delayed(const Duration(milliseconds: 300));
      SnackbarHelper.showSuccess(
        'A local agent will contact you soon.',
        title: 'Lead Submitted Successfully!',
      );
    } on DioException catch (e) {
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ DioException submitting buyer lead: $e');
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
      
      SnackbarHelper.showError(errorMessage);
    } catch (e) {
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ Unexpected error submitting buyer lead: $e');
        print('   Error type: ${e.runtimeType}');
      }
      
      String errorMessage = 'An unexpected error occurred. Please try again.';
      if (e.toString().contains('Exception')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      SnackbarHelper.showError(errorMessage);
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
