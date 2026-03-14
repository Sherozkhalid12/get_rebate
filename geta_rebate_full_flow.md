## GetaRebate Mobile App – Functional & Flow Documentation

This document describes the **current, implemented behavior** of the GetaRebate **mobile application** (Flutter + GetX), focused on the three main roles:

- **Buyer / Seller**
- **Agent**
- **Loan Officer**

It covers **signup/login**, **post‑login navigation**, **all major screens and actions**, **APIs used per screen**, and **how data flows between screens and services**. A **combined flowchart** is included at the end.

---

## 1. Architecture Overview

- **Tech stack**
  - **Flutter** app (`lib/`) using **GetX** for routing, DI, and state.
  - **Dio** as the HTTP client.
  - **GetStorage** for local persistence (auth, flags, etc.).
  - **Firebase Messaging** for push notifications / FCM token management.
  - **Realtime chat** via Socket.IO (`SocketService`) plus REST chat endpoints.

- **Entry point**
  - `MyApp` (`lib/app/app.dart`) configures:
    - `GetMaterialApp` with `initialRoute = AppPages.INITIAL` (`/splash`).
    - `getPages = AppPages.routes` defining all named routes.
    - `initialBinding = InitialBinding()` registering global controllers.

- **Global bindings**
  - `InitialBinding` registers:
    - **ThemeController**
    - **LocationController**
    - **AuthController** (global auth/session)
    - **SplashController** (splash & initial navigation)

- **Routes (key ones)**
  - `/splash` → `SplashView`
  - `/onboarding` → `OnboardingView`
  - `/auth` → `AuthView` (signup/login)
  - `/main` → `MainNavigationView` (Buyer/Seller)
  - `/agent` → `AgentView` (Agent)
  - `/loan-officer` → `LoanOfficerView` (Loan Officer)
  - Plus many feature routes (rebate calculators, checklists, profiles, forms, etc.) described below.

- **Roles**
  - `UserRole.buyerSeller`
  - `UserRole.agent`
  - `UserRole.loanOfficer`
  - Role is stored in `UserModel.role` and drives navigation after login/signup.

---

## 2. Global App Lifecycle & Auth Flow

### 2.1 Splash & Initial Auth Resolution

**Screen:** `SplashView` (`/splash`)  
**Controller:** `SplashController`

**Flow:**

1. **App start**
   - `MyApp` → initial route `/splash`.
   - `InitialBinding` has already created:
     - `AuthController` (restores persisted session if any).
     - `LocationController` (for ZIP-based flows).
2. **Splash timer**
   - `SplashController.onInit()` starts a **1.5s timer** to show branding/text.
3. **Auth check**
   - `_checkAuthAndNavigate()`:
     - Reads `AuthController.isLoggedIn` and `currentUser`.
     - If **no user**:
       - Calls `_preloadLocation()` to start location permission + ZIP prefetch (buyer + signup support).
       - Navigates to **`/onboarding`** (`AppPages.ONBOARDING`).
     - If **user exists**:
       - Calls `_preloadData(user.role)`:
         - Ensures `MessagesController` exists and starts `refreshThreads()` so chat is ready.
         - Preloads location (ZIP) again.
       - For **Agent / Loan Officer**:
         - Calls `_fetchAndStoreFirstZipCodeClaimed(user.id)`:
           - **API:** `GET /api/v1/auth/users/{userId}` (via `ApiConstants.getUserByIdEndpoint`).
           - Stores `firstZipCodeClaimed` in `GetStorage` (`kFirstZipCodeClaimedStorageKey`).
       - For **Loan Officer specifically**:
         - Ensures `CurrentLoanOfficerController` exists, calls `fetchCurrentLoanOfficer(user.id)`:
           - **API:** `GET /api/v1/loan-officers/{id}` via `LoanOfficerService.getCurrentLoanOfficer`.
         - If loan officer profile **fails to load**, shows error + logs user out → sends to `/auth`.
4. **Role‑based navigation**
   - `_navigateBasedOnRole(user.role)`:
     - **Buyer/Seller** → `/main` (Buyer home + bottom nav).
     - **Agent** → `/agent`.
     - **Loan Officer** → `/loan-officer`.

**Data flow:**

- Auth state persisted in `GetStorage` (`current_user`, `auth_token`).
- `AuthController`:
  - Restores user & auth token, attaches token to Dio.
  - Validates user ID format (Mongo ObjectId).
  - For Loan Officers, also ensures `CurrentLoanOfficerController` is hydrated.

---

### 2.2 Onboarding

**Screen:** `OnboardingView` (`/onboarding`)  
**Binding:** `OnboardingBinding`

**Purpose:**

- Marketing / educational funnel before auth.
- CTA to **create account or sign in**.

**Typical flow:**

- User swipes/taps through intro content (no backend calls).
- Taps **“Get Started” / “Sign In”** → navigates to `/auth` (`AuthView`).

---

### 2.3 Auth (Signup & Login)

**Screen:** `AuthView` (`/auth`)  
**Controller:** `AuthViewController` (module-level)  
**Global controller:** `AuthController` (global session & API calls)  
**Key models:** `UserModel`, `UserRole` enum

#### 2.3.1 UI / UX Flow (AuthView)

- The view toggles between:
  - **Login mode** (`isLoginMode == true`)
  - **Signup mode** (`isLoginMode == false`)
- **Common elements:**
  - Logo.
  - Header: “Welcome Back” / “Create Account”.
  - Subtitle: “Sign in…” / “Join GetaRebate…”.
  - **Email** + **Password** fields.
  - Social login buttons (Google, Apple, Facebook) – **currently mocked** only.
  - Toggle link **“Sign Up” / “Sign In”**.

- **Login‑only UI:**
  - “Forgot password?” text button → `/forgot-password`.

- **Signup‑only UI:**
  - **Full name** field.
  - **Profile picture** picker (optional).
  - **Phone number**:
    - Required for **Agent** and **Loan Officer**.
    - Optional for **Buyer/Seller**.
  - **Role selection** cards:
    - Buyer/Seller
    - Agent
    - Loan Officer
  - For **Agent**:
    - Required:
      - Brokerage / Company
      - License number
      - Licensed states chips (from `RebateStatesService.getAllowedStates()`).
      - Office ZIP code (5 digits; can use **“use current location”** via `LocationController.currentZipCode`).
      - Dual agency questions:
        - Is dual agency allowed in state?
        - Is dual agency allowed at brokerage?
      - Agent verification checkbox (multi‑bullet statement).
    - Optional:
      - Bio.
      - Video introduction.
      - Areas of expertise (chips).
      - Website, Google reviews URL, other review URL.
      - Company logo.
  - For **Loan Officer**:
    - Required:
      - Mortgage/lender company.
      - License number.
      - Licensed states.
      - Office ZIP code (with “use current location”).
      - Loan officer verification checkbox.
    - Optional:
      - Bio.
      - Video introduction.
      - Specialty mortgage products (chips).
      - Website, mortgage application URL, external reviews URL.
      - Company logo.
  - **All signup roles:**
    - **Terms of Service agreement** card:
      - Checkbox “I have read and agree…”
      - Link to `/terms-of-service` (user must actually open to set “viewed”).

#### 2.3.2 Login Flow

**User actions:**

