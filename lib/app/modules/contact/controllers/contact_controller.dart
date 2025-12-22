import 'package:get/get.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';

class ContactController extends GetxController {
  final String userId;
  final String userName;
  final String? userProfilePic;
  final String userRole;
  
  final _isCreatingThread = false.obs;
  
  bool get isCreatingThread => _isCreatingThread.value;

  ContactController({
    required this.userId,
    required this.userName,
    this.userProfilePic,
    this.userRole = 'user',
  });

  @override
  void onInit() {
    super.onInit();
    _checkExistingConversation();
  }
  
  /// Checks if a conversation already exists and navigates directly to chat
  Future<void> _checkExistingConversation() async {
    try {
      // Get or create messages controller
      if (!Get.isRegistered<MessagesController>()) {
        Get.put(MessagesController(), permanent: true);
      }
      final messagesController = Get.find<MessagesController>();
      
      // Wait for threads to load if needed
      if (messagesController.allConversations.isEmpty && !messagesController.isLoadingThreads) {
        await messagesController.loadThreads();
      }
      
      // Wait a bit for threads to load
      int retries = 0;
      while (messagesController.allConversations.isEmpty && 
             messagesController.isLoadingThreads && 
             retries < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retries++;
      }
      
      // Check if conversation exists
      ConversationModel? existingConversation;
      try {
        existingConversation = messagesController.allConversations.firstWhere(
          (conv) => conv.senderId == userId,
        );
      } catch (e) {
        existingConversation = null;
      }
      
      if (existingConversation != null) {
        // Conversation exists - navigate directly to chat
        messagesController.selectConversation(existingConversation);
        // Navigate to main screen and switch to messages tab
        Get.offAllNamed('/main');
        // Switch to messages tab (index 2 for messages)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.isRegistered<MainNavigationController>()) {
            try {
              final mainNavController = Get.find<MainNavigationController>();
              mainNavController.changeIndex(2); // Messages tab index (0=Home, 1=Favorites, 2=Messages, 3=Profile)
            } catch (e) {
              print('⚠️ Error changing tab index: $e');
            }
          }
        });
      }
      // If no conversation exists, show ContactView (default behavior)
    } catch (e) {
      print('⚠️ Error checking existing conversation: $e');
      // Continue to show ContactView if check fails
    }
  }

  Future<void> startChat() async {
    try {
      _isCreatingThread.value = true;
      
      // Get or create messages controller
      if (!Get.isRegistered<MessagesController>()) {
        Get.put(MessagesController(), permanent: true);
      }
      final messagesController = Get.find<MessagesController>();

      // Start chat - this will navigate instantly and replace this screen
      await messagesController.startChatWithUser(
        otherUserId: userId,
        otherUserName: userName,
        otherUserProfilePic: userProfilePic,
        otherUserRole: userRole,
      );
      
      // Navigation is handled in startChatWithUser, no need to go back
    } catch (e) {
      print('❌ Error starting chat: $e');
      Get.snackbar('Error', 'Failed to start chat: ${e.toString()}');
    } finally {
      _isCreatingThread.value = false;
    }
  }
}

