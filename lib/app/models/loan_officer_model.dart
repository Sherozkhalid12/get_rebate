import 'package:getrebate/app/utils/api_constants.dart';

class LoanOfficerModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? companyLogoUrl;
  final String company;
  final String licenseNumber;
  final List<String> licensedStates;
  final List<String> claimedZipCodes;
  final List<String>
  specialtyProducts; // Areas of expertise and specialty products
  final String? bio;
  final double rating;
  final int reviewCount;
  final int searchesAppearedIn;
  final int profileViews;
  final int contacts;
  final bool allowsRebates;
  final String? mortgageApplicationUrl;
  final String?
  externalReviewsUrl; // Link to 3rd party reviews (Google, Zillow, etc.)
  final double platformRating; // Rating from Get a Rebate platform transactions
  final int platformReviewCount; // Count of reviews from platform transactions
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final bool isVerified;
  final bool isActive;
  final List<LoanOfficerReview>? reviews; // Dynamic reviews from API
  final List<String>? likes; // Array of user IDs who liked this loan officer

  LoanOfficerModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.companyLogoUrl,
    required this.company,
    required this.licenseNumber,
    this.licensedStates = const [],
    this.claimedZipCodes = const [],
    this.specialtyProducts = const [],
    this.bio,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.searchesAppearedIn = 0,
    this.profileViews = 0,
    this.contacts = 0,
    this.allowsRebates = true,
    this.mortgageApplicationUrl,
    this.externalReviewsUrl,
    this.platformRating = 0.0,
    this.platformReviewCount = 0,
    required this.createdAt,
    this.lastActiveAt,
    this.isVerified = false,
    this.isActive = true,
    this.reviews,
    this.likes,
  });

  // Helper method to parse string field with multiple possible keys
  static String? _parseStringField(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString();
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  factory LoanOfficerModel.fromJson(Map<String, dynamic> json) {
    // Handle both API field names and model field names
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final name = json['fullname']?.toString() ?? json['name']?.toString() ?? '';
    final email = json['email']?.toString() ?? '';
    final phone = json['phone']?.toString();
    
    // Profile picture - normalize URL with base URL prepended
    final profileImageRaw = json['profilePic']?.toString() ?? json['profileImage']?.toString();
    final profileImage = ApiConstants.getImageUrl(profileImageRaw);
    
    // Company logo - normalize URL with base URL prepended
    final companyLogoRaw = json['companyLogo']?.toString();
    final companyLogoUrl = ApiConstants.getImageUrl(companyLogoRaw);
    
    // Company name
    final company = json['CompanyName']?.toString() ?? 
                    json['company']?.toString() ?? 
                    '';
    
    // License number
    final licenseNumber = json['liscenceNumber']?.toString() ?? 
                         json['licenseNumber']?.toString() ?? 
                         '';
    
    // Licensed states - handle both field name variations
    final licensedStatesList = json['LisencedStates'] ?? 
                               json['licensedStates'] ?? 
                               [];
    final licensedStates = List<String>.from(licensedStatesList);
    
    // Service areas/ZIP codes
    final serviceAreasList = json['serviceAreas'] ?? json['claimedZipCodes'] ?? [];
    final claimedZipCodes = List<String>.from(serviceAreasList);
    
    // Specialty products
    final specialtyList = json['specialtyProducts'] ?? [];
    final specialtyProducts = List<String>.from(specialtyList);
    
    // Rating - can be number or calculated from reviews
    double rating = 0.0;
    if (json['ratings'] != null) {
      rating = (json['ratings'] is num) ? (json['ratings'] as num).toDouble() : 0.0;
    } else if (json['rating'] != null) {
      rating = (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0;
    }
    
    // Parse reviews from API
    List<LoanOfficerReview>? reviews;
    final reviewsData = json['reviews'];
    int reviewCount = 0;
    
    if (reviewsData != null && reviewsData is List) {
      // Filter out non-map items (like the 0 in the API response)
      final validReviews = reviewsData.where((r) => r is Map).toList();
      reviews = validReviews
          .map((reviewJson) => LoanOfficerReview.fromJson(reviewJson as Map<String, dynamic>))
          .toList();
      reviewCount = reviews.length;
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
    
    // Parse likes array from API
    List<String>? likes;
    final likesData = json['likes'];
    if (likesData != null && likesData is List) {
      likes = likesData.map((like) => like.toString()).toList();
    }
    
    return LoanOfficerModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      profileImage: profileImage,
      companyLogoUrl: companyLogoUrl,
      company: company,
      licenseNumber: licenseNumber,
      licensedStates: licensedStates,
      claimedZipCodes: claimedZipCodes,
      specialtyProducts: specialtyProducts,
      bio: json['bio']?.toString() ?? json['description']?.toString(),
      rating: rating,
      reviewCount: reviewCount,
      searchesAppearedIn: json['searches'] is int ? json['searches'] : 0,
      profileViews: json['views'] is int ? json['views'] : 0,
      contacts: json['contacts'] is int ? json['contacts'] : 0,
      allowsRebates: json['allowsRebates'] is bool ? json['allowsRebates'] : true,
      mortgageApplicationUrl: _parseStringField(json, ['mortagelink', 'mortgageApplicationUrl', 'mortgage_application_url']),
      externalReviewsUrl: _parseStringField(json, ['externalReviewsUrl', 'external_reviews_link', 'thirdPartReviewLink']),
      platformRating: rating, // Use same rating
      platformReviewCount: reviewCount, // Use same review count
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
      isVerified: json['verified'] is bool ? json['verified'] : false,
      isActive: true, // Assume active if in API response
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
      'company': company,
      'licenseNumber': licenseNumber,
      'licensedStates': licensedStates,
      'claimedZipCodes': claimedZipCodes,
      'specialtyProducts': specialtyProducts,
      'bio': bio,
      'rating': rating,
      'reviewCount': reviewCount,
      'searchesAppearedIn': searchesAppearedIn,
      'profileViews': profileViews,
      'contacts': contacts,
      'allowsRebates': allowsRebates,
      'mortgageApplicationUrl': mortgageApplicationUrl,
      'externalReviewsUrl': externalReviewsUrl,
      'platformRating': platformRating,
      'platformReviewCount': platformReviewCount,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'isVerified': isVerified,
      'isActive': isActive,
      'reviews': reviews?.map((r) => r.toJson()).toList(),
      'likes': likes,
    };
  }

  LoanOfficerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? companyLogoUrl,
    String? company,
    String? licenseNumber,
    List<String>? licensedStates,
    List<String>? claimedZipCodes,
    List<String>? specialtyProducts,
    String? bio,
    double? rating,
    int? reviewCount,
    int? searchesAppearedIn,
    int? profileViews,
    int? contacts,
    bool? allowsRebates,
    String? mortgageApplicationUrl,
    String? externalReviewsUrl,
    double? platformRating,
    int? platformReviewCount,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isVerified,
    bool? isActive,
    List<String>? likes,
  }) {
    return LoanOfficerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      company: company ?? this.company,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licensedStates: licensedStates ?? this.licensedStates,
      claimedZipCodes: claimedZipCodes ?? this.claimedZipCodes,
      specialtyProducts: specialtyProducts ?? this.specialtyProducts,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      searchesAppearedIn: searchesAppearedIn ?? this.searchesAppearedIn,
      profileViews: profileViews ?? this.profileViews,
      contacts: contacts ?? this.contacts,
      allowsRebates: allowsRebates ?? this.allowsRebates,
      mortgageApplicationUrl:
          mortgageApplicationUrl ?? this.mortgageApplicationUrl,
      externalReviewsUrl: externalReviewsUrl ?? this.externalReviewsUrl,
      platformRating: platformRating ?? this.platformRating,
      platformReviewCount: platformReviewCount ?? this.platformReviewCount,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      reviews: reviews ?? this.reviews,
      likes: likes ?? this.likes,
    );
  }
}

/// Loan Officer Review Model
class LoanOfficerReview {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerProfile;
  final double rating;
  final String comment;
  final DateTime createdAt;

  LoanOfficerReview({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerProfile,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory LoanOfficerReview.fromJson(Map<String, dynamic> json) {
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

    return LoanOfficerReview(
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