1. Enters **email** and **password** in **login mode**.
2. Taps **“Sign In”** button → triggers `AuthViewController.submitForm()`.

**Validation:**

- Email present and valid format.
- Password present and min length 6.

**System behavior:**

1. `submitForm()` detects `isLoginMode == true` and calls:

   ```dart
   _globalAuthController.login(email: email, password: password)
   ```

2. `AuthController.login()`:

   - **API call:**

     - **Method:** `POST`
     - **URL:** `/api/v1/auth/login`
       - Base: `ApiConstants.apiBaseUrl` (production `https://api.getarebate.com/api/v1`)
     - **Body:**
       - `{ "email": "<email>", "password": "<password>" }`

   - **Response handling:**
     - Expects `statusCode 200/201`.
     - Validates `response.data['success']` is not `false`.
     - Extracts `user` and `token`.
     - User ID resolved from `user['_id']` or `user['id']`.
     - Builds a `UserModel` including `role`, `licensedStates`, and `additionalData`.
     - Persists:
       - `current_user` (JSON) in `GetStorage`.
       - `auth_token` (if present).
     - Calls `setFCM(user.id)`:
       - **API:** `PATCH /api/v1/auth/setFCM`
       - Body: `{ userId, fcmToken }` (FCM token retrieved from Firebase Messaging).
     - For **Loan Officer role**:
       - Ensures `CurrentLoanOfficerController` and calls `fetchCurrentLoanOfficer(user.id)` (described earlier).
       - If profile fails, logs out and navigates back to `/auth`.
     - Calls `_navigateToRoleBasedScreen()`:
       - Buyer/Seller → `/main`.
       - Agent → `/agent`.
       - Loan Officer → `/loan-officer`.

3. **Error handling:**
   - Uses `SnackbarHelper.showError(<message>)` for:
     - Invalid credentials (`401`).
     - Server errors (`500`), network issues, timeouts.
   - **No navigation** occurs on failure.

#### 2.3.3 Signup Flow with Email OTP

**User actions:**

1. Switches to **signup mode** (taps “Sign Up”).
2. Fills required fields depending on role (see UI section).
3. Checks **Terms of Service** checkbox (must be true).
4. Taps **“Create Account”** → `submitForm()` in signup mode.

**Validation (`_validateForm`)**:

- All common fields, plus:
  - For **Agent**:
    - Brokerage/name, license number, licensed states, office ZIP, dual‑agency answers, verification statement.
  - For **Loan Officer**:
    - Company, license number, licensed states, office ZIP, verification statement.

If validation fails, shows error via `SnackbarHelper` and stops.

**Signup request flow:**

1. `submitForm()` (signup branch):
   - Normalizes phone.
   - Builds `licensedStatesList`.
   - Builds `additionalData` map per role (agent or loan officer).
   - **Step 1 – Send OTP:**

     - Calls `AuthController.sendVerificationEmail(email)`:

       - **API:** `POST /api/v1/auth/sendVerificationEmail`
       - **Body:** `{ "email": "<trimmed email>" }`
       - On failure: throws exception (propagated, shown via snackbar).

   - **Step 2 – Store signup payload in a local “pending” store:**

     - `PendingSignUpStore.instance.set(...)` stores:
       - Email, password, name.
       - Role (`UserRole`).
       - Phone.
       - Licensed states.
       - `additionalData`.
       - Optional files: profilePic, companyLogo, video.

   - **Step 3 – Navigate to OTP verification:**

     - `Get.to(VerifyOtpView, binding: VerifyOtpBinding(), arguments: { 'email': email })`.

2. **Verify OTP screen** (`VerifyOtpView` + `VerifyOtpController`):

   - User enters OTP.
   - `AuthController.verifyOtp(email, otp)`:

     - **API:** `POST /api/v1/auth/verifyOtp`
     - **Body:** `{ "email": "<email>", "otp": "<otp>" }`

   - On success, `VerifyOtpController` uses the payload from `PendingSignUpStore` to call:

     - `AuthController.signUp(...)` with all required form data and files.

3. **Account creation (`AuthController.signUp`)**

   - **API:** `POST /api/v1/auth/createUser`
   - **Body:** `multipart/form-data` built from:
     - `fullname`, `email`, `password`, `phone`, `role`, `timezone`.
     - `licensedStates` JSON string.
     - Agent- or Loan-Officer-specific fields:
       - `CompanyName`, `liscenceNumber`, dual agency flags, serviceAreas, bio, expertise or specialtyProducts, URLs, verification flags, zipCode.
     - Files:
       - `profilePic`, `companyLogo`, `video`.

   - **Success path:**
     - Validates `responseData['success'] != false`.
     - Extracts `user` object and `_id` → `UserModel`.
     - Sets `_currentUser` and `_isLoggedIn`.
     - Writes `current_user` to storage.
     - Calls `setFCM(user.id)` to send FCM token.
     - Shows “Account created successfully!” snackbar.
     - Calls `_navigateToRoleBasedScreen()` (same as login).

   - **Special failure: email already exists**
     - If backend returns:
       - `{"success": false, "message": "User with this email or phone already exists"}`:
     - `AuthController.signUp` throws `EmailAlreadyExistsException`.
     - In `AuthViewController.submitForm()`:
       - Catches that and:
         - Switches to **login mode**.
         - Pre‑fills the email field.
         - Shows snackbar telling user to sign in instead.
         - **Does NOT** navigate to OTP screen.

   - **Other errors**:
     - All other errors throw and are shown via snackbar; user stays in signup.

#### 2.3.4 Forgot / Reset Password

- **Forgot password screen:** `ForgotPasswordView`
  - Triggered from AuthView login “Forgot password?” link.
  - User enters email.
  - `AuthController.sendForgotPasswordOtp(email)`:

    - **API:** `POST /api/v1/auth/sendPasswordResetEmail`.

- **Verify reset OTP:**
  - `AuthController.verifyPasswordResetOtp(email, otp)`:

    - **API:** `POST /api/v1/auth/verifyPasswordResetOtp`.

- **Reset password screen:** `ResetPasswordView`
  - After OTP verification, user sets new password.
  - `AuthController.resetPassword(email, newPassword)`:

    - **API:** `PATCH /api/v1/auth/resetPassword`.

#### 2.3.5 Logout (All Roles)

- Invoked from various UI (e.g. Agent / Loan Officer app bar, Profile screen):
  - `AuthController.logout()`:
    - Dismisses any active snackbar.
    - Calls `removeFCM(user.id)`:

      - **API:** `GET /api/v1/auth/removeFCM/{userId}`.

    - Clears `_currentUser`, `auth_token`, `current_user` in `GetStorage`.
    - Clears chat data via `MessagesController.clearAllData()`.
    - Clears `CurrentLoanOfficerController.currentLoanOfficer` if present.
    - Navigates to `/auth` (`Get.offAllNamed(AppPages.AUTH)`).

---

## 3. Buyer / Seller Flow

### 3.1 Entry & Navigation

- **Role:** `UserRole.buyerSeller`
- After successful login or signup:
  - `AuthController._navigateToRoleBasedScreen()` → `Get.offAllNamed(AppPages.MAIN)`.
