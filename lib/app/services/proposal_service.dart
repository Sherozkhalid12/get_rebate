import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:getrebate/app/models/proposal_model.dart';
import 'package:getrebate/app/utils/api_constants.dart';

class ProposalServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ProposalServiceException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

class ProposalService {
  final Dio _dio = Dio();

  /// Create a new proposal
  Future<ProposalModel> createProposal({
    required String userId,
    required String userName,
    String? userProfilePic,
    required String professionalId,
    required String professionalName,
    required String professionalType, // 'agent' or 'loan_officer'
    String? message,
    String? propertyAddress,
    String? propertyPrice,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 Creating proposal...');
        print('   User: $userName ($userId)');
        print('   Professional: $professionalName ($professionalId)');
      }

      final response = await _dio.post(
        '${ApiConstants.apiBaseUrl}/proposals/create',
        data: {
          'userId': userId,
          'userName': userName,
          if (userProfilePic != null) 'userProfilePic': userProfilePic,
          'professionalId': professionalId,
          'professionalName': professionalName,
          'professionalType': professionalType,
          'status': 'pending',
          if (message != null) 'message': message,
          if (propertyAddress != null) 'propertyAddress': propertyAddress,
          if (propertyPrice != null) 'propertyPrice': propertyPrice,
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Proposal created successfully');
      }

      return ProposalModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ProposalServiceException(
        message: 'Failed to create proposal: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Accept a proposal (agent/loan officer)
  Future<ProposalModel> acceptProposal({
    required String proposalId,
    required String professionalId,
  }) async {
    try {
      if (kDebugMode) {
        print('✅ Accepting proposal: $proposalId');
      }

      final response = await _dio.post(
        '${ApiConstants.apiBaseUrl}/proposals/$proposalId/accept',
        data: {
          'professionalId': professionalId,
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Proposal accepted successfully');
      }

      return ProposalModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ProposalServiceException(
        message: 'Failed to accept proposal: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Reject a proposal (agent/loan officer)
  Future<ProposalModel> rejectProposal({
    required String proposalId,
    required String professionalId,
    String? reason,
  }) async {
    try {
      if (kDebugMode) {
        print('❌ Rejecting proposal: $proposalId');
      }

      final response = await _dio.post(
        '${ApiConstants.apiBaseUrl}/proposals/$proposalId/reject',
        data: {
          'professionalId': professionalId,
          if (reason != null) 'reason': reason,
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Proposal rejected successfully');
      }

      return ProposalModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ProposalServiceException(
        message: 'Failed to reject proposal: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Complete service (either party)
  Future<ProposalModel> completeService({
    required String proposalId,
    required String userId, // User who initiated completion
  }) async {
    try {
      if (kDebugMode) {
        print('✅ Completing service for proposal: $proposalId');
      }

      final response = await _dio.post(
        '${ApiConstants.apiBaseUrl}/proposals/$proposalId/complete',
        data: {
          'userId': userId,
        },
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      if (kDebugMode) {
        print('✅ Service completed successfully');
      }

      return ProposalModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ProposalServiceException(
        message: 'Failed to complete service: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get proposals for a user
  Future<List<ProposalModel>> getUserProposals(String userId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.apiBaseUrl}/proposals/user/$userId',
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['proposals'] ?? []);

      return data.map((json) => ProposalModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ProposalServiceException(
        message: 'Failed to get user proposals: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get proposals for a professional (agent/loan officer)
  Future<List<ProposalModel>> getProfessionalProposals(String professionalId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.apiBaseUrl}/proposals/professional/$professionalId',
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['proposals'] ?? []);

      return data.map((json) => ProposalModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ProposalServiceException(
        message: 'Failed to get professional proposals: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get a specific proposal by ID
  Future<ProposalModel> getProposal(String proposalId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.apiBaseUrl}/proposals/$proposalId',
        options: Options(
          headers: ApiConstants.ngrokHeaders,
        ),
      );

      return ProposalModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ProposalServiceException(
        message: 'Failed to get proposal: ${e.toString()}',
        originalError: e,
      );
    }
  }

  ProposalServiceException _handleDioError(DioException e) {
    String errorMessage;
    int? statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection.';
        statusCode = 408;
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Cannot connect to server. Please ensure the server is running.';
        break;
      case DioExceptionType.badResponse:
        statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          errorMessage = 'Proposal not found.';
        } else if (statusCode == 400) {
          errorMessage = e.response?.data?['message']?.toString() ?? 
                        'Invalid request.';
        } else if (statusCode == 401) {
          errorMessage = 'Unauthorized. Please login again.';
        } else if (statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        } else {
          errorMessage = e.response?.data?['message']?.toString() ?? 
                        e.response?.data?['error']?.toString() ?? 
                        'Failed to process request.';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request was cancelled.';
        break;
      case DioExceptionType.unknown:
        errorMessage = 'Network error. Please try again.';
        break;
      default:
        errorMessage = 'An unexpected error occurred.';
    }

    return ProposalServiceException(
      message: errorMessage,
      statusCode: statusCode,
      originalError: e,
    );
  }
}



