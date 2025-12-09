class OpenHouseModel {
  final String id;
  final String listingId;
  final String agentId;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes; // Optional notes about the open house
  final DateTime createdAt;

  const OpenHouseModel({
    required this.id,
    required this.listingId,
    required this.agentId,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.createdAt,
  });

  factory OpenHouseModel.fromJson(Map<String, dynamic> json) {
    return OpenHouseModel(
      id: (json['id'] ?? '') as String,
      listingId: (json['listingId'] ?? '') as String,
      agentId: (json['agentId'] ?? '') as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingId': listingId,
      'agentId': agentId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  OpenHouseModel copyWith({
    String? id,
    String? listingId,
    String? agentId,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    DateTime? createdAt,
  }) {
    return OpenHouseModel(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      agentId: agentId ?? this.agentId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