- **Main shell:** `MainNavigationView`:
  - `MainNavigationController` manages:
    - **Bottom nav pages:**
      1. **Home** → `BuyerV2View`
      2. **Favorites** → `FavoritesView`
      3. **Messages** → `MessagesView`
      4. **Profile** → `ProfileView`
    - Keeps an `IndexedStack` of these pages.
    - Uses `circle_nav_bar` for the animated bottom bar.
    - Automatically loads notifications when user navigates to Home (tab index 0).

**Shared behavior:**

- `MainNavigationController` calls `BuyerV2Binding`, `FavoritesBinding`, `MessagesBinding`, `ProfileBinding`, `NotificationsBinding` on init.
- Initializes `MessagesController` & its socket connection early so chat works even if the Messages tab isn’t opened yet.

---

### 3.2 Home – Buyer Search & Discovery (`BuyerV2View`)

**Route:** part of `/main` via bottom nav (index 0)  
**Controller:** `BuyerV2Controller`

#### 3.2.1 Data sources & services

- `LocationController` – for local ZIP detection.
- `AuthController` – to know current user and auth state.
- **Services:**
  - `AgentService` – fetches & tracks agents.
    - **API endpoints used:**
      - `GET /api/v1/agent/getAllAgents/{page}` (`getAllAgentsEndpoint`).
      - `GET /api/v1/agent/getAgentsByZipCode/{zipCode}` (`getAgentsByZipCodeEndpoint`).
      - `GET /api/v1/agent/addSearch/{identifier}` (`getAddSearchEndpoint`) – track searches.
      - `GET /api/v1/agent/addContact/{id}` (`getAddContactEndpoint`) – track contacts.
      - `GET /api/v1/agent/addProfileView/{id}` (`getAddProfileViewEndpoint`) – track profile views.
  - `LoanOfficerService` – fetches loan officers & tracks.
    - **API endpoints used:**
      - `GET /api/v1/loan-officers/all`.
      - `GET /api/v1/loan-officers/{id}`.
      - Plus tracking endpoints via `ApiConstants.getAddSearchEndpoint(...)` equivalents.
  - `ListingService` (`InMemoryListingService`) – local in-memory listing storage (currently not backed by external HTTP; only in-memory CRUD).
  - `ListingTrackingService` – tracks listing views and searches.
    - **API endpoints used (via `ApiConstants`):**
      - `GET /api/v1/agent/addListingView/{listingId}` – track listing detail views.
      - `GET /api/v1/agent/addListingSearch/{listingId}` – track listing search appearances.
  - `ZipCodesService` – ZIP validation / within‑10‑miles queries.
    - **API endpoints:**
      - `GET /api/v1/zip-codes/{country}/{state}/{zipcode}` (`verifyZipCodeEndpoint`).
      - `GET /api/v1/zip-codes/within10miles/{zipcode}/{miles}` (`within10MilesEndpoint`).
      - `GET /api/v1/zip-codes/getstateZip/{country}/{state}` for state zips.

- **Favorites and like/unlike:**
  - Uses buyer “like” endpoints (see Favorites section).

#### 3.2.2 Startup behavior

- `BuyerV2Controller.onInit()`:
  - Configures Dio (`baseUrl = ApiConstants.baseUrl`).
  - Prints current user info if logged in.
  - Calls `_loadMockData()`:
    - Populates `_allAgents`, `_allLoanOfficers`, `_allListings`, `_allOpenHouses` (mock/in‑memory).
  - Attaches search listener (`_onSearchChanged`).
  - Preloads chat threads via `MessagesController.refreshThreads()`.
  - Attempts to auto‑fill search box:
    - Uses cached ZIP from `LocationController.currentZipCode` (from Splash).
    - If invalid/missing, requests location and re-reads ZIP.
    - If valid 5‑digit ZIP:
      - Sets search text to ZIP.
      - Calls `searchByZipCode(zipCode)`.

#### 3.2.3 Search Section

**UI elements:**

- **Search field** (`CustomSearchField`):
  - Placeholder: “Enter a ZIP code to begin your search”.
  - **On change:**
    - If empty → `clearZipCodeFilter()`.
    - If exactly **5 digits** → `searchByZipCode(trimmedValue)`.
    - If less than 5 digits → `clearZipCodeFilter()` (resets filter).
  - “Use current location” icon:
    - Calls `useCurrentLocation()`:
      - Uses `LocationController` to fetch location & ZIP, then calls `searchByZipCode(zip)`.

- **Below search: 2×2 grid of CTAs** (buttons using `CustomButton`):
  1. **Rebate Calculators**
     - **Action:** `Get.toNamed('/rebate-calculator')`
     - **Screen:** `RebateCalculatorView`
     - **APIs:** Rebate Calculator endpoints (see shared section).
  2. **Full Survey**
     - **Action:** navigates to `'/post-closing-survey'` with **test arguments**:
       - `agentId`, `agentName`, `userId`, `transactionId`, `isBuyer`.
     - **Screen:** `PostClosingSurveyView`
     - **APIs:** survey endpoints (see shared).
  3. **Buying Checklist**
     - `Get.toNamed('/checklist', arguments: { 'type': 'buyer', 'title': 'Homebuyer Checklist (with Rebate!)' })`
     - Screen: `ChecklistView`.
  4. **Selling Checklist**
     - `Get.toNamed('/checklist', arguments: { 'type': 'seller', 'title': 'Home Seller Checklist (with Rebate!)' })`

#### 3.2.4 Tabs

**Tabs across top:**

1. **Agents**
2. **Homes for Sale**
3. **Open Houses**
4. **Loan Officers**

- `selectedTab` is an observable (`0–3`).
- Each tab changes color and bottom border when selected.
- On tap: `controller.setSelectedTab(index)`.

#### 3.2.5 Agents Tab

- Shows a vertically scrolling list of **AgentCard** items.
- Data logic:
  - If a current ZIP filter is active:
    - `displayedAgents` = top N agents for that ZIP (with incremental “view next 10”).
  - Without ZIP filter:
    - `agents` comes from `_allAgents`, optionally paginated from backend.

- **Pagination & “next 10” behavior:**
  - `canShowNext10Agents` & `_agentsDisplayCount`.
  - If using ZIP pagination:
    - “View next 10 closest agents” button:
      - Calls `showNext10Agents()`.

- **Actions per card:**
  - **Tap agent card:**
    - `controller.viewAgentProfile(agent)`:
      - Typically calls `Get.toNamed(AppPages.AGENT_PROFILE, arguments: { 'agent': agent })`.
      - **APIs inside AgentProfile** (separate views/controllers):
        - `AgentService` fetches full profile, reviews, metrics.
  - **Favorite icon:**
    - Calls `toggleFavoriteAgent(agent.id)`:
      - Updates local favorite IDs and calls buyer like endpoint:
        - **API:** `POST /api/v1/buyer/likeAgent/{agentId}` (via `ApiConstants.getLikeAgentEndpoint`).
  - **Contact CTA:**
    - `contactAgent(agent)`:
      - Calls `_recordContact(agent.id)`:
        - **API:** `GET /api/v1/agent/addContact/{agentId}`.
      - Locates or creates a chat thread for this agent via `MessagesController` and navigates into the chat (see Messages section).

