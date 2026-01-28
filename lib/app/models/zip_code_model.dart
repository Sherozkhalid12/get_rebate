// Zip code model with population-based pricing support
import 'package:getrebate/app/services/zip_code_pricing_service.dart';

class ZipCodeModel {
  final String? id; // MongoDB ID from API
  final String zipCode;
  final String state;
  final String? city;
  final int population;
  final bool? claimedByAgent;
  final bool? claimedByLoanOfficer;
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
    this.city,
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
    final city = json['city']?.toString();
    return ZipCodeModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      zipCode:
          json['postalCode']?.toString() ??
          json['zipCode'] ??
          json['zipcode'] ??
          '',
      state: json['state'] ?? '',
      city: city != null && city.isNotEmpty ? city : null,
      population: json['population'] is int
          ? json['population'] as int
          : (json['population'] is String
                ? int.tryParse(json['population'] as String) ?? 0
                : 0),
      claimedByAgent: json['claimedByAgent'] is bool
          ? json['claimedByAgent'] as bool
          : (json['claimedByAgent'] is String
                ? (json['claimedByAgent']?.toLowerCase() == 'true')
                : null),
      claimedByLoanOfficer: json['claimedByLoanOfficer'] is bool
          ? json['claimedByLoanOfficer'] as bool
          : (json['claimedByLoanOfficer'] is String
                ? (json['claimedByLoanOfficer']?.toLowerCase() == 'true')
                : null),
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
      if (city != null) 'city': city,
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
    String? city,
    int? population,
    bool? claimedByAgent,
    bool? claimedByLoanOfficer,
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
      city: city ?? this.city,
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
