# Loan Officer Module - Unimplemented Features & Current Workflow

**Date:** December 22, 2025  
**Document Version:** 1.0

---

## Part 1: New Client Requirements - Not Yet Implemented

This section lists all features mentioned in the client requirements that are **completely missing** from the current implementation.

---

### 1. Buyer Search & Matching Features

#### 1.1 City-Based Search
**Client Requirement:**
> "Buyers can search for loan officers by: Zip code, City, Current location"

**Status:** ❌ **Not Implemented**

**Current State:**
- Only ZIP code search exists
- Location-based search uses coordinates, not city names
- No city name input field or search functionality

**What's Missing:**
- City name search input field
- City-to-ZIP code mapping service
- Search results filtered by city
- City name autocomplete/suggestions

**Impact:** Buyers cannot search for loan officers by city name, limiting search flexibility.

---

#### 1.2 "Closest 10" Loan Officers with Distance Ranking
**Client Requirement:**
> "Buyers see: The closest 10 loan officers. Option to click 'See Next 10 Closest' (up to 20 total)"

**Status:** ❌ **Not Implemented**

**Current State:**
- All matching loan officers are displayed without limit
- No distance calculation or ranking
- No pagination or "load more" functionality

**What's Missing:**
- Distance calculation from buyer's location to loan officer service areas
- Sorting by distance (closest first)
- Limit initial results to 10 closest
- "See Next 10 Closest" pagination button
- Maximum limit of 20 total results
- Distance display in loan officer cards

**Impact:** Buyers see all results without prioritization, making it harder to find nearby loan officers.

---

#### 1.3 ZIP Code Priority in Search Results
**Client Requirement:**
> "The loan officer assigned to a specific zip code appears first."

**Status:** ⚠️ **Partially Implemented** (but needs enhancement)

**Current State:**
- Loan officers with claimed ZIP codes are filtered and shown when buyer searches that ZIP
- All matching loan officers shown together without explicit prioritization

**What's Missing:**
- Explicit "appears first" sorting logic
- Loan officers with claimed ZIP codes should be at the top
- Within claimed ZIP codes, sort by distance or other criteria
- Clear visual indication of "assigned to this ZIP code"

**Impact:** Loan officers assigned to a ZIP code may not appear at the top of results as required.

---

#### 1.4 "My Loan Officer" Selection
**Client Requirement:**
> "Buyers may: Favorite loan officers, Select a loan officer as 'My Loan Officer'"

**Status:** ❌ **Not Implemented**

**Current State:**
- Favorite/like functionality exists (`toggleFavoriteLoanOfficer()`)
- No "My Loan Officer" designation or selection mechanism

**What's Missing:**
- "Select as My Loan Officer" button in loan officer profile
- Storage of selected loan officer relationship in user model
- Display of selected loan officer in buyer dashboard
- Ability to change or remove "My Loan Officer"
- Only one "My Loan Officer" allowed at a time (needs clarification)

**Impact:** Buyers cannot establish a primary relationship with a loan officer.

---

### 2. Analytics & Reporting Features

#### 2.1 Website Click Tracking
**Client Requirement:**
> "Number of clicks to: Website"

**Status:** ❌ **Not Implemented**

**Current State:**
- Website links can be opened via `url_launcher`
- No tracking of clicks
- No analytics collection

**What's Missing:**
- API endpoint to record website clicks: `POST /api/v1/loan-officers/:id/track-website-click`
- Call tracking endpoint before opening URL
- `websiteClicks` field in `LoanOfficerModel`
- Display click count in loan officer dashboard analytics
- Historical click data tracking

**Impact:** Loan officers cannot see engagement metrics for website links, reducing ability to measure ROI.

---

#### 2.2 "Apply Now" Button Click Tracking
**Client Requirement:**
> "Number of clicks to: 'Apply Now' button"

**Status:** ❌ **Not Implemented**

**Current State:**
- "Apply Now" button opens external mortgage application URL
- No tracking of clicks
- No analytics collection

**What's Missing:**
- API endpoint to record Apply Now clicks: `POST /api/v1/loan-officers/:id/track-apply-click`
- Call tracking endpoint before opening URL
- `applyNowClicks` field in `LoanOfficerModel`
- Display click count in loan officer dashboard analytics
- Conversion tracking (profile view → Apply Now click)

