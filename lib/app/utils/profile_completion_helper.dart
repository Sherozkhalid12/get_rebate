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
        _isEmpty(ad['zipCode']) ||
        !_boolFrom(ad['dualAgencyState']) ||
        !_boolFrom(ad['dualAgencySBrokerage']) ||
        !_boolFrom(ad['verificationStatement']);
  }

  static bool _loanOfficerIncomplete(UserModel user) {
    final ad = user.additionalData ?? {};
    return _isEmpty(user.phone) ||
        _isEmpty(ad['CompanyName']) ||
        _isEmpty(ad['liscenceNumber']) ||
        user.licensedStates.isEmpty ||
        _isEmpty(ad['zipCode']) ||
        !_boolFrom(ad['verificationStatement']);
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
