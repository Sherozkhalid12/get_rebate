import 'package:flutter/foundation.dart';
import 'package:getrebate/app/utils/api_constants.dart';

enum UserRole { buyerSeller, agent, loanOfficer }

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final String? profileImage;
  final List<String> licensedStates;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isVerified;
  final Map<String, dynamic>? additionalData;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.profileImage,
    this.licensedStates = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.isVerified = false,
    this.additionalData,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'id' and '_id' fields (API returns _id, storage uses id)
    final userId = json['_id']?.toString() ?? 
                   json['id']?.toString() ?? 
                   '';
    
    // Normalize profile image URL using helper
    final profileImageRaw = json['profileImage']?.toString() ?? 
                           json['profilePic']?.toString() ??
                           json['profile_pic']?.toString();
    
    if (kDebugMode) {
      print('👤 UserModel.fromJson:');
      print('   Raw profileImage from JSON: "$profileImageRaw"');
    }
    
    final profileImage = ApiConstants.getImageUrl(profileImageRaw);
    
    if (kDebugMode) {
      print('   Normalized profileImage: "$profileImage"');
    }
    
    return UserModel(
      id: userId,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.buyerSeller,
      ),
      profileImage: profileImage,
      licensedStates: List<String>.from(json['licensedStates'] ?? []),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      isVerified: json['isVerified'] ?? false,
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'profileImage': profileImage,
      'licensedStates': licensedStates,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isVerified': isVerified,
      'additionalData': additionalData,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? profileImage,
    List<String>? licensedStates,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isVerified,
    Map<String, dynamic>? additionalData,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      licensedStates: licensedStates ?? this.licensedStates,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
