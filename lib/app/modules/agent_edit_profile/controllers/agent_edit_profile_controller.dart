import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/models/user_model.dart';

class AgentEditProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final descriptionController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final companyNameController = TextEditingController();
  final websiteLinkController = TextEditingController();
  final googleReviewsLinkController = TextEditingController();
  final thirdPartReviewLinkController = TextEditingController();
  final serviceAreasController = TextEditingController();

  // Observable variables
  final _isLoading = false.obs;
  final _selectedProfilePic = Rxn<File>();
  final _selectedCompanyLogo = Rxn<File>();
  final _selectedVideo = Rxn<File>();
  final _videoThumbnail = Rxn<File>();
  final _dualAgencyState = Rxn<bool>();
  final _dualAgencyBrokerage = Rxn<bool>();
  final _licensedStates = <String>[].obs;
  final _areasOfExpertise = <String>[].obs;

  // API Base URL for static files
  // Using ApiConstants for centralized URL management
  static String get _baseUrl => ApiConstants.baseUrl;

  // Getters
  bool get isLoading => _isLoading.value;
  File? get selectedProfilePic => _selectedProfilePic.value;
  File? get selectedCompanyLogo => _selectedCompanyLogo.value;
  File? get selectedVideo => _selectedVideo.value;
  File? get videoThumbnail => _videoThumbnail.value;
  bool? get dualAgencyState => _dualAgencyState.value;
  bool? get dualAgencyBrokerage => _dualAgencyBrokerage.value;
  List<String> get licensedStates => _licensedStates;
  List<String> get areasOfExpertise => _areasOfExpertise;

  // Get profile picture URL - returns full URL if exists, null otherwise
  String? get profilePictureUrl {
    if (_selectedProfilePic.value != null) {
      // If a new picture is selected, return null (will use File)
      return null;
    }

    final user = _authController.currentUser;
    final profilePic = user?.profileImage;

    if (profilePic == null || profilePic.isEmpty) {
      return null;
    }

    // If profilePic already contains http/https, return as is
    if (profilePic.startsWith('http://') || profilePic.startsWith('https://')) {
      print('📸 Using full profile picture URL: $profilePic');
      return profilePic;
    }

    // Otherwise, prepend base URL
    // Handle both paths with and without leading slash
    String path = profilePic;
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    final fullUrl = '$_baseUrl$path';
    print('📸 Constructed profile picture URL: $fullUrl');
    print('   Base URL: $_baseUrl');
    print('   Profile Pic Path: $profilePic');
    return fullUrl;
  }

  // Get video URL - returns full URL if exists, null otherwise
  String? get videoUrl {
    if (_selectedVideo.value != null) {
      // If a new video is selected, return null (will use File)
      return null;
    }

    final user = _authController.currentUser;
    final video = user?.additionalData?['video'];

    if (video == null || video.toString().isEmpty) {
      return null;
    }

    final videoStr = video.toString();
    
    // If video already contains http/https, return as is
    if (videoStr.startsWith('http://') || videoStr.startsWith('https://')) {
      return videoStr;
    }

    // Otherwise, prepend base URL
    String path = videoStr;
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    return '$_baseUrl$path';
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  /// Converts full state name (e.g., "California") to state code (e.g., "CA")
  String _getStateCodeFromName(String name) {
    final stateMap = {
      'Alabama': 'AL',
      'Alaska': 'AK',
      'Arizona': 'AZ',
      'Arkansas': 'AR',
      'California': 'CA',
      'Colorado': 'CO',
      'Connecticut': 'CT',
      'Delaware': 'DE',
      'Florida': 'FL',
      'Georgia': 'GA',
      'Hawaii': 'HI',
      'Idaho': 'ID',
      'Illinois': 'IL',
      'Indiana': 'IN',
      'Iowa': 'IA',
      'Kansas': 'KS',
      'Kentucky': 'KY',
      'Louisiana': 'LA',
      'Maine': 'ME',
      'Maryland': 'MD',
      'Massachusetts': 'MA',
      'Michigan': 'MI',
      'Minnesota': 'MN',
      'Mississippi': 'MS',
      'Missouri': 'MO',
      'Montana': 'MT',
      'Nebraska': 'NE',
      'Nevada': 'NV',
      'New Hampshire': 'NH',
      'New Jersey': 'NJ',
      'New Mexico': 'NM',
      'New York': 'NY',
      'North Carolina': 'NC',
      'North Dakota': 'ND',
      'Ohio': 'OH',
      'Oklahoma': 'OK',
      'Oregon': 'OR',
      'Pennsylvania': 'PA',
      'Rhode Island': 'RI',
      'South Carolina': 'SC',
      'South Dakota': 'SD',
      'Tennessee': 'TN',
      'Texas': 'TX',
      'Utah': 'UT',
      'Vermont': 'VT',
      'Virginia': 'VA',
      'Washington': 'WA',
      'West Virginia': 'WV',
      'Wisconsin': 'WI',
      'Wyoming': 'WY',
    };
    // If already a code (2 letters), return as is
    if (name.length == 2 && name == name.toUpperCase()) {
      return name;
    }
    // Otherwise, try to find the code from the name
    return stateMap[name] ?? name; // Return code if found, otherwise return original
  }

  void _loadUserData() {
    final user = _authController.currentUser;
    if (user != null) {
      fullNameController.text = user.name;
      emailController.text = user.email;
      phoneController.text = user.phone ?? '';
      bioController.text = user.additionalData?['bio'] ?? '';
      descriptionController.text = user.additionalData?['description'] ?? '';
      licenseNumberController.text =
          user.additionalData?['liscenceNumber'] ?? '';
      companyNameController.text = user.additionalData?['CompanyName'] ?? '';
      websiteLinkController.text = user.additionalData?['website_link'] ?? '';
      googleReviewsLinkController.text =
          user.additionalData?['google_reviews_link'] ?? '';
      thirdPartReviewLinkController.text =
          user.additionalData?['thirdPartReviewLink'] ?? '';

      // Load service areas
      final serviceAreas = user.additionalData?['serviceAreas'];
      if (serviceAreas != null) {
        if (serviceAreas is List) {
          serviceAreasController.text = serviceAreas.join(', ');
        } else if (serviceAreas is String) {
          serviceAreasController.text = serviceAreas;
        }
      }

      // Load areas of expertise
      final expertise = user.additionalData?['areasOfExpertise'];
      if (expertise != null && expertise is List) {
        _areasOfExpertise.value = List<String>.from(expertise);
      }

      _dualAgencyState.value = user.additionalData?['dualAgencyState'];
      _dualAgencyBrokerage.value = user.additionalData?['dualAgencySBrokerage'];
      
      // Convert full state names to state codes for UI display
      final stateCodes = user.licensedStates
          .map((state) => _getStateCodeFromName(state))
          .where((code) => code.length == 2) // Only keep valid 2-letter codes
          .toList();
      _licensedStates.value = stateCodes;
    }
  }

  Future<void> pickProfilePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedProfilePic.value = File(image.path);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to pick image: ${e.toString()}');
    }
  }

  void removeProfilePicture() {
    _selectedProfilePic.value = null;
  }

  Future<void> pickCompanyLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedCompanyLogo.value = File(image.path);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to pick company logo: ${e.toString()}');
    }
  }

  void removeCompanyLogo() {
    _selectedCompanyLogo.value = null;
  }

  Future<void> pickVideo() async {
    // This will be called from the view to show the dialog
    // The actual picking is done in pickVideoFromSource
  }

  Future<void> pickVideoFromSource(ImageSource source) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
      );

      if (video != null) {
        _selectedVideo.value = File(video.path);
        if (kDebugMode) {
          print('✅ Video selected from ${source == ImageSource.gallery ? "Gallery" : "Camera"}');
          print('   Path: ${video.path}');
        }
        
        // Generate thumbnail for the selected video
        await _generateVideoThumbnail(File(video.path));
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking video: $e');
      }
      SnackbarHelper.showError(
        source == ImageSource.gallery
            ? 'Unable to access your videos. Please check app permissions and try again.'
            : 'Unable to record video. Please check app permissions and try again.',
      );
    }
  }

  Future<void> _generateVideoThumbnail(File videoFile) async {
    try {
      if (kDebugMode) {
        print('🎬 Generating video thumbnail...');
      }
      
      // Try to generate thumbnail using video_thumbnail package
      try {
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoFile.path,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 400,
          quality: 85,
        );

        if (thumbnailPath != null) {
          _videoThumbnail.value = File(thumbnailPath);
          if (kDebugMode) {
            print('✅ Video thumbnail generated: $thumbnailPath');
          }
          return;
        }
      } catch (pluginError) {
        // If plugin is not available, continue without thumbnail
        if (kDebugMode) {
          print('⚠️ Video thumbnail plugin not available: $pluginError');
          print('   Continuing without thumbnail - video will still be uploaded');
        }
      }
      
      // If thumbnail generation fails, set to null (UI will show fallback)
      _videoThumbnail.value = null;
      if (kDebugMode) {
        print('⚠️ Video thumbnail not available - will show fallback UI');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating video thumbnail: $e');
        print('   Video will still be uploaded without thumbnail');
      }
      _videoThumbnail.value = null;
    }
  }

  void removeVideo() {
    _selectedVideo.value = null;
    _videoThumbnail.value = null;
  }

  void setDualAgencyState(bool? value) {
    _dualAgencyState.value = value;
  }

  void setDualAgencyBrokerage(bool? value) {
    _dualAgencyBrokerage.value = value;
  }

  void toggleLicensedState(String state) {
    if (_licensedStates.contains(state)) {
      _licensedStates.remove(state);
    } else {
      _licensedStates.add(state);
    }
  }

  void toggleAreaOfExpertise(String expertise) {
    if (_areasOfExpertise.contains(expertise)) {
      _areasOfExpertise.remove(expertise);
    } else {
      _areasOfExpertise.add(expertise);
    }
  }

  bool isAreaOfExpertiseSelected(String expertise) {
    return _areasOfExpertise.contains(expertise);
  }

  Future<void> saveProfile() async {
    if (!_validateForm()) return;

    try {
      _isLoading.value = true;

      final currentUser = _authController.currentUser;
      if (currentUser == null) {
        SnackbarHelper.showError('User not found. Please login again.');
        return;
      }

      // Validate user ID - must be a valid MongoDB ObjectId, not a generated one
      if (currentUser.id.isEmpty || currentUser.id.startsWith('user_')) {
        SnackbarHelper.showError('Invalid user ID. Please logout and login again.');
        return;
      }

      // Prepare service areas list
      List<String>? serviceAreasList;
      if (serviceAreasController.text.trim().isNotEmpty) {
        serviceAreasList = serviceAreasController.text
            .trim()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      // Debug: Print user ID being used
      print('🔍 Using User ID for update: ${currentUser.id}');

      // Call API to update user
      await _authController.updateUserProfile(
        userId: currentUser.id,
        fullname: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : null,
        bio: bioController.text.trim().isNotEmpty
            ? bioController.text.trim()
            : null,
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : null,
        companyName: companyNameController.text.trim().isNotEmpty
            ? companyNameController.text.trim()
            : null,
        websiteLink: websiteLinkController.text.trim().isNotEmpty
            ? websiteLinkController.text.trim()
            : null,
        googleReviewsLink: googleReviewsLinkController.text.trim().isNotEmpty
            ? googleReviewsLinkController.text.trim()
            : null,
        clientReviewsLink: null, // Can be added as separate field if needed
        thirdPartReviewLink:
            thirdPartReviewLinkController.text.trim().isNotEmpty
            ? thirdPartReviewLinkController.text.trim()
            : null,
        serviceAreas: serviceAreasList,
        areasOfExpertise: _areasOfExpertise.isNotEmpty
            ? _areasOfExpertise.toList()
            : null,
        licensedStates: _licensedStates.isNotEmpty
            ? _licensedStates.toList()
            : null,
        dualAgencyState: _dualAgencyState.value,
        dualAgencySBrokerage: _dualAgencyBrokerage.value,
        profilePic: _selectedProfilePic.value,
        companyLogo: _selectedCompanyLogo.value,
        video: _selectedVideo.value,
      );

      // Success snackbar is shown in updateUserProfile method
      // Wait a moment for snackbar to be visible, then navigate back
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate back to previous screen instead of clearing stack
      // This preserves the navigation history and allows back button to work
      // Use Navigator directly to avoid Get.back() snackbar controller issues
      try {
        final navigator = Navigator.of(Get.context!);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          // If can't pop, navigate to home page based on user role
          final user = _authController.currentUser;
          if (user != null) {
            switch (user.role) {
              case UserRole.agent:
                Get.offAllNamed(AppPages.AGENT);
                break;
              case UserRole.buyerSeller:
                Get.offAllNamed(AppPages.MAIN);
                break;
              case UserRole.loanOfficer:
                Get.offAllNamed(AppPages.LOAN_OFFICER);
                break;
            }
          }
        }
      } catch (e) {
        // If Navigator fails, try Get.back() with error handling
        try {
          // Close any open snackbars first to avoid controller errors
          Get.closeCurrentSnackbar();
        } catch (_) {
          // Ignore snackbar close errors
        }
        
        try {
          Get.back();
        } catch (e2) {
          // Last resort: navigate to home page
          final user = _authController.currentUser;
          if (user != null) {
            switch (user.role) {
              case UserRole.agent:
                Get.offAllNamed(AppPages.AGENT);
                break;
              case UserRole.buyerSeller:
                Get.offAllNamed(AppPages.MAIN);
                break;
              case UserRole.loanOfficer:
                Get.offAllNamed(AppPages.LOAN_OFFICER);
                break;
            }
          }
        }
      }
    } catch (e) {
      // Error is already handled in updateUserProfile method
      // Just log it here
      print('Error updating profile: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (fullNameController.text.trim().isEmpty) {
      SnackbarHelper.showValidation('Please enter your full name');
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      SnackbarHelper.showValidation('Please enter your email');
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      SnackbarHelper.showValidation('Please enter a valid email');
      return false;
    }

    if (_dualAgencyState.value == null) {
      SnackbarHelper.showValidation('Please answer if dual agency is allowed in your state');
      return false;
    }

    if (_dualAgencyBrokerage.value == null) {
      SnackbarHelper.showValidation('Please answer if dual agency is allowed at your brokerage');
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    descriptionController.dispose();
    licenseNumberController.dispose();
    companyNameController.dispose();
    websiteLinkController.dispose();
    googleReviewsLinkController.dispose();
    thirdPartReviewLinkController.dispose();
    serviceAreasController.dispose();
    super.onClose();
  }
}