- **Tracking search and views:**
  - On search or listing of agents, `BuyerV2Controller` calls:
    - `_recordSearch(identifier)`:
      - **API:** `GET /api/v1/agent/addSearch/{identifier}` (identifier may be agent name or ID).
  - When opening an agent profile:
    - `AgentService.recordProfileView(agent.id)`:
      - **API:** `GET /api/v1/agent/addProfileView/{id}`.

#### 3.2.6 Homes for Sale Tab

- List of property **listings** using in‑memory `ListingService`.
- Each card:
  - Shows listing photo (via `CachedNetworkImage`), price, address, tags (e.g. dual agency allowed).
  - Favorite icon overlays the photo:
    - `toggleFavoriteListing(listing.id)`:
      - Updates local favorites.
      - **API:** `POST /api/v1/buyer/like` with listing payload (via `ApiConstants.likeListingEndpoint`).

- **Tap listing card:**
  - `viewListing(listing)`:
    - `Get.toNamed('/listing-detail', arguments: { 'listing': listing })`.
  - `ListingDetailView`:
    - Uses `ListingTrackingService` to call:
      - **API:** `GET /api/v1/agent/addListingView/{listingId}`.

- **“Load next 10” button:**
  - For ZIP‑filtered scenario, `showNext10Listings()` increments `_listingsDisplayCount`.

- **Data source:**
  - Currently `InMemoryListingService` – no direct listing HTTP requests in `BuyerV2Controller`, but real tracking via `ListingTrackingService`.

#### 3.2.7 Open Houses Tab

- Shows `OpenHouseModel` items, each linked to a `Listing`.
- UI card:
  - Listing photo.
  - **“Open House”** label with date and time range (formatted via `intl`).
  - Favorite overlay (same listing favorite toggle as in listings tab).
- **Tap card:**
  - `viewOpenHouse(openHouse)`:
    - Resolves its `Listing` via `getListingForOpenHouse`.
    - Navigates to `/listing-detail` with that listing.
- “Load next 10” button: `showNext10OpenHouses()`.

#### 3.2.8 Loan Officers Tab

- Shows `LoanOfficerCard` items.
- Data:
  - `loanOfficers` and `displayedLoanOfficers` follow same ZIP display logic as agents.

- **Actions per card:**
  - **Tap card:**
    - `viewLoanOfficerProfile(loanOfficer)`:
      - `Get.toNamed('/loan-officer-profile', arguments: { 'loanOfficer': loanOfficer })`.
      - Profile screen uses `LoanOfficerService` to fetch more detail if needed.
  - **Favorite icon:**
    - `toggleFavoriteLoanOfficer(loanOfficer.id)`:
      - Local favorites + API:
        - **API:** `POST /api/v1/loan-officers/{id}/like` (`getLikeLoanOfficerEndpoint`).
  - **Contact CTA:**
    - `contactLoanOfficer(loanOfficer)`:
      - Records contact/search metrics and navigates into chat (via `MessagesController`), analogous to agents.

- **Search tracking:**
  - `_recordLoanOfficerSearch(loanOfficerId, loanOfficerName)`:
    - Uses `LoanOfficerService` tracking methods (internally relying on `ApiConstants.getAddSearchEndpoint` or similar).

---

### 3.3 Favorites Screen (`FavoritesView`)

**Route:** Tab 1 in `MainNavigationView` bottom nav  
**Controller:** `FavoritesController`

**Purpose:**

- Centralized list of items liked by the buyer:
  - Favorite **agents**.
  - Favorite **loan officers**.
  - Favorite **listings**.

**Behavior:**

- Uses stored favorite IDs (GetStorage + in‑memory).
- For each item:
  - Card similar to AgentCard/LoanOfficerCard/Listing preview.
  - Actions:
    - Navigate to profile/detail:
      - Agent → `AgentProfileView`.
      - Loan officer → `LoanOfficerProfileView`.
      - Listing → `ListingDetailView`.
    - **Unfavorite**:
      - Reverses local state and calls like endpoints again to toggle off.

**APIs:**

- Same as like endpoints in `BuyerV2Controller`:
  - `POST /buyer/likeAgent/{agentId}`
  - `POST /loan-officers/{id}/like`
  - `POST /buyer/like`

Data flows from favorites to **detail screens** via Get arguments (entity or ID), then detail controllers fetch additional data via `AgentService` / `LoanOfficerService` or reuse passed model.

---

### 3.4 Messages Screen (`MessagesView`)

**Route:** Tab 2 in bottom nav (`/messages` route for direct navigation)  
**Controller:** `MessagesController` + `SocketService`

**Purpose:**

- Unified chat for **buyers**, **agents**, and **loan officers**.

**Behaviors (shared across roles):**

- **Threads list:**
  - `MessagesController.allConversations` is preloaded at app start (Splash/BuyerV2).
  - **API:** `GET /api/v1/chat/threads?userId={currentUserId}` (`getChatThreadsEndpoint`).
- **Open conversation:**
  - Loads messages for thread:
    - **API:** `GET /api/v1/chat/thread/{threadId}/messages?userId={userId}` (`getThreadMessagesEndpoint`).
- **Send message:**
  - Sends via Socket.IO and/or REST endpoint (configured in `SocketService` + `ChatService`).
- **Mark thread as read:**
  - **API:** `POST /api/v1/chat/thread/mark-read`.
- **Delete conversation (if supported):**
  - **API:** `POST /api/v1/chat/deleteChat`.

**Data movement:**

- Contact actions from Buyer home, Agent dashboard, Loan Officer dashboard create or open threads:
  - They pass counterpart `userId`, `userName`, `role`, and `profileImage` into `ContactView` / Messages context.
  - Chat module then uses those IDs to find or create the right thread.

---

### 3.5 Profile Screen (`ProfileView`)

**Route:** Tab 3 in bottom nav  
**Binding:** `ProfileBinding`  
**Behavior (for Buyer/Seller):**

- Displays:
  - Name, email, optional phone.
  - Role label “Buyer/Seller”.
- Actions typically include:
  - **View notifications** (`/notifications`).
  - **Help & Support** (`/help-support`).
  - **About / Legal** (`/about-legal`).
  - **Privacy Policy** (`/privacy-policy`).
  - **Terms of Service** (`/terms-of-service`).
  - **Logout** (calls `AuthController.logout()`).

APIs here are minimal; mostly uses stored `UserModel`. Some profile update functions are centralized in `AuthController.updateUserProfile(…)` (used heavily by Agent/Loan Officer, less so by buyers, depending on UI).

---

### 3.6 Buyer & Seller Lead Forms

#### 3.6.1 Buyer Lead Form (`BuyerLeadFormV2View`)

**Route:** `/buyer-lead-form`  
**Controller:** `BuyerLeadFormV2Controller`

**Entry points:**

- Commonly from:
  - Agent profile CTAs (“Contact Agent” / “Work with this Agent”).
  - Listing cards / property detail screens (passing property + agent info in `Get.arguments`).

**Data inputs:**

- Preloaded from `Get.arguments`:
  - `property`: Map with property metadata (id, address, etc.).
  - `agent`: Map with agent metadata (id, name).
- User fields:
  - Full name, email, phone, location ZIP (with “use current location”).
  - Preferences: looking to buy, property types, budget range, beds/baths, timeframe, etc.
  - Additional preferences: must‑have features, comments.
  - Whether they are pre‑approved, working with an agent, want to search for loan officers, awareness of rebates, how they heard about GetaRebate.
  - Auto MLS search toggle.

