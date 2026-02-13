import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/lead_model.dart';
import 'package:getrebate/app/services/leads_service.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';
import 'package:getrebate/app/utils/error_handler.dart';
import 'package:getrebate/app/modules/proposals/controllers/proposal_controller.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';

class LeadDetailController extends GetxController {
  final LeadsService _leadsService = LeadsService();

  // Observable state
  final _lead = Rxn<LeadModel>();
  final _isLoading = true.obs;
  final _error = Rxn<String>();

  LeadModel? get lead => _lead.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    
    // Check if lead is passed directly
    if (args != null && args['lead'] != null && args['lead'] is LeadModel) {
      _lead.value = args['lead'] as LeadModel;
      _isLoading.value = false;
      if (kDebugMode) {
        print('✅ LeadDetailController: Lead passed directly: ${_lead.value?.id}');
      }
      return;
    } 
    // Check if leadId is passed (from notification)
    if (args != null && args['leadId'] != null) {
      final leadId = args['leadId']?.toString();
      if (leadId != null && leadId.isNotEmpty) {
        if (kDebugMode) {
          print('📡 LeadDetailController: Finding lead by ID: $leadId');
        }
        _findLeadById(leadId);
        return;
      }
    } 
    
    // No lead or leadId provided
    _error.value = 'No lead information provided';
    _isLoading.value = false;
    if (kDebugMode) {
      print('❌ LeadDetailController: No lead or leadId provided');
    }
  }

  /// Find lead by ID from ProposalController's leads list
  Future<void> _findLeadById(String leadId) async {
    _isLoading.value = true;
    _error.value = null;

    try {
      if (kDebugMode) {
        print('🔍 Looking for lead ID: $leadId');
      }

      // Try to get lead from ProposalController if it exists and is registered
      try {
        if (Get.isRegistered<ProposalController>()) {
          final proposalController = Get.find<ProposalController>();
          if (proposalController.leads.isNotEmpty) {
            final foundLead = proposalController.getLead(leadId);
            if (foundLead != null) {
              _lead.value = foundLead;
              _isLoading.value = false;
              if (kDebugMode) {
                print('✅ Found lead in ProposalController: ${foundLead.id}');
              }
              return;
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ ProposalController not found or lead not in cache: $e');
        }
        // Continue to fetch from API
      }

      // If not found in controller, try to fetch from API
      await _fetchLeadById(leadId);
    } catch (e) {
      _error.value = 'Failed to load lead: ${e.toString()}';
      _isLoading.value = false;
      if (kDebugMode) {
        print('❌ Error finding lead: $e');
      }
    }
  }

  /// Fetch lead by ID from API
  /// Since there's no single lead endpoint, we fetch all leads and find the matching one
  Future<void> _fetchLeadById(String leadId) async {
    _isLoading.value = true;
    _error.value = null;

    try {
      if (kDebugMode) {
        print('📡 Fetching leads to find lead ID: $leadId');
      }

      // Get current user to fetch their leads
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser;
      
      if (currentUser == null || currentUser.id.isEmpty) {
        _error.value = 'User not logged in';
        _isLoading.value = false;
        return;
      }

      // Fetch all leads for the current user
      final leadsResponse = await _leadsService.getLeadsByBuyerId(currentUser.id);
      
      if (kDebugMode) {
        print('   Found ${leadsResponse.leads.length} leads in response');
      }
      
      // Find the lead with matching ID
      try {
        final foundLead = leadsResponse.leads.firstWhere(
          (lead) => lead.id == leadId,
        );

        _lead.value = foundLead;
        _isLoading.value = false;
        
        if (kDebugMode) {
          print('✅ Found lead in API response: ${foundLead.id}');
        }
      } catch (e) {
        // Lead not found in the list
        _error.value = 'Lead not found in your leads list';
        _isLoading.value = false;
        if (kDebugMode) {
          print('❌ LeadDetailController: Lead ID $leadId not found in ${leadsResponse.leads.length} leads');
        }
        SnackbarHelper.showError('Lead not found');
        return;
      }
    } catch (e) {
      _error.value = 'Failed to load lead details: ${e.toString()}';
      _isLoading.value = false;
      
      if (kDebugMode) {
        print('❌ LeadDetailController: Error fetching lead: $e');
      }
      
      ErrorHandler.handleError(e, defaultMessage: 'Unable to load lead details. Please check your connection and try again.');
    }
  }

  /// Refresh lead data
  Future<void> refresh() async {
    if (_lead.value != null) {
      await _fetchLeadById(_lead.value!.id);
    } else {
      // If no lead, try to get from arguments
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && args['leadId'] != null) {
        final leadId = args['leadId']?.toString();
        if (leadId != null && leadId.isNotEmpty) {
          await _findLeadById(leadId);
        }
      }
    }
  }
  
  /// Public method to find lead by ID (called from view)
  Future<void> findLeadById(String leadId) async {
    await _findLeadById(leadId);
  }
}