**Impact:** Loan officers cannot measure conversion from profile views to application starts, limiting ROI visibility.

---

#### 2.3 Enhanced Analytics Dashboard
**Client Requirement:**
> "These stats are designed to: Increase engagement with the platform, Show ROI on the subscription, Encourage continued participation"

**Status:** ⚠️ **Partially Implemented**

**Current State:**
- Basic stats displayed (searches appeared in, profile views)
- Stats shown in loan officer dashboard

**What's Missing:**
- ROI calculation and visualization
- Engagement optimization features
- Performance recommendations
- Comparison data (e.g., "You're in top 20%")
- Trend analysis (week-over-week, month-over-month)
- Engagement tips and best practices

**Impact:** Loan officers may not see clear value proposition from subscription, reducing retention.

---

### 3. Profile & Visibility Features

#### 3.1 Website URL Editing
**Client Requirement:**
> "Website link" in public profile

**Status:** ⚠️ **Partially Implemented**

**Current State:**
- `websiteUrl` field exists in `LoanOfficerModel`
- Can be entered during signup
- Field is sent to backend during registration

**What's Missing:**
- **NOT editable in `LoanOfficerEditProfileView`** - Users cannot update website URL after initial signup
- Website link may not be displayed in public profile view (needs verification)

**Impact:** Loan officers cannot update their website URL after registration, limiting profile maintenance.

---

#### 3.2 Rebate Compliance Confirmation Workflow
**Client Requirement:**
> "All loan officers listed on the site confirm their lender allows real estate commission rebates, provided: The rebate is disclosed properly, The rebate appears on the settlement statement at closing, Lender and program guidelines are met"

**Status:** ⚠️ **Partially Implemented**

**Current State:**
- `allowsRebates` boolean field exists in model
- Display badge shown when `allowsRebates: true`
- `verificationAgreed` checkbox exists during signup

**What's Missing:**
- No explicit confirmation workflow that requires loan officers to acknowledge:
  - Rebate disclosure requirements
  - Settlement statement appearance requirement
  - Lender/program guidelines compliance
- No documentation or terms acceptance specific to rebate compliance
- No multi-step confirmation process
- No periodic re-confirmation requirement

**Impact:** Legal/compliance risk if loan officers claim rebate-friendly status without proper confirmation.

---

### 4. Subscription & Pricing Features

#### 4.1 Lower Monthly Fee Verification
**Client Requirement:**
> "Loan officers pay a lower monthly subscription fee than real estate agents."

**Status:** ⚠️ **Partially Implemented** (Needs Verification)

**Current State:**
- Both loan officers and agents use zip-code-based pricing via `ZipCodePricingService`
- Promo codes differ (agents: 70% off, loan officers: 6 months free)
- Base pricing logic appears similar

**What's Missing:**
- No explicit verification that loan officers have lower base rates than agents
- Pricing structure may need adjustment per requirements
- Need to confirm if base monthly fee is lower or only promo codes differ

**Impact:** May not meet requirement for lower loan officer subscription fees.

---

## Part 2: Complete Loan Officer Workflow (Current Implementation)

This section documents the **entire current workflow** of loan officers in the application, from registration to daily operations.

---

### 2.1 Registration & Onboarding Flow

#### Step 1: Initial Access
1. **User opens app** → Splash screen → Onboarding (3 slides) → Authentication screen

#### Step 2: Role Selection
1. User selects **"Loan Officer"** role from role selection screen
2. System navigates to loan officer signup form

#### Step 3: Basic Information (Required)
1. **Full Name** - Text input (required)
2. **Email** - Email input with validation (required)
3. **Password** - Password input with strength requirements (required)
4. **Phone** - Phone number input (optional)
5. **Profile Picture** - Image picker (optional)
   - Can select from gallery or take photo
   - Image is uploaded during registration

#### Step 4: Professional Information (Required)
1. **Company Name** - Text input (required)
2. **License Number** - Text input (required)
3. **Licensed States** - Multi-select dropdown (optional)
   - User can select multiple states from a list
   - States are stored as array

#### Step 5: Profile Information (Optional)
1. **Bio/Introduction** - Multi-line text input (optional)
   - Max 3 lines visible
   - Placeholder: "Tell buyers about yourself and your experience..."

