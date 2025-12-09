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
  final String? videoUrl;                    // YouTube/Vimeo intro
  final List<String>? expertise;             // e.g. "Luxury", "First-Time Buyers"
  final String? websiteUrl;                  // Personal site
  final String? googleReviewsUrl;            // Google Business
  final String? thirdPartyReviewsUrl;        // Zillow, Yelp, etc.

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
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage: json['profileImage'],
      companyLogoUrl: json['companyLogo'],
      brokerage: json['brokerage'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      licensedStates: List<String>.from(json['licensedStates'] ?? []),
      claimedZipCodes: List<String>.from(json['claimedZipCodes'] ?? []),
      bio: json['bio'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      searchesAppearedIn: json['searchesAppearedIn'] ?? 0,
      profileViews: json['profileViews'] ?? 0,
      contacts: json['contacts'] ?? 0,
      serviceZipCodes: List<String>.from(json['serviceZipCodes'] ?? []),
      featuredListings: List<String>.from(json['featuredListings'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt']) : null,
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      rebateOffered: json['rebateOffered'] ?? false,
      rebatePercentage: (json['rebatePercentage'] ?? 0.0).toDouble(),
      isDualAgencyAllowedInState: json['isDualAgencyAllowedInState'],
      isDualAgencyAllowedAtBrokerage: json['isDualAgencyAllowedAtBrokerage'],
      externalReviewsUrl: json['externalReviewsUrl'],
      platformRating: (json['platformRating'] ?? 0.0).toDouble(),
      platformReviewCount: json['platformReviewCount'] ?? 0,
      // NEW FIELDS — SAFE FROM JSON
      videoUrl: json['videoUrl'],
      expertise: json['expertise'] != null ? List<String>.from(json['expertise']) : null,
      websiteUrl: json['websiteUrl'],
      googleReviewsUrl: json['googleReviewsUrl'],
      thirdPartyReviewsUrl: json['thirdPartyReviewsUrl'],
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
      licensedStates: licensedStates ?? this.licensedStates,
      claimedZipCodes: claimedZipCodes ?? this.claimedZipCodes,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      searchesAppearedIn: searchesAppearedIn ?? this.searchesAppearedIn,
      profileViews: profileViews ?? this.profileViews,
      contacts: contacts ?? this.contacts,
      serviceZipCodes: serviceZipCodes ?? this.serviceZipCodes,
      featuredListings: featuredListings ?? this.featuredListings,
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
    );
  }
}