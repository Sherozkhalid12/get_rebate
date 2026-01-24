import 'package:intl/intl.dart';

class WaitingListEntry {
  final String id;
  final String name;
  final String email;
  final String zipCodeId;
  final String userId;
  final DateTime? createdAt;
  final String? role;

  WaitingListEntry({
    required this.id,
    required this.name,
    required this.email,
    required this.zipCodeId,
    required this.userId,
    this.createdAt,
    this.role,
  });

  factory WaitingListEntry.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    return WaitingListEntry(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      zipCodeId: json['zipCodeId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      createdAt:
          createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null,
      role: json['role']?.toString(),
    );
  }

  String get formattedTimestamp {
    if (createdAt == null) return '';
    return DateFormat('MMM d, h:mm a').format(createdAt!);
  }
}
