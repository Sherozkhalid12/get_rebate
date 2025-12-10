import 'package:get/get.dart';
import 'package:getrebate/app/modules/messages/controllers/messages_controller.dart';

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