2. **Video Introduction URL** - URL input (optional)
   - Accepts YouTube or Vimeo links
   - Placeholder: "YouTube or Vimeo link"

3. **Areas of Expertise & Specialty Products** - Multi-select checkboxes (optional)
   - User can select from 15 mortgage types:
     - Conventional Conforming Loans
     - Conventional Non-Conforming / Jumbo Loans
     - Conventional Portfolio Loans
     - FHA Loans
     - VA Loans
     - USDA Loans
     - First-Time Homebuyer Programs
     - Renovation Loans
     - Construction-to-Permanent Loan
     - Interest-Only Loan
     - Non-QM (Non-Qualified Mortgage)
     - Fixed-Rate Mortgages
     - Adjustable-Rate Mortgage (ARM)
     - Hybrid Loans
     - Other (custom option)
   - Each selection includes description for buyers

4. **Website URL** - URL input (optional)
   - Placeholder: "https://yourwebsite.com"
   - **Note:** Cannot be edited after signup (gap)

5. **Mortgage Application Link** - URL input (optional)
   - Placeholder: "Link to apply for a mortgage now"
   - Used for "Apply Now" button on public profile

6. **Reviews Page** - URL input (optional)
   - Placeholder: "Google, Zillow, or other review sites"
   - Links to external review platforms

#### Step 6: Verification Agreement
1. **Verification Checkbox** - Required checkbox
   - User must agree to verification terms
   - Stored as `verificationAgreed: true`

#### Step 7: Account Creation
1. User clicks "Sign Up" button
2. Form validation runs:
   - Email format validation
   - Required fields check
   - Password strength check
3. If valid:
   - Profile picture uploaded (if provided)
   - Form data sent to backend: `POST /auth/createUser`
   - API receives:
     - Basic info (name, email, password, phone, role)
     - Company name
     - License number
     - Licensed states (as JSON array)
     - Optional profile fields (bio, videoUrl, specialtyProducts, websiteUrl, mortgageApplicationUrl, externalReviewsUrl)
     - verificationAgreed flag
4. Backend creates user account and loan officer profile
5. User is automatically logged in
6. Redirected to Loan Officer Dashboard

---

### 2.2 Loan Officer Dashboard (Main Interface)

#### Navigation Structure
The dashboard has **3 main tabs** (Billing, Checklists, Stats are commented out):

1. **Dashboard Tab** (Default)
2. **Messages Tab**
3. **ZIP Codes Tab**

#### Tab 1: Dashboard

**Location:** `lib/app/modules/loan_officer/views/loan_officer_view.dart`

**Components:**

1. **Stats Cards (4 cards in 2x2 grid):**
   - **Searches Appeared In**
     - Icon: Search icon
     - Value: `searchesAppearedIn` from `LoanOfficerModel`
     - Description: "Times shown in buyer searches"
   
   - **Profile Views**
     - Icon: Eye icon
     - Value: `profileViews` from `LoanOfficerModel`
     - Description: "Total profile views"
   
   - **Contacts**
     - Icon: Message icon
     - Value: `contacts` from `LoanOfficerModel`
     - Description: "Buyer contacts"
   
   - **Total Revenue** (if applicable)
     - Icon: Dollar icon
     - Value: Calculated from subscription
     - Description: "Monthly subscription"

2. **Quick Actions Section:**
   - **Edit Profile Button**
     - Opens `LoanOfficerEditProfileView`
     - Allows editing: name, phone, bio, license, company, service areas, specialty products, professional links
     - **Note:** Website URL NOT editable (gap)
   
   - **View My Profile Button** (if implemented)
     - Opens public profile view as buyers see it

3. **Recent Activity Section:**
   - Shows recent profile views
   - Shows recent contacts/messages
   - Shows recent searches appeared in

4. **Subscription & Promo Code Section:**
   - Displays current subscription status
   - Shows base monthly price (calculated from claimed ZIP codes)
   - Shows current monthly price (may be 0 if in free period)
   - Promo code input field
   - "Apply Promo Code" button
   - Promo code validation:
     - Accepts codes starting with "LO" (Loan Officer promo codes)
     - Validates against backend (currently mocked)
     - If valid: Applies 6 months free subscription
     - Updates subscription status to "promo"
     - Sets `freePeriodEndsAt` to 6 months from now
     - Sets `currentMonthlyPrice` to 0.0 during free period

