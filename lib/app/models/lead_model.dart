class LeadModel {
  final String id;
  final PropertyInformation? propertyInformation;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? preferredContact;
  final String? bestTime;
  final String? buyingOrBuilding;
  final String? propertyType;
  final String? priceRange;
  final int? bedrooms;
  final int? bathrooms;
  final bool? workingWithAgent;
  final String? rebateAwareness;
  final String? howHeard;
  final String? comments;
  final String? renovation;
  final String? whenPlanningSell;
  final bool? isPropertyListed;
  final String? idealSellingPrice;
  final String? howMotivatedToSell;
  final String? mostImportantToYou;
  final String? howMuchRebateCouldBe;
  final String? planningArea;
  final String? currentlyLiving;
  final String? mustHaveFeatures;
  final String? timeFrame;
  final String? preApproved;
  final String? loanOfficerRebate;
  final bool? autoMlsSearch;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final LeadUserInfo? currentUserId;
  final LeadUserInfo? agentId;
  final String? leadStatus; // "accepted", "rejected", "pending", etc.
  final LeadAgentResponse? agentResponse; // Contains status, note, respondedAt
  final List<dynamic>?
  markedCompleteBy; // Array of user IDs who marked the lead as complete

  LeadModel({
    required this.id,
    this.propertyInformation,
    this.fullName,
    this.email,
    this.phone,
    this.preferredContact,
    this.bestTime,
    this.buyingOrBuilding,
    this.propertyType,
    this.priceRange,
    this.bedrooms,
    this.bathrooms,
    this.workingWithAgent,
    this.rebateAwareness,
    this.howHeard,
    this.comments,
    this.renovation,
    this.whenPlanningSell,
    this.isPropertyListed,
    this.idealSellingPrice,
    this.howMotivatedToSell,
    this.mostImportantToYou,
    this.howMuchRebateCouldBe,
    this.planningArea,
    this.currentlyLiving,
    this.mustHaveFeatures,
    this.timeFrame,
    this.preApproved,
    this.loanOfficerRebate,
    this.autoMlsSearch,
    this.createdAt,
    this.updatedAt,
    this.currentUserId,
    this.agentId,
    this.leadStatus,
    this.agentResponse,
    this.markedCompleteBy,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['_id']?.toString() ?? '',
      propertyInformation: json['propertyInformation'] != null
          ? PropertyInformation.fromJson(json['propertyInformation'])
          : null,
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      preferredContact: json['preferredContact']?.toString(),
      bestTime: json['bestTime']?.toString(),
      buyingOrBuilding: json['buyingOrBuilding']?.toString(),
      propertyType: json['propertyType']?.toString(),
      priceRange: json['priceRange']?.toString(),
      bedrooms: json['bedrooms'] is int
          ? json['bedrooms'] as int
          : (json['bedrooms'] != null
                ? int.tryParse(json['bedrooms'].toString())
                : null),
      bathrooms: json['bathrooms'] is int
          ? json['bathrooms'] as int
          : (json['bathrooms'] != null
                ? int.tryParse(json['bathrooms'].toString())
                : null),
      workingWithAgent: json['workingWithAgent'] as bool?,
      rebateAwareness: json['rebateAwareness']?.toString(),
      howHeard: json['howHeard']?.toString(),
      comments: json['comments']?.toString(),
      renovation: json['renovation']?.toString(),
      whenPlanningSell: json['whenPlanningSell']?.toString(),
      isPropertyListed: json['isPropertyListed'] as bool?,
      idealSellingPrice: json['idealSellingPrice']?.toString(),
      howMotivatedToSell: json['howMotivatedToSell']?.toString(),
      mostImportantToYou: json['mostImportantToYou']?.toString(),
      howMuchRebateCouldBe: json['howMuchRebateCouldBe']?.toString(),
      planningArea: json['planningArea']?.toString(),
      currentlyLiving: json['currentlyLiving']?.toString(),
      mustHaveFeatures: json['mustHaveFeatures']?.toString(),
      timeFrame: json['timeFrame']?.toString(),
      preApproved: json['preApproved']?.toString(),
      loanOfficerRebate: json['loanOfficerRebate']?.toString(),
      autoMlsSearch: json['autoMlsSearch'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      currentUserId: json['currentUserId'] != null
          ? LeadUserInfo.fromJson(json['currentUserId'])
          : null,
      agentId: json['agentId'] != null
          ? LeadUserInfo.fromJson(json['agentId'])
          : null,
      leadStatus: json['leadStatus']?.toString(),
      agentResponse: json['agentResponse'] is Map<String, dynamic>
          ? LeadAgentResponse.fromJson(
              json['agentResponse'] as Map<String, dynamic>,
            )
          : null,
      markedCompleteBy: json['markedCompleteBy'] as List<dynamic>?,
    );
  }

  // Check if lead is already accepted
  bool get isAccepted => leadStatus?.toLowerCase() == 'accepted';

  // Check if lead is completed
  bool get isCompleted =>
      markedCompleteBy != null && markedCompleteBy!.isNotEmpty;

  // Get agent response note if available
  String? get agentResponseNote => agentResponse?.note;

  // Check if lead is reported
  bool get isReported {
    final status = leadStatus?.toLowerCase();
    if (status == 'reported') {
      return true;
    }
    return agentResponse?.status?.toLowerCase() == 'reported';
  }

  // Get buyer info (currentUserId is the buyer/seller)
  LeadUserInfo? get buyerInfo => currentUserId;

  // Check if this is a buying lead
  bool get isBuyingLead => buyingOrBuilding == 'buying';

  // Check if this is a selling lead
  bool get isSellingLead =>
      buyingOrBuilding == 'selling' || isPropertyListed == true;

  // Get formatted date
  String get formattedDate {
    if (createdAt == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt!.month}/${createdAt!.day}/${createdAt!.year}';
    }
  }
}

