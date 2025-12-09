import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';

class MessagesView extends GetView<MessagesController> {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
            ),
          ),
        ),
        title: Text(
          'Messages',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
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
            onPressed: () => Get.back(),
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
      if (controller.conversations.isEmpty) {
        return _buildEmptyState(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.conversations.length,
        itemBuilder: (context, index) {
          final conversation = controller.conversations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildConversationCard(context, conversation),
          );
        },
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
              CircleAvatar(
                radius: 25,
                backgroundColor: _getSenderColor(
                  conversation.senderType,
                ).withOpacity(0.1),
                backgroundImage: conversation.senderImage != null
                    ? NetworkImage(conversation.senderImage!)
                    : null,
                child: conversation.senderImage == null
                    ? Icon(
                        _getSenderIcon(conversation.senderType),
                        color: _getSenderColor(conversation.senderType),
                        size: 25,
                      )
                    : null,
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

        // Messages
        Expanded(child: _buildMessagesList(context)),

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
          CircleAvatar(
            radius: 20,
            backgroundColor: _getSenderColor(
              controller.selectedConversation!.senderType,
            ).withOpacity(0.1),
            backgroundImage:
                controller.selectedConversation!.senderImage != null
                ? NetworkImage(controller.selectedConversation!.senderImage!)
                : null,
            child: controller.selectedConversation!.senderImage == null
                ? Icon(
                    _getSenderIcon(controller.selectedConversation!.senderType),
                    color: _getSenderColor(
                      controller.selectedConversation!.senderType,
                    ),
                    size: 20,
                  )
                : null,
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
      if (controller.messages.isEmpty) {
        return const Center(child: Text('No messages yet'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
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
    final isUser = message.senderType == 'user';

    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: _getSenderColor(
              message.senderType,
            ).withOpacity(0.1),
            backgroundImage: message.senderImage != null
                ? NetworkImage(message.senderImage!)
                : null,
            child: message.senderImage == null
                ? Icon(
                    _getSenderIcon(message.senderType),
                    color: _getSenderColor(message.senderType),
                    size: 16,
                  )
                : null,
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
              'Start a conversation with agents or loan officers',
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
        return 'User';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
