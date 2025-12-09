import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/models/user_model.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderType; // 'agent', 'loan_officer', 'user'
  final String? senderImage;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? propertyAddress;
  final String? propertyPrice;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    this.senderImage,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.propertyAddress,
    this.propertyPrice,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderType: json['senderType'] ?? '',
      senderImage: json['senderImage'],
      message: json['message'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['isRead'] ?? false,
      propertyAddress: json['propertyAddress'],
      propertyPrice: json['propertyPrice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'senderImage': senderImage,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'propertyAddress': propertyAddress,
      'propertyPrice': propertyPrice,
    };
  }
}

class ConversationModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderType;
  final String? senderImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? propertyAddress;
  final String? propertyPrice;

  ConversationModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    this.senderImage,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.propertyAddress,
    this.propertyPrice,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderType: json['senderType'] ?? '',
      senderImage: json['senderImage'],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(
        json['lastMessageTime'] ?? DateTime.now().toIso8601String(),
      ),
      unreadCount: json['unreadCount'] ?? 0,
      propertyAddress: json['propertyAddress'],
      propertyPrice: json['propertyPrice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'senderImage': senderImage,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'propertyAddress': propertyAddress,
      'propertyPrice': propertyPrice,
    };
  }
}

class MessagesController extends GetxController {
  // Data
  final _conversations = <ConversationModel>[].obs;
  final _messages = <MessageModel>[].obs;
  final _selectedConversation = Rxn<ConversationModel>();
  final _isLoading = false.obs;
  final _searchQuery = ''.obs;

  // Message input
  final messageController = TextEditingController();

  // Auth controller
  late final AuthController _authController;

