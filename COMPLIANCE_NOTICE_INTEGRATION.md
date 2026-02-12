# Compliance Notice Integration Guide

## Files Created
1. `lib/app/services/rebate_states_service.dart` - Service to fetch allowed states from backend
2. `lib/app/widgets/rebate_compliance_notice.dart` - Reusable compliance notice widget
3. `lib/app/widgets/rebate_states_info_modal.dart` - Modal showing all allowed states

## Required Changes

### 1. Add API Endpoint (`lib/app/utils/api_constants.dart`)
After line 73, add:
```dart
  /// GET /api/v1/rebate/allowed-states — get list of states that allow rebates
  static String get rebateAllowedStatesEndpoint => "$apiBaseUrl/rebate/allowed-states";
```

### 2. Auth View - Sign Up (`lib/app/modules/auth/views/auth_view.dart`)

**Add import** (after line 10):
```dart
import 'package:getrebate/app/widgets/rebate_compliance_notice.dart';
```

**Add compliance notice BEFORE state selection** (replace line 574):
```dart
              const SizedBox(height: 12),
              RebateComplianceNotice(
                accentColor: controller.selectedRole == UserRole.agent 
                    ? AppTheme.primaryBlue 
                    : AppTheme.lightGreen,
              ),
              const SizedBox(height: 12),
              _buildLicensedStatesSelection(context),
```

**Do the same for loan officer section** (replace line 677):
```dart
              const SizedBox(height: 12),
              RebateComplianceNotice(
                accentColor: AppTheme.lightGreen,
              ),
              const SizedBox(height: 12),
              _buildLicensedStatesSelection(context),
```

### 3. Buyer View - ZIP Search (`lib/app/modules/buyer/views/buyer_view.dart`)

**Add import** (after line 16):
```dart
import 'package:getrebate/app/widgets/rebate_compliance_notice.dart';
```

**Add compliance notice** (replace lines 105-109):
```dart
              ),
              const SizedBox(height: 12),
              RebateComplianceNotice(
                accentColor: AppTheme.primaryBlue,
              ),
              if (hasSearch) ...[
                const SizedBox(height: 12),
                _buildStateLimitNote(context),
              ],
```

### 4. Buyer V2 View - ZIP Search (`lib/app/modules/buyer_v2/views/buyer_v2_view.dart`)

**Add import** (after line 16):
```dart
import 'package:getrebate/app/widgets/rebate_compliance_notice.dart';
```

**Add compliance notice** (replace lines 111-116):
```dart
              ),
              const SizedBox(height: 12),
              RebateComplianceNotice(
                accentColor: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 20),
```

### 5. Payment Web View - Checkout (`lib/app/widgets/payment_web_view.dart`)

**Add import** (after line 5):
```dart
import 'package:getrebate/app/widgets/rebate_compliance_notice.dart';
```

**Add compliance notice** (replace line 209):
```dart
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: RebateComplianceNotice(
                accentColor: AppTheme.primaryBlue,
              ),
            ),
          ),
          if (_errorMessage != null)
```

## Backend API Endpoint Required

The backend needs to implement:
- **GET** `/api/v1/rebate/allowed-states`
- Returns: `{ "states": ["AZ", "AR", "CA", ...] }` or `["AZ", "AR", "CA", ...]`

If the endpoint doesn't exist yet, the app will use the fallback list of 40 allowed states.