**Data Source:**
- Uses `CurrentLoanOfficerController` to fetch current loan officer data
- Falls back to mock data if API data not available
- Real-time updates via GetX reactive variables

---

#### Tab 2: Messages

**Location:** `lib/app/modules/messages/views/messages_view.dart`

**Functionality:**
1. **Conversation List:**
   - Shows all conversations with buyers
   - Displays buyer name, last message preview, timestamp
   - Unread message indicators
   - Sorted by most recent activity

2. **Message Thread:**
   - Click conversation to open message thread
   - View message history
   - Send new messages
   - Real-time message updates (if WebSocket implemented)

3. **Features:**
   - Text messaging only
   - No file attachments (current implementation)
   - No video calls (current implementation)
   - General-purpose messaging (not loan-specific)

**Purpose:** Connection and introduction, not loan processing (as per requirements)

---

#### Tab 3: ZIP Codes Management

**Location:** `lib/app/modules/loan_officer/views/loan_officer_view.dart` → `_buildZipManagement()`

**Functionality:**

1. **State Selection:**
   - Dropdown to select US state
   - Default: California (CA)
   - Country is always "US"

2. **Search Functionality:**
   - Search input field with debouncing (300ms delay)
   - Filters both available and claimed ZIP codes
   - Real-time search as user types

3. **Available ZIP Codes Section:**
   - Shows ZIP codes NOT claimed by current loan officer
   - Displays for each ZIP code:
     - ZIP code number
     - City name
     - State
     - Population
     - Price (monthly subscription cost for this ZIP)
   - **Claim Button:**
     - Click to claim ZIP code
     - Shows loading spinner on button during API call
     - Calls: `POST /api/v1/zip-codes/claim`
     - Request body: `{ id, zipcode, price, state, population }`
     - On success:
       - ZIP code moves from "Available" to "Claimed" list
       - Subscription price updates automatically
       - Cache refreshes

4. **Claimed ZIP Codes Section:**
   - Shows ZIP codes currently claimed by loan officer
   - Same display format as available ZIP codes
   - **Release Button:**
     - Click to release ZIP code
     - Shows loading spinner on button during API call
     - Calls: `PATCH /api/v1/zip-codes/release`
     - Request body: `{ id, zipcode }`
     - On success:
       - ZIP code moves from "Claimed" to "Available" list
       - Subscription price updates automatically
       - Cache refreshes

5. **Caching & Performance:**
   - ZIP codes cached in GetStorage by state
   - Cache key: `zip_codes_cache_{state}`
   - Cache invalidated when state changes
   - Background refresh if cache older than 1 hour
   - Memory cache for instant UI updates
   - Optimized for large datasets (1000+ ZIP codes)

6. **Loading States:**
   - Initial load: Shows circular progress indicator
   - Individual ZIP code actions: Button-level loading spinner
   - Pull-to-refresh: RefreshIndicator wrapper

7. **Empty States:**
   - Shows message if no available ZIP codes
   - Shows message if no claimed ZIP codes
   - Shows message if search returns no results

**Pricing Calculation:**
- Uses `ZipCodePricingService` for population-based pricing
- Price tiers based on population:
  - High population: Higher price
  - Low population: Lower price
- Total monthly subscription = Sum of all claimed ZIP code prices
- Minimum fallback price if no ZIP codes claimed

---

### 2.3 Profile Editing Flow

**Location:** `lib/app/modules/loan_officer_edit_profile/views/loan_officer_edit_profile_view.dart`

**Access:** Dashboard → Quick Actions → "Edit Profile" button

**Editable Fields:**

1. **Profile Picture:**
   - Current profile picture displayed
   - "Change Picture" button
   - Image picker (gallery or camera)
   - "Remove Picture" option

2. **Company Logo:**
   - Current logo displayed
   - "Change Logo" button
   - Image picker
   - "Remove Logo" option

3. **Basic Information:**
   - **Full Name** - Text input (editable)
   - **Email** - Text input (disabled, cannot change)
   - **Phone** - Phone input (editable)
   - **License Number** - Text input (editable)

