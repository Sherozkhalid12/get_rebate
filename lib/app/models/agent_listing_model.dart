enum MarketStatus { forSale, pending, sold }

extension MarketStatusLabel on MarketStatus {
  String get label {
    switch (this) {
      case MarketStatus.forSale:
        return 'For Sale';
      case MarketStatus.pending:
        return 'Pending';
      case MarketStatus.sold:
        return 'Sold';
    }
  }

  String get subtitle {
    switch (this) {
      case MarketStatus.forSale:
        return 'Actively accepting offers';
      case MarketStatus.pending:
        return 'Offer accepted / under contract';
      case MarketStatus.sold:
        return 'Closed and recorded';
    }
  }
}

MarketStatus _marketStatusFromString(String? value) {
  if (value == null || value.isEmpty) return MarketStatus.forSale;
  
  switch (value.toLowerCase()) {
    case 'pending':
    case 'draft':
      return MarketStatus.pending;
    case 'sold':
      return MarketStatus.sold;
    case 'active':
    case 'forsale':
    case 'for_sale':
    case 'for sale':
      return MarketStatus.forSale;
    default:
      return MarketStatus.forSale;
  }
}

class AgentListingModel {
  final String id;
  final String agentId;
  final String title;
  final String description;
  final int priceCents;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final List<String> photoUrls;
  final double bacPercent;
  final bool dualAgencyAllowed;
  final double?
  dualAgencyCommissionPercent; // Total commission % for dual agency (e.g., 4.0, 5.0, 6.0)
  final bool
  isListingAgent; // Whether the submitting agent is the actual listing agent
  final bool isActive;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final int searchCount;
  final int viewCount;
  final int contactCount;
  final String? rejectionReason;
  final MarketStatus marketStatus;

  AgentListingModel({
    required this.id,
    required this.agentId,
    required this.title,
    required this.description,
    required this.priceCents,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.photoUrls = const [],
    required this.bacPercent,
    required this.dualAgencyAllowed,
    this.dualAgencyCommissionPercent,
    this.isListingAgent = true, // Default to true for backward compatibility
    this.isActive = true,
    this.isApproved = false,
    required this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.searchCount = 0,
    this.viewCount = 0,
    this.contactCount = 0,
    this.rejectionReason,
    this.marketStatus = MarketStatus.forSale,
  });

