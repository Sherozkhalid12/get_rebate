// Promo code model for subscription promotions

enum PromoCodeType {
  agent70Off, // 70% off for agents, valid up to 1 year
  loanOfficer6MonthsFree, // 6 months free for loan officers
  retention, // Retention promo codes (admin-provided)
}

enum PromoCodeStatus {
  active,
  expired,
  used,
  invalid,
}

class PromoCodeModel {
  final String id;
  final String code;
  final PromoCodeType type;
  final PromoCodeStatus status;
  final String? createdBy; // Agent ID who created it (for agent-generated codes)
  final String? usedBy; // User ID who used it
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final int? maxUses; // null = unlimited
  final int currentUses; // How many times it's been used
  final double? discountPercent; // For percentage-based discounts
  final int? freeMonths; // For free months promotions
  final String? description;

  PromoCodeModel({
    required this.id,
    required this.code,
    required this.type,
    required this.status,
    this.createdBy,
    this.usedBy,
    required this.createdAt,
    this.expiresAt,
    this.usedAt,
    this.maxUses,
    this.currentUses = 0,
    this.discountPercent,
    this.freeMonths,
    this.description,
  });

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    return PromoCodeModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      type: PromoCodeType.values.firstWhere(
        (e) => e.toString() == 'PromoCodeType.${json['type']}',
        orElse: () => PromoCodeType.agent70Off,
      ),
      status: PromoCodeStatus.values.firstWhere(
        (e) => e.toString() == 'PromoCodeStatus.${json['status']}',
        orElse: () => PromoCodeStatus.active,
      ),
      createdBy: json['createdBy'],
      usedBy: json['usedBy'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      usedAt:
          json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
      maxUses: json['maxUses'],
      currentUses: json['currentUses'] ?? 0,
      discountPercent: json['discountPercent']?.toDouble(),
      freeMonths: json['freeMonths'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdBy': createdBy,
      'usedBy': usedBy,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'usedAt': usedAt?.toIso8601String(),
      'maxUses': maxUses,
      'currentUses': currentUses,
      'discountPercent': discountPercent,
      'freeMonths': freeMonths,
      'description': description,
    };
  }

  PromoCodeModel copyWith({
    String? id,
    String? code,
    PromoCodeType? type,
    PromoCodeStatus? status,
    String? createdBy,
    String? usedBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    int? maxUses,
    int? currentUses,
    double? discountPercent,
    int? freeMonths,
    String? description,
  }) {
    return PromoCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      usedBy: usedBy ?? this.usedBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      discountPercent: discountPercent ?? this.discountPercent,
      freeMonths: freeMonths ?? this.freeMonths,
      description: description ?? this.description,
    );
  }

  bool get isValid {
    if (status != PromoCodeStatus.active) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    if (maxUses != null && currentUses >= maxUses!) return false;
    return true;
  }

  String get displayText {
    switch (type) {
      case PromoCodeType.agent70Off:
        return '70% Off (Up to 1 Year)';
      case PromoCodeType.loanOfficer6MonthsFree:
        return '6 Months Free';
      case PromoCodeType.retention:
        return description ?? 'Retention Promo';
    }
  }
}