4. **About Section:**
   - **Bio** - Multi-line text input (editable)

5. **Service Areas:**
   - **Licensed States** - Multi-select (editable)
   - Currently managed via ZIP code claiming (not editable here)

6. **Specialty Products:**
   - Multi-select checkboxes (editable)
   - Same 15 mortgage types as signup

7. **Professional Links:**
   - **Website URL** - **NOT EDITABLE** (gap - exists in model but not in form)
   - **Mortgage Application URL** - URL input (editable)
   - **External Reviews URL** - URL input (editable)

**Save Process:**
1. User makes changes
2. Clicks "Save Changes" button
3. Form validation
4. Calls: `PATCH /api/v1/auth/updateUser/:userId`
5. Updates profile picture/logo if changed
6. Updates all text fields
7. On success:
   - Shows success message
   - Refreshes `CurrentLoanOfficerController`
   - Returns to dashboard
   - Profile updates reflected immediately

---

### 2.4 Public Profile View (Buyer-Facing)

**Location:** `lib/app/modules/loan_officer_profile/views/loan_officer_profile_view.dart`

**How Buyers Access:**
- From buyer search results
- From favorites list
- Direct link (if shared)

**Profile Structure:**

1. **Header Section:**
   - Profile picture (or default icon)
   - Name
   - Company name
   - Rating and review count
   - Verified badge (if `isVerified: true`)

2. **Bio Section:**
   - Bio text (if provided)
   - Rebate-Friendly Lender Verified badge (if `allowsRebates: true`)
     - Green-bordered box
     - Check icon
     - Message: "This loan officer has confirmed their lender allows real estate commission rebates to be credited to buyers at closing, appearing directly on the Closing Disclosure or Settlement Statement."

3. **Action Buttons:**
   - **Apply for a Mortgage** (if `mortgageApplicationUrl` exists)
     - Opens external URL in browser
     - **Note:** No click tracking (gap)
   - **Contact** / **Message** button
     - Opens messaging interface
   - **Favorite** / **Like** button
     - Toggles favorite status
     - Calls: `POST /api/v1/loan-officers/:id/like`
     - Updates `likes` array in model

4. **Tabs:**
   - **Overview Tab:**
     - Contact information (phone, email if visible)
     - Licensed states
     - Company information
     - Service areas (claimed ZIP codes)
   
   - **Reviews Tab:**
     - Platform reviews (from `reviews` array)
     - External reviews link (if `externalReviewsUrl` provided)
     - Review submission (if buyer has worked with loan officer)
   
   - **Loan Programs Tab:**
     - Specialty products list
     - Each product shows name and description
     - Empty state if no products selected

**Profile View Tracking:**
- When buyer views profile, calls: `POST /api/v1/loan-officers/:id/add-profile-view`
- Increments `profileViews` count
- Updates displayed in loan officer dashboard

---

### 2.5 Buyer Search & Discovery Flow

**Location:** `lib/app/modules/buyer/views/buyer_view.dart`

**How Loan Officers Appear in Search:**

1. **ZIP Code Search:**
   - Buyer enters ZIP code (5 digits)
   - System filters loan officers where `claimedZipCodes` contains the ZIP
   - Results displayed in list
   - **Note:** No distance sorting or "closest 10" limit (gap)

2. **Location-Based Search:**
   - Buyer clicks location icon
   - System gets current GPS coordinates
   - Converts to ZIP code
   - Filters loan officers by ZIP code
   - **Note:** No distance calculation or ranking (gap)

3. **Search Results Display:**
   - Loan officer cards showing:
     - Profile picture
     - Name
     - Company
     - Rating
     - Distance (if calculated - currently not)
     - "Claimed ZIP" indicator (if applicable)
   - Click card to view full profile

4. **Search Tracking:**
   - When loan officer appears in search results, increments `searchesAppearedIn`
   - Tracking happens silently in background
   - Updates reflected in loan officer dashboard

**Current Limitations:**
- ❌ No city-based search
- ❌ No "closest 10" limit
- ❌ No "See Next 10" pagination
- ❌ No distance-based sorting
- ⚠️ ZIP code priority not explicitly implemented (filtering works but no "appears first" logic)

