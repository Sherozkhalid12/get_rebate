/// User Listing Model - Represents a listing created by a user
class UserListingModel {
  final String id;
  final String propertyTitle;
  final String description;
  final String price;
  final String bacPercentage;
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;
  final String status;
  final List<String> propertyPhotos;
  final List<String> propertyFeatures;
  final Map<String, dynamic>? propertyDetails;
  final String? userId;
  final String? userName;
  final String? userProfilePic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int views;
  final int contacts;
  final int searches;

  UserListingModel({
    required this.id,
    required this.propertyTitle,
    required this.description,
    required this.price,
    required this.bacPercentage,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.status,
    this.propertyPhotos = const [],
    this.propertyFeatures = const [],
    this.propertyDetails,
    this.userId,
    this.userName,
    this.userProfilePic,
    required this.createdAt,
    required this.updatedAt,
    this.views = 0,
    this.contacts = 0,
    this.searches = 0,
  });

  factory UserListingModel.fromJson(Map<String, dynamic> json) {
    // Parse dates
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Parse user info
    final user = json['user'] as Map<String, dynamic>?;
    final userId = user?['_id']?.toString() ?? user?['id']?.toString();
    final userName = user?['fullname']?.toString() ?? user?['name']?.toString();
    final userProfilePic = user?['profilePic']?.toString();

    // Parse property photos
    final photos = json['propertyPhotos'] as List<dynamic>? ?? [];
    final propertyPhotos = photos.map((e) => e.toString()).toList();

    // Parse property features
    final features = json['propertyFeatures'] as List<dynamic>? ?? [];
    final propertyFeatures = features.map((e) => e.toString()).toList();

    return UserListingModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      propertyTitle: json['propertyTitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      bacPercentage: json['BACPercentage']?.toString() ?? '0',
      streetAddress: json['streetAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      propertyPhotos: propertyPhotos,
      propertyFeatures: propertyFeatures,
      propertyDetails: json['propertyDetails'] as Map<String, dynamic>?,
      userId: userId,
      userName: userName,
      userProfilePic: userProfilePic,
      createdAt: parseDate(json['createdAt']?.toString()) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']?.toString()) ?? DateTime.now(),
      views: (json['views'] as num?)?.toInt() ?? 0,
      contacts: (json['contacts'] as num?)?.toInt() ?? 0,
      searches: (json['searches'] as num?)?.toInt() ?? 0,
    );
  }

  String get fullAddress => '$streetAddress, $city, $state $zipCode';

  String get formattedPrice {
    try {
      final priceNum = double.tryParse(price) ?? 0;
      if (priceNum >= 1000000) {
        return '\$${(priceNum / 1000000).toStringAsFixed(2)}M';
      } else if (priceNum >= 1000) {
        return '\$${(priceNum / 1000).toStringAsFixed(0)}K';
      }
      return '\$${priceNum.toStringAsFixed(0)}';
    } catch (e) {
      return '\$$price';
    }
  }

  String? get firstPhotoUrl {
    if (propertyPhotos.isEmpty) return null;
    final photo = propertyPhotos.first;
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }
    // Build full URL - will be built in view using ApiConstants
    return photo;
  }
}

