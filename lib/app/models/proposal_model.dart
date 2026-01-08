/// Proposal Model for Service Lifecycle Management
/// Represents a proposal from a user to an agent or loan officer

enum ProposalStatus {
  pending,      // Initial state - waiting for response
  accepted,     // Agent/LO accepted the proposal
  rejected,     // Agent/LO rejected the proposal
  inProgress,   // Service has started (after acceptance)
  completed,    // Service completed successfully
  reported,     // Service reported as incomplete/problematic
}

extension ProposalStatusExtension on ProposalStatus {
  String get label {
    switch (this) {
      case ProposalStatus.pending:
        return 'Pending';
      case ProposalStatus.accepted:
        return 'Accepted';
      case ProposalStatus.rejected:
        return 'Rejected';
      case ProposalStatus.inProgress:
        return 'In Progress';
      case ProposalStatus.completed:
        return 'Completed';
      case ProposalStatus.reported:
        return 'Reported';
    }
  }

  String get description {
    switch (this) {
      case ProposalStatus.pending:
        return 'Waiting for response';
      case ProposalStatus.accepted:
        return 'Proposal accepted';
      case ProposalStatus.rejected:
        return 'Proposal rejected';
      case ProposalStatus.inProgress:
        return 'Service in progress';
      case ProposalStatus.completed:
        return 'Service completed';
      case ProposalStatus.reported:
        return 'Issue reported';
    }
  }

  bool get canCompleteService {
    return this == ProposalStatus.inProgress;
  }

  bool get canSubmitReview {
    return this == ProposalStatus.completed;
  }

  bool get canReportIssue {
    return this == ProposalStatus.inProgress;
  }

  bool get isActive {
    return this == ProposalStatus.accepted || this == ProposalStatus.inProgress;
  }

  bool get isTerminal {
    return this == ProposalStatus.rejected || 
           this == ProposalStatus.completed || 
           this == ProposalStatus.reported;
  }
}

class ProposalModel {
  final String id;
  final String userId;              // User who made the proposal
  final String userName;            // User's name
  final String? userProfilePic;     // User's profile picture
  final String professionalId;      // Agent or Loan Officer ID
  final String professionalName;   // Agent or Loan Officer name
  final String professionalType;    // 'agent' or 'loan_officer'
  final ProposalStatus status;
  final String? message;            // Optional message from user
  final String? propertyAddress;    // Optional property address if applicable
  final String? propertyPrice;      // Optional property price if applicable
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? reportedAt;
  final String? rejectionReason;   // If rejected, reason provided
  final String? reportReason;       // If reported, reason provided
  final String? reportDescription;  // If reported, detailed description
  final bool userHasReviewed;       // Whether user has submitted review
  final bool professionalHasReported; // Whether professional has submitted service report

  ProposalModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    required this.professionalId,
    required this.professionalName,
    required this.professionalType,
    required this.status,
    this.message,
    this.propertyAddress,
    this.propertyPrice,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.completedAt,
    this.reportedAt,
    this.rejectionReason,
    this.reportReason,
    this.reportDescription,
    this.userHasReviewed = false,
    this.professionalHasReported = false,
  });

  factory ProposalModel.fromJson(Map<String, dynamic> json) {
    // Parse status
    ProposalStatus status = ProposalStatus.pending;
    final statusStr = json['status']?.toString().toLowerCase() ?? 'pending';
    switch (statusStr) {
      case 'pending':
        status = ProposalStatus.pending;
        break;
      case 'accepted':
        status = ProposalStatus.accepted;
        break;
      case 'rejected':
        status = ProposalStatus.rejected;
        break;
      case 'in_progress':
      case 'inprogress':
        status = ProposalStatus.inProgress;
        break;
      case 'completed':
        status = ProposalStatus.completed;
        break;
      case 'reported':
        status = ProposalStatus.reported;
        break;
    }

    // Parse dates
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    return ProposalModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'User',
      userProfilePic: json['userProfilePic']?.toString(),
      professionalId: json['professionalId']?.toString() ?? '',
      professionalName: json['professionalName']?.toString() ?? 'Professional',
      professionalType: json['professionalType']?.toString() ?? 'agent',
      status: status,
      message: json['message']?.toString(),
      propertyAddress: json['propertyAddress']?.toString(),
      propertyPrice: json['propertyPrice']?.toString(),
      createdAt: parseDate(json['createdAt']?.toString()) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']?.toString()),
      acceptedAt: parseDate(json['acceptedAt']?.toString()),
      completedAt: parseDate(json['completedAt']?.toString()),
      reportedAt: parseDate(json['reportedAt']?.toString()),
      rejectionReason: json['rejectionReason']?.toString(),
      reportReason: json['reportReason']?.toString(),
      reportDescription: json['reportDescription']?.toString(),
      userHasReviewed: json['userHasReviewed'] == true,
      professionalHasReported: json['professionalHasReported'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case ProposalStatus.pending:
        statusStr = 'pending';
        break;
      case ProposalStatus.accepted:
        statusStr = 'accepted';
        break;
      case ProposalStatus.rejected:
        statusStr = 'rejected';
        break;
      case ProposalStatus.inProgress:
        statusStr = 'in_progress';
        break;
      case ProposalStatus.completed:
        statusStr = 'completed';
        break;
      case ProposalStatus.reported:
        statusStr = 'reported';
        break;
    }

    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      if (userProfilePic != null) 'userProfilePic': userProfilePic,
      'professionalId': professionalId,
      'professionalName': professionalName,
      'professionalType': professionalType,
      'status': statusStr,
      if (message != null) 'message': message,
      if (propertyAddress != null) 'propertyAddress': propertyAddress,
      if (propertyPrice != null) 'propertyPrice': propertyPrice,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (reportedAt != null) 'reportedAt': reportedAt!.toIso8601String(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (reportReason != null) 'reportReason': reportReason,
      if (reportDescription != null) 'reportDescription': reportDescription,
      'userHasReviewed': userHasReviewed,
      'professionalHasReported': professionalHasReported,
    };
  }

  ProposalModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePic,
    String? professionalId,
    String? professionalName,
    String? professionalType,
    ProposalStatus? status,
    String? message,
    String? propertyAddress,
    String? propertyPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? reportedAt,
    String? rejectionReason,
    String? reportReason,
    String? reportDescription,
    bool? userHasReviewed,
    bool? professionalHasReported,
  }) {
    return ProposalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      professionalId: professionalId ?? this.professionalId,
      professionalName: professionalName ?? this.professionalName,
      professionalType: professionalType ?? this.professionalType,
      status: status ?? this.status,
      message: message ?? this.message,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyPrice: propertyPrice ?? this.propertyPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      reportedAt: reportedAt ?? this.reportedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reportReason: reportReason ?? this.reportReason,
      reportDescription: reportDescription ?? this.reportDescription,
      userHasReviewed: userHasReviewed ?? this.userHasReviewed,
      professionalHasReported: professionalHasReported ?? this.professionalHasReported,
    );
  }
}



