import 'package:getrebate/app/utils/api_constants.dart';

class AgentModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? companyLogoUrl;
  final String brokerage;
  final String licenseNumber;
  final List<String> licensedStates;
  final List<String> claimedZipCodes;
  final String? bio;
  final double rating;
  final int reviewCount;
  final int searchesAppearedIn;
  final int profileViews;
  final int contacts;
  final List<String> serviceZipCodes;
  final List<String> activeListingZipCodes; // Parsed from listings array
  final List<String> featuredListings;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final bool isVerified;
  final bool isActive;
  final bool rebateOffered;
  final double rebatePercentage;
  final bool? isDualAgencyAllowedInState;
  final bool? isDualAgencyAllowedAtBrokerage;
  final String? externalReviewsUrl;
  final double platformRating;
  final int platformReviewCount;

  // NEW FIELDS — CLIENT REQUEST
  final String? videoUrl; // YouTube/Vimeo intro or video file URL
  final List<String>? expertise; // e.g. "Luxury", "First-Time Buyers" (areasOfExpertise)
  final String? websiteUrl; // Personal site (website_link)
  final String? googleReviewsUrl; // Google Business (google_reviews_link)
  final String? thirdPartyReviewsUrl; // Zillow, Yelp, etc. (thirdPartReviewLink)
  final List<String>? serviceAreas; // Service areas (cities) - separate from serviceZipCodes
  final List<AgentReview>? reviews; // Dynamic reviews from API
  final List<String>? likes; // Array of user IDs who liked this agent

  AgentModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.companyLogoUrl,
    required this.brokerage,
    required this.licenseNumber,
    this.licensedStates = const [],
    this.claimedZipCodes = const [],
    this.bio,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.searchesAppearedIn = 0,
    this.profileViews = 0,
    this.contacts = 0,
    this.serviceZipCodes = const [],
    this.activeListingZipCodes = const [],
    this.featuredListings = const [],
    required this.createdAt,
    this.lastActiveAt,
    this.isVerified = false,
    this.isActive = true,
    this.rebateOffered = false,
    this.rebatePercentage = 0.0,
    this.isDualAgencyAllowedInState,
    this.isDualAgencyAllowedAtBrokerage,
    this.externalReviewsUrl,
    this.platformRating = 0.0,
    this.platformReviewCount = 0,
    // NEW FIELDS — SAFE DEFAULTS
    this.videoUrl,
    this.expertise,
    this.websiteUrl,
    this.googleReviewsUrl,
    this.thirdPartyReviewsUrl,
    this.serviceAreas,
    this.reviews,
    this.likes,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    // Handle both API field names and model field names
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final name = json['fullname']?.toString() ?? json['name']?.toString() ?? '';
    final email = json['email']?.toString() ?? '';
    final phone = json['phone']?.toString();

    // Profile picture - normalize URL with base URL prepended
    final profileImageRaw =
        json['profilePic']?.toString() ?? json['profileImage']?.toString();
    final profileImage = ApiConstants.getImageUrl(profileImageRaw);

    // Company logo - normalize URL with base URL prepended
    final companyLogoRaw = json['companyLogo']?.toString();
    final companyLogoUrl = ApiConstants.getImageUrl(companyLogoRaw);

    // Brokerage/Company name
    final brokerage =
        json['CompanyName']?.toString() ??
        json['brokerageCompanyName']?.toString() ??
        json['brokerage']?.toString() ??
        '';

    // License number
    final licenseNumber =
        json['liscenceNumber']?.toString() ??
        json['licenseNumber']?.toString() ??
        '';

    // Licensed states - handle both field name variations
    final licensedStatesList =
        json['LisencedStates'] ?? json['licensedStates'] ?? [];
    final licensedStates = List<String>.from(licensedStatesList);

    // Parse claimedZipCodes - can be array of objects with postalCode or array of strings
    List<String> claimedZipCodesList = [];
    final claimedZipCodesData = json['claimedZipCodes'];
    if (claimedZipCodesData != null && claimedZipCodesData is List) {
      for (var item in claimedZipCodesData) {
        if (item is Map) {
          // Extract postalCode from object
          final postalCode = item['postalCode']?.toString();
          if (postalCode != null && postalCode.isNotEmpty) {
            claimedZipCodesList.add(postalCode);
          }
        } else if (item is String) {
          // Direct string value
          claimedZipCodesList.add(item);
        }
      }
    }

    // Service areas/ZIP codes - can be from serviceAreas or serviceZipCodes
    final serviceAreasList =
        json['serviceAreas'] ?? json['serviceZipCodes'] ?? [];
    final serviceZipCodes = List<String>.from(serviceAreasList);

    // Parse active listing ZIP codes from 'listings' array
    List<String> activeListingZipCodes = [];
    final listingsData = json['listings'];
    if (listingsData != null && listingsData is List) {
      for (var item in listingsData) {
        if (item is Map) {
          final zip = item['zipCode']?.toString();
          if (zip != null && zip.isNotEmpty && zip != '0') {
            activeListingZipCodes.add(zip);
          }
        }
      }
    }

    // Rating - can be number or calculated from reviews
    double rating = 0.0;
    if (json['ratings'] != null) {
      rating = (json['ratings'] is num)
          ? (json['ratings'] as num).toDouble()
          : 0.0;
    } else if (json['rating'] != null) {
      rating = (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : 0.0;
    }

    // Review count - from reviews array length
    final reviewsList = json['reviews'] ?? [];
    int reviewCount = 0;
    if (reviewsList is List) {
      reviewCount = reviewsList.length;
    } else if (json['reviewCount'] != null) {
      reviewCount = json['reviewCount'] is int ? json['reviewCount'] : 0;
    }

    // Dates
    DateTime createdAt = DateTime.now();
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    }

    DateTime? lastActiveAt;
    if (json['updatedAt'] != null) {
      try {
        lastActiveAt = DateTime.parse(json['updatedAt'].toString());
      } catch (e) {
        // Ignore parse errors
      }
    }

    // Video URL - normalize using ApiConstants.getImageUrl for proper URL handling
    final videoUrlRaw =
        json['video']?.toString() ??
        json['agentvideo']?.toString() ??
        json['videoUrl']?.toString();
    final videoUrl = videoUrlRaw != null && videoUrlRaw.isNotEmpty
        ? ApiConstants.getImageUrl(videoUrlRaw)
        : null;

    // Expertise
    List<String>? expertise;
    final expertiseList = json['areasOfExpertise'] ?? json['expertise'];
    if (expertiseList != null && expertiseList is List) {
      expertise = expertiseList
          .map((e) => e.toString().replaceAll(RegExp(r'[\[\]"]'), ''))
          .where((e) => e.isNotEmpty)
          .toList()
          .cast<String>();
    }

    // Parse service areas (cities) - separate from serviceZipCodes
    List<String>? serviceAreas;
    final serviceAreasData = json['serviceAreas'];
    if (serviceAreasData != null && serviceAreasData is List) {
      serviceAreas = List<String>.from(serviceAreasData);
    }
    
    // Parse reviews from API
    List<AgentReview>? reviews;
    final reviewsData = json['reviews'];
    if (reviewsData != null && reviewsData is List) {
      reviews = reviewsData
          .map((reviewJson) => AgentReview.fromJson(reviewJson as Map<String, dynamic>))
          .toList();
    }
    
    // Parse likes array from API
    List<String>? likes;
    final likesData = json['likes'];
    if (likesData != null && likesData is List) {
      likes = likesData.map((like) => like.toString()).toList();
    }
    
    return AgentModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      profileImage: profileImage,
      companyLogoUrl: companyLogoUrl,
      brokerage: brokerage,
      licenseNumber: licenseNumber,
      licensedStates: licensedStates,
      claimedZipCodes: claimedZipCodesList, // Use parsed claimedZipCodes from API
      bio: json['bio']?.toString() ?? json['description']?.toString(),
      rating: rating,
      reviewCount: reviewCount,
      searchesAppearedIn: json['searches'] is int ? json['searches'] : 0,
      profileViews: json['views'] is int ? json['views'] : 0,
      contacts: json['contacts'] is int ? json['contacts'] : 0,
      serviceZipCodes: serviceZipCodes,
      activeListingZipCodes: activeListingZipCodes,
      featuredListings: const [], // Not in API response
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
      isVerified: json['verified'] is bool ? json['verified'] : false,
      isActive: true, // Assume active if in API response
      rebateOffered: false, // Not in API response
      rebatePercentage: 0.0, // Not in API response
      isDualAgencyAllowedInState: json['dualAgencyState'] is bool
          ? json['dualAgencyState']
          : null,
      isDualAgencyAllowedAtBrokerage: json['dualAgencySBrokerage'] is bool
          ? json['dualAgencySBrokerage']
          : null,
      externalReviewsUrl:
          json['thirdPartReviewLink']?.toString() ??
          json['client_reviews_link']?.toString() ??
          json['externalReviewsUrl']?.toString(),
      platformRating: rating, // Use same rating
      platformReviewCount: reviewCount, // Use same review count
      videoUrl: videoUrl,
      expertise: expertise,
      websiteUrl:
          json['website_link']?.toString() ?? json['websiteUrl']?.toString(),
      googleReviewsUrl:
          json['google_reviews_link']?.toString() ??
          json['googleReviewsUrl']?.toString(),
      thirdPartyReviewsUrl:
          json['client_reviews_link']?.toString() ??
          json['thirdPartyReviewsUrl']?.toString(),
      serviceAreas: serviceAreas,
      reviews: reviews,
      likes: likes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'companyLogo': companyLogoUrl,
      'brokerage': brokerage,
      'licenseNumber': licenseNumber,
      'licensedStates': licensedStates,
      'claimedZipCodes': claimedZipCodes,
      'bio': bio,
      'rating': rating,
      'reviewCount': reviewCount,
      'searchesAppearedIn': searchesAppearedIn,
      'profileViews': profileViews,
      'contacts': contacts,
      'serviceZipCodes': serviceZipCodes,
      'activeListingZipCodes': activeListingZipCodes,
      'featuredListings': featuredListings,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'isVerified': isVerified,
      'isActive': isActive,
      'rebateOffered': rebateOffered,
      'rebatePercentage': rebatePercentage,
      'isDualAgencyAllowedInState': isDualAgencyAllowedInState,
      'isDualAgencyAllowedAtBrokerage': isDualAgencyAllowedAtBrokerage,
      'externalReviewsUrl': externalReviewsUrl,
      'platformRating': platformRating,
      'platformReviewCount': platformReviewCount,
      // NEW FIELDS — SAVE TO FIRESTORE
      'videoUrl': videoUrl,
      'expertise': expertise,
      'websiteUrl': websiteUrl,
      'googleReviewsUrl': googleReviewsUrl,
      'thirdPartyReviewsUrl': thirdPartyReviewsUrl,
      'serviceAreas': serviceAreas,
      'reviews': reviews?.map((r) => r.toJson()).toList(),
      'likes': likes,
    };
  }

  AgentModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? companyLogoUrl,
    String? brokerage,
    String? licenseNumber,
    List<String>? licensedStates,
    List<String>? claimedZipCodes,
    String? bio,
    double? rating,
    int? reviewCount,
    int? searchesAppearedIn,
    int? profileViews,
    int? contacts,
    List<String>? serviceZipCodes,
    List<String>? activeListingZipCodes,
    List<String>? featuredListings,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isVerified,
    bool? isActive,
    bool? rebateOffered,
    double? rebatePercentage,
    bool? isDualAgencyAllowedInState,
    bool? isDualAgencyAllowedAtBrokerage,
    String? externalReviewsUrl,
    double? platformRating,
    int? platformReviewCount,
    // NEW FIELDS — COPYWITH SUPPORT
    String? videoUrl,
    List<String>? expertise,
    String? websiteUrl,
    String? googleReviewsUrl,
    String? thirdPartyReviewsUrl,
    List<AgentReview>? reviews,
    List<String>? likes,
  }) {
    return AgentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      brokerage: brokerage ?? this.brokerage,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licensedStates: licensedStates ?? this.licensedStates ?? const [],
      claimedZipCodes: claimedZipCodes ?? this.claimedZipCodes ?? const [],
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      searchesAppearedIn: searchesAppearedIn ?? this.searchesAppearedIn,
      profileViews: profileViews ?? this.profileViews,
      contacts: contacts ?? this.contacts,
      serviceZipCodes: serviceZipCodes ?? this.serviceZipCodes ?? const [],
      activeListingZipCodes: activeListingZipCodes ?? this.activeListingZipCodes ?? const [],
      featuredListings: featuredListings ?? this.featuredListings ?? const [],
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      rebateOffered: rebateOffered ?? this.rebateOffered,
      rebatePercentage: rebatePercentage ?? this.rebatePercentage,
      isDualAgencyAllowedInState: isDualAgencyAllowedInState ?? this.isDualAgencyAllowedInState,
      isDualAgencyAllowedAtBrokerage: isDualAgencyAllowedAtBrokerage ?? this.isDualAgencyAllowedAtBrokerage,
      externalReviewsUrl: externalReviewsUrl ?? this.externalReviewsUrl,
      platformRating: platformRating ?? this.platformRating,
      platformReviewCount: platformReviewCount ?? this.platformReviewCount,
      videoUrl: videoUrl ?? this.videoUrl,
      expertise: expertise ?? this.expertise,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      googleReviewsUrl: googleReviewsUrl ?? this.googleReviewsUrl,
      thirdPartyReviewsUrl: thirdPartyReviewsUrl ?? this.thirdPartyReviewsUrl,
      reviews: reviews ?? this.reviews,
      likes: likes ?? this.likes,
    );
  }
}

/// Agent Review Model
class AgentReview {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerProfile;
  final double rating;
  final String comment;
  final DateTime createdAt;

  AgentReview({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerProfile,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory AgentReview.fromJson(Map<String, dynamic> json) {
    // Parse profile pic URL
    String? reviewerProfile = json['reviewerProfile']?.toString();
    if (reviewerProfile != null && reviewerProfile.isNotEmpty && !reviewerProfile.contains('file://')) {
      reviewerProfile = reviewerProfile.replaceAll('\\', '/');
      if (!reviewerProfile.startsWith('http://') && !reviewerProfile.startsWith('https://')) {
        if (reviewerProfile.startsWith('/')) {
          reviewerProfile = reviewerProfile.substring(1);
        }
        // Will be built with base URL in the view if needed
      }
    } else {
      reviewerProfile = null;
    }

    // Parse created date
    DateTime createdAt = DateTime.now();
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    }

    return AgentReview(
      id: json['_id']?.toString() ?? '',
      reviewerId: json['reviewerId']?.toString() ?? '',
      reviewerName: json['reviewerName']?.toString() ?? 'Anonymous',
      reviewerProfile: reviewerProfile,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      comment: json['comment']?.toString() ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerProfile': reviewerProfile,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}