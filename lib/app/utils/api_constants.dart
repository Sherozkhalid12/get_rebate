import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConstants {
  const ApiConstants._();

  // ============================================================================
  // BASE URL CONFIGURATION
  // ============================================================================
  // 
  // OPTION 1: Using ngrok (for external access)
  //   - Get your ngrok URL from: https://dashboard.ngrok.com/
  //   - Update _ngrokUrl below with your current ngrok URL
  //   - Example: "https://a8b8ef09fa9a.ngrok-free.app"
  // 
  // OPTION 2: Using local network IP (for same network devices)
  //   - Find your computer's IP: 
  //     Windows: Run 'ipconfig' in CMD → IPv4 Address
  //     Mac/Linux: Run 'ifconfig' or 'ip addr' → inet address
  //   - Update _localNetworkIp below with your IP
  //   - Example: "192.168.1.100"
  //   - Port should be 3001
  // 
  // OPTION 3: Using localhost (for emulator/simulator only)
  //   - Android Emulator: Use "10.0.2.2"
  //   - iOS Simulator: Use "localhost"
  // 
  // ============================================================================

  // Server URL
  static const String _serverUrl = 'http://98.93.16.113:3001';
  
  // Ngrok URL (update this when ngrok restarts)
  static const String _ngrokUrl = 'https://004db1f400ae.ngrok-free.app';
  // Local network IP (update with your computer's IP address)
  static const String _localNetworkIp = '192.168.1.100'; // TODO: Update this!

  // Choose which base URL to use
  static const bool _useServerUrl = true; // Set to true to use server URL, false for ngrok/local
  static const bool _useNgrok = false; // Set to true to use ngrok, false for server URL

  // API version prefix
  static const String _apiVersion = '/api/v1';

  // Base URL getter
  static String get baseUrl {
    if (_useServerUrl) {
      return _serverUrl;
    }
    
    if (_useNgrok) {
      return _ngrokUrl;
    }

    if (kIsWeb) {
      return "http://localhost:3001";
    }

    if (Platform.isAndroid) {
      // For Android emulator
      // return "http://10.0.2.2:3001";

      // For real Android device on same network
      return "http://$_localNetworkIp:3001";
    }

    if (Platform.isIOS) {
      // For iOS simulator
      // return "http://localhost:3001";

      // For real iOS device on same network
      return "http://$_localNetworkIp:3001";
    }

    return "http://localhost:3001";
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

  // Get all agents with pagination endpoint
  static String getAllAgentsEndpoint(int page) {
    return "$apiBaseUrl/agent/getAllAgents/$page";
  }

  // Get all listings endpoint (for buyer home screen)
  static String getAllListingsEndpoint({String? agentId}) {
    if (agentId != null && agentId.isNotEmpty) {
      return "$apiBaseUrl/agent/getListings?id=$agentId";
    }
    return "$apiBaseUrl/agent/getListings";
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
  
  // Get leads by agent ID endpoint
  static String getLeadsByAgentIdEndpoint(String agentId) {
    return "$apiBaseUrl/agent/getLeadsByAgentId/$agentId";
  }

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

  // Agent and Loan Officer tracking endpoints (shared)
  // Note: addSearch endpoint expects name, not ID
  static String getAddSearchEndpoint(String identifier) {
    return "$apiBaseUrl/agent/addSearch/$identifier";
  }

  static String getAddContactEndpoint(String id) {
    return "$apiBaseUrl/agent/addContact/$id";
  }

  static String getAddProfileViewEndpoint(String id) {
    return "$apiBaseUrl/agent/addProfileView/$id";
  }

  // Listing specific endpoints
  static String get createListingEndpoint => "$apiBaseUrl/agent/createListing/";

  static String getUpdateListingEndpoint(String listingId) {
    return "$apiBaseUrl/agent/updateListing/$listingId";
  }

  static String getDeleteListingEndpoint(String listingId) {
    return "$apiBaseUrl/agent/deleteListing/$listingId";
  }

  static String getListingsByUserIdEndpoint(String userId) {
    return "$apiBaseUrl/agent/getListingsByUserId/$userId";
  }


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
    if (_useNgrok) {
      return {'ngrok-skip-browser-warning': 'true'};
    }
    return {};
  }

  // Socket.IO Server URL
  static String get socketUrl {
    if (_useServerUrl) {
      return _serverUrl;
    }
    
    if (_useNgrok) {
      return _ngrokUrl;
    }

    if (kIsWeb) {
      return "http://localhost:3001";
    }

    if (Platform.isAndroid) {
      return "http://$_localNetworkIp:3001";
    }

    if (Platform.isIOS) {
      return "http://$_localNetworkIp:3001";
    }

    return "http://localhost:3001";
  }

  // Proposal endpoints
  static String get createProposalEndpoint => "$apiBaseUrl/proposals/create";
  static String getProposalEndpoint(String proposalId) => "$apiBaseUrl/proposals/$proposalId";
  static String acceptProposalEndpoint(String proposalId) => "$apiBaseUrl/proposals/$proposalId/accept";
  static String rejectProposalEndpoint(String proposalId) => "$apiBaseUrl/proposals/$proposalId/reject";
  static String completeServiceEndpoint(String proposalId) => "$apiBaseUrl/proposals/$proposalId/complete";
  static String getUserProposalsEndpoint(String userId) => "$apiBaseUrl/proposals/user/$userId";
  static String getProfessionalProposalsEndpoint(String professionalId) => "$apiBaseUrl/proposals/professional/$professionalId";

  // Report endpoints
  static String get submitReportEndpoint => "$apiBaseUrl/reports";

  // Review endpoints
  static String get submitReviewEndpoint => "$apiBaseUrl/buyer/addReview";
  static String submitLoanOfficerReviewEndpoint(String loanOfficerId) => "$apiBaseUrl/loan-officers/$loanOfficerId/reviews";
}

