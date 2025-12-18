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

  // Ngrok URL (update this when ngrok restarts)
  static const String _ngrokUrl = 'https://6b84b3644e66.ngrok-free.app';

  // Local network IP (update with your computer's IP address)
  static const String _localNetworkIp = '192.168.1.100'; // TODO: Update this!

  // Choose which base URL to use
  static const bool _useNgrok = true; // Set to true to use ngrok, false for local IP

  // API version prefix
  static const String _apiVersion = '/api/v1';

  // Base URL getter
  static String get baseUrl {
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

  // Loan Officer specific endpoints
  static String get allLoanOfficersEndpoint => "$apiBaseUrl/loan-officers/all";

  static String getLoanOfficerByIdEndpoint(String loanOfficerId) {
    return "$apiBaseUrl/loan-officers/$loanOfficerId";
  }

  // User specific endpoints
  static String getUserByIdEndpoint(String userId) {
    return "${authEndPoint}users/$userId";
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

  // Listing specific endpoints
  static String get createListingEndpoint => "$apiBaseUrl/agent/createListing/";

  static String getUpdateListingEndpoint(String listingId) {
    return "$apiBaseUrl/agent/updateListing/$listingId";
  }

  static String getDeleteListingEndpoint(String listingId) {
    return "$apiBaseUrl/agent/deleteListing/$listingId";
  }


  // Rebate Calculator endpoints
  static String get rebateEstimateEndpoint => "$apiBaseUrl/rebate/estimate";
  static String get rebateCalculateExactEndpoint => "$apiBaseUrl/rebate/calculate-exact";
  static String get rebateCalculateSellerRateEndpoint => "$apiBaseUrl/rebate/calculate-seller-rate";

  // Helper to get ngrok headers if using ngrok
  static Map<String, String> get ngrokHeaders {
    if (_useNgrok) {
      return {'ngrok-skip-browser-warning': 'true'};
    }
    return {};
  }

  // Socket.IO Server URL
  static String get socketUrl {
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
}

