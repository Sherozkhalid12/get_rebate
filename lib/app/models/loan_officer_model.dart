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
  });

  factory LoanOfficerModel.fromJson(Map<String, dynamic> json) {
    return LoanOfficerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage: json['profileImage'],
      companyLogoUrl: json['companyLogo'],
      company: json['company'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      licensedStates: List<String>.from(json['licensedStates'] ?? []),
      claimedZipCodes: List<String>.from(json['claimedZipCodes'] ?? []),
      specialtyProducts: List<String>.from(json['specialtyProducts'] ?? []),
      bio: json['bio'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      searchesAppearedIn: json['searchesAppearedIn'] ?? 0,
      profileViews: json['profileViews'] ?? 0,
      contacts: json['contacts'] ?? 0,
      allowsRebates: json['allowsRebates'] ?? true,
      mortgageApplicationUrl: json['mortgageApplicationUrl'],
      externalReviewsUrl: json['externalReviewsUrl'],
      platformRating: (json['platformRating'] ?? 0.0).toDouble(),
      platformReviewCount: json['platformReviewCount'] ?? 0,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'])
          : null,
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
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
    );
  }
}
