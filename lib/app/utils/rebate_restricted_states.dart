/// States that ban or restrict real estate rebates.
/// Buyers in these states may not receive rebates; estimates are for reference only.
class RebateRestrictedStates {
  RebateRestrictedStates._();

  /// State codes that do not allow rebates (Alabama, Alaska, Kansas, Louisiana,
  /// Mississippi, Missouri, Oklahoma, Oregon, Tennessee, Iowa).
  static const Set<String> stateCodes = {
    'AL', // Alabama
    'AK', // Alaska
    'KS', // Kansas
    'LA', // Louisiana
    'MS', // Mississippi
    'MO', // Missouri
    'OK', // Oklahoma
    'OR', // Oregon
    'TN', // Tennessee
    'IA', // Iowa
  };

  /// Full state names mapped to codes (for lookup).
  static const Map<String, String> _stateNameToCode = {
    'Alabama': 'AL',
    'Alaska': 'AK',
    'Kansas': 'KS',
    'Louisiana': 'LA',
    'Mississippi': 'MS',
    'Missouri': 'MO',
    'Oklahoma': 'OK',
    'Oregon': 'OR',
    'Tennessee': 'TN',
    'Iowa': 'IA',
  };

  /// Returns true if the given state (code or full name) restricts rebates.
  static bool isRestricted(String state) {
    if (state.isEmpty) return false;
    final trimmed = state.trim();
    final upper = trimmed.toUpperCase();
    if (stateCodes.contains(upper)) return true;
    final code = _stateNameToCode[trimmed];
    return code != null && stateCodes.contains(code);
  }

  /// Short message for restricted states.
  static const String restrictedStateNotice =
      'Real estate rebates are not permitted in this state. '
      'The estimates below are for reference only and do not apply to transactions in this location.';
}
