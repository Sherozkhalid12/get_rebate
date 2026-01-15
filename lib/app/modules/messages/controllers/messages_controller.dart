import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/services/chat_service.dart';
import 'package:getrebate/app/services/user_service.dart';
import 'package:getrebate/app/services/socket_service.dart';
import 'package:getrebate/app/services/agent_service.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/utils/network_error_handler.dart';

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
  final AuthController _authController = Get.find<AuthController>();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  // Data
  final _conversations = <ConversationModel>[].obs;
  final _allConversations = <ConversationModel>[].obs; // Store all conversations for filtering
  final _messages = <MessageModel>[].obs;
  final _selectedConversation = Rxn<ConversationModel>();
  final _isLoading = false.obs;
  final _isLoadingThreads = false.obs;
  final _isLoadingMessages = false.obs;
  final _searchQuery = ''.obs;
  final _error = Rxn<String>();

  // Message input
  final messageController = TextEditingController();
  
  // Track previous message count for auto-scroll
  int _previousMessageCount = 0;

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<ConversationModel> get allConversations => _allConversations;
  List<MessageModel> get messages => _messages;
  ConversationModel? get selectedConversation => _selectedConversation.value;
  Rxn<ConversationModel> get selectedConversationRx => _selectedConversation;
  bool get isLoading => _isLoading.value;
  bool get isLoadingThreads => _isLoadingThreads.value;
  bool get isLoadingMessages => _isLoadingMessages.value;
  String get searchQuery => _searchQuery.value;
  String? get error => _error.value;
  
  // Check if current user is a loan officer
  bool get isLoanOfficer {
    final user = _authController.currentUser;
    return user?.role == UserRole.loanOfficer;
  }
  
  // Check if current user is an agent
  bool get isAgent {
    final user = _authController.currentUser;
    return user?.role == UserRole.agent;
  }

  SocketService? _socketService;

  bool _hasInitialized = false;
  
  // Scroll controller for messages list
  final ScrollController _messagesScrollController = ScrollController();
  ScrollController get messagesScrollController => _messagesScrollController;
  
  /// Scrolls to the bottom of the messages list
  void _scrollToBottom({bool immediate = false}) {
    // Use multiple attempts to ensure scroll happens after ListView rebuilds
    void attemptScroll(int attempt) {
      if (attempt > 5) {
        if (kDebugMode) {
          print('⚠️ Failed to scroll after 5 attempts');
        }
        return;
      }

      if (!_messagesScrollController.hasClients) {
        // If scroll controller not ready, try again after a delay
        Future.delayed(Duration(milliseconds: 50 * (attempt + 1)), () {
          attemptScroll(attempt + 1);
        });
        return;
      }

      // Use post frame callback to ensure ListView is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add another small delay to ensure ListView has updated
        Future.delayed(Duration(milliseconds: immediate ? 10 : 50), () {
          if (_messagesScrollController.hasClients) {
            try {
              final position = _messagesScrollController.position;
              final maxExtent = position.maxScrollExtent;
              
              if (maxExtent > 0) {
                if (immediate) {
                  // Jump immediately without animation for instant feedback
                  _messagesScrollController.jumpTo(maxExtent);
                  if (kDebugMode) {
                    print('✅ Scrolled to bottom immediately (maxExtent: $maxExtent, attempt: $attempt)');
                  }
                } else {
                  // Animate smoothly
                  _messagesScrollController.animateTo(
                    maxExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                  if (kDebugMode) {
                    print('✅ Scrolled to bottom with animation (maxExtent: $maxExtent, attempt: $attempt)');
                  }
                }
              } else {
                // If maxExtent is 0, the list might not be rendered yet, try again
                if (attempt < 5) {
                  Future.delayed(Duration(milliseconds: 100 * (attempt + 1)), () {
                    attemptScroll(attempt + 1);
                  });
                } else {
                  if (kDebugMode) {
                    print('⚠️ Cannot scroll - maxExtent is 0 after $attempt attempts');
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error scrolling to bottom: $e');
              }
              // Try again if error occurs
              if (attempt < 5) {
                Future.delayed(Duration(milliseconds: 100 * (attempt + 1)), () {
                  attemptScroll(attempt + 1);
                });
              }
            }
          } else {
            // Scroll controller lost clients, try again
            if (attempt < 5) {
              Future.delayed(Duration(milliseconds: 100 * (attempt + 1)), () {
                attemptScroll(attempt + 1);
              });
            }
          }
        });
      });
    }

    attemptScroll(0);
  }

  @override
  void onInit() {
    super.onInit();
    
    if (kDebugMode) {
      print('📱 MessagesController: onInit called (initialized: $_hasInitialized)');
    }
    
    _loadArguments();
    
    // Listen to messages list changes and auto-scroll when new messages are added
    ever(_messages, (_) {
      // Only auto-scroll if there's a selected conversation and message count increased
      if (_selectedConversation.value != null && 
          _messages.isNotEmpty && 
          _messages.length > _previousMessageCount) {
        _previousMessageCount = _messages.length;
        // Delay to ensure ListView has rebuilt
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 150), () {
            _scrollToBottom(immediate: true);
          });
        });
      } else if (_messages.length != _previousMessageCount) {
        // Update count even if not scrolling (e.g., when loading initial messages)
        _previousMessageCount = _messages.length;
      }
    });
    
    // Always initialize socket if user is logged in (socket can reconnect)
    if (_authController.isLoggedIn && _authController.currentUser != null) {
      if (!_hasInitialized) {
        _hasInitialized = true;
        if (kDebugMode) {
          print('📱 MessagesController: First initialization - loading threads and socket');
        }
        // Load threads immediately in background - don't wait
        // This ensures threads are ready when user opens messages screen
        if (!_isLoadingThreads.value) {
          // Use microtask to load in background without blocking initialization
          Future.microtask(() => loadThreads());
        }
        // Initialize socket in parallel
        _initializeSocket();
      } else {
        // Already initialized - ensure socket is still connected
        if (kDebugMode) {
          print('📱 MessagesController: Re-initialization - checking socket connection');
        }
        
        // Check if socket is connected, reconnect if needed
        if (_socketService != null && !_socketService!.isConnected) {
          if (kDebugMode) {
            print('⚠️ Socket not connected, reinitializing...');
          }
          _initializeSocket();
        }
        
        // Use silent refresh to update data without showing loading spinner
        _refreshThreadsSilently();
        
        // If a conversation is already selected, refresh messages to catch any missed ones
        if (_selectedConversation.value != null) {
          final conversationId = _selectedConversation.value!.id;
          // Only refresh if it's not a temporary conversation
          if (!conversationId.startsWith('temp_') && !conversationId.startsWith('conv_')) {
            if (kDebugMode) {
              print('🔄 Refreshing messages for selected conversation: $conversationId');
            }
            // Refresh messages silently (don't show loading spinner)
            Future.microtask(() => _loadMessagesForConversation(conversationId));
          }
        }
      }
    } else {
      if (kDebugMode) {
        print('📱 MessagesController: User not logged in - skipping initialization');
      }
    }
  }

  /// Initializes socket connection
  void _initializeSocket() async {
    final user = _authController.currentUser;
    if (user == null || user.id.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Cannot initialize socket: User not logged in');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔌 Initializing socket connection...');
        print('   User ID: ${user.id}');
        print('   Socket URL: ${ApiConstants.socketUrl}');
      }

      // Get or create socket service
      if (!Get.isRegistered<SocketService>()) {
        Get.put(SocketService(), permanent: true);
        if (kDebugMode) {
          print('✅ Created new SocketService instance');
        }
      }
      _socketService = Get.find<SocketService>();

      // Register listeners FIRST (before connecting)
      // This ensures we don't miss any events
      if (kDebugMode) {
        print('📡 Registering socket event listeners BEFORE connecting...');
      }

      // Listen for new messages - register BEFORE connecting
      _socketService!.onNewMessage((data) {
        if (kDebugMode) {
          print('📨 onNewMessage callback triggered');
          print('   Current selected conversation: ${_selectedConversation.value?.id}');
        }
        _handleNewMessage(data);
      });

      // Listen for new threads
      _socketService!.onNewThread((data) {
        if (kDebugMode) {
          print('💬 onNewThread callback triggered');
        }
        _handleNewThread(data);
      });

      // Listen for unread count updates
      _socketService!.onUnreadCountUpdated((data) {
        if (kDebugMode) {
          print('🔔 onUnreadCountUpdated callback triggered');
        }
        _handleUnreadCountUpdate(data);
      });

      if (kDebugMode) {
        print('✅ All socket listeners registered');
      }

      // NOW connect to socket (listeners are already set up)
      // The connect() method will create the socket and register the listeners
      await _socketService!.connect(user.id);

      // Wait a bit to ensure connection is established
      await Future.delayed(const Duration(milliseconds: 1000));

      if (kDebugMode) {
        print('✅ Socket initialization complete');
        print('   Connected: ${_socketService!.isConnected}');
        print('   Socket ID: ${_socketService!.socket?.id ?? "N/A"}');
        
        // Verify listeners are registered
        if (_socketService!.socket != null) {
          print('   Socket exists: true');
          print('   Socket connected: ${_socketService!.socket!.connected}');
          
          // Verify socket is actually connected
          final isSocketConnected = _socketService!.socket?.connected ?? false;
          if (!isSocketConnected) {
            print('⚠️ WARNING: Socket not connected!');
            print('   Will retry connection...');
            // Retry connection after a delay
            Future.delayed(const Duration(seconds: 2), () {
              final currentUser = _authController.currentUser;
              if (currentUser != null && !(_socketService!.socket?.connected ?? false)) {
                if (kDebugMode) {
                  print('🔄 Retrying socket connection...');
                }
                _socketService!.connect(currentUser.id);
              }
            });
          } else {
            // Join all existing conversation rooms after connection
            if (_allConversations.isNotEmpty) {
              for (final conversation in _allConversations) {
                _socketService!.joinRoom(conversation.id);
              }
              if (kDebugMode) {
                print('🚪 Joined ${_allConversations.length} existing conversation rooms');
              }
            }
          }
        } else {
          print('   Socket exists: false');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing socket: $e');
        print('   Stack trace: ${StackTrace.current}');
      }
    }
  }

  /// Handles incoming new message from socket (matching HTML tester: new_message)
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print('📨 ========================================');
        print('📨 Handling new message from socket');
        print('   Raw data: $data');
        print('   Socket connected: ${_socketService?.isConnected ?? false}');
        print('   Current conversations count: ${_allConversations.length}');
      }

      // Parse chatId/threadId - can be from different fields
      final chatId = data['chatId']?.toString() ?? 
                     data['threadId']?.toString() ?? 
                     data['_id']?.toString() ?? '';
      
      // Parse sender - can be object or ID string
      final sender = data['sender'] is Map 
          ? data['sender'] as Map<String, dynamic>
          : null;
      final senderId = sender?['_id']?.toString() ?? 
                      sender?['id']?.toString() ?? 
                      data['sender']?.toString() ?? 
                      data['senderId']?.toString() ?? '';
      
      // Extract and clean message text - handle JSON escaping
      String text = data['text']?.toString() ?? 
                   data['message']?.toString() ?? '';
      
      // Clean the text - remove any unwanted escaping
      // Replace escaped quotes and backslashes that might come from JSON
      text = text.replaceAll('\\"', '"')
                 .replaceAll('\\n', '\n')
                 .replaceAll('\\t', '\t')
                 .replaceAll('\\\\', '\\')
                 .trim();
      
      // Parse timestamp
      DateTime createdAt;
      if (data['createdAt'] != null) {
        final dateStr = data['createdAt'].toString();
        final parsed = DateTime.tryParse(dateStr);
        createdAt = parsed != null 
            ? (parsed.isUtc ? parsed : parsed.toUtc())
            : DateTime.now().toUtc();
      } else {
        createdAt = DateTime.now().toUtc();
      }

      if (kDebugMode) {
        print('   Parsed - ChatId: $chatId, SenderId: $senderId, Text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      }

      // Always update the conversation list with new message, even if not viewing that conversation
      // This ensures agents see new messages instantly even when on dashboard
      final user = _authController.currentUser;
      final isFromMe = senderId == (user?.id ?? '');
      
      // Find the conversation in our list and update it
      final conversationIndex = _allConversations.indexWhere((c) => c.id == chatId);
      if (conversationIndex != -1) {
        // Update existing conversation with new last message
        final existingConversation = _allConversations[conversationIndex];
        final updatedConversation = existingConversation.copyWith(
          lastMessage: text,
          lastMessageTime: createdAt,
          unreadCount: isFromMe ? existingConversation.unreadCount : existingConversation.unreadCount + 1,
        );
        _allConversations[conversationIndex] = updatedConversation;
        _allConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        // Also update in filtered conversations list
        final filteredIndex = _conversations.indexWhere((c) => c.id == chatId);
        if (filteredIndex != -1) {
          _conversations[filteredIndex] = updatedConversation;
          _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        }
        
        if (kDebugMode) {
          print('✅ Updated conversation list with new message');
          print('   Conversation: ${updatedConversation.senderName}');
          print('   Last message: $text');
        }
      } else {
        // New conversation - create it immediately from socket data so it appears instantly
        if (kDebugMode) {
          print('📬 New conversation detected, creating from socket data...');
          print('   ChatId: $chatId');
          print('   SenderId: $senderId');
        }
        
        // Get sender information from socket data
        String senderName = sender?['fullname']?.toString() ?? 
                           sender?['name']?.toString() ?? 
                           'User';
        
        String senderType = 'user';
        final role = sender?['role']?.toString()?.toLowerCase() ?? '';
        if (role == 'agent') {
          senderType = 'agent';
        } else if (role == 'loanofficer' || role == 'loan_officer') {
          senderType = 'loan_officer';
        }
        
        // Build profile pic URL
        String? senderImage = sender?['profilePic']?.toString()?.trim();
        if (senderImage != null && senderImage.isNotEmpty && !senderImage.contains('file://')) {
          senderImage = senderImage.replaceAll('\\', '/');
          if (!senderImage.startsWith('http://') && !senderImage.startsWith('https://')) {
            if (senderImage.startsWith('/')) {
              senderImage = senderImage.substring(1);
            }
            final baseUrl = ApiConstants.baseUrl.endsWith('/') 
                ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
                : ApiConstants.baseUrl;
            senderImage = '$baseUrl/$senderImage';
          }
          // Validate URI
          try {
            final uri = Uri.parse(senderImage);
            if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
              senderImage = null;
            }
          } catch (e) {
            senderImage = null;
          }
        } else {
          senderImage = null;
        }
        
        // Create new conversation immediately
        final newConversation = ConversationModel(
          id: chatId,
          senderId: senderId,
          senderName: senderName,
          senderType: senderType,
          senderImage: senderImage,
          lastMessage: text,
          lastMessageTime: createdAt,
          unreadCount: isFromMe ? 0 : 1,
        );
        
        // Add to both lists
        _allConversations.insert(0, newConversation);
        _allConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        _conversations.insert(0, newConversation);
        _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        // Join the room for this new conversation so we receive future messages
        if (_socketService != null && _socketService!.isConnected) {
          _socketService!.joinRoom(chatId);
          if (kDebugMode) {
            print('🚪 Joined room for new conversation: $chatId');
          }
        }
        
        if (kDebugMode) {
          print('✅ Created new conversation from socket message');
          print('   Conversation: $senderName');
          print('   ChatId: $chatId');
        }
        
        // Also refresh threads in background to get full conversation data
        _refreshThreadsSilently();
      }

      // If this message is for the currently selected conversation, also add it to messages list
      // Check both exact match and if chatId is contained in conversation id (for flexibility)
      final currentConversationId = _selectedConversation.value?.id ?? '';
      final isCurrentConversation = currentConversationId == chatId || 
                                     currentConversationId.contains(chatId) ||
                                     chatId.contains(currentConversationId);
      
      if (kDebugMode) {
        print('   Checking if message belongs to current conversation:');
        print('   Current conversation ID: $currentConversationId');
        print('   Message chatId: $chatId');
        print('   Match: $isCurrentConversation');
      }
      
      if (isCurrentConversation) {
        // user and isFromMe are already declared above
        
        // Get message ID from socket data
        final messageId = data['_id']?.toString() ?? 
                         data['id']?.toString() ?? 
                         'msg_${DateTime.now().millisecondsSinceEpoch}';

        // Check if message already exists (to prevent duplicates)
        final existingMessage = _messages.firstWhereOrNull((m) => m.id == messageId);
        if (existingMessage != null) {
          if (kDebugMode) {
            print('⚠️ Message already exists, skipping duplicate');
            print('   Message ID: $messageId');
          }
          return; // Don't add duplicate
        }

        // Get sender name from socket data or conversation
        String senderName;
        if (isFromMe) {
          senderName = 'You';
        } else {
          senderName = sender?['fullname']?.toString() ?? 
                      sender?['name']?.toString() ?? 
                      _selectedConversation.value?.senderName ?? 
                      'User';
        }

        // Get sender type
        String senderType;
        if (isFromMe) {
          // Determine sender type based on current user's role
          if (user?.role == UserRole.agent) {
            senderType = 'agent';
          } else if (user?.role == UserRole.loanOfficer) {
            senderType = 'loan_officer';
          } else {
            senderType = 'user';
          }
        } else {
          final role = sender?['role']?.toString()?.toLowerCase() ?? '';
          if (role == 'agent') {
            senderType = 'agent';
          } else if (role == 'loanofficer' || role == 'loan_officer') {
            senderType = 'loan_officer';
          } else {
            senderType = _selectedConversation.value?.senderType ?? 'user';
          }
        }

        // Check if message is read
        final isReadBy = data['isReadBy'] as List<dynamic>? ?? [];
        final isRead = isFromMe || isReadBy.contains(user?.id) || 
                      isReadBy.any((id) => id.toString() == user?.id);

        final message = MessageModel(
          id: messageId,
          senderId: senderId,
          senderName: senderName,
          senderType: senderType,
          senderImage: isFromMe ? null : _selectedConversation.value?.senderImage,
          message: text.trim(), // Use cleaned and trimmed text
          timestamp: createdAt,
          isRead: isRead,
        );

        // Use assign to trigger reactive update
        final updatedMessages = List<MessageModel>.from(_messages);
        updatedMessages.add(message);
        _messages.value = updatedMessages;
        
        // Remove any temporary optimistic messages with the same text and sender
        // This handles the case where we added an optimistic message before getting the real one
        if (isFromMe) {
          final cleanedMessages = List<MessageModel>.from(_messages);
          cleanedMessages.removeWhere((m) => 
            m.id.startsWith('temp_') && 
            m.message == text && 
            m.senderId == senderId &&
            m.id != messageId
          );
          _messages.value = cleanedMessages;
        }
        
        // Auto-scroll to bottom when new message arrives
        // Use immediate scroll for socket messages to show them instantly
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(immediate: true);
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToBottom(immediate: true);
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            _scrollToBottom(immediate: false);
          });
        });
        
        if (kDebugMode) {
          print('✅ Added message to current conversation');
          print('   Message ID: ${message.id}');
          print('   From: $senderName ($senderType)');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ Message received for different thread: $chatId');
          print('   Current thread: ${_selectedConversation.value?.id ?? "none"}');
        }
      }

      // Note: Conversation list is already updated above (before the if statement)
      // This ensures messages are visible even when agent is on dashboard
      
      if (kDebugMode) {
        print('✅ Message handling complete');
        print('   Updated conversations count: ${_allConversations.length}');
        print('📨 ========================================');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling new message: $e');
        print('   Stack trace: ${StackTrace.current}');
        print('📨 ========================================');
      }
    }
  }

  /// Handles new thread from socket
  void _handleNewThread(Map<String, dynamic> data) {
    try {
      // Refresh threads to get the new one
      refreshThreads();
    } catch (e) {
      print('❌ Error handling new thread: $e');
    }
  }

  /// Handles unread count update from socket
  void _handleUnreadCountUpdate(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId']?.toString() ?? '';
      final unreadCount = int.tryParse(data['unreadCount']?.toString() ?? '0') ?? 0;

      // Update in both lists
      final conversation = _allConversations.firstWhereOrNull((c) => c.id == chatId);
      if (conversation != null) {
        final updatedConversation = conversation.copyWith(unreadCount: unreadCount);
        
        // Update in all conversations
        final allIndex = _allConversations.indexWhere((c) => c.id == chatId);
        if (allIndex != -1) {
          _allConversations[allIndex] = updatedConversation;
          _allConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        }


        ;
        // Update in filtered conversations
        final filteredIndex = _conversations.indexWhere((c) => c.id == chatId);
        if (filteredIndex != -1) {
          _conversations[filteredIndex] = updatedConversation;
          _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        }
      }
    } catch (e) {
      print('❌ Error handling unread count update: $e');
    }
  }

  void _loadArguments() {
    // Just load arguments but don't auto-open conversations
    // This allows navigation to messages screen to show threads list
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['agent'] != null) {
      // Create a new conversation with the agent using temp ID
      // This will be replaced with real thread ID once thread is created
      final agent = args['agent'] as Map<String, dynamic>;
      final listing = args['listing'] as Map<String, dynamic>?;
      final propertyAddress = args['propertyAddress'] as String?;

      // Use temp_ prefix so we know it's temporary and won't try to load messages
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final newConversation = ConversationModel(
        id: tempId,
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

      // Add to both lists if not already exists
      if (!_allConversations.any((conv) => conv.senderId == agent['id'])) {
        _allConversations.insert(0, newConversation);
        _conversations.insert(0, newConversation);
      }

      // Select this conversation (will skip message loading since it's temp)
      selectConversation(newConversation);
      
      // Create thread in background
      final user = _authController.currentUser;
      if (user != null) {
        _createThreadInBackground(
          userId1: user.id,
          userId2: agent['id'] as String,
          tempConversation: newConversation,
          otherUserName: agent['name'] as String,
          profilePicUrl: agent['profileImage'] as String?,
          otherUserRole: 'agent',
        );
      }
    }
    // Don't auto-select conversations - let user choose from threads list
  }

  /// Loads chat threads from the API - optimized and fast
  Future<void> loadThreads() async {
    // Prevent multiple simultaneous loads
    if (_isLoadingThreads.value) {
      print('⚠️ Threads already loading, skipping duplicate call');
      return;
    }

    final user = _authController.currentUser;
    if (user == null || user.id.isEmpty) {
      _error.value = 'Please log in to view messages';
      _isLoadingThreads.value = false; // Reset loading state
      return;
    }

    _isLoadingThreads.value = true;
    _error.value = null;

    try {
      // Fetch threads from API
      final threads = await _chatService.getChatThreads(user.id);
      
      // Convert threads to conversations - FAST, no individual API calls
      final conversations = threads
          .map((thread) {
            try {
              // Get the other participant
              final otherParticipant = thread.getOtherParticipant(user.id);
              if (otherParticipant == null) return null;

              // Use profile pic URL directly from API - don't prepend base URL
              // Normalize: trim whitespace and convert empty strings to null
              String? profilePicUrl = otherParticipant.profilePic?.trim();
              if (profilePicUrl != null && profilePicUrl.isNotEmpty && !profilePicUrl.contains('file://')) {
                // Normalize path separators (handle Windows backslashes)
                profilePicUrl = profilePicUrl.replaceAll('\\', '/');
                // Use the path directly from API - no base URL prepending
                // The API should return full URLs or paths that work directly
              } else {
                // Set to null if empty or invalid to avoid 404 errors
                profilePicUrl = null;
              }

              // Map role from API to sender type - use role directly from API response
              String senderType = 'user';
              final role = otherParticipant.role?.toLowerCase() ?? '';
              if (role == 'agent') {
                senderType = 'agent';
              } else if (role == 'loanofficer' || role == 'loan_officer') {
                senderType = 'loan_officer';
              }
              
              // Get unread count for current user
              final unreadCount = thread.getUnreadCountForUser(user.id);

              // Determine the best timestamp to use for last message time
              // Priority: lastMessage.createdAt > updatedAt > createdAt > now
              DateTime lastMessageTime;
              if (thread.lastMessage?.createdAt != null) {
                lastMessageTime = thread.lastMessage!.createdAt!;
              } else if (thread.updatedAt != null) {
                lastMessageTime = thread.updatedAt!;
              } else if (thread.createdAt != null) {
                lastMessageTime = thread.createdAt!;
              } else {
                // Fallback to now only if all are null
                lastMessageTime = DateTime.now().toUtc();
                if (kDebugMode) {
                  print('⚠️ Thread ${thread.id}: All timestamps are null, using now()');
                }
              }

              // Ensure we're working with UTC times
              if (!lastMessageTime.isUtc) {
                lastMessageTime = lastMessageTime.toUtc();
              }

              // Debug logging to verify time parsing
              if (kDebugMode) {
                final nowUtc = DateTime.now().toUtc();
                final diff = nowUtc.difference(lastMessageTime);
                print('⏰ Thread ${thread.id.substring(0, 8)}...:');
                print('   lastMessage.createdAt: ${thread.lastMessage?.createdAt}');
                print('   updatedAt: ${thread.updatedAt}');
                print('   createdAt: ${thread.createdAt}');
                print('   Using: $lastMessageTime (UTC)');
                print('   Now: $nowUtc (UTC)');
                print('   Difference: ${diff.inMinutes}m ${diff.inSeconds % 60}s');
              }

              // Create conversation model
              return ConversationModel(
                id: thread.id,
                senderId: otherParticipant.id,
                senderName: otherParticipant.fullname,
                senderType: senderType, // Will be updated from API response
                senderImage: profilePicUrl,
                lastMessage: thread.lastMessage?.text ?? '',
                lastMessageTime: lastMessageTime,
                unreadCount: unreadCount,
              );
            } catch (e) {
              print('❌ Error processing thread: $e');
              return null;
            }
          })
          .whereType<ConversationModel>()
          .toList();

      // Sort by last message time (most recent first)
      conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      // Join all conversation rooms so we receive messages for all conversations
      // This ensures we get real-time messages even when not viewing a specific conversation
      if (_socketService != null && _socketService!.isConnected) {
        for (final conversation in conversations) {
          _socketService!.joinRoom(conversation.id);
        }
        if (kDebugMode) {
          print('🚪 Joined ${conversations.length} conversation rooms for real-time messages');
        }
      }

      // Merge with existing conversations to preserve any newly created threads
      // that haven't appeared in the API response yet
      final existingConversations = _conversations.toList();
      final mergedConversations = <ConversationModel>[];
      
      // Add all conversations from API
      mergedConversations.addAll(conversations);
      
      // Preserve conversations that:
      // 1. Are temp conversations (starting with 'temp_') that don't have a match in API
      // 2. Are real conversations (not temp) that don't appear in API yet (newly created)
      for (final existing in existingConversations) {
        // Check if this conversation exists in the API response
        final existsInApi = conversations.any((c) => 
          c.id == existing.id || 
          (c.senderId == existing.senderId && !existing.id.startsWith('temp_'))
        );
        
        if (!existsInApi) {
          // Keep this conversation if it's not in the API response
          mergedConversations.add(existing);
          if (kDebugMode) {
            print('📌 Preserving conversation not in API: ${existing.id} (${existing.senderName})');
          }
        }
      }
      
      // Sort again after merging
      mergedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      
      // Update both lists - all conversations and filtered conversations
      _allConversations.value = mergedConversations;
      
      // Apply current search filter if any
      if (_searchQuery.value.trim().isNotEmpty) {
        searchConversations(_searchQuery.value);
      } else {
        _conversations.value = mergedConversations;
      }
      
      if (kDebugMode) {
        print('✅ Loaded ${conversations.length} conversations');
      }
    } on ChatServiceException catch (e) {
      _error.value = NetworkErrorHandler.getUserFriendlyMessage(
        e,
        defaultMessage: 'Unable to load conversations. Please check your internet connection and try again.',
      );
      if (kDebugMode) {
        print('❌ Error loading threads: ${e.message}');
      }
    } catch (e) {
      _error.value = NetworkErrorHandler.getUserFriendlyMessage(
        e,
        defaultMessage: 'Unable to load conversations. Please check your internet connection and try again.',
      );
      if (kDebugMode) {
        print('❌ Unexpected error loading threads: $e');
      }
    } finally {
      _isLoadingThreads.value = false;
      if (kDebugMode) {
        print('✅ Loading state reset to false');
      }
    }
  }

  void selectConversation(ConversationModel conversation) {
    _selectedConversation.value = conversation;
    
    if (kDebugMode) {
      print('📱 Selected conversation: ${conversation.senderName}');
      print('   Conversation ID: ${conversation.id}');
    }
    
    // Check if this is a temporary conversation (not yet created on server)
    // If it's temporary, don't try to load messages - just show empty state
    // Messages will be loaded once the thread is created and conversation is updated with real ID
    // Also check for old format 'conv_' IDs which are also temporary
    if (conversation.id.startsWith('temp_') || conversation.id.startsWith('conv_')) {
      if (kDebugMode) {
        print('⚠️ Temporary conversation detected - skipping message load');
        print('   Will load messages once thread is created');
      }
      // Clear messages and set loading to false for empty state
      _messages.clear();
      _isLoadingMessages.value = false;
      // Don't join room or mark as read for temp conversations
      return;
    }
    
    // Join socket room FIRST for real-time updates (before loading messages)
    // This ensures we receive messages via socket even while loading
    if (_socketService != null) {
      if (_socketService!.isConnected) {
        _socketService!.joinRoom(conversation.id);
        if (kDebugMode) {
          print('🚪 Joined socket room: ${conversation.id}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Socket not connected, attempting to reconnect...');
        }
        // Try to reconnect socket
        final currentUser = _authController.currentUser;
        if (currentUser != null) {
          _socketService!.connect(currentUser.id).then((_) {
            if (_socketService!.isConnected) {
              _socketService!.joinRoom(conversation.id);
              if (kDebugMode) {
                print('🚪 Joined socket room after reconnect: ${conversation.id}');
              }
            }
          });
        }
      }
    }
    
    // Load messages for this conversation
    _loadMessagesForConversation(conversation.id);
    
    // Mark as read
    markAsRead(conversation.id);
  }

  /// Loads messages for a specific conversation from the API
  Future<void> _loadMessagesForConversation(String conversationId) async {
    final user = _authController.currentUser;
    if (user == null || user.id.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Cannot load messages: User not logged in');
      }
      _messages.clear();
      return;
    }

    // Set loading state
    _isLoadingMessages.value = true;
    _messages.clear();
    _previousMessageCount = 0; // Reset message count when loading new conversation
    
    // Reset scroll position before loading (in case user had scrolled up in previous chat)
    if (_messagesScrollController.hasClients) {
      try {
        _messagesScrollController.jumpTo(0);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not reset scroll position: $e');
        }
      }
    }

    try {
      if (kDebugMode) {
        print('📡 Loading messages for conversation: $conversationId');
        print('   User ID: ${user.id}');
      }

      // Fetch messages from API
      final messagesData = await _chatService.getThreadMessages(
        threadId: conversationId,
        userId: user.id,
      );

      if (kDebugMode) {
        print('✅ Received ${messagesData.length} messages from API');
      }

      // Convert API response to MessageModel
      final messages = messagesData.map((json) {
        try {
          // Parse sender information
          final sender = json['sender'] is Map
              ? json['sender'] as Map<String, dynamic>
              : null;
          
          final senderId = sender?['_id']?.toString() ?? 
                          sender?['id']?.toString() ?? 
                          json['sender']?.toString() ?? '';
          
          final senderName = sender?['fullname']?.toString() ?? 
                            sender?['name']?.toString() ?? 
                            'User';
          
          final senderRole = sender?['role']?.toString()?.toLowerCase() ?? 'user';
          String senderType = 'user';
          if (senderRole == 'agent') {
            senderType = 'agent';
          } else if (senderRole == 'loanofficer' || senderRole == 'loan_officer') {
            senderType = 'loan_officer';
          }

          // Build profile pic URL
          String? senderImage = sender?['profilePic']?.toString()?.trim();
          if (senderImage != null && senderImage.isNotEmpty && !senderImage.contains('file://')) {
            senderImage = senderImage.replaceAll('\\', '/');
            if (!senderImage.startsWith('http://') && !senderImage.startsWith('https://')) {
              if (senderImage.startsWith('/')) {
                senderImage = senderImage.substring(1);
              }
              final baseUrl = ApiConstants.baseUrl.endsWith('/') 
                  ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
                  : ApiConstants.baseUrl;
              senderImage = '$baseUrl/$senderImage';
            }
            // Validate URI
            try {
              final uri = Uri.parse(senderImage);
              if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
                senderImage = null;
              }
            } catch (e) {
              senderImage = null;
            }
          } else {
            senderImage = null;
          }

          // Parse timestamp
          DateTime timestamp;
          if (json['createdAt'] != null) {
            final dateStr = json['createdAt'].toString();
            final parsed = DateTime.tryParse(dateStr);
            if (parsed != null) {
              timestamp = parsed.isUtc ? parsed : parsed.toUtc();
            } else {
              timestamp = DateTime.now().toUtc();
            }
          } else if (json['timestamp'] != null) {
            final dateStr = json['timestamp'].toString();
            final parsed = DateTime.tryParse(dateStr);
            if (parsed != null) {
              timestamp = parsed.isUtc ? parsed : parsed.toUtc();
            } else {
              timestamp = DateTime.now().toUtc();
            }
          } else {
            timestamp = DateTime.now().toUtc();
          }

          // Check if message is read
          final isReadBy = json['isReadBy'] as List<dynamic>? ?? [];
          final isRead = isReadBy.contains(user.id) || 
                        isReadBy.any((id) => id.toString() == user.id);

          // Determine if message is from current user
          final isFromMe = senderId == user.id;

          // Extract and clean message text
          String messageText = json['text']?.toString() ?? 
                              json['message']?.toString() ?? 
                              '';
          
          // Clean the text - remove any unwanted escaping
          messageText = messageText.replaceAll('\\"', '"')
                                  .replaceAll('\\n', '\n')
                                  .replaceAll('\\t', '\t')
                                  .replaceAll('\\\\', '\\')
                                  .trim();
          
          return MessageModel(
            id: json['_id']?.toString() ?? 
                json['id']?.toString() ?? 
                'msg_${DateTime.now().millisecondsSinceEpoch}',
            senderId: senderId,
            senderName: isFromMe ? 'You' : senderName,
            senderType: senderType,
            senderImage: isFromMe ? null : senderImage,
            message: messageText,
            timestamp: timestamp,
            isRead: isRead,
          );
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing message: $e');
            print('   Message data: $json');
          }
          return null;
        }
      }).whereType<MessageModel>().toList();

      // Sort messages by timestamp (oldest first)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Update messages list
      _messages.value = messages;
      
      // Update message count after loading
      _previousMessageCount = _messages.length;

      // Auto-scroll to bottom after loading messages
      // Use post frame callback to ensure ListView is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _scrollToBottom(immediate: true);
        });
      });
      
      // Also try again after a delay to handle cases where list takes time to render
      Future.delayed(const Duration(milliseconds: 400), () {
        _scrollToBottom(immediate: false);
      });

      if (kDebugMode) {
        print('✅ Loaded ${messages.length} messages for conversation: $conversationId');
        if (messages.isEmpty) {
          print('⚠️ No messages found in this conversation');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading messages: $e');
        print('   Stack trace: ${StackTrace.current}');
      }
      // Clear messages on error
      _messages.clear();
      
      // Check if this is a temporary conversation or a conversation that doesn't exist yet
      // If so, don't show error - just show empty state (user hasn't sent any messages yet)
      final isTempConversation = conversationId.startsWith('temp_') || conversationId.startsWith('conv_');
      if (!isTempConversation) {
        // Only show error for real conversations that fail to load
        // This could be a network error or the conversation was deleted
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('not found') || 
            errorMessage.contains('404') ||
            errorMessage.contains('thread not found')) {
          // Conversation doesn't exist - this is normal for new chats, don't show error
          if (kDebugMode) {
            print('ℹ️ Conversation not found - likely a new chat with no messages yet');
          }
        } else {
          // Real error - show to user
          Get.snackbar(
            'Error',
            'Unable to load chat. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade400,
            colorText: Colors.white,
          );
        }
      }
    } finally {
      _isLoadingMessages.value = false;
      if (kDebugMode) {
        print('✅ Message loading state reset');
      }
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    if (_selectedConversation.value == null) return;

    final user = _authController.currentUser;
    if (user == null) return;

    final text = messageController.text.trim();
    final conversation = _selectedConversation.value!;
    final receiverId = conversation.senderId;
    final now = DateTime.now().toUtc();

    // Create optimistic message with unique ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Determine sender type based on user role
    String senderType = 'user';
    if (user.role == UserRole.agent) {
      senderType = 'agent';
    } else if (user.role == UserRole.loanOfficer) {
      senderType = 'loan_officer';
    }
    
    final message = MessageModel(
      id: tempId,
      senderId: user.id,
      senderName: 'You',
      senderType: senderType,
      message: text,
      timestamp: now,
      isRead: true,
    );

    // Add optimistic message
    _messages.add(message);
    messageController.clear();
    
    // Force scroll to bottom immediately and multiple times to ensure it works
    // This ensures the ListView scrolls down when a new message is added
    _scrollToBottom(immediate: true);
    
    // Also try after a short delay to handle ListView rebuild
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom(immediate: true);
    });
    
    // And once more after ListView fully renders
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollToBottom(immediate: false);
    });
    
    if (kDebugMode) {
      print('📝 Added optimistic message: $tempId');
    }

    // Immediately update conversation's last message and move to top
    // Update in both lists to keep search results in sync
    final updatedConversation = conversation.copyWith(
      lastMessage: text,
      lastMessageTime: now,
    );
    
    // Update in all conversations list
    final allIndex = _allConversations.indexWhere((c) => c.id == conversation.id);
    if (allIndex != -1) {
      _allConversations[allIndex] = updatedConversation;
      _allConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    }
    
    // Update in filtered conversations list
    final filteredIndex = _conversations.indexWhere((c) => c.id == conversation.id);
    if (filteredIndex != -1) {
      _conversations[filteredIndex] = updatedConversation;
      _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    }
    
    if (kDebugMode) {
      print('✅ Moved conversation to top of list instantly');
    }

    // Try to send via socket first, fallback to API if socket not connected
    bool messageSent = false;
    
    // Check and attempt to reconnect socket if disconnected
    if (_socketService != null && !_socketService!.isConnected) {
      if (kDebugMode) {
        print('🔄 Socket not connected, attempting to reconnect...');
      }
      // Try to reconnect in background (don't wait)
      _socketService!.connect(user.id).catchError((e) {
        if (kDebugMode) {
          print('⚠️ Socket reconnection failed: $e');
        }
      });
    }
    
    // Try socket first if connected
    if (_socketService != null && _socketService!.isConnected) {
      try {
      _socketService!.sendMessage(
        threadId: conversation.id,
        senderId: user.id,
        text: text,
      );
        messageSent = true;
      if (kDebugMode) {
          print('✅ Message sent via socket');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to send via socket: $e');
        }
      }
    }
    
    // Use API as fallback to ensure message is sent
    // This ensures messages are sent even if socket fails
    if (!messageSent) {
      if (kDebugMode) {
        print('📤 Socket not available, sending message via API');
      }
      
      try {
        // Send via API
        final response = await _chatService.sendMessage(
          threadId: conversation.id,
          senderId: user.id,
          text: text,
        );
        
        if (kDebugMode) {
          print('✅ Message sent via API successfully');
          print('   Response: $response');
        }
        
        // If API response includes the message, handle it like a socket message
        // This ensures the message appears in the UI even if socket didn't receive it
        if (response.containsKey('message') || response.containsKey('_id')) {
          // Replace optimistic message with real message from API
          final messageId = response['_id']?.toString() ?? 
                           response['id']?.toString() ?? 
                           tempId;
          
          // Update the optimistic message with real ID
          final messageIndex = _messages.indexWhere((m) => m.id == tempId);
          if (messageIndex != -1) {
            final realMessage = MessageModel(
              id: messageId,
              senderId: user.id,
              senderName: 'You',
              senderType: senderType,
              message: text,
              timestamp: response['createdAt'] != null
                  ? DateTime.parse(response['createdAt'])
                  : now,
              isRead: true,
            );
            _messages[messageIndex] = realMessage;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to send message via API: $e');
        }
        
        // Only show error if socket also failed
        if (!messageSent) {
          Get.snackbar(
            'Error',
            'Failed to send message. Please check your connection and try again.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
          
          // Remove optimistic message on failure
          _messages.removeWhere((m) => m.id == tempId);
        }
      }
    }
  }

  void searchConversations(String query) {
    _searchQuery.value = query;
    
    if (query.trim().isEmpty) {
      // If search is empty, show all conversations
      _conversations.value = List.from(_allConversations);
      return;
    }
    
    // Filter conversations by sender name or last message
    final lowerQuery = query.toLowerCase().trim();
    final filtered = _allConversations.where((conv) {
      final nameMatch = conv.senderName.toLowerCase().contains(lowerQuery);
      final messageMatch = conv.lastMessage.toLowerCase().contains(lowerQuery);
      return nameMatch || messageMatch;
    }).toList();
    
    _conversations.value = filtered;
    
    if (kDebugMode) {
      print('🔍 Search: "$query" found ${filtered.length} results');
    }
  }

  Future<void> markAsRead(String conversationId) async {
    final user = _authController.currentUser;
    if (user == null || user.id.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Cannot mark as read: User not logged in');
      }
      return;
    }

    // Immediately update UI for instant feedback
    final conversation = _allConversations.firstWhereOrNull(
      (conv) => conv.id == conversationId,
    );
    if (conversation != null && conversation.unreadCount > 0) {
      final updatedConv = conversation.copyWith(unreadCount: 0);
      
      // Update in all conversations
      final allIndex = _allConversations.indexWhere((conv) => conv.id == conversationId);
      if (allIndex != -1) {
        _allConversations[allIndex] = updatedConv;
      }
      
      // Update in filtered conversations
      final filteredIndex = _conversations.indexWhere((conv) => conv.id == conversationId);
      if (filteredIndex != -1) {
        _conversations[filteredIndex] = updatedConv;
      }
    }

    // Mark as read via API in background
    try {
      final result = await _chatService.markThreadAsRead(
        threadId: conversationId,
        userId: user.id,
      );
      
      if (kDebugMode) {
        print('✅ Thread marked as read via API');
        print('   Updated count: ${result['updatedCount']}');
        print('   Unread count: ${result['unreadCount']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to mark thread as read via API: $e');
      }
      // Don't show error to user - unread count already updated in UI
    }

    // Also mark as read via socket if connected
    if (_socketService != null && _socketService!.isConnected) {
      _socketService!.markAsRead(
        threadId: conversationId,
        userId: user.id,
      );
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      if (kDebugMode) {
        print('🗑️ Deleting chat: $conversationId');
      }

      // Call API to delete the chat
      await _chatService.deleteChat(chatId: conversationId);

      // Remove from both lists after successful API call
      _allConversations.removeWhere((conv) => conv.id == conversationId);
      _conversations.removeWhere((conv) => conv.id == conversationId);
      
      if (_selectedConversation.value?.id == conversationId) {
        _selectedConversation.value = null;
        _messages.clear();
        
        // Show navbar again when conversation is deleted
        if (Get.isRegistered<MainNavigationController>()) {
          try {
            final mainNavController = Get.find<MainNavigationController>();
            mainNavController.showNavBar();
          } catch (e) {
            // Navbar controller might not be available
          }
        }
      }
      
      SnackbarHelper.showSuccess('Conversation deleted', title: 'Deleted');
    } on ChatServiceException catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting chat: ${e.message}');
      }
      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to delete conversation. Please check your internet connection and try again.',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error deleting chat: $e');
      }
      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to delete conversation. Please check your internet connection and try again.',
      );
    }
  }

  void goBack() {
    // Clear conversation state - this will automatically show conversations list
    // Don't use Navigator.pop() because MessagesView is part of main navigation
    _selectedConversation.value = null;
    _messages.clear();
    
    // Show navbar again
    if (Get.isRegistered<MainNavigationController>()) {
      try {
        final mainNavController = Get.find<MainNavigationController>();
        mainNavController.showNavBar();
      } catch (e) {
        // Navbar controller might not be available
      }
    }
    
    // Always refresh threads silently when going back to ensure list is up-to-date
    // This ensures threads are sorted correctly with latest messages at top
    if (kDebugMode) {
      print('🔄 Going back: Clearing conversation and showing conversations list');
    }
    _refreshThreadsSilently();
  }

  /// Refreshes chat threads from the API - can be called from anywhere
  Future<void> refreshThreads() async {
    // Only load if not already loading
    if (!_isLoadingThreads.value) {
      await loadThreads();
    }
  }

  /// Refreshes threads silently without showing loading indicator
  /// Used when going back from chat to ensure threads are sorted correctly
  Future<void> _refreshThreadsSilently() async {
    final user = _authController.currentUser;
    if (user == null || user.id.isEmpty) {
      return;
    }

    // Prevent multiple simultaneous silent refreshes
    if (_isLoadingThreads.value) {
      return;
    }

    // Don't set loading state - this is a silent refresh
    if (kDebugMode) {
      print('🔄 Silently refreshing threads...');
    }

    try {
      // Fetch threads from API
      final threads = await _chatService.getChatThreads(user.id);
      
      // Convert threads to conversations - FAST, no individual API calls
      final conversations = threads
          .map((thread) {
            try {
              // Get the other participant
              final otherParticipant = thread.getOtherParticipant(user.id);
              if (otherParticipant == null) return null;

              // Build profile pic URL from API data (no extra fetch needed)
              String? profilePicUrl = otherParticipant.profilePic?.trim();
              // Use profile pic URL directly from API - don't prepend base URL
              if (profilePicUrl != null && profilePicUrl.isNotEmpty && !profilePicUrl.contains('file://')) {
                profilePicUrl = profilePicUrl.replaceAll('\\', '/');
                // Use the path directly from API - no base URL prepending
              } else {
                profilePicUrl = null;
              }

              // Map role from API to sender type
              String senderType = 'user';
              final role = otherParticipant.role?.toLowerCase() ?? '';
              if (role == 'agent') {
                senderType = 'agent';
              } else if (role == 'loanofficer' || role == 'loan_officer') {
                senderType = 'loan_officer';
              }
              
              // Get unread count for current user
              final unreadCount = thread.getUnreadCountForUser(user.id);

              // Determine the best timestamp to use
              DateTime lastMessageTime;
              if (thread.lastMessage?.createdAt != null) {
                lastMessageTime = thread.lastMessage!.createdAt!;
              } else if (thread.updatedAt != null) {
                lastMessageTime = thread.updatedAt!;
              } else if (thread.createdAt != null) {
                lastMessageTime = thread.createdAt!;
              } else {
                lastMessageTime = DateTime.now().toUtc();
              }

              if (!lastMessageTime.isUtc) {
                lastMessageTime = lastMessageTime.toUtc();
              }

              return ConversationModel(
                id: thread.id,
                senderId: otherParticipant.id,
                senderName: otherParticipant.fullname,
                senderType: senderType,
                senderImage: profilePicUrl,
                lastMessage: thread.lastMessage?.text ?? '',
                lastMessageTime: lastMessageTime,
                unreadCount: unreadCount,
              );
            } catch (e) {
              if (kDebugMode) {
                print('❌ Error processing thread: $e');
              }
              return null;
            }
          })
          .whereType<ConversationModel>()
          .toList();

      // Sort by last message time (most recent first)
      conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      // Join all conversation rooms so we receive messages for all conversations
      // This ensures we get real-time messages even when not viewing a specific conversation
      if (_socketService != null && _socketService!.isConnected) {
        for (final conversation in conversations) {
          _socketService!.joinRoom(conversation.id);
        }
        if (kDebugMode) {
          print('🚪 Joined ${conversations.length} conversation rooms (silent refresh)');
        }
      }

      // Update both lists
      _allConversations.value = conversations;
      
      // Apply current search filter if any
      if (_searchQuery.value.trim().isNotEmpty) {
        searchConversations(_searchQuery.value);
      } else {
        _conversations.value = conversations;
      }
      
      if (kDebugMode) {
        print('✅ Silently refreshed ${conversations.length} conversations');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error silently refreshing threads: $e');
      }
      // Don't show error to user - this is a silent background refresh
    }
  }

  /// Starts a chat with another user - creates thread if it doesn't exist
  /// Navigates instantly and creates thread in background
  Future<ConversationModel?> startChatWithUser({
    required String otherUserId,
    required String otherUserName,
    String? otherUserProfilePic,
    String otherUserRole = 'user',
    bool navigateToMessages = true, // Control whether to navigate
  }) async {
    final user = _authController.currentUser;
    if (user == null || user.id.isEmpty) {
      SnackbarHelper.showError('Please login to start a chat');
      return null;
    }

    if (otherUserId.isEmpty) {
      SnackbarHelper.showError('Invalid user ID');
      return null;
    }

    // Record contact if chatting with an agent
    if (otherUserRole == 'agent' && otherUserId.isNotEmpty) {
      try {
        if (Get.isRegistered<AgentService>()) {
          final agentService = Get.find<AgentService>();
          agentService.recordContact(otherUserId);
        } else {
          final agentService = AgentService();
          agentService.recordContact(otherUserId);
        }
        if (kDebugMode) {
          print('📞 Recording contact for agent: $otherUserId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error recording contact: $e');
        }
        // Don't block chat if contact recording fails
      }
    }

    // Build profile pic URL - set to null if empty or invalid to avoid 404 errors
    // Normalize: trim whitespace and convert empty strings to null
    String? profilePicUrl = otherUserProfilePic?.trim();
    // Use profile pic URL directly from API - don't prepend base URL
    if (profilePicUrl != null && profilePicUrl.isNotEmpty && !profilePicUrl.contains('file://')) {
      profilePicUrl = profilePicUrl.replaceAll('\\', '/');
      // Use the path directly from API - no base URL prepending
    } else {
      // Set to null if empty or invalid to avoid 404 errors
      profilePicUrl = null;
    }

    // Check if thread already exists
    final existingThread = _allConversations.firstWhereOrNull(
      (conv) => conv.senderId == otherUserId,
    );

    if (existingThread != null) {
      // Thread exists, select it and navigate if requested
      selectConversation(existingThread);
      if (navigateToMessages) {
        _navigateToMessages();
      } else {
        // Just navigate to messages screen without replacing stack
        Get.toNamed('/messages');
      }
      return existingThread;
    }

    // Create temporary conversation for instant navigation
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempConversation = ConversationModel(
      id: tempId,
      senderId: otherUserId,
      senderName: otherUserName,
      senderType: otherUserRole,
      senderImage: profilePicUrl,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
    );

    // Add to both lists immediately
    _allConversations.insert(0, tempConversation);
    _conversations.insert(0, tempConversation);
    selectConversation(tempConversation);
    
    // Navigate based on parameter
    if (navigateToMessages) {
      _navigateToMessages();
    } else {
      // Just navigate to messages screen without replacing stack
      Get.toNamed('/messages');
    }

    // Create thread in background
    _createThreadInBackground(
      userId1: user.id,
      userId2: otherUserId,
      tempConversation: tempConversation,
      otherUserName: otherUserName,
      profilePicUrl: profilePicUrl,
      otherUserRole: otherUserRole,
    );

    return tempConversation;
  }

  /// Creates thread in background and updates conversation
  void _createThreadInBackground({
    required String userId1,
    required String userId2,
    required ConversationModel tempConversation,
    required String otherUserName,
    String? profilePicUrl,
    required String otherUserRole,
  }) async {
    try {
      print('📡 Creating thread in background...');
      
      final threadData = await _chatService.createThread(
        userId1: userId1,
        userId2: userId2,
      );

      final threadId = threadData['_id']?.toString() ?? 
                      threadData['id']?.toString() ?? 
                      threadData['threadId']?.toString() ?? 
                      '';

      if (threadId.isEmpty) {
        throw Exception('Thread ID not found in API response');
      }

      print('✅ Thread created successfully: $threadId');

      // Update conversation with real ID
      final updatedConversation = ConversationModel(
        id: threadId,
        senderId: tempConversation.senderId,
        senderName: tempConversation.senderName,
        senderType: tempConversation.senderType,
        senderImage: tempConversation.senderImage,
        lastMessage: tempConversation.lastMessage,
        lastMessageTime: tempConversation.lastMessageTime,
        unreadCount: tempConversation.unreadCount,
      );

      // Replace temp conversation with real one in both lists
      final allIndex = _allConversations.indexWhere((c) => c.id == tempConversation.id);
      if (allIndex != -1) {
        _allConversations[allIndex] = updatedConversation;
      } else {
        _allConversations.insert(0, updatedConversation);
      }
      
      final filteredIndex = _conversations.indexWhere((c) => c.id == tempConversation.id);
      if (filteredIndex != -1) {
        _conversations[filteredIndex] = updatedConversation;
        if (kDebugMode) {
          print('✅ Updated temp conversation with real thread ID');
          print('   Old ID: ${tempConversation.id}');
          print('   New ID: $threadId');
        }
      } else {
        // If temp conversation not found, add the new one at the top
        _conversations.insert(0, updatedConversation);
        if (kDebugMode) {
          print('✅ Added new conversation to list (temp not found)');
        }
      }

      // Update selected conversation if it's the temp one
      if (_selectedConversation.value?.id == tempConversation.id) {
        _selectedConversation.value = updatedConversation;
        if (kDebugMode) {
          print('✅ Updated selected conversation with real thread ID');
        }
        // Now that we have the real thread ID, load messages and join room
        _loadMessagesForConversation(updatedConversation.id);
        if (_socketService != null && _socketService!.isConnected) {
          _socketService!.joinRoom(updatedConversation.id);
        }
        markAsRead(updatedConversation.id);
      }

      // Don't refresh threads immediately - the new thread is already in the list
      // Refresh after a delay to sync with server (gives API time to index the new thread)
      Future.delayed(const Duration(seconds: 2), () {
        refreshThreads().catchError((e) {
          if (kDebugMode) {
            print('⚠️ Error refreshing threads after thread creation: $e');
          }
        });
      });
      
      if (kDebugMode) {
        print('✅ Thread creation complete - conversation list updated instantly');
        print('   Thread ID: $threadId');
        print('   Will refresh threads in 2 seconds to sync with server');
      }
    } catch (e) {
      print('❌ Error creating thread in background: $e');
      // Remove temp conversation on error from both lists
      _allConversations.removeWhere((c) => c.id == tempConversation.id);
      _conversations.removeWhere((c) => c.id == tempConversation.id);
      if (_selectedConversation.value?.id == tempConversation.id) {
        _selectedConversation.value = null;
      }
      NetworkErrorHandler.handleError(
        e,
        defaultMessage: 'Unable to start conversation. Please check your internet connection and try again.',
      );
    }
  }

  /// Navigates to messages screen
  void _navigateToMessages() {
    try {
      // Navigate to main screen and switch to messages tab (index 2)
      // Use offAllNamed to replace the entire navigation stack (removes contact screen)
      Get.offAllNamed('/main');
      
      // Wait a frame to ensure navigation completes before changing tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<MainNavigationController>()) {
          try {
            final mainNavController = Get.find<MainNavigationController>();
            mainNavController.changeIndex(2); // Messages tab is at index 2 (0=Home, 1=Favorites, 2=Messages, 3=Profile)
          } catch (e) {
            print('⚠️ Error changing tab index: $e');
          }
        }
      });
    } catch (e) {
      print('⚠️ Error navigating to messages: $e');
      // Fallback: just navigate to messages route if available
      Get.offAllNamed('/messages');
    }
  }

  @override
  void onClose() {
    // Leave socket room if in conversation
    if (_selectedConversation.value != null && _socketService != null) {
      _socketService!.leaveRoom(_selectedConversation.value!.id);
    }
    
    // Dispose scroll controller
    _messagesScrollController.dispose();
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
