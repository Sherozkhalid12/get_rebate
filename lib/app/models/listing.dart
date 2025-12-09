// Defines the Listing domain model and related value objects.

class ListingStats {
  final int searches;
  final int views;
  final int contacts;

  const ListingStats({this.searches = 0, this.views = 0, this.contacts = 0});

  ListingStats copyWith({int? searches, int? views, int? contacts}) {
    return ListingStats(
      searches: searches ?? this.searches,
      views: views ?? this.views,
      contacts: contacts ?? this.contacts,
    );
  }

  factory ListingStats.fromJson(Map<String, dynamic> json) {
    return ListingStats(
      searches: (json['searches'] ?? 0) as int,
      views: (json['views'] ?? 0) as int,
      contacts: (json['contacts'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'searches': searches, 'views': views, 'contacts': contacts};
  }
}

class ListingAddress {
  final String street;
  final String city;
  final String state;
  final String zip;

  const ListingAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
  });

  factory ListingAddress.fromJson(Map<String, dynamic> json) {
    return ListingAddress(
      street: (json['street'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      state: (json['state'] ?? '') as String,
      zip: (json['zip'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'street': street, 'city': city, 'state': state, 'zip': zip};
  }

  @override
  String toString() {
    return '$street, $city, $state $zip';
  }
}

class Listing {
  final String id;
  final String agentId;
  final int priceCents; // Store currency in cents to avoid precision loss
  final ListingAddress address;
  final List<String> photoUrls;
  final double bacPercent; // Buyer Agent Commission percentage (0..100)
  final bool dualAgencyAllowed;
  final double?
  dualAgencyCommissionPercent; // Total commission % for dual agency (0..100), null if not specified
  final DateTime createdAt;
  final ListingStats stats;

  const Listing({
    required this.id,
    required this.agentId,
    required this.priceCents,
    required this.address,
    required this.photoUrls,
    required this.bacPercent,
    required this.dualAgencyAllowed,
    this.dualAgencyCommissionPercent,
    required this.createdAt,
    this.stats = const ListingStats(),
  });

  Listing copyWith({
    String? id,
    String? agentId,
    int? priceCents,
    ListingAddress? address,
    List<String>? photoUrls,
    double? bacPercent,
    bool? dualAgencyAllowed,
    double? dualAgencyCommissionPercent,
    DateTime? createdAt,
    ListingStats? stats,
  }) {
    return Listing(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      priceCents: priceCents ?? this.priceCents,
      address: address ?? this.address,
      photoUrls: photoUrls ?? this.photoUrls,
      bacPercent: bacPercent ?? this.bacPercent,
      dualAgencyAllowed: dualAgencyAllowed ?? this.dualAgencyAllowed,
      dualAgencyCommissionPercent:
          dualAgencyCommissionPercent ?? this.dualAgencyCommissionPercent,
      createdAt: createdAt ?? this.createdAt,
      stats: stats ?? this.stats,
    );
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: (json['id'] ?? '') as String,
      agentId: (json['agentId'] ?? '') as String,
      priceCents: (json['priceCents'] ?? 0) as int,
      address: ListingAddress.fromJson(json['address'] as Map<String, dynamic>),
      photoUrls: List<String>.from(
        (json['photoUrls'] ?? const <String>[]) as List,
      ),
      bacPercent: ((json['bacPercent'] ?? 0.0) as num).toDouble(),
      dualAgencyAllowed: (json['dualAgencyAllowed'] ?? false) as bool,
      dualAgencyCommissionPercent: json['dualAgencyCommissionPercent'] != null
          ? ((json['dualAgencyCommissionPercent']) as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      stats: json['stats'] == null
          ? const ListingStats()
          : ListingStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'priceCents': priceCents,
      'address': address.toJson(),
      'photoUrls': photoUrls,
      'bacPercent': bacPercent,
      'dualAgencyAllowed': dualAgencyAllowed,
      'dualAgencyCommissionPercent': dualAgencyCommissionPercent,
      'createdAt': createdAt.toIso8601String(),
      'stats': stats.toJson(),
    };
  }
}