**Submit flow:**

- Validation (ensures essential fields).
- Builds payload including:
  - Buyer contact info.
  - Property/agent context (if present).
  - Preference answers.
  - Current logged‑in buyer ID from `AuthController` (if available).

- **API:** `LeadService.createLead(leadData, leadType: 'buyer')`

  - **Method:** `POST`
  - **URL:** `/api/v1/buyer/createLead`
  - **Body:** JSON `leadData`.

- On success:
  - Shows success snackbar.
  - Navigates back to previous screen (often property/agent detail or home).

#### 3.6.2 Seller Lead Form (`SellerLeadFormView`)

**Route:** `/seller-lead-form`  
**Controller:** `SellerLeadFormController`

**Entry points:**

- From seller‑oriented CTAs (e.g., selling checklist, “Talk to an agent about selling”).

**Data inputs:**

- Preloaded `property` and `agent` from `Get.arguments` if provided.
- Seller form fields:
  - Contact: name, email, phone.
  - Property: address, city, year built, square footage, recent updates.
  - Market: estimated value range, property type, beds/baths, timeframe to sell.
  - Status: currently listed? working with another agent? living situation.
  - Motivation and “most important” (multi‑select).
  - Awareness of rebate, interest in rebate calculator, “how did you hear?”.

**Submit flow:**

- Validates required fields.
- Builds `leadData` with `leadType: 'seller'`.
- **API:** same endpoint as buyer:

  - `POST /api/v1/buyer/createLead` with all seller form fields.

- Success:
  - Shows success snackbar.
  - Navigates back.

**Data movement:**

- Both lead forms create **Lead** records consumed by:
  - **Agent** dashboards (`LeadsService.getLeadsByAgentId`) and
  - **Buyer** lead lists (`LeadsService.getLeadsByBuyerId`) in other parts of the app.

---

### 3.7 Property & Listing Detail

- **Property Detail** (`/property-detail`)
  - `PropertyDetailView` + `PropertyDetailController`.
  - Receives listing/property object via `Get.arguments`.
  - Uses:
    - `ListingTrackingService` to record views/searches.
    - `RebateCalculatorWidget` to show property-specific rebate estimates.
  - Actions:
    - “Request showing” or “Contact agent” → navigates to `BuyerLeadFormV2View` with property + agent context.
    - “Open house” CTAs → open open house info or directions.

- **Listing Detail** (`/listing-detail`)
  - `ListingDetailView` + `ListingDetailController`.
  - Receives `Listing` via arguments.
  - Calls tracking API for listing views via `ApiConstants.getAddListingViewEndpoint`.

---

### 3.8 Checklists & Surveys (Buyer/Seller)

- **Consumer checklist** (`/checklist`)
  - `ChecklistView` + `ChecklistController`.
  - Input via `Get.arguments`:
    - `type: 'buyer' | 'seller'`.
    - `title` text.
  - Local JSON-defined steps; may integrate with `RebateChecklist` for more advanced flows.
- **Rebate checklist** (`/rebate-checklist`)
  - `RebateChecklistView` + `RebateChecklistController`.
  - More detailed rebate process steps (shared with Agent/Loan Officer views).
- **Post‑closing survey** (`/post-closing-survey`)
  - `PostClosingSurveyView` + `PostClosingSurveyController`.
  - **API:** `SurveyService` / `SurveyRatingService` endpoints (POST responses, GET questions).
- **Simple survey** (`/simple-survey`)
  - `SimpleSurveyView` (lightweight version).

---

## 4. Agent Flow

### 4.1 Entry & Role Routing

- **Role:** `UserRole.agent`.
- After login or signup, `AuthController._navigateToRoleBasedScreen()`:
  - `Get.offAllNamed(AppPages.AGENT)` → `/agent`.
- `SplashController` also routes to `/agent` if restoring an Agent session.

---

### 4.2 Agent Dashboard Shell (`AgentView`)

**Route:** `/agent`  
**Controller:** `AgentController`  
**Main tasks:**

- Manage **ZIP code territories**.
- Manage **listings**.
- View **leads**, **billing/subscriptions**, and **performance stats**.
- Access **agent checklist** and compliance tools.
- Chat & notifications.

#### 4.2.1 AppBar

- Title: “Agent Dashboard”.
- Actions:
  - **Skip** (ZIP selection) – shown when `showZipSelectionFirst` is true:
    - Calls `AgentController.skipZipSelection()`; sets `_hasSkippedZipSelection` so agent can bypass initial ZIP claim.
  - **Messages icon**:
    - `onPressed: () => Get.toNamed('/messages')`.
  - **Notification icon**:
    - `NotificationBadgeIcon` – shows unread count; opens `/notifications` from other UI.
  - **Logout icon**:
    - Calls a confirmation dialog then `AuthController.logout()`.

#### 4.2.2 Tabs (Horizontal, scrollable)

Tabs constant:

1. **Dashboard**
2. **ZIP Codes**
3. **Listings**
4. **Stats**
5. **Billing**
6. **Leads**

The selected tab index is stored in `AgentController._selectedTab`.

##### 4.2.2.1 Dashboard Tab

- Summary view including:
  - Quick metrics:
    - Searches appeared in.
    - Profile views.
    - Contacts.
    - Website clicks.
    - Total revenue (derived from subscription/lead tracking).
  - Featured cards:
    - **Rebate Checklist**:
      - CTA: “View Complete Checklist” → `Get.toNamed('/rebate-checklist')`.
    - Rebate compliance notice widget.

- Data sources:
  - `RebateStatesService` – for state‑level info.
  - `NotificationService` – for recent activity.
  - `UserService` – for profile metrics where applicable.

##### 4.2.2.2 ZIP Codes Tab

**Purpose:**

- Manage **exclusive ZIP territories** for leads & listings, including subscription billing.

**Data state:**

- `_claimedZipCodes` (`List<ZipCodeModel>`) – ZIPs currently held by this agent.
- `_availableZipCodes` – ZIPs in a selected state not yet claimed.
- `_stateZipCodesFromApi` – backing of all state ZIPs.
- `_selectedState` – currently selected state for searching available ZIPs.
- Several sets and maps for waiting list, processing flags, joined waiting lists.

**APIs:**

- `ZipCodePricingService` + `ZipCodesService`:
  - `GET /api/v1/zip-codes/getstateZip/{country}/{state}` – available zips.
  - `GET /api/v1/zip-codes/validate/{zipcode}/{state}` – validate ZIP.
- Claim/release endpoints (`ApiConstants`):
  - `POST /api/v1/zip-codes/claim` – claim ZIP (with payment).
  - `POST /api/v1/zip-codes/release` – release ZIP.
  - `POST /api/v1/subscription/cancelSubscription` – cancel subscription for a ZIP.
- First ZIP claim status:
  - `GET /api/v1/auth/users/{userId}` (already fetched in Splash; reused here).

**UI interactions:**

- When **firstZipCodeClaimed == false** and user hasn’t skipped:
  - Agents see ZIP selection screen before normal tabs.
