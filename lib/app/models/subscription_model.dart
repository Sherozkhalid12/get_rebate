// Subscription model for tracking user subscriptions

import 'package:getrebate/app/models/promo_code_model.dart';

enum SubscriptionStatus {
  active,
  cancelled, // Cancelled but still active until cancellation date
  expired,
  trial,
  promo, // Active with promo code applied
}

class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate; // null for ongoing subscriptions
  final DateTime? cancellationDate; // When user requested cancellation
  final DateTime? cancellationEffectiveDate; // When cancellation takes effect (30 days after request)
  // Base monthly price calculated from claimed zip codes using population-based tiers
  // This is the sum of all zip code prices based on their population tiers
  final double baseMonthlyPrice;
  final double? currentMonthlyPrice; // Current price after discounts/promos
  final PromoCodeModel? activePromoCode; // Currently applied promo code
  final DateTime? promoExpiresAt; // When the promo expires
  final bool isPromoActive; // Whether promo is currently active
  final int? freeMonthsRemaining; // For loan officers with 6 months free
  final DateTime? freePeriodEndsAt; // When free period ends
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.startDate,
    this.endDate,
    this.cancellationDate,
    this.cancellationEffectiveDate,
    required this.baseMonthlyPrice,
    this.currentMonthlyPrice,
    this.activePromoCode,
    this.promoExpiresAt,
    this.isPromoActive = false,
    this.freeMonthsRemaining,
    this.freePeriodEndsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString() == 'SubscriptionStatus.${json['status']}',
        orElse: () => SubscriptionStatus.active,
      ),
      startDate: DateTime.parse(
        json['startDate'] ?? DateTime.now().toIso8601String(),
      ),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      cancellationDate: json['cancellationDate'] != null
          ? DateTime.parse(json['cancellationDate'])
          : null,
      cancellationEffectiveDate: json['cancellationEffectiveDate'] != null
          ? DateTime.parse(json['cancellationEffectiveDate'])
          : null,
      baseMonthlyPrice: (json['baseMonthlyPrice'] ?? 0.0).toDouble(),
      currentMonthlyPrice: json['currentMonthlyPrice']?.toDouble(),
      activePromoCode: json['activePromoCode'] != null
          ? PromoCodeModel.fromJson(json['activePromoCode'])
          : null,
      promoExpiresAt: json['promoExpiresAt'] != null
          ? DateTime.parse(json['promoExpiresAt'])
          : null,
      isPromoActive: json['isPromoActive'] ?? false,
      freeMonthsRemaining: json['freeMonthsRemaining'],
      freePeriodEndsAt: json['freePeriodEndsAt'] != null
          ? DateTime.parse(json['freePeriodEndsAt'])
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'status': status.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'cancellationDate': cancellationDate?.toIso8601String(),
      'cancellationEffectiveDate': cancellationEffectiveDate?.toIso8601String(),
      'baseMonthlyPrice': baseMonthlyPrice,
      'currentMonthlyPrice': currentMonthlyPrice,
      'activePromoCode': activePromoCode?.toJson(),
      'promoExpiresAt': promoExpiresAt?.toIso8601String(),
      'isPromoActive': isPromoActive,
      'freeMonthsRemaining': freeMonthsRemaining,
      'freePeriodEndsAt': freePeriodEndsAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? cancellationDate,
    DateTime? cancellationEffectiveDate,
    double? baseMonthlyPrice,
    double? currentMonthlyPrice,
    PromoCodeModel? activePromoCode,
    DateTime? promoExpiresAt,
    bool? isPromoActive,
    int? freeMonthsRemaining,
    DateTime? freePeriodEndsAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cancellationDate: cancellationDate ?? this.cancellationDate,
      cancellationEffectiveDate:
          cancellationEffectiveDate ?? this.cancellationEffectiveDate,
      baseMonthlyPrice: baseMonthlyPrice ?? this.baseMonthlyPrice,
      currentMonthlyPrice: currentMonthlyPrice ?? this.currentMonthlyPrice,
      activePromoCode: activePromoCode ?? this.activePromoCode,
      promoExpiresAt: promoExpiresAt ?? this.promoExpiresAt,
      isPromoActive: isPromoActive ?? this.isPromoActive,
      freeMonthsRemaining: freeMonthsRemaining ?? this.freeMonthsRemaining,
      freePeriodEndsAt: freePeriodEndsAt ?? this.freePeriodEndsAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == SubscriptionStatus.active ||
      status == SubscriptionStatus.promo ||
      status == SubscriptionStatus.cancelled; // Still active until cancellation date

  bool get isCancelled => status == SubscriptionStatus.cancelled;

  bool get isInFreePeriod {
    if (freePeriodEndsAt == null) return false;
    return DateTime.now().isBefore(freePeriodEndsAt!);
  }

  int get daysUntilCancellation {
    if (cancellationEffectiveDate == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(cancellationEffectiveDate!)) return 0;
    return cancellationEffectiveDate!.difference(now).inDays;
  }
}

