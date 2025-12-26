import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      // Hide navbar when conversation is selected, show when null
      _updateNavBarVisibility(conversation != null);
      // Also ensure it's applied after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateNavBarVisibility(conversation != null);
      });
    });

    // Set initial navbar state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedConversation != null) {
        _updateNavBarVisibility(true); // Hide navbar when in chat
      } else {
        _updateNavBarVisibility(false); // Show navbar when on conversations list
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      // Ensure no bottom navigation bar is shown in chat
      bottomNavigationBar: null,
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
    return Obx(() {
      // Check if navbar is visible - use Obx to reactively update
      final isNavBarVisible = Get.isRegistered<MainNavigationController>()
          ? Get.find<MainNavigationController>().isNavBarVisible
          : true;
      
      return Column(
        children: [
          // Header with back button - only show when navbar is NOT visible (hidden)
          if (!isNavBarVisible) _buildHeader(context),
          
          // Search
          _buildSearch(context),

          // Conversations List
          Expanded(child: _buildConversationsListView(context)),
        ],
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.primaryGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppTheme.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Obx(() {
                      final count = controller.conversations.length;
                      return Text(
                        count == 0 
                          ? 'No conversations'
                          : '$count ${count == 1 ? 'conversation' : 'conversations'}',
                        style: TextStyle(
                          color: AppTheme.white.withOpacity(0.9),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Get.snackbar('Info', 'New message feature coming soon!');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: AppTheme.white,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildSearch(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          onChanged: controller.searchConversations,
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(
              color: AppTheme.mediumGray,
              fontSize: 14.sp,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.mediumGray,
              size: 22.sp,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: -0.1, end: 0);
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
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off,
                    size: 50,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Unable to Load Conversations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  controller.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumGray,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: controller.refreshThreads,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
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

      if (controller.conversations.isEmpty) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshThreads,
        color: AppTheme.primaryBlue,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: controller.conversations.length,
          itemBuilder: (context, index) {
            final conversation = controller.conversations[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildConversationCard(context, conversation, index),
            );
          },
        ),
      );
    });
  }

  Widget _buildConversationCard(
    BuildContext context,
    ConversationModel conversation,
    int index,
  ) {
    final hasUnread = conversation.unreadCount > 0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.selectConversation(conversation),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(20),
            border: hasUnread
                ? Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: hasUnread
                    ? AppTheme.primaryBlue.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: hasUnread ? 12 : 8,
                offset: const Offset(0, 2),
                spreadRadius: hasUnread ? 1 : 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with status indicator
              Stack(
                children: [
                  _buildAvatar(
                    imageUrl: conversation.senderImage,
                    senderType: conversation.senderType,
                    radius: 28,
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16.w),
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
                            style: TextStyle(
                              color: hasUnread ? AppTheme.black : AppTheme.darkGray,
                              fontSize: 16.sp,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(conversation.lastMessageTime),
                          style: TextStyle(
                            color: hasUnread
                                ? AppTheme.primaryBlue
                                : AppTheme.mediumGray,
                            fontSize: 12.sp,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      conversation.lastMessage,
                      style: TextStyle(
                        color: hasUnread
                            ? AppTheme.darkGray
                            : AppTheme.mediumGray,
                        fontSize: 14.sp,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (conversation.propertyAddress != null) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14.sp,
                            color: AppTheme.mediumGray,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              conversation.propertyAddress!,
                              style: TextStyle(
                                color: AppTheme.mediumGray,
                                fontSize: 12.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Unread indicator
              if (hasUnread) ...[
                SizedBox(width: 12.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: conversation.unreadCount > 9 ? 8.w : 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    conversation.unreadCount > 99 ? '99+' : conversation.unreadCount.toString(),
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: (index * 50).ms,
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: 400.ms,
          delay: (index * 50).ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 300.ms,
          delay: (index * 50).ms,
          curve: Curves.easeOut,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.primaryGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.goBack(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppTheme.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              _buildAvatar(
                imageUrl: controller.selectedConversation!.senderImage,
                senderType: controller.selectedConversation!.senderType,
                radius: 22,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.selectedConversation!.senderName,
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _getSenderTypeLabel(
                        controller.selectedConversation!.senderType,
                      ),
                      style: TextStyle(
                        color: AppTheme.white.withOpacity(0.9),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      controller.deleteConversation(
                        controller.selectedConversation!.id,
                      );
                    }
                  },
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: AppTheme.white,
                      size: 20.sp,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20.sp),
                          SizedBox(width: 12.w),
                          Text(
                            'Delete Conversation',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        reverse: false, // Show oldest first
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final message = controller.messages[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildMessageBubble(context, message, index),
          );
        },
      );
    });
  }

  Widget _buildMessageBubble(BuildContext context, MessageModel message, int index) {
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          _buildAvatar(
            imageUrl: message.senderImage,
            senderType: message.senderType,
            radius: 18,
          ),
          SizedBox(width: 8.w),
        ],
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: isUser
                  ? LinearGradient(
                      colors: AppTheme.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUser ? null : AppTheme.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? AppTheme.primaryBlue.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: isUser ? 12 : 8,
                  offset: const Offset(0, 2),
                  spreadRadius: isUser ? 1 : 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    color: isUser ? AppTheme.white : AppTheme.darkGray,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: isUser
                            ? AppTheme.white.withOpacity(0.8)
                            : AppTheme.mediumGray,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          SizedBox(width: 8.w),
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.primaryGradient,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.white,
              size: 18.sp,
            ),
          ),
        ],
      ],
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: (index * 30).ms,
        )
        .slideX(
          begin: isUser ? 0.2 : -0.2,
          end: 0,
          duration: 400.ms,
          delay: (index * 30).ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 300.ms,
          delay: (index * 30).ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: TextField(
                    controller: controller.messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 15.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 14.h,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppTheme.darkGray,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => controller.sendMessage(),
                    onChanged: (_) {
                      // Auto-scroll when typing
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (controller.messagesScrollController.hasClients) {
                          final position = controller.messagesScrollController.position;
                          final maxScroll = position.maxScrollExtent;
                          final currentScroll = position.pixels;
                          
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
              ),
              SizedBox(width: 12.w),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.sendMessage,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 56.w,
                    height: 56.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppTheme.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: AppTheme.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.primaryBlue.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 60.sp,
                color: AppTheme.primaryBlue,
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            SizedBox(height: 32.h),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: AppTheme.darkGray,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms),
            SizedBox(height: 12.h),
            Text(
              controller.isLoanOfficer
                  ? 'You\'ll see messages from buyers and sellers here'
                  : 'Start a conversation with agents or loan officers',
              style: TextStyle(
                color: AppTheme.mediumGray,
                fontSize: 14.sp,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 300.ms),
            SizedBox(height: 40.h),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.toNamed('/buyer'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppTheme.white,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Find Professionals',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 300.ms,
                  delay: 400.ms,
                  curve: Curves.easeOut,
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
