import 'package:get/get.dart';

class SimpleSurveyController extends GetxController {
  final _currentStep = 0.obs;

  int get currentStep => _currentStep.value;

  void nextStep() {
    if (_currentStep.value < 9) {
      _currentStep.value++;
    }
  }

  void previousStep() {
    if (_currentStep.value > 0) {
      _currentStep.value--;
    }
  }
}
