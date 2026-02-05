import 'dart:io';
import 'package:getrebate/app/models/user_model.dart';

/// Holds signup payload for OTP flow. Used to avoid passing File/UserRole
/// through Get.arguments, which can cause GetX route issues.
class PendingSignUpStore {
  PendingSignUpStore._();
  static final PendingSignUpStore _instance = PendingSignUpStore._();
  static PendingSignUpStore get instance => _instance;

  String? _email;
  String? _password;
  String? _name;
  UserRole? _role;
  String? _phone;
  List<String>? _licensedStates;
  Map<String, dynamic>? _additionalData;
  File? _profilePic;
  File? _companyLogo;
  File? _video;

  void set({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    List<String>? licensedStates,
    Map<String, dynamic>? additionalData,
    File? profilePic,
    File? companyLogo,
    File? video,
  }) {
    _email = email;
    _password = password;
    _name = name;
    _role = role;
    _phone = phone;
    _licensedStates = licensedStates;
    _additionalData = additionalData;
    _profilePic = profilePic;
    _companyLogo = companyLogo;
    _video = video;
  }

  PendingSignUpData? take() {
    if (_email == null || _password == null || _name == null || _role == null) {
      return null;
    }
    final data = PendingSignUpData(
      email: _email!,
      password: _password!,
      name: _name!,
      role: _role!,
      phone: _phone,
      licensedStates: _licensedStates,
      additionalData: _additionalData,
      profilePic: _profilePic,
      companyLogo: _companyLogo,
      video: _video,
    );
    clear();
    return data;
  }

  void clear() {
    _email = null;
    _password = null;
    _name = null;
    _role = null;
    _phone = null;
    _licensedStates = null;
    _additionalData = null;
    _profilePic = null;
    _companyLogo = null;
    _video = null;
  }

  bool get hasData =>
      _email != null &&
      _password != null &&
      _name != null &&
      _role != null;
}

class PendingSignUpData {
  final String email;
  final String password;
  final String name;
  final UserRole role;
  final String? phone;
  final List<String>? licensedStates;
  final Map<String, dynamic>? additionalData;
  final File? profilePic;
  final File? companyLogo;
  final File? video;

  PendingSignUpData({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.phone,
    this.licensedStates,
    this.additionalData,
    this.profilePic,
    this.companyLogo,
    this.video,
  });
}
