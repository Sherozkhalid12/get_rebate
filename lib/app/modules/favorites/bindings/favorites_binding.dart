import 'package:get/get.dart';
import 'package:getrebate/app/modules/favorites/controllers/favorites_controller.dart';

class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoritesController>(() => FavoritesController());
  }
}
