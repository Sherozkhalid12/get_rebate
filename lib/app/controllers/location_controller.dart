import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:getrebate/app/models/zip_code_model.dart';

class LocationController extends GetxController {
  // Observable variables
  final _currentPosition = Rxn<Position>();
  final _currentAddress = Rxn<String>();
  final _currentZipCode = Rxn<String>();
  final _isLoading = false.obs;
  final _permissionGranted = false.obs;

  // Getters
  Position? get currentPosition => _currentPosition.value;
  String? get currentAddress => _currentAddress.value;
  String? get currentZipCode => _currentZipCode.value;
  bool get isLoading => _isLoading.value;
  bool get permissionGranted => _permissionGranted.value;

  @override
  void onInit() {
    super.onInit();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      _permissionGranted.value =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error checking location permission: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      _isLoading.value = true;

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Error', 'Location services are disabled');
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Error', 'Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('Error', 'Location permissions are permanently denied');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition.value = position;
      _permissionGranted.value = true;

      // Get address from coordinates
      await _getAddressFromPosition(position);
    } catch (e) {
      Get.snackbar('Error', 'Failed to get location: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentAddress.value =
            '${placemark.locality}, ${placemark.administrativeArea}';
        _currentZipCode.value = placemark.postalCode;
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  Future<List<ZipCodeModel>> searchZipCodes(String query) async {
    try {
      _isLoading.value = true;

      // Simulate API call - in real app, this would call your backend
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data for demonstration
      // Prices are now calculated from population using pricing tiers
      final mockZipCodes = <ZipCodeModel>[
        ZipCodeModel(
          zipCode: '10001',
          state: 'NY',
          population: 50000,
          // price is optional - will be calculated from population
          createdAt: DateTime.now(),
        ),
        ZipCodeModel(
          zipCode: '10002',
          state: 'NY',
          population: 45000,
          createdAt: DateTime.now(),
        ),
        ZipCodeModel(
          zipCode: '90210',
          state: 'CA',
          population: 30000,
          createdAt: DateTime.now(),
        ),
      ];

      // Filter by query
      final filteredZips = mockZipCodes
          .where(
            (zip) =>
                zip.zipCode.contains(query) ||
                zip.state.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      return filteredZips;
    } catch (e) {
      Get.snackbar('Error', 'Failed to search ZIP codes: ${e.toString()}');
      return [];
    } finally {
      _isLoading.value = false;
    }
  }

  Future<List<ZipCodeModel>> getNearbyZipCodes(
    String zipCode, {
    int radius = 10,
  }) async {
    try {
      _isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data for demonstration
      // Prices are now calculated from population using pricing tiers
      final mockZipCodes = <ZipCodeModel>[
        ZipCodeModel(
          zipCode: zipCode,
          state: 'NY',
          population: 50000,
          // price is optional - will be calculated from population
          createdAt: DateTime.now(),
        ),
        ZipCodeModel(
          zipCode: '10002',
          state: 'NY',
          population: 45000,
          createdAt: DateTime.now(),
        ),
        ZipCodeModel(
          zipCode: '10003',
          state: 'NY',
          population: 40000,
          createdAt: DateTime.now(),
        ),
      ];

      return mockZipCodes;
    } catch (e) {
      Get.snackbar('Error', 'Failed to get nearby ZIP codes: ${e.toString()}');
      return [];
    } finally {
      _isLoading.value = false;
    }
  }

  void setCurrentZipCode(String zipCode) {
    _currentZipCode.value = zipCode;
  }

  void clearLocation() {
    _currentPosition.value = null;
    _currentAddress.value = null;
    _currentZipCode.value = null;
  }
}
