# ZIP Code Section - Implementation Summary

## Overview
This document explains how the ZIP code claiming and management system works in the Loan Officer dashboard.

## Key Components

### 1. Controller: `LoanOfficerController`
Location: `lib/app/modules/loan_officer/controllers/loan_officer_controller.dart`

#### Key Reactive Lists:
- `_claimedZipCodes` (RxList<ZipCodeModel>): List of ZIP codes claimed by the loan officer
- `_availableZipCodes` (RxList<ZipCodeModel>): List of ZIP codes available to claim
- `_allZipCodes` (RxList<ZipCodeModel>): All ZIP codes loaded for the current state
- `_filteredClaimedZipCodes` (RxList<ZipCodeModel>): Filtered claimed ZIP codes (for search)
- `_filteredAvailableZipCodes` (RxList<ZipCodeModel>): Filtered available ZIP codes (for search)

#### Key Methods:

##### `onInit()`
**Current Flow:**
1. Clears `_claimedZipCodes` and `_availableZipCodes`
2. Calls `_initializeSubscription()`
3. Calls `checkPromoExpiration()`
4. Calls `_preloadThreads()`
5. Calls `_setupLoanOfficerListener()` - Sets up listener for loan officer data changes
6. Calls `_loadInitialClaimedZipCodes()` - Loads claimed ZIP codes from backend
7. After `_loadInitialClaimedZipCodes()` completes, calls `_loadMockData()`
8. After 100ms delay, calls `_loadZipCodes()` - Loads ZIP codes for selected state

**Issues:**
- `_loadMockData()` is called AFTER `_loadInitialClaimedZipCodes()`, but it might still add mock ZIP codes if conditions aren't met
- The order of operations might cause race conditions

##### `_loadMockData()`
**Purpose:** Loads mock data for loans and stats (not ZIP codes if real data exists)

**Current Logic:**
- Checks if `CurrentLoanOfficerController` has real loan officer data
- If officer exists (even with empty `claimedZipCodes`), skips loading mock ZIP codes
- Only loads mock ZIP codes if no officer data exists at all

**Issues:**
- If officer exists but `claimedZipCodes` is empty, it clears lists but doesn't add mock ZIP codes
- However, if there's a timing issue and officer data isn't loaded yet, mock data might be added

##### `_loadInitialClaimedZipCodes()`
**Purpose:** Fetches fresh loan officer data from backend and loads claimed ZIP codes

**Current Flow:**
1. Gets `CurrentLoanOfficerController`
2. Gets existing officer data (if any)
3. Gets user ID from `AuthController` or officer
4. If user ID exists, calls `refreshData(userId, true)` with force refresh
5. Gets updated officer data
6. Calls `_loadClaimedZipCodesFromModel(officer)` to sync ZIP codes

**Issues:**
- This is async, but `onInit()` doesn't properly await it before calling `_loadMockData()`
- The `.then()` callback might execute after mock data is loaded

##### `_loadClaimedZipCodesFromModel(LoanOfficerModel officer)`
**Purpose:** Loads claimed ZIP codes from the loan officer model

**Current Flow:**
1. Gets `claimedZipCodes` from officer model
2. If empty, clears ALL claimed ZIP codes and returns
3. Otherwise, creates `ZipCodeModel` objects for each claimed ZIP code
4. Removes any claimed ZIP codes NOT in the model's `claimedZipCodes` array
5. Adds new claimed ZIP codes to `_claimedZipCodes` list

**Issues:**
- This method adds to the list but doesn't clear it first (relies on other methods)
- If called multiple times, might create duplicates

##### `_loadZipCodes({bool forceRefresh = false})`
**Purpose:** Loads ZIP codes for the selected state

**Current Flow:**
1. Gets current loan officer to determine state
2. Checks cache first (unless force refresh)
3. If cache exists and valid, loads from cache
4. Otherwise, fetches from API
5. Updates `_allZipCodes` with fetched ZIP codes
6. Calls `_updateZipCodeLists()` to separate claimed/available

##### `_updateZipCodeLists()`
**Purpose:** Updates the claimed and available ZIP code lists based on `_allZipCodes` and loan officer model

**Current Flow:**
1. Gets loan officer ID
2. Gets `claimedZipCodes` from loan officer model
3. If model has 0 claimed ZIP codes, clears all and returns
4. Preserves any just-claimed ZIP codes (not yet in backend)
5. Processes all ZIP codes from `_allZipCodes`:
   - Checks if claimed by field (`claimedByLoanOfficer`)
   - Checks if claimed in model (`claimedZipCodes` array)
   - Separates into claimed/available lists
6. Adds any claimed ZIP codes from model not in `_allZipCodes`
7. Clears existing lists
8. Adds preserved just-claimed ZIP codes back
9. Adds new claimed/available lists
10. Applies search filter

**Issues:**
- The "preserve just-claimed" logic might not work correctly if the backend hasn't updated
- If `_allZipCodes` is empty, no ZIP codes will be processed

##### `claimZipCode(ZipCodeModel zipCode)`
**Purpose:** Claims a ZIP code

**Current Flow:**
1. Checks if already processing this ZIP code
2. Checks if max 6 ZIP codes reached
3. Gets loan officer ID
4. Calls API to claim ZIP code
5. **INSTANTLY** updates local state:
   - Removes from `_availableZipCodes`
   - Adds to `_claimedZipCodes`
   - Updates in `_allZipCodes`
