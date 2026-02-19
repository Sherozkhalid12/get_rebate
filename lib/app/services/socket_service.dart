import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'package:getrebate/app/utils/api_constants.dart';

class SocketService extends GetxService {
  IO.Socket? _socket;
  final _isConnected = false.obs;
  final _isConnecting = false.obs;

  bool get isConnected => _isConnected.value;
  bool get isConnecting => _isConnecting.value;
  IO.Socket? get socket => _socket;

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      print('🔌 SocketService initialized');
    }
  }

  /// Connects to the socket server
  Future<void> connect(String userId) async {
    // Check if already connected for the same user
    if (_socket?.connected == true && _currentUserId == userId) {
      if (kDebugMode) {
        print('✅ Socket already connected for user: $userId');
      }
      // Re-emit user_online in case server needs it
      try {
        _socket!.emit('user_online', userId);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error re-emitting user_online: $e');
        }
      }
      return;
    }

    // If connecting for different user, disconnect first
    if (_socket != null && _currentUserId != null && _currentUserId != userId) {
      if (kDebugMode) {
        print('🔄 Different user detected, disconnecting old socket...');
        print('   Old user: $_currentUserId');
        print('   New user: $userId');
      }
      try {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error disconnecting old socket: $e');
        }
      }
    }

    if (_isConnecting.value) {
      if (kDebugMode) {
        print('⏳ Socket connection already in progress');
      }
      return;
    }

    try {
      _isConnecting.value = true;
      
      if (kDebugMode) {
        print('🔌 Connecting to socket server: ${ApiConstants.socketUrl}');
        print('   User ID: $userId');
      }

      // Store userId for reconnection
      _currentUserId = userId;

      // Disconnect existing socket if any (safety check)
      if (_socket != null) {
        try {
          _socket!.disconnect();
          _socket!.dispose();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error disposing old socket: $e');
          }
        }
        _socket = null;
      }

      // Build socket URL - ensure it's correct
      final socketUrl = ApiConstants.socketUrl;
      if (kDebugMode) {
        print('   Socket URL: $socketUrl');
      }

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect() // We'll connect manually after setting up listeners
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .setTimeout(20000)
            .setExtraHeaders({
              if (ApiConstants.ngrokHeaders.containsKey('ngrok-skip-browser-warning'))
                'ngrok-skip-browser-warning': 'true',
            })
            .build(),
      );

      // Set up ALL event listeners BEFORE connecting
      _setupSocketListeners(userId);

      // Register message listeners if callbacks were set before socket creation
      if (_newMessageCallback != null) {
        onNewMessage(_newMessageCallback!);
      }
      if (_newThreadCallback != null) {
        onNewThread(_newThreadCallback!);
      }
      if (_unreadCountCallback != null) {
        onUnreadCountUpdated(_unreadCountCallback!);
      }
      if (_notificationCountCallback != null) {
        onNotificationCountUpdated(_notificationCountCallback!);
      }

      // Now connect
      if (kDebugMode) {
        print('🔌 Attempting to connect socket...');
      }
      _socket!.connect();
      
      // Wait a moment for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify connection
      if (!_socket!.connected && !_isConnecting.value) {
        if (kDebugMode) {
          print('⚠️ Socket connection may have failed, checking status...');
        }
        // Connection might still be in progress, wait a bit more
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
    } catch (e) {
      _isConnected.value = false;
      _isConnecting.value = false;
      if (kDebugMode) {
        print('❌ Failed to initialize socket: $e');
        print('   Stack trace: ${StackTrace.current}');
      }
      // Clear socket on error
      try {
        if (_socket != null) {
          _socket!.disconnect();
          _socket!.dispose();
          _socket = null;
        }
      } catch (disposeError) {
        if (kDebugMode) {
          print('⚠️ Error disposing socket after error: $disposeError');
        }
      }
    }
  }

  String? _currentUserId;

  /// Sets up all socket event listeners
  void _setupSocketListeners(String userId) {
    if (_socket == null) return;

    // Connection event
    _socket!.onConnect((_) {
      _isConnected.value = true;
      _isConnecting.value = false;
      if (kDebugMode) {
        print('✅ Socket connected successfully');
        print('   Socket ID: ${_socket!.id}');
        print('   Server URL: ${ApiConstants.socketUrl}');
        print('   User ID: $userId');
      }
      
      // Notify server that user is connected (matching HTML tester)
      try {
        _socket!.emit('user_online', userId);
        if (kDebugMode) {
          print('📤 Emitted user_online event');
          print('   Event: user_online');
          print('   Payload: $userId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error emitting user_online: $e');
        }
      }
      
      // Ensure listeners are registered after connection
      try {
        if (_newMessageCallback != null) {
          onNewMessage(_newMessageCallback!);
        }
        if (_newThreadCallback != null) {
          onNewThread(_newThreadCallback!);
        }
        if (_unreadCountCallback != null) {
          onUnreadCountUpdated(_unreadCountCallback!);
        }
        if (_notificationCountCallback != null) {
          onNotificationCountUpdated(_notificationCountCallback!);
        }
        if (kDebugMode) {
          print('✅ Verified listeners are registered after connection');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error verifying listeners after connection: $e');
        }
      }
    });

    // Disconnection event
    _socket!.onDisconnect((reason) {
      _isConnected.value = false;
      _isConnecting.value = false;
      if (kDebugMode) {
        print('❌ Socket disconnected');
        print('   Reason: $reason');
        print('   Socket ID: ${_socket?.id ?? "N/A"}');
      }
    });

    // Error event
    _socket!.onError((error) {
      _isConnected.value = false;
      _isConnecting.value = false;
      if (kDebugMode) {
        print('❌ Socket error occurred');
        print('   Error: $error');
        print('   Type: ${error.runtimeType}');
      }
    });

    // Connect error
    _socket!.onConnectError((error) {
      _isConnected.value = false;
      _isConnecting.value = false;
      if (kDebugMode) {
        print('❌ Socket connection error');
        print('   Error: $error');
        print('   Server URL: ${ApiConstants.socketUrl}');
        print('   User ID: $userId');
      }
    });

    // Reconnection events
    _socket!.onReconnect((attemptNumber) {
      _isConnected.value = true;
      _isConnecting.value = false;
      if (kDebugMode) {
        print('🔄 Socket reconnected');
        print('   Attempt number: $attemptNumber');
        print('   Socket ID: ${_socket!.id}');
      }
      if (_currentUserId != null) {
        _socket!.emit('user_online', _currentUserId!);
        if (kDebugMode) {
          print('📤 Re-emitted user_online after reconnect');
        }
      }
      
      // Re-register listeners after reconnect to ensure they're active
      try {
        if (_newMessageCallback != null) {
          onNewMessage(_newMessageCallback!);
          if (kDebugMode) {
            print('✅ Re-registered newMessage listener after reconnect');
          }
        }
        if (_newThreadCallback != null) {
          onNewThread(_newThreadCallback!);
          if (kDebugMode) {
            print('✅ Re-registered newThread listener after reconnect');
          }
        }
        if (_unreadCountCallback != null) {
          onUnreadCountUpdated(_unreadCountCallback!);
          if (kDebugMode) {
            print('✅ Re-registered unreadCountUpdated listener after reconnect');
          }
        }
        if (_notificationCountCallback != null) {
          onNotificationCountUpdated(_notificationCountCallback!);
          if (kDebugMode) {
            print('✅ Re-registered get_notification_count listener after reconnect');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error re-registering listeners after reconnect: $e');
        }
      }
    });

    _socket!.onReconnectAttempt((_) {
      if (kDebugMode) {
        print('🔄 Attempting to reconnect...');
      }
    });

    _socket!.onReconnectError((error) {
      if (kDebugMode) {
        print('❌ Reconnection error: $error');
      }
    });

    _socket!.onReconnectFailed((_) {
      _isConnected.value = false;
      _isConnecting.value = false;
      if (kDebugMode) {
        print('❌ Reconnection failed');
      }
    });
  }

  /// Joins a chat room (matching HTML tester: join_thread)
  void joinRoom(String chatId) {
    if (_socket?.connected == true) {
      _socket!.emit('join_thread', chatId);
      if (kDebugMode) {
        print('🚪 Joined thread: $chatId');
        print('   Event: join_thread');
        print('   Socket ID: ${_socket!.id}');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ Cannot join thread: Socket not connected');
        print('   Attempted thread: $chatId');
      }
    }
  }

  /// Leaves a chat room
  void leaveRoom(String chatId) {
    if (_socket?.connected == true) {
      _socket!.emit('leaveRoom', chatId);
      if (kDebugMode) {
        print('🚪 Left room: $chatId');
      }
    }
  }

  /// Sends a message via socket (matching HTML tester: send_message)
  void sendMessage({
    required String threadId,
    required String senderId,
    required String text,
    List<String>? participantIds,
  }) {
    if (_socket?.connected == true) {
      final normalizedThreadId = threadId.trim();
      final hasValidThreadId =
          normalizedThreadId.isNotEmpty && !normalizedThreadId.startsWith('temp_');

      final Map<String, dynamic> messageData = {
        'senderId': senderId,
        'text': text,
        // Per backend contract: send threadId only when it exists, else empty string.
        'threadId': hasValidThreadId ? normalizedThreadId : '',
      };

      if (!hasValidThreadId &&
          participantIds != null &&
          participantIds.length >= 2) {
        messageData['participantIds'] = participantIds;
      }

      _socket!.emit('send_message', messageData);
      if (kDebugMode) {
        print('📤 Sent message via socket');
        print('   Event: send_message');
        print('   ThreadId: ${messageData['threadId']}');
        if (messageData.containsKey('participantIds')) {
          print('   participantIds: ${messageData['participantIds']}');
        }
        print('   Sender: $senderId');
        print('   Text: $text');
        print('   Socket ID: ${_socket!.id}');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ Cannot send message: Socket not connected');
        print('   ThreadId: $threadId, Sender: $senderId');
      }
    }
  }

  /// Marks messages as read (matching HTML tester: mark_messages_read)
  void markAsRead({
    required String threadId,
    required String userId,
  }) {
    if (_socket?.connected == true) {
      _socket!.emit('mark_messages_read', {
        'threadId': threadId,
        'userId': userId,
      });
      if (kDebugMode) {
        print('✅ Marked messages as read');
        print('   Event: mark_messages_read');
        print('   ThreadId: $threadId');
        print('   UserId: $userId');
      }
    }
  }

  // Store callbacks to re-register on reconnect
  Function(Map<String, dynamic>)? _newMessageCallback;
  Function(Map<String, dynamic>)? _newThreadCallback;
  Function(Map<String, dynamic>)? _unreadCountCallback;
  Function(Map<String, dynamic>)? _notificationCountCallback;

  /// Listens for new messages
  void onNewMessage(Function(Map<String, dynamic>) callback) {
    _newMessageCallback = callback;
    
    if (_socket == null) {
      if (kDebugMode) {
        print('⚠️ Cannot register newMessage listener: Socket is null');
        print('   Will register when socket is created');
      }
      // Store callback to register later when socket is created
      return;
    }
    
    // Remove existing listener first to avoid duplicates
    _socket!.off('new_message');
    
    _socket!.on('new_message', (data) {
      if (kDebugMode) {
        print('📨 Received new message via socket');
        print('   Data: $data');
        print('   Data type: ${data.runtimeType}');
        print('   Socket ID: ${_socket?.id}');
        print('   Socket connected: ${_socket?.connected}');
      }
      
      // Handle different data formats
      Map<String, dynamic> messageData;
      if (data is Map<String, dynamic>) {
        messageData = data;
      } else if (data is Map) {
        messageData = Map<String, dynamic>.from(data);
      } else {
        if (kDebugMode) {
          print('⚠️ Invalid message format: $data (type: ${data.runtimeType})');
        }
        return;
      }
      
      try {
        callback(messageData);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error in newMessage callback: $e');
          print('   Stack trace: ${StackTrace.current}');
        }
      }
    });
    
    if (kDebugMode) {
      print('✅ Registered newMessage listener');
      print('   Socket exists: ${_socket != null}');
      print('   Socket connected: ${_socket?.connected ?? false}');
    }
  }

  /// Listens for new threads
  void onNewThread(Function(Map<String, dynamic>) callback) {
    _newThreadCallback = callback;
    
    if (_socket == null) {
      if (kDebugMode) {
        print('⚠️ Cannot register newThread listener: Socket is null');
      }
      return;
    }
    
    void handleThreadEvent(String eventName, dynamic data) {
      if (kDebugMode) {
        print('💬 Received thread event via socket');
        print('   Event: $eventName');
        print('   Data: $data');
        print('   Data type: ${data.runtimeType}');
        print('   Socket ID: ${_socket?.id}');
        print('   Socket connected: ${_socket?.connected}');
      }
      
      Map<String, dynamic> threadData;
      if (data is Map<String, dynamic>) {
        threadData = data;
      } else if (data is Map) {
        threadData = Map<String, dynamic>.from(data);
      } else {
        if (kDebugMode) {
          print('⚠️ Invalid thread format: $data (type: ${data.runtimeType})');
        }
        return;
      }
      
      try {
        callback(threadData);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error in newThread callback: $e');
          print('   Stack trace: ${StackTrace.current}');
        }
      }
    }

    // Remove existing listeners first to avoid duplicates
    _socket!.off('newThread');
    _socket!.off('thread_created');
    _socket!.off('thread_updated');

    _socket!.on('newThread', (data) => handleThreadEvent('newThread', data));
    _socket!.on(
      'thread_created',
      (data) => handleThreadEvent('thread_created', data),
    );
    _socket!.on(
      'thread_updated',
      (data) => handleThreadEvent('thread_updated', data),
    );
    
    if (kDebugMode) {
      print('✅ Registered newThread/thread_created/thread_updated listeners');
      print('   Socket exists: ${_socket != null}');
      print('   Socket connected: ${_socket?.connected ?? false}');
    }
  }

  /// Emits create_thread to create a thread via socket.
  void createThread({
    required List<String> participantIds,
    required String initiatorId,
  }) {
    if (_socket?.connected == true) {
      final payload = {
        'participantIds': participantIds,
        'initiatorId': initiatorId,
      };
      _socket!.emit('create_thread', payload);
      if (kDebugMode) {
        print('📤 Emitted create_thread');
        print('   Payload: $payload');
      }
      return;
    }

    if (kDebugMode) {
      print('⚠️ Cannot emit create_thread: socket not connected');
      print('   participantIds: $participantIds');
      print('   initiatorId: $initiatorId');
    }
  }

  /// Listens for unread count updates
  void onUnreadCountUpdated(Function(Map<String, dynamic>) callback) {
    _unreadCountCallback = callback;
    
    if (_socket == null) {
      if (kDebugMode) {
        print('⚠️ Cannot register unreadCountUpdated listener: Socket is null');
      }
      return;
    }
    
    // Remove existing listener first to avoid duplicates
    _socket!.off('unreadCountUpdated');
    
    _socket!.on('unreadCountUpdated', (data) {
      if (kDebugMode) {
        print('🔔 Unread count updated via socket');
        print('   Data: $data');
        print('   Data type: ${data.runtimeType}');
        print('   Socket ID: ${_socket?.id}');
        print('   Socket connected: ${_socket?.connected}');
      }
      
      Map<String, dynamic> unreadData;
      if (data is Map<String, dynamic>) {
        unreadData = data;
      } else if (data is Map) {
        unreadData = Map<String, dynamic>.from(data);
      } else {
        if (kDebugMode) {
          print('⚠️ Invalid unread count format: $data (type: ${data.runtimeType})');
        }
        return;
      }
      
      try {
        callback(unreadData);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error in unreadCountUpdated callback: $e');
          print('   Stack trace: ${StackTrace.current}');
        }
      }
    });
    
    if (kDebugMode) {
      print('✅ Registered unreadCountUpdated listener');
      print('   Socket exists: ${_socket != null}');
      print('   Socket connected: ${_socket?.connected ?? false}');
    }
  }

  /// Listens for notification count updates (server event: get_notification_count)
  void onNotificationCountUpdated(Function(Map<String, dynamic>) callback) {
    _notificationCountCallback = callback;

    if (_socket == null) {
      if (kDebugMode) {
        print('⚠️ Cannot register get_notification_count listener: Socket is null');
      }
      return;
    }

    _socket!.off('get_notification_count');

    _socket!.on('get_notification_count', (data) {
      if (kDebugMode) {
        print('🔔 Notification count updated via socket');
        print('   Event: get_notification_count');
        print('   Data: $data');
      }

      Map<String, dynamic> payload;
      if (data is Map<String, dynamic>) {
        payload = data;
      } else if (data is Map) {
        payload = Map<String, dynamic>.from(data);
      } else {
        if (kDebugMode) {
          print('⚠️ Invalid get_notification_count payload format: ${data.runtimeType}');
        }
        return;
      }

      try {
        callback(payload);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error in get_notification_count callback: $e');
        }
      }
    });

    if (kDebugMode) {
      print('✅ Registered get_notification_count listener');
      print('   Socket exists: ${_socket != null}');
      print('   Socket connected: ${_socket?.connected ?? false}');
    }
  }

  /// Removes a listener
  void off(String event) {
    _socket?.off(event);
  }

  /// Disconnects from the socket server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected.value = false;
      _isConnecting.value = false;
      _currentUserId = null; // Clear user ID
      // Clear callbacks to prevent stale callbacks
      _newMessageCallback = null;
      _newThreadCallback = null;
      _unreadCountCallback = null;
      _notificationCountCallback = null;
      if (kDebugMode) {
        print('🔌 Socket disconnected and disposed');
      }
    }
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
