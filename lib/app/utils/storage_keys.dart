/// Storage keys used across the app. Prefer these over raw strings.

/// Pre-fetched during splash for agent/loan officer. Value: bool.
/// Agent/LoanOfficer controllers read this on init to avoid loading flicker.
const String kFirstZipCodeClaimedStorageKey = 'first_zip_code_claimed';

/// Guest browse mode (no account). Value: bool.
const String kGuestModeStorageKey = 'guest_mode';

/// When true, successful login/signup should not reset navigation stack.
const String kGuestAuthPreserveRouteKey = 'guest_auth_preserve_route';
