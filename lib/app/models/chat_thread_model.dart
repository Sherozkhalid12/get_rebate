class ChatThreadModel {
  final String id;
  final List<String> participants;
  final LastMessage? lastMessage;
  final Map<String, int> unreadCounts;
  final List<ParticipantInfo> otherParticipants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatThreadModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCounts,
    required this.otherParticipants,
    this.createdAt,
    this.updatedAt,
  });

  /// Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(String dateString) {
    try {
      if (dateString.isEmpty) return null;
      
      // DateTime.tryParse already handles UTC when string ends with 'Z'
      // It returns a UTC DateTime automatically
      final parsed = DateTime.tryParse(dateString);
      
      if (parsed != null) {
        // If the string ends with Z, parsed is already in UTC
        // If not, we assume it's UTC and convert it
        if (dateString.endsWith('Z')) {
          // Already UTC, but ensure it's marked as such
          return parsed.isUtc ? parsed : parsed.toUtc();
        } else {
          // Assume UTC if no timezone specified
          return parsed.toUtc();
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error parsing date: $dateString - $e');
      return null;
    }
  }

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    // Parse participants
    final participantsList = json['participants'] as List<dynamic>? ?? [];
    final participants = participantsList.map((e) => e.toString()).toList();

    // Parse last message
    LastMessage? lastMessage;
    if (json['lastMessage'] != null && json['lastMessage'] is Map) {
      final lastMsgJson = json['lastMessage'] as Map<String, dynamic>;
      // Only create LastMessage if it has actual content (not empty object)
      if (lastMsgJson.isNotEmpty) {
        lastMessage = LastMessage(
          text: lastMsgJson['text']?.toString() ?? '',
          createdAt: lastMsgJson['createdAt'] != null && 
                     lastMsgJson['createdAt'].toString().isNotEmpty
              ? _parseDateTime(lastMsgJson['createdAt'].toString())
              : null,
        );
      }
    }

    // Parse unread counts - handle both Map format and direct number format
    final unreadCountsMap = <String, int>{};
    if (json['unreadCounts'] != null && json['unreadCounts'] is Map) {
      (json['unreadCounts'] as Map).forEach((key, value) {
        unreadCountsMap[key.toString()] = int.tryParse(value.toString()) ?? 0;
      });
    } else if (json['unreadCount'] != null) {
      // Handle direct unreadCount number (from API response)
      // We'll need to know the current user ID to set this properly
      // For now, we'll store it with a placeholder key
      final unreadCount = int.tryParse(json['unreadCount'].toString()) ?? 0;
      unreadCountsMap['_current_user'] = unreadCount;
    }

    // Parse other participants - handle both 'otherParticipants' array and 'otherUser' object
    final List<ParticipantInfo> otherParticipants = [];
    
    if (json['otherParticipants'] != null && json['otherParticipants'] is List) {
      final otherParticipantsList = json['otherParticipants'] as List<dynamic>;
      otherParticipants.addAll(
        otherParticipantsList
            .map((e) => ParticipantInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } else if (json['otherUser'] != null && json['otherUser'] is Map) {
      // Handle the new API format with 'otherUser' object
      final otherUserJson = json['otherUser'] as Map<String, dynamic>;
      otherParticipants.add(ParticipantInfo.fromJson(otherUserJson));
    }

    return ChatThreadModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      participants: participants,
      lastMessage: lastMessage,
      unreadCounts: unreadCountsMap,
      otherParticipants: otherParticipants,
      createdAt: json['createdAt'] != null && json['createdAt'].toString().isNotEmpty
          ? _parseDateTime(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null && json['updatedAt'].toString().isNotEmpty
          ? _parseDateTime(json['updatedAt'].toString())
          : null,
    );
  }

  /// Gets the unread count for a specific user ID
  /// Also handles the case where unreadCount is stored with '_current_user' key
  int getUnreadCountForUser(String userId) {
    if (unreadCounts.containsKey(userId)) {
      return unreadCounts[userId] ?? 0;
    }
    // Fallback to _current_user key if userId not found
    return unreadCounts['_current_user'] ?? 0;
  }

  /// Gets the other participant (not the current user)
  ParticipantInfo? getOtherParticipant(String currentUserId) {
    if (otherParticipants.isEmpty) return null;
    // Return first other participant, or find by ID if needed
    return otherParticipants.first;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage != null
          ? {
              'text': lastMessage!.text,
              'createdAt': lastMessage!.createdAt?.toIso8601String(),
            }
          : null,
      'unreadCounts': unreadCounts,
      'otherParticipants': otherParticipants.map((p) => p.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class LastMessage {
  final String text;
  final DateTime? createdAt;

  LastMessage({
    required this.text,
    this.createdAt,
  });
}

class ParticipantInfo {
  final String id;
  final String fullname;
  final String bio;
  final String? profilePic;
  final String? role; // Added role from API

  ParticipantInfo({
    required this.id,
    required this.fullname,
    required this.bio,
    this.profilePic,
    this.role,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    // Normalize profilePic: convert empty strings to null
    String? profilePic = json['profilePic']?.toString()?.trim();
    if (profilePic != null && profilePic.isEmpty) {
      profilePic = null;
    }
    
    return ParticipantInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      profilePic: profilePic,
      role: json['role']?.toString(), // Extract role from API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullname': fullname,
      'bio': bio,
      'profilePic': profilePic,
      'role': role,
    };
  }
}