---

### 2.6 Subscription Management Flow

**Location:** Dashboard → Subscription section

**Current Subscription Display:**
- Base monthly price (calculated from claimed ZIP codes)
- Current monthly price (0 if in free period, otherwise equals base price)
- Subscription status (active, promo, cancelled)
- Free period end date (if promo active)

**Promo Code Application:**
1. User enters promo code (format: "LOxxxxx")
2. Clicks "Apply Promo Code"
3. System validates code:
   - Checks format (starts with "LO")
   - Validates with backend (currently mocked)
   - Checks if already has active promo
   - Checks if code expired or reached usage limit
4. If valid:
   - Applies 6 months free
   - Updates subscription status
   - Sets `freePeriodEndsAt` to 6 months from now
   - Sets `currentMonthlyPrice` to 0.0
   - Shows success message
5. If invalid:
   - Shows error message
   - Promo code not applied

**Subscription Renewal:**
- Ongoing subscription model
- Continues as long as loan officer wants visibility
- No automatic cancellation
- Manual cancellation available (if implemented)

**Pricing Calculation:**
- Base price = Sum of all claimed ZIP code prices
- Uses `ZipCodePricingService.calculateTotalMonthlyPrice()`
- Population-based pricing tiers
- Minimum fallback price if no ZIP codes claimed

---

### 2.7 Logout Flow

**Location:** Dashboard → AppBar → Logout icon

**Process:**
1. User clicks logout icon (top right)
2. Confirmation dialog appears
3. User confirms logout
4. System:
   - Clears authentication token
   - Clears user session
   - Clears cached data (if needed)
   - Redirects to login screen

---

### 2.8 Data Flow & State Management

**Controllers Used:**
1. **`LoanOfficerController`** - Main dashboard controller
   - Manages ZIP code operations
   - Handles subscription and promo codes
   - Manages dashboard state

2. **`CurrentLoanOfficerController`** - Current user profile controller
   - Fetches current loan officer data from API
   - Provides reactive updates
   - Used across multiple views

3. **`LoanOfficerEditProfileController`** - Profile editing controller
   - Manages edit profile form
   - Handles image uploads
   - Updates profile via PATCH API

4. **`LoanOfficerProfileController`** - Public profile controller (buyer-facing)
   - Loads loan officer profile by ID
   - Handles favorite/like functionality
   - Tracks profile views

**API Endpoints Used:**
- `POST /auth/createUser` - Registration
- `GET /api/v1/loan-officers/current` - Get current loan officer
- `PATCH /api/v1/auth/updateUser/:userId` - Update profile
- `GET /api/v1/zip-codes/:country/:state` - Get ZIP codes
- `POST /api/v1/zip-codes/claim` - Claim ZIP code
- `PATCH /api/v1/zip-codes/release` - Release ZIP code
- `POST /api/v1/loan-officers/:id/like` - Toggle favorite
- `POST /api/v1/loan-officers/:id/add-profile-view` - Track profile view

**State Management:**
- GetX for reactive state management
- RxList for lists (ZIP codes, messages)
- RxBool for loading states
- RxSet for tracking loading ZIP codes
- GetStorage for local caching

---

## Summary

### Unimplemented Features Summary:
1. ❌ City-based search
2. ❌ "Closest 10" with distance ranking
3. ❌ "See Next 10 Closest" pagination
4. ❌ "My Loan Officer" selection
5. ❌ Website click tracking
6. ❌ "Apply Now" click tracking
7. ⚠️ Website URL editing (exists in model, not in UI)
8. ⚠️ Enhanced rebate compliance confirmation workflow
9. ⚠️ Enhanced analytics with ROI visualization

### Current Workflow Summary:
The loan officer workflow is **fully functional** for:
- ✅ Registration and profile setup
- ✅ Dashboard with stats and quick actions
- ✅ ZIP code management (claim/release)
- ✅ Profile editing (most fields)
- ✅ Messaging with buyers
- ✅ Promo code application
- ✅ Subscription management
- ✅ Public profile display

**Gaps in workflow:**
- Website URL cannot be edited after signup
- No explicit rebate compliance confirmation step
- Limited analytics (missing click tracking)
- Search results not optimized (no distance ranking, no pagination)

---

**Document End**






