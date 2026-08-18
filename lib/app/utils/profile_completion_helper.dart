import 'package:getrebate/app/models/user_model.dart';

/// Detects whether a user still needs signup-equivalent profile details after social login.
class ProfileCompletionHelper {
  ProfileCompletionHelper._();

  static bool needsCompletion(UserModel? user) {
    if (user == null) return false;

    switch (user.role) {
      case UserRole.buyerSeller:
        return user.name.trim().isEmpty;
      case UserRole.agent:
        return _agentIncomplete(user);
      case UserRole.loanOfficer:
        return _loanOfficerIncomplete(user);
    }
  }

  static bool _agentIncomplete(UserModel user) {
    final ad = user.additionalData ?? {};
    return _isEmpty(user.phone) ||
        _isEmpty(ad['CompanyName']) ||
        _isEmpty(ad['liscenceNumber']) ||
        user.licensedStates.isEmpty ||
        _hasNoZip(ad) ||
        // Dual-agency consents: any non-null value (true OR false) is a valid
        // answer. Treating false as incomplete traps users on the
        // Complete-Profile screen on every app restart.
        ad['dualAgencyState'] == null ||
        ad['dualAgencySBrokerage'] == null ||
        // Verification statement MUST be true (legal consent).
        !_boolFrom(ad['verificationStatement']);
  }

  static bool _loanOfficerIncomplete(UserModel user) {
    final ad = user.additionalData ?? {};
    return _isEmpty(user.phone) ||
        _isEmpty(ad['CompanyName']) ||
        _isEmpty(ad['liscenceNumber']) ||
        user.licensedStates.isEmpty ||
        _hasNoZip(ad) ||
        !_boolFrom(ad['verificationStatement']);
  }

  // Office ZIP can live under any of these keys depending on which path
  // populated the user: edit-profile flow stores 'zipCode', fresh signup
  // from API only stores 'serviceAreas' / 'serviceZipCodes'. Accept any.
  static bool _hasNoZip(Map<String, dynamic> ad) {
    return _isEmpty(ad['zipCode']) &&
        _isEmpty(ad['serviceAreas']) &&
        _isEmpty(ad['serviceZipCodes']);
  }

  static bool _isEmpty(dynamic value) {
    if (value == null) return true;
    return value.toString().trim().isEmpty;
  }

  static bool _boolFrom(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    final s = value.toString().toLowerCase();
    return s == 'true' || s == '1';
  }
}
