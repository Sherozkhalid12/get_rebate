
class ApiConstants {
  const ApiConstants._();

  // ============================================================================
  // BASE URL CONFIGURATION
  // ============================================================================
  
  // Base URL for all API calls
  static const String _baseUrl = 'http://98.93.16.113:3001';

  // API version prefix
  static const String _apiVersion = '/api/v1';

  // Base URL getter
  static String get baseUrl {
    return _baseUrl;
  }

  // Full API base URL with version
  static String get apiBaseUrl => "$baseUrl$_apiVersion";

  // API Endpoints
  static String get chatEndPoint => "$apiBaseUrl/chat/";
  static String get userEndPoint => "$apiBaseUrl/user/";
  static String get authEndPoint => "$apiBaseUrl/auth/";

  // Chat specific endpoints
  static String getChatThreadsEndpoint(String userId) {
    return "${chatEndPoint}threads?userId=$userId";
  }

  static String getThreadMessagesEndpoint(String threadId, String userId) {
    return "${chatEndPoint}thread/$threadId/messages?userId=$userId";
  }

  static String get markThreadAsReadEndpoint => "${chatEndPoint}thread/mark-read";
  static String get deleteChatEndpoint => "${chatEndPoint}deleteChat";

  // Agent specific endpoints
  static String getAgentListingsEndpoint(String agentId) {
    return "$apiBaseUrl/agent/getListingByAgentId/$agentId";
  }

  // Get agents by ZIP code endpoint
  static String getAgentsByZipCodeEndpoint(String zipCode) {
    return "$apiBaseUrl/agent/getAgentsByZipCode/$zipCode";
  }

  // Get all listings endpoint (for buyer home screen)
  static String getAllListingsEndpoint({String? agentId}) {
    if (agentId != null && agentId.isNotEmpty) {
      return "$apiBaseUrl/agent/getListings?id=$agentId";
    }
    return "$apiBaseUrl/agent/getListings";
  }

  // Get leads by agent ID endpoint
  static String getLeadsByAgentIdEndpoint(String agentId) {
    return "$apiBaseUrl/buyer/getLeadsByAgentId/$agentId";
  }

  // Respond to lead endpoint (returns path only, not full URL)
  static String getRespondToLeadEndpoint(String leadId) {
    return "$_apiVersion/buyer/respondToLead/$leadId";
  }

  // Mark lead as complete endpoint
  static String getMarkLeadCompleteEndpoint(String leadId) {
    return "$_apiVersion/buyer/markLeadComplete/$leadId";
  }

  // Subscription checkout session endpoint
  static String get createCheckoutSessionEndpoint => "$apiBaseUrl/subscription/create-checkout-session";
  
  // Cancel subscription endpoint
  static String get cancelSubscriptionEndpoint => "$apiBaseUrl/subscription/cancelSubscription";
  
  // Payment success endpoint (takes checkout session ID as path parameter)
  static String getPaymentSuccessEndpoint(String checkoutSessionId) {
    return "$apiBaseUrl/subscription/paymentSuccess/$checkoutSessionId";
  }
  // Loan Officer specific endpoints
  static String get allLoanOfficersEndpoint => "$apiBaseUrl/loan-officers/all";

  static String getLoanOfficerByIdEndpoint(String loanOfficerId) {
    return "$apiBaseUrl/loan-officers/$loanOfficerId";
  }

  // User specific endpoints
  static String getUserByIdEndpoint(String userId) {
    return "${authEndPoint}users/$userId";
  }

  static String getUpdateUserEndpoint(String userId) {
    return "${authEndPoint}updateUser/$userId";
  }

  // Auth specific endpoints
  static String get createUserEndpoint => "${authEndPoint}createUser";
  static String get loginEndpoint => "${authEndPoint}login";

  // Lead specific endpoints - Using same endpoint for both buyer and seller leads
  static String get createLeadEndpoint => "$apiBaseUrl/buyer/createLead";

  // Like/Unlike agent endpoint
  static String getLikeAgentEndpoint(String agentId) {
    return "$apiBaseUrl/buyer/likeAgent/$agentId";
  }

  // Like/Unlike loan officer endpoint
  // Based on loan-officers endpoints using /loan-officers/ prefix
  // Using RESTful pattern: /loan-officers/{id}/like
  static String getLikeLoanOfficerEndpoint(String loanOfficerId) {
    return "$apiBaseUrl/loan-officers/$loanOfficerId/like";
  }

  // Like/Unlike listing endpoint
  static String get likeListingEndpoint => "$apiBaseUrl/buyer/likeListing";

  // Agent and Loan Officer tracking endpoints (shared)
  // Note: addSearch endpoint expects name, not ID
  static String getAddSearchEndpoint(String identifier) {
    return "$apiBaseUrl/agent/addSearch/$identifier";
  }

  static String getAddContactEndpoint(String agentId) {
    return "$apiBaseUrl/agent/addContact/$agentId";
  }

  static String getAddProfileViewEndpoint(String agentId) {
    return "$apiBaseUrl/agent/addProfileView/$agentId";
  }

  // Listing specific endpoints
  static String get createListingEndpoint => "$apiBaseUrl/agent/createListing/";

  static String getUpdateListingEndpoint(String listingId) {
    return "$apiBaseUrl/agent/updateListing/$listingId";
  }

  static String getDeleteListingEndpoint(String listingId) {
    return "$apiBaseUrl/agent/deleteListing/$listingId";
  }

  // Update listing status endpoint
  static String get updateListingStatusEndpoint => "$apiBaseUrl/agent/updateListingStatus";


  // Rebate Calculator endpoints
  static String get rebateEstimateEndpoint => "$apiBaseUrl/rebate/estimate";
  static String get rebateCalculateExactEndpoint => "$apiBaseUrl/rebate/calculate-exact";
  static String get rebateCalculateSellerRateEndpoint => "$apiBaseUrl/rebate/calculate-seller-rate";

  // Notification endpoints
  static String getNotificationsEndpoint(String userId) {
    return "$apiBaseUrl/notifications/$userId";
  }

  static String getMarkNotificationReadEndpoint(String notificationId) {
    return "$apiBaseUrl/notifications/mark-read/$notificationId";
  }

  static String getMarkAllNotificationsReadEndpoint(String userId) {
    return "$apiBaseUrl/notifications/mark-all-read/$userId";
  }

  // Helper to get ngrok headers if using ngrok
  static Map<String, String> get ngrokHeaders {
    // No longer using ngrok, return empty headers
    return {};
  }

  // Socket.IO Server URL
  static String get socketUrl {
    return _baseUrl;
  }
}

