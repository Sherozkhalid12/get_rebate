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
  static const bool _useServerUrl =
      true; // Set to true to use server URL, false for ngrok/local
  static const bool _useNgrok =
      false; // Set to true to use ngrok, false for server URL
  static String getZipCodesEndpoint(String country, String state) {
    return "$apiBaseUrl/zip-codes/$country/$state";
  }
  static String get zipCodeClaimEndpoint => "$apiBaseUrl/zip-codes/claim";
  static String get zipCodeReleaseEndpoint => "$apiBaseUrl/zip-codes/release";
  // API version prefix
  static const String _apiVersion = '/api/v1';

  // Base URL getter - ALWAYS use server URL: http://98.93.16.113:3001
  static String get baseUrl {
    // Always return the server URL
    if (kDebugMode) {
      print('🌐 ApiConstants.baseUrl = "$_serverUrl"');
    }
    return _serverUrl;

    // Commented out fallback logic - always use server URL
    // if (_useNgrok) {
    //   return _ngrokUrl;
    // }
    // if (kIsWeb) {
    //   return "http://localhost:3001";
    // }
    // if (Platform.isAndroid) {
    //   return "http://$_localNetworkIp:3001";
    // }
    // if (Platform.isIOS) {
    //   return "http://$_localNetworkIp:3001";
    // }
    // return "http://localhost:3001";
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

  static String get markThreadAsReadEndpoint =>
      "${chatEndPoint}thread/mark-read";
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
  static String get setFCMEndpoint => "${authEndPoint}setFCM";
  static String removeFCMEndpoint(String userId) => "${authEndPoint}removeFCM/$userId";

  // Lead specific endpoints - Using same endpoint for both buyer and seller leads
  static String get createLeadEndpoint => "$apiBaseUrl/buyer/createLead";

  // Get leads by agent ID endpoint (for agents to see their leads)
  static String getLeadsByAgentIdEndpoint(String agentId) {
    return "$apiBaseUrl/buyer/getLeadsByAgentId/$agentId";
  }

  // Get leads by buyer/user ID endpoint (for buyers to see their own leads)
  static String getLeadsByBuyerIdEndpoint(String buyerId) {
    return "$apiBaseUrl/buyer/getLeadsByAgentId/$buyerId";
  }

  // Agent lead response endpoints
  static String getRespondToLeadEndpoint(String leadId) {
    return "$apiBaseUrl/buyer/respondToLead/$leadId";
  }

  static String getMarkLeadCompleteEndpoint(String leadId) {
    return "$apiBaseUrl/buyer/markLeadComplete/$leadId";
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

  // Like/Unlike listing endpoint
  static String get likeListingEndpoint => "$apiBaseUrl/buyer/like";

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
  static String get rebateCalculateExactEndpoint =>
      "$apiBaseUrl/rebate/calculate-exact";
  static String get rebateCalculateSellerRateEndpoint =>
      "$apiBaseUrl/rebate/calculate-seller-rate";

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

  // Survey endpoints
  static String get submitSurveyEndpoint => "$apiBaseUrl/survey/submit";

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
  static String getProposalEndpoint(String proposalId) =>
      "$apiBaseUrl/proposals/$proposalId";
  static String acceptProposalEndpoint(String proposalId) =>
      "$apiBaseUrl/proposals/$proposalId/accept";
  static String rejectProposalEndpoint(String proposalId) =>
      "$apiBaseUrl/proposals/$proposalId/reject";
  static String completeServiceEndpoint(String proposalId) =>
      "$apiBaseUrl/proposals/$proposalId/complete";
  static String getUserProposalsEndpoint(String userId) =>
      "$apiBaseUrl/proposals/user/$userId";
  static String getProfessionalProposalsEndpoint(String professionalId) =>
      "$apiBaseUrl/proposals/professional/$professionalId";

  // Report endpoints
  static String get submitReportEndpoint => "$apiBaseUrl/reports";

  // Review endpoints
  static String get submitReviewEndpoint => "$apiBaseUrl/buyer/addReview";
  static String submitLoanOfficerReviewEndpoint(String loanOfficerId) =>
      "$apiBaseUrl/loan-officers/$loanOfficerId/reviews";

  /// Normalizes an image URL by prepending the base URL if needed
  /// Returns null if the input is null or empty
  /// Returns the original URL if it's already a full HTTP/HTTPS URL
  /// Otherwise prepends the base URL
  /// Get image URL - properly encode URLs with spaces and special characters
  static String? getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      if (kDebugMode) {
        print('🖼️ getImageUrl: Input is null or empty');
      }
      return null;
    }

    final trimmedPath = imagePath.trim();

    if (kDebugMode) {
      print('🖼️ getImageUrl: Input path = "$trimmedPath"');
    }

    // If it's a full URL, encode it properly to handle spaces and special characters
    if (trimmedPath.startsWith('http://') ||
        trimmedPath.startsWith('https://')) {
      try {
        // Check if URL contains unencoded characters (spaces, parentheses, etc.)
        // Check for spaces, parentheses, brackets that aren't already encoded
        // Also check if URL is partially encoded (has %20 but still has unencoded parentheses)
        final hasUnencodedChars =
            (trimmedPath.contains(' ') && !trimmedPath.contains('%20')) ||
            (trimmedPath.contains('(') && !trimmedPath.contains('%28')) ||
            (trimmedPath.contains(')') && !trimmedPath.contains('%29')) ||
            (trimmedPath.contains('[') && !trimmedPath.contains('%5B')) ||
            (trimmedPath.contains(']') && !trimmedPath.contains('%5D'));

        // Also check if URL is partially encoded (e.g., has %20 but still has unencoded parentheses)
        final isPartiallyEncoded =
            trimmedPath.contains('%20') &&
            (trimmedPath.contains('(') || trimmedPath.contains(')'));

        if (hasUnencodedChars || isPartiallyEncoded) {
          // Manually parse and encode the URL to avoid Uri.parse() issues with spaces
          final schemeEnd = trimmedPath.indexOf('://');
          if (schemeEnd == -1) {
            return trimmedPath; // Invalid URL format
          }

          final scheme = trimmedPath.substring(0, schemeEnd);
          final afterScheme = trimmedPath.substring(schemeEnd + 3);

          // Find the first '/' to separate host from path
          final pathStart = afterScheme.indexOf('/');
          if (pathStart == -1) {
            // No path, just return as-is
            return trimmedPath;
          }

          final host = afterScheme.substring(0, pathStart);
          final pathAndQuery = afterScheme.substring(pathStart);

          // Separate path from query/fragment
          final queryStart = pathAndQuery.indexOf('?');
          final fragmentStart = pathAndQuery.indexOf('#');

          String path;
          String? query;
          String? fragment;

          if (queryStart != -1) {
            path = pathAndQuery.substring(0, queryStart);
            final afterQuery = pathAndQuery.substring(queryStart + 1);
            if (fragmentStart != -1 && fragmentStart > queryStart) {
              final fragmentIndexInAfterQuery = fragmentStart - queryStart - 1;
              query = afterQuery.substring(0, fragmentIndexInAfterQuery);
              fragment = afterQuery.substring(fragmentIndexInAfterQuery + 1);
            } else {
              query = afterQuery;
            }
          } else if (fragmentStart != -1) {
            path = pathAndQuery.substring(0, fragmentStart);
            fragment = pathAndQuery.substring(fragmentStart + 1);
          } else {
            path = pathAndQuery;
          }

          // Encode path segments
          final segments = path.split('/').where((s) => s.isNotEmpty).toList();
          final encodedSegments = segments.map((segment) {
            try {
              // Decode first in case it's partially encoded
              final decoded = Uri.decodeComponent(segment);
              return Uri.encodeComponent(decoded);
            } catch (e) {
              // If decoding fails, just encode as-is
              return Uri.encodeComponent(segment);
            }
          }).toList();

          // Reconstruct the encoded path
          final encodedPath = '/${encodedSegments.join('/')}';

          // Reconstruct the full URL
          String encodedUrl = '$scheme://$host$encodedPath';
          if (query != null && query.isNotEmpty) {
            encodedUrl += '?$query';
          }
          if (fragment != null && fragment.isNotEmpty) {
            encodedUrl += '#$fragment';
          }

          if (kDebugMode) {
            print('🖼️ getImageUrl: Encoded URL');
            print('   Original: "$trimmedPath"');
            print('   Encoded:  "$encodedUrl"');
          }
          return encodedUrl;
        } else {
          // Already properly encoded or no special characters
          if (kDebugMode) {
            print(
              '🖼️ getImageUrl: URL appears properly encoded, returning as-is',
            );
          }
          return trimmedPath;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ getImageUrl: Error encoding URL: $e');
        }
        // Fallback: return original
        return trimmedPath;
      }
    }

    // Not a full URL, return as-is
    return trimmedPath;
  }
}
