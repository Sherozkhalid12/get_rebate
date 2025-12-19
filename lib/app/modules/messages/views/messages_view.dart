import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';

class MessagesView extends GetView<MessagesController> {
  const MessagesView({super.key});

  void _updateNavBarVisibility(bool hide) {
    if (Get.isRegistered<MainNavigationController>()) {
      try {
        final mainNavController = Get.find<MainNavigationController>();
        if (hide) {
          mainNavController.hideNavBar();
        } else {
          mainNavController.showNavBar();
        }
      } catch (e) {
        // Navbar controller might not be available
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to conversation changes and update navbar - outside of Obx
    ever(controller.selectedConversationRx, (conversation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateNavBarVisibility(conversation != null);
      });
    });

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: SafeArea(
        child: Obx(() {
          if (controller.selectedConversation != null) {
            return _buildChatView(context);
          } else {
            return _buildConversationsList(context);
          }
        }),
      ),
    );
  }

  Widget _buildConversationsList(BuildContext context) {
    return Column(
      children: [
        // Search
        _buildSearch(context),

        // Conversations List
        Expanded(child: _buildConversationsListView(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkGray),
          ),
          Expanded(
            child: Text(
              'Messages',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Get.snackbar('Info', 'New message feature coming soon!');
            },
            icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.white,
      child: CustomTextField(
        controller: TextEditingController(),
        labelText: 'Search conversations',
        prefixIcon: Icons.search,
        onChanged: controller.searchConversations,
      ),
    );
  }

  Widget _buildConversationsListView(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingThreads) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitFadingCircle(
                  color: AppTheme.primaryBlue,
                  size: 50.0,
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading conversations...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.error != null && controller.conversations.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading conversations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: controller.refreshThreads,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.conversations.isEmpty) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshThreads,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.conversations.length,
          itemBuilder: (context, index) {
            final conversation = controller.conversations[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildConversationCard(context, conversation),
            );
          },
        ),
      );
    });
  }

  Widget _buildConversationCard(
    BuildContext context,
    ConversationModel conversation,
  ) {
    return Card(
      child: InkWell(
        onTap: () => controller.selectConversation(conversation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(
                imageUrl: conversation.senderImage,
                senderType: conversation.senderType,
                radius: 25,
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.senderName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.black,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Text(
                          _formatTime(conversation.lastMessageTime),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mediumGray),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (conversation.propertyAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        conversation.propertyAddress!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Unread indicator
              if (conversation.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatView(BuildContext context) {
    return Column(
      children: [
        // Chat Header
        _buildChatHeader(context),

        // Messages - with scroll controller for auto-scroll
        Expanded(
          child: _buildMessagesList(context),
        ),

        // Message Input
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.goBack,
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkGray),
          ),
          _buildAvatar(
            imageUrl: controller.selectedConversation!.senderImage,
            senderType: controller.selectedConversation!.senderType,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.selectedConversation!.senderName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getSenderTypeLabel(
                    controller.selectedConversation!.senderType,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                controller.deleteConversation(
                  controller.selectedConversation!.id,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Conversation'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert, color: AppTheme.darkGray),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    return Obx(() {
      // Show loading indicator while fetching messages
      if (controller.isLoadingMessages) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitFadingCircle(
                  color: AppTheme.primaryBlue,
                  size: 50.0,
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading messages...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Show empty state if no messages
      if (controller.messages.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppTheme.mediumGray,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Show messages list - use reverse to show newest at bottom
      return ListView.builder(
        controller: controller.messagesScrollController,
        padding: const EdgeInsets.all(16),
        reverse: false, // Show oldest first
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final message = controller.messages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMessageBubble(context, message),
          );
        },
      );
    });
  }

  Widget _buildMessageBubble(BuildContext context, MessageModel message) {
    // Determine if message is from current user based on their role
    // For agents, messages from agent type are "from me"
    // For loan officers, messages from loan_officer type are "from me"
    // For buyers/sellers, messages from user type are "from me"
    final isUser = controller.isAgent
        ? message.senderType == 'agent'
        : (controller.isLoanOfficer 
            ? message.senderType == 'loan_officer'
            : message.senderType == 'user');

    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isUser) ...[
          _buildAvatar(
            imageUrl: message.senderImage,
            senderType: message.senderType,
            radius: 16,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primaryBlue : AppTheme.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isUser ? AppTheme.white : AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isUser
                        ? AppTheme.white.withOpacity(0.7)
                        : AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              color: AppTheme.primaryBlue,
              size: 16,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => controller.sendMessage(),
              onChanged: (_) {
                // Auto-scroll when typing (optional, but provides better UX)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (controller.messagesScrollController.hasClients) {
                    // Only scroll if user is near the bottom (within 200px)
                    final position = controller.messagesScrollController.position;
                    final maxScroll = position.maxScrollExtent;
                    final currentScroll = position.pixels;
                    
                    // If user is near bottom (within 200px), auto-scroll
                    if (maxScroll - currentScroll < 200) {
                      controller.messagesScrollController.animateTo(
                        maxScroll,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: controller.sendMessage,
            icon: const Icon(Icons.send, color: AppTheme.primaryBlue),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.message,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              controller.isLoanOfficer
                  ? 'You\'ll see messages from buyers and sellers here'
                  : 'Start a conversation with agents or loan officers',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/buyer'),
              icon: const Icon(Icons.search),
              label: const Text('Find Professionals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSenderColor(String senderType) {
    switch (senderType) {
      case 'agent':
        return AppTheme.primaryBlue;
      case 'loan_officer':
        return AppTheme.lightGreen;
      default:
        return AppTheme.mediumGray;
    }
  }

  IconData _getSenderIcon(String senderType) {
    switch (senderType) {
      case 'agent':
        return Icons.person;
      case 'loan_officer':
        return Icons.account_balance;
      default:
        return Icons.person;
    }
  }

  String _getSenderTypeLabel(String senderType) {
    switch (senderType) {
      case 'agent':
        return 'Real Estate Agent';
      case 'loan_officer':
        return 'Loan Officer';
      default:
        return 'Loan Officer';
    }
  }

  String _formatTime(DateTime time) {
    // Convert to local time for display
    final localTime = time.toLocal();
    final now = DateTime.now();
    final nowLocal = now.toLocal();
    
    // Calculate difference in local time
    final difference = nowLocal.difference(localTime);
    
    // Format time in 12-hour format with AM/PM
    String format12Hour(DateTime dt) {
      int hour = dt.hour;
      final minute = dt.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      
      if (hour == 0) {
        hour = 12; // 12 AM
      } else if (hour > 12) {
        hour = hour - 12; // 1 PM - 11 PM
      }
      
      // Format minute with leading zero if needed
      final minuteStr = minute.toString().padLeft(2, '0');
      
      return '$hour:$minuteStr $period';
    }
    
    // If time is in the future or less than 1 minute ago, show current time
    if (difference.isNegative || difference.inMinutes < 1) {
      return format12Hour(localTime);
    }
    
    // Same day - show time only
    if (localTime.year == nowLocal.year && 
        localTime.month == nowLocal.month && 
        localTime.day == nowLocal.day) {
      return format12Hour(localTime);
    }
    
    // Yesterday - show "Yesterday" and time
    final yesterday = nowLocal.subtract(const Duration(days: 1));
    if (localTime.year == yesterday.year && 
        localTime.month == yesterday.month && 
        localTime.day == yesterday.day) {
      return 'Yesterday ${format12Hour(localTime)}';
    }
    
    // Within same week - show day name and time
    if (difference.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = days[localTime.weekday - 1];
      return '$dayName ${format12Hour(localTime)}';
    }
    
    // More than a week - show date and time
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[localTime.month - 1];
    final day = localTime.day;
    
    // If same year, don't show year
    if (localTime.year == nowLocal.year) {
      return '$month $day, ${format12Hour(localTime)}';
    } else {
      return '$month $day, ${localTime.year} ${format12Hour(localTime)}';
    }
  }

  /// Builds an avatar widget with proper error handling for invalid URLs
  Widget _buildAvatar({
    required String? imageUrl,
    required String senderType,
    required double radius,
  }) {
    // Normalize and validate URL - trim whitespace, check for empty, and validate format
    String? normalizedUrl = imageUrl?.trim();
    if (normalizedUrl != null && normalizedUrl.isEmpty) {
      normalizedUrl = null;
    }
    
    // Validate URL - must be non-null, non-empty, and a valid HTTP/HTTPS URL
    final isValidUrl = normalizedUrl != null && 
        normalizedUrl.isNotEmpty && 
        (normalizedUrl.startsWith('http://') || normalizedUrl.startsWith('https://')) &&
        !normalizedUrl.contains('file://') &&
        Uri.tryParse(normalizedUrl) != null; // Additional URI validation

    // CircleAvatar assertion: if backgroundImage is null, onBackgroundImageError must also be null
    if (isValidUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _getSenderColor(senderType).withOpacity(0.1),
        backgroundImage: NetworkImage(
          normalizedUrl!,
          headers: {'ngrok-skip-browser-warning': 'true'},
        ),
        onBackgroundImageError: (exception, stackTrace) {
          // Silently handle image load errors - will show icon instead
        },
        child: null,
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _getSenderColor(senderType).withOpacity(0.1),
        backgroundImage: null, // Explicitly null
        // onBackgroundImageError must be null when backgroundImage is null
        child: Icon(
          _getSenderIcon(senderType),
          color: _getSenderColor(senderType),
          size: radius,
        ),
      );
    }
  }
}
