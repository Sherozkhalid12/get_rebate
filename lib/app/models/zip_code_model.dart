// Zip code model with population-based pricing support
import 'package:getrebate/app/services/zip_code_pricing_service.dart';

class ZipCodeModel {
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
      zipCode: json['zipCode'] ?? '',
      state: json['state'] ?? '',
      population: json['population'] ?? 0,
      claimedByAgent: json['claimedByAgent'],
      claimedByLoanOfficer: json['claimedByLoanOfficer'],
      claimedAt: json['claimedAt'] != null
          ? DateTime.parse(json['claimedAt'])
          : null,
      price: json['price']?.toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastSearchedAt: json['lastSearchedAt'] != null
          ? DateTime.parse(json['lastSearchedAt'])
          : null,
      searchCount: json['searchCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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

  /// Get the calculated price based on population tier (if price is not explicitly set)
  double get calculatedPrice {
    if (price != null) return price!;
    return ZipCodePricingService.calculatePriceForPopulation(population);
  }

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
