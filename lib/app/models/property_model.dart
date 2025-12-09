class PropertyModel {
  final String id;
  final String title;
  final String description;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double price;
  final int bedrooms;
  final int bathrooms;
  final double squareFeet;
  final String propertyType; // 'house', 'condo', 'townhouse', 'apartment'
  final String status; // 'active', 'pending', 'sold', 'draft'
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String ownerId;
  final String? agentId;
  final Map<String, dynamic>?
  features; // Additional features like pool, garage, etc.
  final double? lotSize;
  final int? yearBuilt;
  final String? mlsNumber;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.propertyType,
    required this.status,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.ownerId,
    this.agentId,
    this.features,
    this.lotSize,
    this.yearBuilt,
    this.mlsNumber,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      squareFeet: (json['squareFeet'] ?? 0).toDouble(),
      propertyType: json['propertyType'] ?? 'house',
      status: json['status'] ?? 'draft',
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      ownerId: json['ownerId'] ?? '',
      agentId: json['agentId'],
      features: json['features'],
      lotSize: json['lotSize']?.toDouble(),
      yearBuilt: json['yearBuilt'],
      mlsNumber: json['mlsNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'price': price,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'propertyType': propertyType,
      'status': status,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'ownerId': ownerId,
      'agentId': agentId,
      'features': features,
      'lotSize': lotSize,
      'yearBuilt': yearBuilt,
      'mlsNumber': mlsNumber,
    };
  }

  PropertyModel copyWith({
    String? id,
    String? title,
    String? description,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? price,
    int? bedrooms,
    int? bathrooms,
    double? squareFeet,
    String? propertyType,
    String? status,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerId,
    String? agentId,
    Map<String, dynamic>? features,
    double? lotSize,
    int? yearBuilt,
    String? mlsNumber,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      price: price ?? this.price,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      squareFeet: squareFeet ?? this.squareFeet,
      propertyType: propertyType ?? this.propertyType,
      status: status ?? this.status,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerId: ownerId ?? this.ownerId,
      agentId: agentId ?? this.agentId,
      features: features ?? this.features,
      lotSize: lotSize ?? this.lotSize,
      yearBuilt: yearBuilt ?? this.yearBuilt,
      mlsNumber: mlsNumber ?? this.mlsNumber,
    );
  }
}