6. Reapplies search filter
7. Updates cache
8. Updates subscription price
9. **Background:** Refreshes loan officer data with force refresh
10. After refresh, calls `_updateZipCodeLists()` to sync

**Issues:**
- The background refresh might overwrite the instant update
- `_updateZipCodeLists()` might clear the just-claimed ZIP code if backend hasn't updated yet

##### `releaseZipCode(ZipCodeModel zipCode)`
**Purpose:** Releases a claimed ZIP code

**Current Flow:**
1. Checks if already processing
2. Gets loan officer ID
3. Verifies ZIP code is actually claimed (local and backend)
4. Calls API to release
5. **INSTANTLY** updates local state:
   - Removes from `_claimedZipCodes`
   - Adds to `_availableZipCodes`
   - Updates in `_allZipCodes`
6. Reapplies search filter
7. Updates cache
8. Updates subscription price
9. **Background:** Refreshes loan officer data with force refresh
10. After refresh, calls `_updateZipCodeLists()` to sync

**Error Handling:**
- If backend says "not claimed", clears from local list and forces refresh

##### `_setupLoanOfficerListener()`
**Purpose:** Sets up a listener to sync ZIP codes when loan officer data changes

**Current Flow:**
1. Gets `CurrentLoanOfficerController`
2. Uses `ever()` to listen to `currentLoanOfficer` changes
3. When officer data changes:
   - Calls `_loadClaimedZipCodesFromModel(officer)`
   - If `_allZipCodes` is not empty, calls `_updateZipCodeLists()`

**Issues:**
- This might trigger multiple times and cause race conditions
- If `_allZipCodes` is empty, `_updateZipCodeLists()` won't be called

### 2. View: `loan_officer_view.dart`
Location: `lib/app/modules/loan_officer/views/loan_officer_view.dart`

#### Key Widgets:

##### `_buildZipManagement(BuildContext context)`
**Structure:**
- Wrapped in `RefreshIndicator` for pull-to-refresh
- Contains `CustomScrollView` with slivers
- Shows:
  1. Search field
  2. Licensed States section
  3. State selector dropdown
  4. Claimed ZIP Codes section (using `Obx` with `controller.claimedZipCodes`)
  5. Available ZIP Codes section (using `Obx` with `controller.availableZipCodes`)

**Reactive Updates:**
- Claimed ZIP codes: `Obx(() => ...controller.claimedZipCodes...)`
- Available ZIP codes: `Obx(() => ...controller.availableZipCodes...)`

**Issues:**
- The `Obx` widgets should automatically update when lists change, but if lists are cleared and rebuilt, there might be flickering

## Data Flow Diagram

```
onInit()
  ├─> Clear lists
  ├─> _loadInitialClaimedZipCodes() [ASYNC]
  │     ├─> Force refresh loan officer data from backend
  │     └─> _loadClaimedZipCodesFromModel()
  │           └─> Add claimed ZIP codes to _claimedZipCodes
  ├─> _loadMockData() [AFTER _loadInitialClaimedZipCodes completes]
  │     └─> Only loads if no officer data exists
  └─> _loadZipCodes() [AFTER 100ms delay]
        ├─> Load ZIP codes from cache or API
        └─> _updateZipCodeLists()
              └─> Separate into claimed/available based on model

claimZipCode()
  ├─> Call API
  ├─> INSTANTLY update local lists
  └─> Background: Refresh loan officer data
        └─> _updateZipCodeLists() [MIGHT OVERWRITE INSTANT UPDATE]
```

## Current Issues

### Issue 1: Mock Data Appearing on Refresh
**Root Cause:**
- `_loadMockData()` is called in `.then()` callback of `_loadInitialClaimedZipCodes()`
- If `_loadInitialClaimedZipCodes()` fails or takes time, mock data might be loaded
- The check in `_loadMockData()` might not catch all cases

**Solution Needed:**
- Ensure `_loadMockData()` NEVER loads ZIP codes if we have any loan officer data
- Better yet, completely separate mock ZIP codes from real ZIP codes loading

### Issue 2: 3 ZIP Codes Appearing When Claiming 1
**Root Cause:**
- When claiming, the instant update adds 1 ZIP code
- Background refresh might trigger `_updateZipCodeLists()` which processes `_allZipCodes`
- If `_allZipCodes` has ZIP codes that were previously claimed (from cache or previous state), they might be added
- The "preserve just-claimed" logic might not be working correctly
- Mock data might still be present

**Solution Needed:**
- Ensure `_updateZipCodeLists()` ONLY shows ZIP codes from the backend model
- Clear any ZIP codes not in the backend `claimedZipCodes` array
- Ensure mock data is completely cleared before loading real data

## Recommended Fixes

1. **Separate Mock Data Loading:**
   - Don't load mock ZIP codes at all if we have loan officer data
   - Only load mock loans and stats

2. **Fix Initialization Order:**
   - Wait for `_loadInitialClaimedZipCodes()` to complete before loading ZIP codes
   - Clear lists at the start and only populate from backend

3. **Fix `_updateZipCodeLists()`:**
   - Always use backend `claimedZipCodes` as source of truth
   - Clear all claimed ZIP codes not in backend array
   - Only preserve just-claimed ZIP codes temporarily (with timeout)

4. **Fix Claim Flow:**
   - Don't call `_updateZipCodeLists()` immediately after claim
   - Only sync after backend confirms the claim
   - Use a flag to track "pending claims" that should be preserved