  factory AgentListingModel.fromJson(Map<String, dynamic> json) {
    return AgentListingModel(
      id: json['id'] ?? '',
      agentId: json['agentId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priceCents: json['priceCents'] ?? 0,
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      bacPercent: (json['bacPercent'] ?? 0.0).toDouble(),
      dualAgencyAllowed: json['dualAgencyAllowed'] ?? false,
      dualAgencyCommissionPercent: json['dualAgencyCommissionPercent'] != null
          ? (json['dualAgencyCommissionPercent'] as num).toDouble()
          : null,
      isListingAgent: json['isListingAgent'] ?? true,
      isActive: json['isActive'] ?? true,
      isApproved: json['isApproved'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      searchCount: json['searchCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      contactCount: json['contactCount'] ?? 0,
      rejectionReason: json['rejectionReason'],
      marketStatus: _marketStatusFromString(json['marketStatus']?.toString()),
    );
  }

  // Factory method to parse API response format
  factory AgentListingModel.fromApiJson(Map<String, dynamic> json) {
    // Convert price string to cents (e.g., "8000" -> 800000 cents)
    final priceString = json['price']?.toString() ?? '0';
    final priceDouble = double.tryParse(priceString) ?? 0.0;
    final priceCents = (priceDouble * 100).toInt();

    // Convert BACPercentage string to double
    final bacPercentageString = json['BACPercentage']?.toString() ?? '0';
    final bacPercent = double.tryParse(bacPercentageString) ?? 0.0;

    // Handle propertyPhotos - URLs should already be processed by controller
    // If they're full URLs, use as is; if relative, they should already have base URL prepended
    final propertyPhotos = json['propertyPhotos'] as List<dynamic>? ?? [];
    final photoUrls = propertyPhotos
        .map((photo) {
          final photoPath = photo.toString();
          if (photoPath.isEmpty) return null;
          return photoPath;
        })
        .where((photo) => photo != null)
        .cast<String>()
        .toList();

    // Determine approval status and market status
    // status: "active" means For Sale, "draft" means pending approval
    final statusString = json['status']?.toString() ?? '';
    final isActive = json['active'] ?? false;
    final isApproved = statusString == 'active' || isActive;
    
    // Map status to MarketStatus
    MarketStatus marketStatus;
    if (statusString == 'active') {
      marketStatus = MarketStatus.forSale;
    } else if (statusString == 'pending' || statusString == 'draft') {
      marketStatus = MarketStatus.pending;
    } else if (statusString == 'sold') {
      marketStatus = MarketStatus.sold;
    } else {
      // Default based on active flag
      marketStatus = isActive ? MarketStatus.forSale : MarketStatus.pending;
    }

    return AgentListingModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      agentId: json['id']?.toString() ?? '', // The agent ID field in API response
      title: json['propertyTitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priceCents: priceCents,
      address: json['streetAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      photoUrls: photoUrls,
      bacPercent: bacPercent,
      dualAgencyAllowed: json['dualAgencyAllowed'] ?? false,
      isListingAgent: json['listingAgent'] ?? true,
      isActive: isActive,
      isApproved: isApproved,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      searchCount: json['searches'] ?? 0, // From API
      viewCount: json['views'] ?? 0, // From API
      contactCount: json['contacts'] ?? 0, // From API
      marketStatus: marketStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'title': title,
      'description': description,
      'priceCents': priceCents,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'photoUrls': photoUrls,
      'bacPercent': bacPercent,
      'dualAgencyAllowed': dualAgencyAllowed,
      'dualAgencyCommissionPercent': dualAgencyCommissionPercent,
      'isListingAgent': isListingAgent,
      'isActive': isActive,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'searchCount': searchCount,
      'viewCount': viewCount,
      'contactCount': contactCount,
      'rejectionReason': rejectionReason,
      'marketStatus': marketStatus.name,
    };
  }

  AgentListingModel copyWith({
    String? id,
    String? agentId,
    String? title,
    String? description,
    int? priceCents,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    List<String>? photoUrls,
    double? bacPercent,
    bool? dualAgencyAllowed,
    double? dualAgencyCommissionPercent,
    bool? isListingAgent,
    bool? isActive,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    int? searchCount,
    int? viewCount,
    int? contactCount,
    String? rejectionReason,
    MarketStatus? marketStatus,
  }) {
    return AgentListingModel(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      title: title ?? this.title,
      description: description ?? this.description,
      priceCents: priceCents ?? this.priceCents,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      photoUrls: photoUrls ?? this.photoUrls,
      bacPercent: bacPercent ?? this.bacPercent,
      dualAgencyAllowed: dualAgencyAllowed ?? this.dualAgencyAllowed,
      dualAgencyCommissionPercent:
          dualAgencyCommissionPercent ?? this.dualAgencyCommissionPercent,
      isListingAgent: isListingAgent ?? this.isListingAgent,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      searchCount: searchCount ?? this.searchCount,
      viewCount: viewCount ?? this.viewCount,
      contactCount: contactCount ?? this.contactCount,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      marketStatus: marketStatus ?? this.marketStatus,
    );
  }

  String get fullAddress => '$address, $city, $state $zipCode';

  String get formattedPrice {
    final dollars = priceCents ~/ 100;
    final cents = priceCents % 100;
    final formattedDollars = dollars.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '\$$formattedDollars.${cents.toString().padLeft(2, '0')}';
  }

  String get status {
    if (!isApproved) return 'Pending Approval';
    if (rejectionReason != null) return 'Rejected';
    switch (marketStatus) {
      case MarketStatus.forSale:
        return 'For Sale';
      case MarketStatus.pending:
        return 'Pending';
      case MarketStatus.sold:
        return 'Sold';
    }
  }

  bool get isStale {
    if (marketStatus != MarketStatus.forSale) return false;
    final lastUpdated = updatedAt ?? createdAt;
    return DateTime.now().difference(lastUpdated).inDays >= 60;
  }
}
