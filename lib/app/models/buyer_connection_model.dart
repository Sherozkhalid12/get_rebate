class BuyerConnectionModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String? buyerEmail;
  final String? buyerPhone;
  final String? preferredContactMethod;
  final DateTime selectedAt;
  final String status; // 'active' or 'removed'
  final bool checklistCompleted;
  final DateTime? checklistCompletedAt;

  BuyerConnectionModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    this.buyerEmail,
    this.buyerPhone,
    this.preferredContactMethod,
    required this.selectedAt,
    required this.status,
    this.checklistCompleted = false,
    this.checklistCompletedAt,
  });

  factory BuyerConnectionModel.fromJson(Map<String, dynamic> json) {
    return BuyerConnectionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      buyerId: json['buyerId']?.toString() ?? json['buyer']['_id']?.toString() ?? '',
      buyerName: json['buyerName'] ?? json['buyer']['name'] ?? 'Unknown Buyer',
      buyerEmail: json['buyerEmail'] ?? json['buyer']['email'],
      buyerPhone: json['buyerPhone'] ?? json['buyer']['phone'],
      preferredContactMethod: json['preferredContactMethod'] ?? json['buyer']['preferredContactMethod'],
      selectedAt: json['selectedAt'] != null
          ? DateTime.parse(json['selectedAt'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
      status: json['status'] ?? 'active',
      checklistCompleted: json['checklistCompleted'] ?? false,
      checklistCompletedAt: json['checklistCompletedAt'] != null
          ? DateTime.parse(json['checklistCompletedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'buyerPhone': buyerPhone,
      'preferredContactMethod': preferredContactMethod,
      'selectedAt': selectedAt.toIso8601String(),
      'status': status,
      'checklistCompleted': checklistCompleted,
      'checklistCompletedAt': checklistCompletedAt?.toIso8601String(),
    };
  }

  BuyerConnectionModel copyWith({
    String? id,
    String? buyerId,
    String? buyerName,
    String? buyerEmail,
    String? buyerPhone,
    String? preferredContactMethod,
    DateTime? selectedAt,
    String? status,
    bool? checklistCompleted,
    DateTime? checklistCompletedAt,
  }) {
    return BuyerConnectionModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      selectedAt: selectedAt ?? this.selectedAt,
      status: status ?? this.status,
      checklistCompleted: checklistCompleted ?? this.checklistCompleted,
      checklistCompletedAt: checklistCompletedAt ?? this.checklistCompletedAt,
    );
  }
}


