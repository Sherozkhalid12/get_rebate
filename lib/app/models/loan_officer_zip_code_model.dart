// Loan Officer Zip code model - separate from agent zip code model
import 'package:getrebate/app/services/loan_officer_zip_code_pricing_service.dart';

class LoanOfficerZipCodeModel {
  final String? id; // MongoDB ID from API
  final String postalCode; // API uses "postalCode" not "zipCode"
  final String state;
  final int population;
  final bool claimedByAgent;
  final bool claimedByOfficer; // API uses "claimedByOfficer" not "claimedByLoanOfficer"
  final String country;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanOfficerZipCodeModel({
    this.id,
    required this.postalCode,
    required this.state,
    required this.population,
    this.claimedByAgent = false,
    this.claimedByOfficer = false,
    this.country = 'US',
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoanOfficerZipCodeModel.fromJson(Map<String, dynamic> json) {
    return LoanOfficerZipCodeModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      postalCode: json['postalCode']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      population: json['population'] is int
          ? json['population'] as int
          : (json['population'] is String
          ? int.tryParse(json['population'] as String) ?? 0
          : 0),
      claimedByAgent: json['claimedByAgent'] == true || json['claimedByAgent'] == 'true',
      claimedByOfficer: json['claimedByOfficer'] == true || json['claimedByOfficer'] == 'true',
      country: json['country']?.toString() ?? 'US',
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
      if (id != null) '_id': id,
      'postalCode': postalCode,
      'state': state,
      'population': population,
      'claimedByAgent': claimedByAgent,
      'claimedByOfficer': claimedByOfficer,
      'country': country,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  LoanOfficerZipCodeModel copyWith({
    String? id,
    String? postalCode,
    String? state,
    int? population,
    bool? claimedByAgent,
    bool? claimedByOfficer,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanOfficerZipCodeModel(
      id: id ?? this.id,
      postalCode: postalCode ?? this.postalCode,
      state: state ?? this.state,
      population: population ?? this.population,
      claimedByAgent: claimedByAgent ?? this.claimedByAgent,
      claimedByOfficer: claimedByOfficer ?? this.claimedByOfficer,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isClaimed => claimedByAgent || claimedByOfficer;
  bool get isAvailable => !claimedByOfficer;

  /// Get the calculated price based on population tier (for loan officers)
  double get calculatedPrice {
    return LoanOfficerZipCodePricingService.calculatePriceForPopulation(population);
  }

  /// Get the pricing tier name for this zip code
  String get tier {
    final tier = LoanOfficerZipCodePricingService.getTierForPopulation(population);
    return tier?.tierName ?? 'Unknown';
  }

  /// Get the pricing tier description for this zip code
  String get tierDescription {
    final tier = LoanOfficerZipCodePricingService.getTierForPopulation(population);
    return tier?.description ?? 'Unknown tier';
  }
}