- Within ZIP tab:
  - Switchable subtabs: **“Claimed ZIPs” / “Available ZIPs”**.
  - **Claim ZIP** flow:
    1. Select state.
    2. Search or scroll available ZIP list.
    3. Tap **“Claim”** on a ZIP:
       - Triggers network calls to:
         - Validate and price the ZIP.
         - Open `PaymentWebView` for Stripe checkout.
         - On success:
           - **API:** `GET /subscription/paymentSuccess/{sessionId}/{zipcode}` (via `ApiConstants.getPaymentSuccessPath`).
           - Then `POST /zip-codes/claim`.
       - Updates local `_claimedZipCodes` and marks `firstZipCodeClaimed = true`.
  - **Release ZIP**:
    - Initiates a release flow that:
      - Calls release endpoint.
      - Optionally cancels subscription for that ZIP.
  - **Waiting list**:
    - If a ZIP is full, an agent can be added to `WaitingListEntry` for that ZIP.
    - `AgentController` keeps `_waitingListRequests`, `_waitingListEntries`, `_joinedWaitingListZipCodes`.

##### 4.2.2.3 Listings Tab

**Purpose:**

- Manage the agent’s **for‑sale listings**.

**Data:**

- `_myListings` – filtered list.
- `_allListings` – all agent listings from API.
- Filters: `_selectedStatusFilter` (market status) and `_searchQuery` (title/address/city/state/ZIP).

**Key actions:**

- **Add listing** (floating action button when tab index == 2):
  - `_handleAddListing(context)`:
    - Navigates to `Get.toNamed('/add-listing')` → `AddListingView`.
    - AddListing flow:
      - Captures property info, price, photos, etc.
      - **API:** `POST /api/v1/agent/createListing` (`createListingEndpoint`).
- **Edit listing**:
  - From listing row context menu, navigate to `EditListingView` or `EditAgentListingView`.
  - **API:** `PATCH /api/v1/agent/updateListing/{id}` (via service).
- **Listing stats:**
  - Each listing shows search count, views, contacts.
  - `AgentController._applyFilters()` recalculates filtered list.

##### 4.2.2.4 Stats Tab

- Shows aggregated metrics from:
  - `NotificationService` activity.
  - `LeadsService` or proposal service (where used).
- Metrics:
  - `searchesAppearedIn`, `profileViews`, `contacts`, `websiteClicks`, `totalRevenue`.
- Helps agent understand performance across ZIPs and listings.

##### 4.2.2.5 Billing Tab

- Uses `SubscriptionModel` and `_subscriptions` list to show:
  - Active subscriptions (non‑canceled).
  - Free period states (if any).
  - Payment history.
- **APIs:**
  - Subscription endpoints under `/subscription/**` (via `ApiConstants`).
  - Cancel, update end date, etc.

##### 4.2.2.6 Leads Tab

- Shows leads tied to the agent:
  - Uses `LeadsService.getLeadsByAgentId(agentId)`:

    - **API:** `GET /api/v1/buyer/getLeadsByAgentId/{agentId}`.

- Each `Lead` can be:
  - Opened in **Lead Detail** view (`/lead-detail`).
  - Responded to:
    - **API:** `POST /api/v1/buyer/respondToLead/{leadId}`.
  - Marked complete:
    - **API:** `POST /api/v1/buyer/markLeadComplete/{leadId}`.

**Lead data is ultimately created from Buyer/Seller lead forms.**

---

### 4.3 Agent Profile & Edit Profile

- **Profile view route:** `/agent-profile`  
  - `AgentProfileView` + `AgentProfileController`.
  - Shows:
    - Name, brokerage, licensed states.
    - Bio, video, expertise, service areas.
    - Ratings and reviews (`AgentReviewsView`).
  - **APIs:**
    - `UserService.getAgentById()` (wraps `ApiConstants.getUserByIdEndpoint` + agent-collection endpoints).
    - `ReviewService` for reviews.

- **Edit profile route:** `/agent-edit-profile`  
  - `AgentEditProfileView` + `AgentEditProfileController`.
  - Uses `AuthController.updateUserProfile(...)`:

    - **API:** `PATCH /api/v1/auth/updateUser/{userId}` with multipart form:
      - `fullname`, `phone`, `CompanyName`, `bio`, `zipCode`, `licensedStates`, `areasOfExpertise`, `serviceAreas`, `website_link`, `google_reviews_link`, `thirdPartReviewLink`, etc.
      - Optional `profilePic`, `companyLogo`, `video`.

---

### 4.4 Agent Checklist & Rebate Tools

- **Agent-specific checklist route:** `/agent-checklist`
  - `AgentChecklistView` + `AgentChecklistController`.
  - Provides an internal agent workflow for managing rebate transactions (stepwise tasks).
- **Rebate calculators:**
  - Agent can access the same `/rebate-calculator` route from in‑app CTAs:
    - E.g., from `AgentView` (bottom sheet `RebateCalculatorOptionBottomSheet`).
  - Uses `RebateCalculatorApiService`:
    - **APIs:**
      - `POST /api/v1/rebate/estimate` (estimated rebate tier and range).
      - `POST /api/v1/rebate/calculate-exact` (exact commission/rebate amounts).
      - `POST /api/v1/rebate/calculate-seller-rate` (seller savings and contract listing fee).
  - Responses parsed into `RebateCalculatorResponse` for display and explanation.

---

### 4.5 Messaging & Notifications (Agent)

- **Messages:** identical shared module as described in Buyer section.
- **Notifications:**
  - `NotificationService`:
    - **API:** `GET /api/v1/notifications/{userId}` (exact path from `ApiConstants`).
  - `NotificationsView` shows:
    - New leads.
    - Subscription events.
    - Contact events.
    - System announcements.

---

## 5. Loan Officer Flow

### 5.1 Entry & Role Routing

- **Role:** `UserRole.loanOfficer`.
- After login/signup:
  - `AuthController._navigateToRoleBasedScreen()`:
    - Ensures `CurrentLoanOfficerController.fetchCurrentLoanOfficer(user.id)` first.
    - On success → `Get.offAllNamed(AppPages.LOAN_OFFICER)` (`/loan-officer`).
    - On failure → logs out and shows error.

- Splash resume logic mirrors this for restored sessions.

---

### 5.2 Loan Officer Dashboard Shell (`LoanOfficerView`)

**Route:** `/loan-officer`  
**Controller:** `LoanOfficerController` (business logic) + `CurrentLoanOfficerController` (profile data)

#### 5.2.1 AppBar

- Title: “Loan Officer Dashboard”.
- Subtitle: “Welcome, {officer.name}” or “Loading your profile…”.
- Actions:
  - **Skip** (ZIP selection) when `showZipSelectionFirst` is true.
  - **Messages** icon → `/messages`.
  - **NotificationBadgeIcon** for notifications.
  - **Logout** icon (calls `AuthController.logout()`).

#### 5.2.2 Tabs

Tabs constant:

1. **Dashboard**
2. **Messages**
3. **ZIP Codes**
4. **Billing**
5. **Checklists**

##### 5.2.2.1 Dashboard Tab

- Uses `CurrentLoanOfficerController.currentLoanOfficer` to show:
  - Overview of loans.
  - Search appearances, profile views, contacts.
  - Product mix based on `specialtyProducts`.