  // Check if current user is loan officer
  bool get isLoanOfficer {
    return _authController.currentUser?.role == UserRole.loanOfficer;
  }

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  ConversationModel? get selectedConversation => _selectedConversation.value;
  bool get isLoading => _isLoading.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>();
    _loadArguments();
    _loadMockData();
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['agent'] != null) {
      // Create a new conversation with the agent
      final agent = args['agent'] as Map<String, dynamic>;
      final listing = args['listing'] as Map<String, dynamic>?;
      final propertyAddress = args['propertyAddress'] as String?;

      final newConversation = ConversationModel(
        id: 'conv_${agent['id']}_${DateTime.now().millisecondsSinceEpoch}',
        senderId: agent['id'] as String,
        senderName: agent['name'] as String,
        senderType: 'agent',
        senderImage: agent['profileImage'] as String?,
        lastMessage:
            'Hi! I\'m interested in learning more about this property.',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        propertyAddress: propertyAddress,
        propertyPrice: listing?['priceCents'] != null
            ? '\$${((listing!['priceCents'] as int) / 100).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
            : null,
      );

      // Add to conversations if not already exists
      if (!_conversations.any((conv) => conv.senderId == agent['id'])) {
        _conversations.insert(0, newConversation);
      }

      // Select this conversation
      selectConversation(newConversation);
    }
  }

  void _loadMockData() {
    // Load different mock data based on user role
    if (isLoanOfficer) {
      // Loan officer sees conversations with buyers/sellers
      _conversations.value = [
        ConversationModel(
          id: 'conv_1',
          senderId: 'buyer_1',
          senderName: 'John Smith',
          senderType: 'user',
          senderImage: 'https://i.pravatar.cc/150?img=5',
          lastMessage:
              'Hi! I\'m interested in learning more about your mortgage options. Can you help me with pre-approval?',
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
          unreadCount: 1,
          propertyAddress: '123 Main St, New York, NY',
          propertyPrice: '\$450,000',
        ),
        ConversationModel(
          id: 'conv_2',
          senderId: 'buyer_2',
          senderName: 'Emily Johnson',
          senderType: 'user',
          senderImage: 'https://i.pravatar.cc/150?img=6',
          lastMessage:
              'Thank you for the information! When can we schedule a call to discuss the loan terms?',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
          unreadCount: 0,
          propertyAddress: '456 Oak Ave, Brooklyn, NY',
          propertyPrice: '\$320,000',
        ),
        ConversationModel(
          id: 'conv_3',
          senderId: 'buyer_3',
          senderName: 'Michael Davis',
          senderType: 'user',
          senderImage: 'https://i.pravatar.cc/150?img=7',
          lastMessage:
              'I have a question about the rebate program. Does your lender allow commission rebates?',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
          unreadCount: 2,
          propertyAddress: '789 Pine St, Queens, NY',
          propertyPrice: '\$580,000',
        ),
      ];
    } else {
      // Buyer/seller sees conversations with agents/loan officers
      _conversations.value = [
        ConversationModel(
          id: 'conv_1',
          senderId: 'agent_1',
          senderName: 'Sarah Johnson',
          senderType: 'agent',
          senderImage: 'https://i.pravatar.cc/150?img=1',
          lastMessage:
              'I have a great property that matches your criteria. Would you like to schedule a viewing?',
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
          unreadCount: 2,
          propertyAddress: '123 Main St, New York, NY',
          propertyPrice: '\$750,000',
        ),
        ConversationModel(
          id: 'conv_2',
          senderId: 'loan_1',
          senderName: 'Jennifer Davis',
          senderType: 'loan_officer',
          senderImage: 'https://i.pravatar.cc/150?img=2',
          lastMessage:
              'Your pre-approval is ready! I can offer you a 3.5% rate with our rebate program.',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
          unreadCount: 1,
          propertyAddress: '456 Oak Ave, Brooklyn, NY',
          propertyPrice: '\$650,000',
        ),
        ConversationModel(
          id: 'conv_3',
          senderId: 'agent_2',
          senderName: 'Michael Chen',
          senderType: 'agent',
          senderImage: 'https://i.pravatar.cc/150?img=3',
          lastMessage:
              'Thanks for your interest! I\'ll send you the property details shortly.',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
          unreadCount: 0,
          propertyAddress: '789 Pine St, Queens, NY',
          propertyPrice: '\$580,000',
        ),
      ];
    }

    // Mock messages for first conversation - different based on role
    if (isLoanOfficer && _selectedConversation.value != null) {
      // Loan officer perspective - buyer is the sender
      _messages.value = [
        MessageModel(
          id: 'msg_1',
          senderId: _selectedConversation.value!.senderId,
          senderName: _selectedConversation.value!.senderName,
          senderType: 'user',
          senderImage: _selectedConversation.value!.senderImage,
          message:
              'Hi! I\'m interested in learning more about your mortgage options. Can you help me with pre-approval?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
          propertyAddress: _selectedConversation.value!.propertyAddress,
          propertyPrice: _selectedConversation.value!.propertyPrice,
        ),
        MessageModel(
          id: 'msg_2',
          senderId: _authController.currentUser?.id ?? 'loan_officer',
          senderName: _authController.currentUser?.name ?? 'You',
          senderType: 'loan_officer',
          senderImage: _authController.currentUser?.profileImage,
          message: 'Absolutely! I\'d be happy to help you with pre-approval. Let me gather some information from you.',
          timestamp: DateTime.now().subtract(
            const Duration(hours: 1, minutes: 45),
          ),
          isRead: true,
        ),
        MessageModel(
          id: 'msg_3',
          senderId: _selectedConversation.value!.senderId,
          senderName: _selectedConversation.value!.senderName,
          senderType: 'user',
          senderImage: _selectedConversation.value!.senderImage,
          message:
              'Great! I\'m looking for a property around \$450,000. What interest rates can you offer?',
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          isRead: true,
        ),
        MessageModel(
          id: 'msg_4',
          senderId: _selectedConversation.value!.senderId,
          senderName: _selectedConversation.value!.senderName,
          senderType: 'user',
          senderImage: _selectedConversation.value!.senderImage,
          message:
              'Also, does your lender allow commission rebates? That\'s important to me.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          isRead: false,
          propertyAddress: _selectedConversation.value!.propertyAddress,
          propertyPrice: _selectedConversation.value!.propertyPrice,
        ),
      ];
    } else {
      // Buyer/seller perspective - agent/loan officer is the sender
      _messages.value = [
        MessageModel(
          id: 'msg_1',
          senderId: _selectedConversation.value?.senderId ?? 'agent_1',
          senderName: _selectedConversation.value?.senderName ?? 'Sarah Johnson',
          senderType: _selectedConversation.value?.senderType ?? 'agent',
          senderImage: _selectedConversation.value?.senderImage ?? 'https://i.pravatar.cc/150?img=3',
          message:
              'Hi! I saw you\'re looking for a 2-bedroom apartment in Manhattan. I have some great options for you.',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: true,
          propertyAddress: _selectedConversation.value?.propertyAddress,
          propertyPrice: _selectedConversation.value?.propertyPrice,
        ),
        MessageModel(
          id: 'msg_2',
          senderId: _authController.currentUser?.id ?? 'user',
          senderName: 'You',
          senderType: 'user',
          message: 'That sounds great! What\'s the price range?',
          timestamp: DateTime.now().subtract(
            const Duration(hours: 2, minutes: 30),
          ),
          isRead: true,
        ),
        MessageModel(
          id: 'msg_3',
          senderId: _selectedConversation.value?.senderId ?? 'agent_1',
          senderName: _selectedConversation.value?.senderName ?? 'Sarah Johnson',
          senderType: _selectedConversation.value?.senderType ?? 'agent',
          senderImage: _selectedConversation.value?.senderImage ?? 'https://i.pravatar.cc/150?img=3',
          message:
              'The properties I have range from \$700k to \$800k. All are in great locations with excellent amenities.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
        ),
        MessageModel(
          id: 'msg_4',
          senderId: _selectedConversation.value?.senderId ?? 'agent_1',
          senderName: _selectedConversation.value?.senderName ?? 'Sarah Johnson',
          senderType: _selectedConversation.value?.senderType ?? 'agent',
          senderImage: _selectedConversation.value?.senderImage ?? 'https://i.pravatar.cc/150?img=3',
          message:
              'I have a great property that matches your criteria. Would you like to schedule a viewing?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isRead: false,
          propertyAddress: _selectedConversation.value?.propertyAddress,
          propertyPrice: _selectedConversation.value?.propertyPrice,
        ),
      ];
    }
  }

  void selectConversation(ConversationModel conversation) {
    _selectedConversation.value = conversation;
    _loadMessagesForConversation(conversation.id);
  }

  void _loadMessagesForConversation(String conversationId) {
    // In a real app, this would load messages from the server
    // For now, we'll reload mock messages based on current role
    _loadMockMessages();
  }

  void _loadMockMessages() {
    if (isLoanOfficer && _selectedConversation.value != null) {
      // Loan officer perspective - buyer is the sender
      _messages.value = [
        MessageModel(
          id: 'msg_1',
          senderId: _selectedConversation.value!.senderId,
          senderName: _selectedConversation.value!.senderName,
          senderType: 'user',
          senderImage: _selectedConversation.value!.senderImage,
          message:
              'Hi! I\'m interested in learning more about your mortgage options. Can you help me with pre-approval?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
          propertyAddress: _selectedConversation.value!.propertyAddress,
          propertyPrice: _selectedConversation.value!.propertyPrice,
        ),
        MessageModel(
          id: 'msg_2',
          senderId: _authController.currentUser?.id ?? 'loan_officer',
          senderName: _authController.currentUser?.name ?? 'You',
          senderType: 'loan_officer',
          senderImage: _authController.currentUser?.profileImage,
          message: 'Absolutely! I\'d be happy to help you with pre-approval. Let me gather some information from you.',
          timestamp: DateTime.now().subtract(
            const Duration(hours: 1, minutes: 45),
          ),
          isRead: true,
        ),
        MessageModel(
          id: 'msg_3',
          senderId: _selectedConversation.value!.senderId,
          senderName: _selectedConversation.value!.senderName,
          senderType: 'user',
          senderImage: _selectedConversation.value!.senderImage,
          message:
              'Great! I\'m looking for a property around \$450,000. What interest rates can you offer?',
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          isRead: true,
        ),
        MessageModel(
          id: 'msg_4',
          senderId: _selectedConversation.value!.senderId,
          senderName: _selectedConversation.value!.senderName,
          senderType: 'user',
          senderImage: _selectedConversation.value!.senderImage,
          message:
              'Also, does your lender allow commission rebates? That\'s important to me.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          isRead: false,
          propertyAddress: _selectedConversation.value!.propertyAddress,
          propertyPrice: _selectedConversation.value!.propertyPrice,
        ),
      ];
    } else if (_selectedConversation.value != null) {
      // Buyer/seller perspective
      _messages.value = [
        MessageModel(
          id: 'msg_1',
          senderId: _selectedConversation.value!.senderId,
          senderName: _selectedConversation.value!.senderName,
          senderType: _selectedConversation.value!.senderType,
          senderImage: _selectedConversation.value!.senderImage,
          message:
              'Hi! I saw you\'re looking for a 2-bedroom apartment in Manhattan. I have some great options for you.',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: true,
          propertyAddress: _selectedConversation.value!.propertyAddress,
          propertyPrice: _selectedConversation.value!.propertyPrice,
        ),
        MessageModel(
          id: 'msg_2',
          senderId: _authController.currentUser?.id ?? 'user',
          senderName: 'You',
          senderType: 'user',
          message: 'That sounds great! What\'s the price range?',
          timestamp: DateTime.now().subtract(
            const Duration(hours: 2, minutes: 30),
          ),
          isRead: true,
        ),
        MessageModel(
          id: 'msg_3',
          senderId: _selectedConversation.value!.senderId,
          senderName: _selectedConversation.value!.senderName,
          senderType: _selectedConversation.value!.senderType,
          senderImage: _selectedConversation.value!.senderImage,
          message:
              'The properties I have range from \$700k to \$800k. All are in great locations with excellent amenities.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
        ),
        MessageModel(
          id: 'msg_4',
          senderId: _selectedConversation.value!.senderId,
          senderName: _selectedConversation.value!.senderName,
          senderType: _selectedConversation.value!.senderType,
          senderImage: _selectedConversation.value!.senderImage,
          message:
              'I have a great property that matches your criteria. Would you like to schedule a viewing?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isRead: false,
          propertyAddress: _selectedConversation.value!.propertyAddress,
          propertyPrice: _selectedConversation.value!.propertyPrice,
        ),
      ];
    }
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    // Determine sender info based on role
    final currentUser = _authController.currentUser;
    final senderId = currentUser?.id ?? (isLoanOfficer ? 'loan_officer' : 'user');
    final senderName = isLoanOfficer ? (currentUser?.name ?? 'You') : 'You';
    final senderType = isLoanOfficer ? 'loan_officer' : 'user';
    final senderImage = currentUser?.profileImage;

    final message = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      senderImage: senderImage,
      message: messageController.text.trim(),
      timestamp: DateTime.now(),
      isRead: true,
    );

    _messages.add(message);
    messageController.clear();

    // Update conversation last message
    if (_selectedConversation.value != null) {
      final convIndex = _conversations.indexWhere(
        (c) => c.id == _selectedConversation.value!.id,
      );
      if (convIndex != -1) {
        _conversations[convIndex] = _selectedConversation.value!.copyWith(
          lastMessage: message.message,
          lastMessageTime: message.timestamp,
        );
      }
    }

    // Simulate response only for buyer/seller (not for loan officers)
    if (!isLoanOfficer) {
      Future.delayed(const Duration(seconds: 2), () {
        final response = MessageModel(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderId: _selectedConversation.value?.senderId ?? '',
          senderName: _selectedConversation.value?.senderName ?? '',
          senderType: _selectedConversation.value?.senderType ?? '',
          senderImage: _selectedConversation.value?.senderImage,
          message: 'Thanks for your message! I\'ll get back to you soon.',
          timestamp: DateTime.now(),
          isRead: false,
        );
        _messages.add(response);
      });
    }
  }

  void searchConversations(String query) {
    _searchQuery.value = query;
    // In a real app, this would filter conversations
  }

  void markAsRead(String conversationId) {
    final conversation = _conversations.firstWhereOrNull(
      (conv) => conv.id == conversationId,
    );
    if (conversation != null) {
      final index = _conversations.indexWhere(
        (conv) => conv.id == conversationId,
      );
      _conversations[index] = conversation.copyWith(unreadCount: 0);
    }
  }

  void deleteConversation(String conversationId) {
    _conversations.removeWhere((conv) => conv.id == conversationId);
    if (_selectedConversation.value?.id == conversationId) {
      _selectedConversation.value = null;
      _messages.clear();
    }
    Get.snackbar('Deleted', 'Conversation deleted');
  }

  void goBack() {
    _selectedConversation.value = null;
    _messages.clear();
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}

extension ConversationModelExtension on ConversationModel {
  ConversationModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderType,
    String? senderImage,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? propertyAddress,
    String? propertyPrice,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      senderImage: senderImage ?? this.senderImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyPrice: propertyPrice ?? this.propertyPrice,
    );
  }
}
