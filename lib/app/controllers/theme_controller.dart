import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();

  // Observable variables
  final _isDarkMode = false.obs;
  final _primaryColor = const Color(0xFF2563EB).obs;

  // Getters
  bool get isDarkMode => _isDarkMode.value;
  Color get primaryColor => _primaryColor.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemeSettings();
  }

  void _loadThemeSettings() {
    _isDarkMode.value = _storage.read('isDarkMode') ?? false;
    final colorValue = _storage.read('primaryColor');
    if (colorValue != null) {
      _primaryColor.value = Color(colorValue);
    }
  }

  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    _storage.write('isDarkMode', _isDarkMode.value);
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void setPrimaryColor(Color color) {
    _primaryColor.value = color;
    _storage.write('primaryColor', color.value);
  }

  void resetTheme() {
    _isDarkMode.value = false;
    _primaryColor.value = const Color(0xFF2563EB);
    _storage.remove('isDarkMode');
    _storage.remove('primaryColor');
    Get.changeThemeMode(ThemeMode.light);
  }
}