- Integrates:
  - `RebateStatesService` – filter to allowed states.
  - `NotificationService` – recent activity.

##### 5.2.2.2 Messages Tab

- For convenience a separate tab navigates into messaging (`MessagesView`), but the Messages module is global.
- Preloading & APIs identical to Buyer and Agent.

##### 5.2.2.3 ZIP Codes Tab (Loan Officers)

**Controller:** `LoanOfficerController`  
**Data state:**

- `_claimedZipCodes` – `List<LoanOfficerZipCodeModel>`.
- `_availableZipCodes`, `_allZipCodes`, `_stateZipCodesFromApi`.
- `_firstZipCodeClaimed` – determines whether to show “ZIP selection first” UI.
- `_waitingListRequests`, `_waitingListEntries` for full ZIP waiting lists.
- `_loadingZipCodeIds` – per‑ZIP busy indicators.

**APIs & services:**

- `LoanOfficerZipCodeService`:
  - `GET /api/v1/loan-officer-zip-codes/getstateZip/{country}/{state}` (loan-officer-specific variant).
  - `POST /api/v1/loan-officer-zip-codes/claim` – claim loan-officer ZIP.
  - `POST /api/v1/loan-officer-zip-codes/release` – release.
- `LoanOfficerZipCodePricingService`:
  - Calculates subscription prices per ZIP (pop‑based).
  - Payment flows use `PaymentWebView` + Stripe session endpoints.
- `ApiConstants`:
  - Same subscription payment success path: `getPaymentSuccessPath(sessionId, zipcode)`.

**UI flow:**

- If `firstZipCodeClaimed == false` and user hasn’t skipped:
  - Show full-screen ZIP selection similar to agent.
- Otherwise:
  - Tabbed view:
    - **Claimed ZIPs:**
      - Shows active ZIPs, stats (searches, contacts, revenue).
      - Actions:
        - Release.
        - View waiting list.
    - **Available ZIPs:**
      - Filter by state then ZIP.
      - Claim flows similar to Agents.

##### 5.2.2.4 Billing Tab

- `SubscriptionModel` & `_subscriptions` list:
  - Shows free period status, active subscriptions, cancellation state.
  - Exposes actions:
    - Cancel subscription for zipped territories.
- **APIs:**
  - `/subscription/**` endpoints from `ApiConstants` (same family as Agent).

##### 5.2.2.5 Checklists Tab

- **Loan Officer checklist route:** `/loan-officer-checklist`
  - `LoanOfficerChecklistView` + `LoanOfficerChecklistController`.
  - Presents a loan-officer‑centric stepwise checklist for rebate‑friendly transactions (loan and rebate coordination).
- This tab also references **buyer version** of consumer checklists:
  - Uses `Get.toNamed(AppPages.CHECKLIST, arguments: { 'type': 'buyer' })` to open consumer‑facing path for perspective.

---

### 5.3 Loan Management

- **List of loans:**
  - Stored in `_loans` (`List<LoanModel>`).
  - Fetched via `LoanOfficerController.fetchLoans()`:
    - **API:** `GET /api/v1/loans/{loanOfficerId}` (exact path via internal constants).
- **Add Loan** (`/add-loan`)
  - Floating action button on dashboard or empty state.
  - `AddLoanView` + `AddLoanController`.
  - **API:** `POST /api/v1/loans` (loan details).
- **Edit Loan** (`/edit-loan`)
  - Popup menu action on a loan card.
  - `EditLoanView` + `AddLoanController` or dedicated edit controller.
  - **API:** `PATCH /api/v1/loans/{loanId}`.
- **Delete Loan:**
  - Prompt via `_showDeleteConfirmDialog`.
  - **API:** `DELETE /api/v1/loans/{loanId}`.

---

### 5.4 Loan Officer Profile & Edit Profile

- **Profile view:** `/loan-officer-profile`
  - `LoanOfficerProfileView` + `LoanOfficerProfileController`.
  - Shows:
    - Name, company, licensed states.
    - Bio, video, specialty products.
    - Mortgage application link and reviews URLs.
- **Edit profile:** `/loan-officer-edit-profile`
  - `LoanOfficerEditProfileView` + `LoanOfficerEditProfileController`.
  - Uses `AuthController.updateUserProfile` similarly to Agent but with loan‑officer fields:
    - `CompanyName`, `licenseNumber`, `serviceAreas`, `specialtyProducts`, `mortgageApplicationUrl`, `externalReviewsUrl`, `yearsOfExperience`, `languagesSpoken`, `discountsOffered`, etc.

---

### 5.5 Messaging & Notifications (Loan Officer)

- Messaging: same shared module (threads, messages, mark read, delete).
- Notifications: `NotificationService` and `NotificationsView` show:
  - New leads in claimed ZIPs.
  - Subscription and billing events.
  - Contact events (when buyers request loan officers).

---

## 6. Shared Modules & Data Flows

### 6.1 Rebate Calculator

**Route:** `/rebate-calculator`  
**View:** `RebateCalculatorView` + `RebateCalculatorController`  
**Services:**

- `RebateCalculatorApiService`
- `RebateCalculatorService`

**APIs (via `ApiConstants`):**

- `POST /api/v1/rebate/estimate`:
  - Inputs: price, commission %, ZIP/state, buyer/agent context.
  - Returns tier, estimated rebate range, commission range, warnings/notes.
- `POST /api/v1/rebate/calculate-exact`:
  - Inputs: actual contract terms.
  - Returns exact rebate amount, total commission, net agent commission.
- `POST /api/v1/rebate/calculate-seller-rate`:
  - Inputs: listing price, original commission, requested rebate, etc.
  - Returns seller savings, new effective rate, listing fee text for contracts.

**Data movement:**

- Inputs may be prefilled from:
  - `ListingDetailView` / `PropertyDetailView` (property price, state).
  - Default state from `LocationController`.
- Outputs reused across:
  - Buyer information screens (explaining savings).
  - Agent and Loan Officer dashboards (to configure offers and disclaimers).

---

### 6.2 Checklists

- **Consumer checklist** (`/checklist`) – buyer/seller view.
- **Rebate checklist** (`/rebate-checklist`) – process‑oriented steps for all roles, but particularly:
  - Buyers using app-level CTAs.
  - Agents via dashboard.
  - Loan Officers via direct CTAs referencing buyer version.

---

### 6.3 Notifications

- **Notifications screen:** `/notifications`
  - `NotificationsView` + `NotificationsController`.
- **Service:** `NotificationService`:
  - **API:** `GET /api/v1/notifications/{userId}` to fetch notifications list.
- Consumers are all roles; unread counts are shown in app bars and bottom navs where relevant.

---

### 6.4 Proposals (Offers & Closings)

- **Routes:**
  - `/proposals` → `ProposalsView` + `ProposalController`.
  - `/lead-detail` → `LeadDetailView` + `LeadDetailController`.

**APIs:**

- `ProposalService` calls endpoints such as:
  - `GET /api/v1/proposals/{agentId}` (agent view).
  - `GET /api/v1/proposals/{buyerId}` (buyer view).
  - `POST /api/v1/proposals/accept/{proposalId}`.
  - `POST /api/v1/proposals/reject/{proposalId}`.

**Data flow:**

