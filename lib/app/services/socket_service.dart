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
    if (_socket?.connected == true) {
      if (kDebugMode) {
        print('✅ Socket already connected');
      }
      // Re-emit userConnected in case server needs it
      _socket!.emit('userConnected', userId);
      return;
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

      // Disconnect existing socket if any
      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
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

      // Now connect
      if (kDebugMode) {
        print('🔌 Attempting to connect socket...');
      }
      _socket!.connect();
      
      // Wait a moment for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      _isConnected.value = false;
      _isConnecting.value = false;
      if (kDebugMode) {
        print('❌ Failed to initialize socket: $e');
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
      _socket!.emit('user_online', userId);
      if (kDebugMode) {
        print('📤 Emitted user_online event');
        print('   Event: user_online');
        print('   Payload: $userId');
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
      
      // Re-register listeners after reconnect
      if (_newMessageCallback != null) {
        onNewMessage(_newMessageCallback!);
      }
      if (_newThreadCallback != null) {
        onNewThread(_newThreadCallback!);
      }
      if (_unreadCountCallback != null) {
        onUnreadCountUpdated(_unreadCountCallback!);
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
  }) {
    if (_socket?.connected == true) {
      final messageData = {
        'threadId': threadId,
        'senderId': senderId,
        'text': text,
      };
      _socket!.emit('send_message', messageData);
      if (kDebugMode) {
        print('📤 Sent message via socket');
        print('   Event: send_message');
        print('   ThreadId: $threadId');
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
    
    // Remove existing listener first to avoid duplicates
    _socket!.off('newThread');
    
    _socket!.on('newThread', (data) {
      if (kDebugMode) {
        print('💬 Received new thread via socket');
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
    });
    
    if (kDebugMode) {
      print('✅ Registered newThread listener');
      print('   Socket exists: ${_socket != null}');
      print('   Socket connected: ${_socket?.connected ?? false}');
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

