// Loan Officer Zip code model - separate from agent zip code model
import 'package:getrebate/app/services/loan_officer_zip_code_pricing_service.dart';

class LoanOfficerZipCodeModel {
  final String? id; // MongoDB ID from API
  final String postalCode; // API uses "postalCode" not "zipCode"
  final String state;
  final String? city;
  final int population;
  final bool claimedByAgent;
  final bool claimedByOfficer; // API uses "claimedByOfficer" not "claimedByLoanOfficer"
  final String country;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> waitingUsers; // User IDs in waiting list (from API WaitingUsers)

  LoanOfficerZipCodeModel({
    this.id,
    required this.postalCode,
    required this.state,
    this.city,
    required this.population,
    this.claimedByAgent = false,
    this.claimedByOfficer = false,
    this.country = 'US',
    required this.createdAt,
    required this.updatedAt,
    this.waitingUsers = const [],
  });

  factory LoanOfficerZipCodeModel.fromJson(Map<String, dynamic> json) {
    List<String> waitingUsersList = [];
    final wu = json['WaitingUsers'] ?? json['waitingUsers'];
    if (wu != null && wu is List) {
      for (final e in wu) {
        if (e == null) continue;
        if (e is String && e.isNotEmpty) {
          waitingUsersList.add(e);
        } else if (e is Map) {
          final id = (e['_id'] ?? e['id'])?.toString();
          if (id != null && id.isNotEmpty) waitingUsersList.add(id);
        } else {
          final s = e.toString();
          if (s.isNotEmpty) waitingUsersList.add(s);
        }
      }
    }
    final city = json['city']?.toString();
    return LoanOfficerZipCodeModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      postalCode: json['postalCode']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      city: city != null && city.isNotEmpty ? city : null,
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
      waitingUsers: waitingUsersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'postalCode': postalCode,
      'state': state,
      if (city != null) 'city': city,
      'population': population,
      'claimedByAgent': claimedByAgent,
      'claimedByOfficer': claimedByOfficer,
      'country': country,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'WaitingUsers': waitingUsers,
    };
  }

  LoanOfficerZipCodeModel copyWith({
    String? id,
    String? postalCode,
    String? state,
    String? city,
    int? population,
    bool? claimedByAgent,
    bool? claimedByOfficer,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? waitingUsers,
  }) {
    return LoanOfficerZipCodeModel(
      id: id ?? this.id,
      postalCode: postalCode ?? this.postalCode,
      state: state ?? this.state,
      city: city ?? this.city,
      population: population ?? this.population,
      claimedByAgent: claimedByAgent ?? this.claimedByAgent,
      claimedByOfficer: claimedByOfficer ?? this.claimedByOfficer,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      waitingUsers: waitingUsers ?? this.waitingUsers,
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