- Generated from `Lead` records and actions by agents/loan officers.
- Feeds into **post‑closing survey** screens for feedback capture.

---

## 7. Complete Application Flowchart (All Roles)

Below is a combined flowchart describing major route transitions and role‑based flows.

```mermaid
flowchart TD

  %% Startup and Auth
  A[App Start\nMyApp] --> B[SplashView\n/splash]
  B -->|Timer 1.5s| C{AuthController\nisLoggedIn?}

  C -->|No| D[OnboardingView\n/onboarding]
  D --> E[AuthView\n/auth]

  C -->|Yes, Buyer/Seller| F[MainNavigationView\n/main]
  C -->|Yes, Agent| G[AgentView\n/agent]
  C -->|Yes, Loan Officer| H[LoanOfficerView\n/loan-officer]

  %% AuthView flows
  E -->|Login mode\nSign In| I[AuthController.login\nPOST /auth/login]
  I -->|OK, role=Buyer/Seller| F
  I -->|OK, role=Agent| G
  I -->|OK, role=LoanOfficer| H

  E -->|Signup mode\nCreate Account| J[sendVerificationEmail\nPOST /auth/sendVerificationEmail]
  J --> K[VerifyOtpView\n/verify-otp]
  K --> L[AuthController.signUp\nPOST /auth/createUser]
  L -->|role=Buyer/Seller| F
  L -->|role=Agent| G
  L -->|role=LoanOfficer| H

  E -->|Forgot password| M[ForgotPasswordView\n/forgot-password]
  M --> N[sendPasswordResetEmail]
  N --> O[VerifyPasswordResetOtp\n/verify-otp-reset]
  O --> P[ResetPasswordView\n/reset-password]

  %% Buyer/Seller Main Nav
  subgraph Buyer_Seller_Flow [Buyer / Seller Flow]
    F --> F1[Home\nBuyerV2View]
    F --> F2[FavoritesView]
    F --> F3[MessagesView]
    F --> F4[ProfileView]

    %% Home tabs
    F1 --> F1A[Search ZIP\nZipCodesService]
    F1 --> F1B[Agents Tab]
    F1 --> F1C[Homes for Sale Tab]
    F1 --> F1D[Open Houses Tab]
    F1 --> F1E[Loan Officers Tab]
    F1 --> F1F[Rebate Calculators\n/rebate-calculator]
    F1 --> F1G[Buying/Selling Checklists\n/checklist]

    %% Agent flows from Buyer home
    F1B -->|View profile| AGP[AgentProfileView\n/agent-profile]
    F1B -->|Contact| MSG1[MessagesView\ncontact agent]

    %% Listing flows
    F1C -->|Tap listing| LD[ListingDetailView\n/listing-detail]
    F1D -->|Tap open house| LD

    %% Lead forms
    LD --> BLF[BuyerLeadFormV2View\n/buyer-lead-form]
    LD --> SLF[SellerLeadFormView\n/seller-lead-form]
    BLF -->|POST /buyer/createLead| Q[Lead created]
    SLF -->|POST /buyer/createLead| Q

    %% Favorites, Messages, Profile
    F2 -->|Tap item| AGP
    F2 -->|Tap loan officer| LOP[LoanOfficerProfileView\n/loan-officer-profile]
    F3 -->|Open thread| MSGT[Thread Messages\n/chat endpoints]
    F4 -->|Notifications| NOTIF[NotificationsView\n/notifications]
    F4 -->|Help, Legal, TOS, Privacy| HL[Static Info Views]
    F4 -->|Logout| E
  end

  %% Agent Flow
  subgraph Agent_Flow [Agent Flow]
    G --> G1[Dashboard Tab]
    G --> G2[ZIP Codes Tab]
    G --> G3[Listings Tab]
    G --> G4[Stats Tab]
    G --> G5[Billing Tab]
    G --> G6[Leads Tab]

    %% Agent ZIP
    G2 -->|First login & no ZIP| G2A[ZIP Selection First]
    G2 -->|Claim ZIP| G2B[PaymentWebView\nStripe]
    G2B -->|GET /subscription/paymentSuccess| G2C[POST /zip-codes/claim]
    G2 -->|Release ZIP| G2D[POST /zip-codes/release]
    G2 -->|Waiting list| G2E[WaitingListEntry\nper ZIP]

    %% Agent Listings
    G3 -->|Add Listing| G3A[AddListingView\n/add-listing]
    G3A -->|POST /agent/createListing| G3B[Listing created]
    G3 -->|Edit Listing| G3C[EditListingView\n/edit-listing]
    G3 -->|Tap Listing| LD
    LD -->|Track view| G3D[GET /agent/addListingView/{id}]

    %% Agent Leads & Proposals
    G6 -->|GET /buyer/getLeadsByAgentId| G6A[Leads list]
    G6A -->|Open lead| G6B[LeadDetailView\n/lead-detail]
    G6B -->|Respond| G6C[POST /buyer/respondToLead/{id}]
    G6B -->|Mark complete| G6D[POST /buyer/markLeadComplete/{id}]

    %% Agent profile & checklist
    G1 -->|Agent Checklist CTA| G1A[AgentChecklistView\n/agent-checklist]
    G1 -->|Rebate Checklist CTA| G1B[RebateChecklistView\n/rebate-checklist]
    G1 -->|Edit Profile| G1C[AgentEditProfileView\n/agent-edit-profile]
    G1C -->|PATCH /auth/updateUser/{id}| G1D[Profile updated]

    %% Agent messaging & notifications
    G -->|Messages icon| F3
    G -->|Notifications| NOTIF
  end

  %% Loan Officer Flow
  subgraph LO_Flow [Loan Officer Flow]
    H --> H1[Dashboard Tab]
    H --> H2[Messages Tab]
    H --> H3[ZIP Codes Tab]
    H --> H4[Billing Tab]
    H --> H5[Checklists Tab]

    %% LO ZIP
    H3 -->|First login & no ZIP| H3A[ZIP Selection First]
    H3 -->|Claim ZIP| H3B[PaymentWebView\nStripe]
    H3B -->|GET /subscription/paymentSuccess| H3C[POST /loan-officer-zip-codes/claim]
    H3 -->|Release ZIP| H3D[POST /loan-officer-zip-codes/release]
    H3 -->|Waiting list| H3E[WaitingListEntry\nper ZIP]

    %% LO Loans
    H1 -->|View Loans| H1A[Loan list\nGET /loans/{officerId}]
    H1A -->|Add Loan| H1B[AddLoanView\n/add-loan]
    H1B -->|POST /loans| H1C[Loan created]
    H1A -->|Edit Loan| H1D[EditLoanView\n/edit-loan]
    H1A -->|Delete Loan| H1E[DELETE /loans/{id}]

    %% LO Checklists
    H5 --> H5A[LoanOfficerChecklistView\n/loan-officer-checklist]
    H5 -->|View Buyer Checklist| H5B[ChecklistView\n/checklist type=buyer]

    %% LO messaging & notifications
    H2 --> F3
    H -->|Notifications| NOTIF
  end
```

---

This markdown describes the **current implemented flows** for Buyer/Seller, Agent, and Loan Officer roles, including **signup/login**, **navigation**, **screens and actions**, **APIs per feature**, and **data movement between screens and services**.
