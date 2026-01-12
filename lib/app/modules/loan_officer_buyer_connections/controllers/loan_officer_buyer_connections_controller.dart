import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:getrebate/app/models/buyer_connection_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';

class LoanOfficerBuyerConnectionsController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final Dio _dio = Dio();

  final _buyerConnections = <BuyerConnectionModel>[].obs;
  final _isLoading = false.obs;
  final _selectedStatus = 'all'.obs; // 'all', 'active', 'removed'

  List<BuyerConnectionModel> get buyerConnections => _buyerConnections;
  bool get isLoading => _isLoading.value;
  String get selectedStatus => _selectedStatus.value;

  @override
  void onInit() {
    super.onInit();
    _setupDio();
    fetchBuyerConnections();
  }

  void _setupDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.headers['Content-Type'] = 'application/json';
    
    // Add auth token if available
    final token = _authController.token;
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> fetchBuyerConnections() async {
    try {
      _isLoading.value = true;
      
      final currentUser = _authController.currentUser;
      if (currentUser == null || currentUser.id.isEmpty) {
        if (kDebugMode) print('❌ No current user found');
        return;
      }

      // API endpoint: GET /api/v1/loan-officers/:id/buyer-connections
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/loan-officers/${currentUser.id}/buyer-connections',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final connections = (response.data['buyerConnections'] as List?)
                ?.map((json) => BuyerConnectionModel.fromJson(json))
                .toList() ??
            [];
        
        _buyerConnections.value = connections;
        
        if (kDebugMode) {
          print('✅ Loaded ${connections.length} buyer connections');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Unexpected response format: ${response.data}');
        }
        _buyerConnections.value = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching buyer connections: $e');
      }
      _buyerConnections.value = [];
      
      // Show error message only if not initial load
      if (_buyerConnections.isNotEmpty) {
        SnackbarHelper.showError('Failed to load buyer connections');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  void setStatusFilter(String status) {
    _selectedStatus.value = status;
  }

  List<BuyerConnectionModel> get filteredConnections {
    if (_selectedStatus.value == 'all') {
      return _buyerConnections;
    }
    return _buyerConnections
        .where((connection) => connection.status == _selectedStatus.value)
        .toList();
  }

  Future<void> refreshConnections() async {
    await fetchBuyerConnections();
  }
}


