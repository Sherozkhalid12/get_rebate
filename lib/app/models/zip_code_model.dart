// Zip code model with population-based pricing support
import 'package:getrebate/app/services/zip_code_pricing_service.dart';

class ZipCodeModel {
  final String? id; // MongoDB ID from API
  final String zipCode;
  final String state;
  final int population;
  final String? claimedByAgent;
  final String? claimedByLoanOfficer;
  final DateTime? claimedAt;
  final double? price; // Optional: can be calculated from population if null
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime? lastSearchedAt;
  final int searchCount;

  ZipCodeModel({
    this.id,
    required this.zipCode,
    required this.state,
    required this.population,
    this.claimedByAgent,
    this.claimedByLoanOfficer,
    this.claimedAt,
    this.price, // Optional: will be calculated from population if null
    this.isAvailable = true,
    required this.createdAt,
    this.lastSearchedAt,
    this.searchCount = 0,
  });

  factory ZipCodeModel.fromJson(Map<String, dynamic> json) {
    return ZipCodeModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      zipCode: json['zipCode'] ?? json['zipcode'] ?? '',
      state: json['state'] ?? '',
      population: json['population'] is int
          ? json['population'] as int
          : (json['population'] is String
                ? int.tryParse(json['population'] as String) ?? 0
                : 0),
      claimedByAgent: json['claimedByAgent'],
      claimedByLoanOfficer: json['claimedByLoanOfficer'],
      claimedAt: json['claimedAt'] != null
          ? DateTime.parse(json['claimedAt'])
          : null,
      price: json['price']?.toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastSearchedAt: json['lastSearchedAt'] != null
          ? DateTime.parse(json['lastSearchedAt'])
          : null,
      searchCount: json['searchCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'zipCode': zipCode,
      'state': state,
      'population': population,
      'claimedByAgent': claimedByAgent,
      'claimedByLoanOfficer': claimedByLoanOfficer,
      'claimedAt': claimedAt?.toIso8601String(),
      'price': price,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'lastSearchedAt': lastSearchedAt?.toIso8601String(),
      'searchCount': searchCount,
    };
  }

  ZipCodeModel copyWith({
    String? id,
    String? zipCode,
    String? state,
    int? population,
    String? claimedByAgent,
    String? claimedByLoanOfficer,
    DateTime? claimedAt,
    double? price,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? lastSearchedAt,
    int? searchCount,
  }) {
    return ZipCodeModel(
      id: id ?? this.id,
      zipCode: zipCode ?? this.zipCode,
      state: state ?? this.state,
      population: population ?? this.population,
      claimedByAgent: claimedByAgent ?? this.claimedByAgent,
      claimedByLoanOfficer: claimedByLoanOfficer ?? this.claimedByLoanOfficer,
      claimedAt: claimedAt ?? this.claimedAt,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      lastSearchedAt: lastSearchedAt ?? this.lastSearchedAt,
      searchCount: searchCount ?? this.searchCount,
    );
  }

  bool get isClaimed => claimedByAgent != null || claimedByLoanOfficer != null;

  /// Get the calculated price based on population tier (ignores backend price)
  double get calculatedPrice =>
      ZipCodePricingService.calculatePriceForPopulation(population);

  /// Get the pricing tier name for this zip code
  String get tier {
    final tier = ZipCodePricingService.getTierForPopulation(population);
    return tier?.tierName ?? 'Unknown';
  }

  /// Get the pricing tier description for this zip code
  String get tierDescription {
    final tier = ZipCodePricingService.getTierForPopulation(population);
    return tier?.description ?? 'Unknown tier';
  }
}
