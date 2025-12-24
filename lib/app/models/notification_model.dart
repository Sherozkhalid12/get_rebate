class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final LeadInfo? leadId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.leadId,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      leadId: json['leadId'] != null
          ? LeadInfo.fromJson(
              json['leadId'] is Map<String, dynamic>
                  ? json['leadId'] as Map<String, dynamic>
                  : {},
            )
          : null,
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'leadId': leadId?.toJson(),
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    LeadInfo? leadId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      leadId: leadId ?? this.leadId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LeadInfo {
  final String id;
  final String fullName;
  final String email;

  LeadInfo({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory LeadInfo.fromJson(Map<String, dynamic> json) {
    return LeadInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
    };
  }
}

class NotificationResponse {
  final bool success;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int total;

  NotificationResponse({
    required this.success,
    required this.notifications,
    required this.unreadCount,
    required this.total,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['success'] ?? false,
      notifications: (json['notifications'] as List<dynamic>?)
              ?.map((item) => NotificationModel.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList() ??
          [],
      unreadCount: json['unreadCount'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