class PropertyInformation {
  final String? propertyAddress;
  final String? city;
  final String? zipCode;
  final String? yearBuilt;
  final String? squareFeet;

  PropertyInformation({
    this.propertyAddress,
    this.city,
    this.zipCode,
    this.yearBuilt,
    this.squareFeet,
  });

  factory PropertyInformation.fromJson(Map<String, dynamic> json) {
    return PropertyInformation(
      propertyAddress: json['propertyAddress']?.toString(),
      city: json['city']?.toString(),
      zipCode: json['zipCode']?.toString(),
      yearBuilt: json['yearBuilt']?.toString(),
      squareFeet: json['squareFeet']?.toString(),
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (propertyAddress != null && propertyAddress!.isNotEmpty) {
      parts.add(propertyAddress!);
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    if (zipCode != null && zipCode!.isNotEmpty) {
      parts.add(zipCode!);
    }
    return parts.isEmpty ? 'Address not provided' : parts.join(', ');
  }
}

class LeadUserInfo {
  final String id;
  final String? fullname;
  final String? email;
  final String? phone;
  final String? role;
  final String? profilePic;

  LeadUserInfo({
    required this.id,
    this.fullname,
    this.email,
    this.phone,
    this.role,
    this.profilePic,
  });

  factory LeadUserInfo.fromJson(Map<String, dynamic> json) {
    return LeadUserInfo(
      id: json['_id']?.toString() ?? '',
      fullname: json['fullname']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      profilePic: json['profilePic']?.toString(),
    );
  }
}

class LeadsResponse {
  final bool success;
  final int count;
  final int total;
  final int totalPages;
  final int currentPage;
  final bool hasNextPage;
  final bool hasPrevPage;
  final String? nextPage;
  final String? prevPage;
  final List<LeadModel> leads;

  LeadsResponse({
    required this.success,
    required this.count,
    required this.total,
    required this.totalPages,
    required this.currentPage,
    required this.hasNextPage,
    required this.hasPrevPage,
    this.nextPage,
    this.prevPage,
    required this.leads,
  });

  factory LeadsResponse.fromJson(Map<String, dynamic> json) {
    return LeadsResponse(
      success: json['success'] as bool? ?? false,
      count: json['count'] is int
          ? json['count'] as int
          : (json['count'] != null
                ? int.tryParse(json['count'].toString()) ?? 0
                : 0),
      total: json['total'] is int
          ? json['total'] as int
          : (json['total'] != null
                ? int.tryParse(json['total'].toString()) ?? 0
                : 0),
      totalPages: json['totalPages'] is int
          ? json['totalPages'] as int
          : (json['totalPages'] != null
                ? int.tryParse(json['totalPages'].toString()) ?? 0
                : 0),
      currentPage: json['currentPage'] is int
          ? json['currentPage'] as int
          : (json['currentPage'] != null
                ? int.tryParse(json['currentPage'].toString()) ?? 1
                : 1),
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPrevPage: json['hasPrevPage'] as bool? ?? false,
      nextPage: json['nextPage']?.toString(),
      prevPage: json['prevPage']?.toString(),
      leads: (json['leads'] as List<dynamic>? ?? [])
          .map((lead) => LeadModel.fromJson(lead as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LeadAgentResponse {
  final String? status;
  final String? note;
  final DateTime? respondedAt;

  LeadAgentResponse({this.status, this.note, this.respondedAt});

  factory LeadAgentResponse.fromJson(Map<String, dynamic> json) {
    return LeadAgentResponse(
      status: json['status']?.toString(),
      note: json['note']?.toString(),
      respondedAt: json['respondedAt'] != null
          ? DateTime.tryParse(json['respondedAt'].toString())
          : null,
    );
  }
}
