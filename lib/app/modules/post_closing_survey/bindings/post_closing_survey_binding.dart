import 'package:get/get.dart';
import 'package:getrebate/app/modules/post_closing_survey/controllers/post_closing_survey_controller.dart';

class PostClosingSurveyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostClosingSurveyController>(
      () => PostClosingSurveyController(),
    );
  }
}
