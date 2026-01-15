import 'package:get/get.dart';
import 'package:getrebate/app/modules/splash/bindings/splash_binding.dart';
import 'package:getrebate/app/modules/splash/views/splash_view.dart';
import 'package:getrebate/app/modules/onboarding/bindings/onboarding_binding.dart';
import 'package:getrebate/app/modules/onboarding/views/onboarding_view.dart';
import 'package:getrebate/app/modules/auth/bindings/auth_binding.dart';
import 'package:getrebate/app/modules/auth/views/auth_view.dart';
import 'package:getrebate/app/views/main_navigation_view.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';
import 'package:getrebate/app/modules/agent/bindings/agent_binding.dart';
import 'package:getrebate/app/modules/agent/views/agent_view.dart';
import 'package:getrebate/app/modules/loan_officer/bindings/loan_officer_binding.dart';
import 'package:getrebate/app/modules/loan_officer/views/loan_officer_view.dart';
import 'package:getrebate/app/modules/rebate_calculator/bindings/rebate_calculator_binding.dart';
import 'package:getrebate/app/modules/rebate_calculator/views/rebate_calculator_view.dart';
import 'package:getrebate/app/modules/agent_profile/bindings/agent_profile_binding.dart';
import 'package:getrebate/app/modules/agent_profile/views/agent_profile_view.dart';
import 'package:getrebate/app/modules/agent_edit_profile/bindings/agent_edit_profile_binding.dart';
import 'package:getrebate/app/modules/agent_edit_profile/views/agent_edit_profile_view.dart';
import 'package:getrebate/app/modules/loan_officer_profile/bindings/loan_officer_profile_binding.dart';
import 'package:getrebate/app/modules/loan_officer_profile/views/loan_officer_profile_view.dart';
import 'package:getrebate/app/modules/buyer_lead_form/bindings/buyer_lead_form_binding.dart';
import 'package:getrebate/app/modules/buyer_lead_form/views/buyer_lead_form_view.dart';
import 'package:getrebate/app/modules/seller_lead_form/bindings/seller_lead_form_binding.dart';
import 'package:getrebate/app/modules/seller_lead_form/views/seller_lead_form_view.dart';
import 'package:getrebate/app/modules/property_detail/bindings/property_detail_binding.dart';
import 'package:getrebate/app/modules/property_detail/views/property_detail_view.dart';
// DISABLED: Create listing imports - buyers cannot create listings anymore
// import 'package:getrebate/app/modules/create_listing/bindings/create_listing_binding.dart';
// import 'package:getrebate/app/modules/create_listing/views/create_listing_view.dart';
import 'package:getrebate/app/modules/edit_listing/bindings/edit_listing_binding.dart';
import 'package:getrebate/app/modules/edit_listing/views/edit_listing_view.dart';
import 'package:getrebate/app/modules/messages/bindings/messages_binding.dart';
import 'package:getrebate/app/modules/messages/views/messages_view.dart';
import 'package:getrebate/app/modules/listing_detail/bindings/listing_detail_binding.dart';
import 'package:getrebate/app/modules/listing_detail/views/listing_detail_view.dart';
import 'package:getrebate/app/modules/find_agents/bindings/find_agents_binding.dart';
import 'package:getrebate/app/modules/find_agents/views/find_agents_view.dart';
// Add listing imports - enabled for agents
import 'package:getrebate/app/modules/add_listing/bindings/add_listing_binding.dart';
import 'package:getrebate/app/modules/add_listing/views/add_listing_view.dart';
import 'package:getrebate/app/modules/add_loan/bindings/add_loan_binding.dart';
import 'package:getrebate/app/modules/add_loan/views/add_loan_view.dart';
import 'package:getrebate/app/modules/post_closing_survey/bindings/post_closing_survey_binding.dart';
import 'package:getrebate/app/modules/post_closing_survey/views/post_closing_survey_view.dart';
import 'package:getrebate/app/modules/post_closing_survey/views/simple_survey_view.dart';
import 'package:getrebate/app/modules/post_closing_survey/controllers/simple_survey_controller.dart';
import 'package:getrebate/app/modules/rebate_checklist/bindings/rebate_checklist_binding.dart';
import 'package:getrebate/app/modules/rebate_checklist/views/rebate_checklist_view.dart';
import 'package:getrebate/app/modules/checklist/bindings/checklist_binding.dart';
import 'package:getrebate/app/modules/checklist/views/checklist_view.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/modules/contact/views/contact_view.dart';
import 'package:getrebate/app/modules/contact/bindings/contact_binding.dart';
import 'package:getrebate/app/modules/privacy_policy/views/privacy_policy_view.dart';
import 'package:getrebate/app/modules/privacy_policy/bindings/privacy_policy_binding.dart';
import 'package:getrebate/app/modules/help_support/views/help_support_view.dart';
import 'package:getrebate/app/modules/help_support/bindings/help_support_binding.dart';
import 'package:getrebate/app/modules/terms_of_service/views/terms_of_service_view.dart';
import 'package:getrebate/app/modules/terms_of_service/bindings/terms_of_service_binding.dart';
import 'package:getrebate/app/modules/notifications/views/notifications_view.dart';
import 'package:getrebate/app/modules/notifications/bindings/notifications_binding.dart';
import 'package:getrebate/app/modules/compliance_tutorial/views/compliance_tutorial_view.dart';
import 'package:getrebate/app/modules/compliance_tutorial/bindings/compliance_tutorial_binding.dart';
import 'package:flutter/material.dart';

class AppPages {
  static const INITIAL = '/splash';
  static const ONBOARDING = '/onboarding';
  static const AUTH = '/auth';
  static const MAIN = '/main';
  static const AGENT = '/agent';
  static const LOAN_OFFICER = '/loan-officer';
  static const REBATE_CALCULATOR = '/rebate-calculator';
  static const AGENT_PROFILE = '/agent-profile';
  static const AGENT_EDIT_PROFILE = '/agent-edit-profile';
  static const LOAN_OFFICER_PROFILE = '/loan-officer-profile';
  static const BUYER_LEAD_FORM = '/buyer-lead-form';
  static const SELLER_LEAD_FORM = '/seller-lead-form';
  static const PROPERTY_DETAIL = '/property-detail';
  static const LISTING_DETAIL = '/listing-detail';
  static const FIND_AGENTS = '/find-agents';
  static const CONTACT_AGENT = '/contact-agent';
  static const CONTACT_LOAN_OFFICER = '/contact-loan-officer';
  static const CONTACT = '/contact';
  static const MESSAGES = '/messages';
  static const CREATE_LISTING = '/create-listing';
  static const EDIT_LISTING = '/edit-listing';
  static const ADD_LISTING = '/add-listing';
  static const ADD_LOAN = '/add-loan';
  static const POST_CLOSING_SURVEY = '/post-closing-survey';
  static const SIMPLE_SURVEY = '/simple-survey';
  static const REBATE_CHECKLIST = '/rebate-checklist';
  static const CHECKLIST = '/checklist';
  static const PRIVACY_POLICY = '/privacy-policy';
  static const HELP_SUPPORT = '/help-support';
  static const TERMS_OF_SERVICE = '/terms-of-service';
  static const NOTIFICATIONS = '/notifications';
  static const COMPLIANCE_TUTORIAL = '/compliance-tutorial';

  static final routes = [
    GetPage(
      name: INITIAL,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: ONBOARDING,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(name: AUTH, page: () => const AuthView(), binding: AuthBinding()),
    GetPage(
      name: MAIN,
      page: () => const MainNavigationView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MainNavigationController>(() => MainNavigationController());
      }),
    ),
    GetPage(
      name: AGENT,
      page: () => const AgentView(),
      binding: AgentBinding(),
    ),
    GetPage(
      name: LOAN_OFFICER,
      page: () => const LoanOfficerView(),
      binding: LoanOfficerBinding(),
    ),
    GetPage(
      name: REBATE_CALCULATOR,
      page: () => const RebateCalculatorView(),
      binding: RebateCalculatorBinding(),
    ),
    GetPage(
      name: AGENT_PROFILE,
      page: () => const AgentProfileView(),
      binding: AgentProfileBinding(),
    ),
    GetPage(
      name: AGENT_EDIT_PROFILE,
      page: () => const AgentEditProfileView(),
      binding: AgentEditProfileBinding(),
    ),
    GetPage(
      name: LOAN_OFFICER_PROFILE,
      page: () => const LoanOfficerProfileView(),
      binding: LoanOfficerProfileBinding(),
    ),
    GetPage(
      name: BUYER_LEAD_FORM,
      page: () => const BuyerLeadFormView(),
      binding: BuyerLeadFormBinding(),
    ),
    GetPage(
      name: SELLER_LEAD_FORM,
      page: () => const SellerLeadFormView(),
      binding: SellerLeadFormBinding(),
    ),
    GetPage(
      name: PROPERTY_DETAIL,
      page: () => const PropertyDetailView(),
      binding: PropertyDetailBinding(),
    ),
    GetPage(
      name: LISTING_DETAIL,
      page: () => const ListingDetailView(),
      binding: ListingDetailBinding(),
    ),
    GetPage(
      name: FIND_AGENTS,
      page: () => const FindAgentsView(),
      binding: FindAgentsBinding(),
    ),
    GetPage(name: CONTACT_AGENT, page: () => const ContactAgentView()),
    GetPage(
      name: CONTACT_LOAN_OFFICER,
      page: () => const ContactLoanOfficerView(),
    ),
    GetPage(
      name: CONTACT,
      page: () => const ContactView(),
      binding: ContactBinding(),
    ),
    GetPage(
      name: MESSAGES,
      page: () => const MessagesView(),
      binding: MessagesBinding(),
    ),
    // DISABLED: Create listing route - buyers cannot create listings anymore
    // GetPage(
    //   name: CREATE_LISTING,
    //   page: () => const CreateListingView(),
    //   binding: CreateListingBinding(),
    // ),
    GetPage(
      name: EDIT_LISTING,
      page: () => const EditListingView(),
      binding: EditListingBinding(),
    ),
    // Add listing route - enabled for agents
    GetPage(
      name: ADD_LISTING,
      page: () => const AddListingView(),
      binding: AddListingBinding(),
    ),
    GetPage(
      name: ADD_LOAN,
      page: () => const AddLoanView(),
      binding: AddLoanBinding(),
    ),
    GetPage(
      name: POST_CLOSING_SURVEY,
      page: () => const PostClosingSurveyView(),
      binding: PostClosingSurveyBinding(),
    ),
    GetPage(
      name: SIMPLE_SURVEY,
      page: () => const SimpleSurveyView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SimpleSurveyController>(() => SimpleSurveyController());
      }),
    ),
    GetPage(
      name: REBATE_CHECKLIST,
      page: () => const RebateChecklistView(),
      binding: RebateChecklistBinding(),
    ),
    GetPage(
      name: CHECKLIST,
      page: () => const ChecklistView(),
      binding: ChecklistBinding(),
    ),
    GetPage(
      name: PRIVACY_POLICY,
      page: () => const PrivacyPolicyView(),
      binding: PrivacyPolicyBinding(),
    ),
    GetPage(
      name: HELP_SUPPORT,
      page: () => const HelpSupportView(),
      binding: HelpSupportBinding(),
    ),
    GetPage(
      name: TERMS_OF_SERVICE,
      page: () => const TermsOfServiceView(),
      binding: TermsOfServiceBinding(),
    ),
    GetPage(
      name: NOTIFICATIONS,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: COMPLIANCE_TUTORIAL,
      page: () => const ComplianceTutorialView(),
      binding: ComplianceTutorialBinding(),
    ),
  ];
}

// Placeholder views for contact pages
class ContactAgentView extends StatelessWidget {
  const ContactAgentView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final agent = args?['agent'] as AgentModel?;
    final agentName = agent?.name ?? 'Agent';

    return Scaffold(
      appBar: AppBar(
        title: Text(agentName),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat, size: 80, color: AppTheme.primaryBlue),
              const SizedBox(height: 20),
              Text(
                'Chat with $agentName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Start a conversation with this agent about properties and services.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.mediumGray,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  if (agent == null) {
                    Get.snackbar('Error', 'Agent information not available');
                    return;
                  }
                  
                  // Navigate to contact screen first
                  Get.toNamed('/contact', arguments: {
                    'userId': agent.id,
                    'userName': agent.name,
                    'userProfilePic': agent.profileImage,
                    'userRole': 'agent',
                  });
                },
                icon: const Icon(Icons.chat),
                label: const Text('Start Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactLoanOfficerView extends StatelessWidget {
  const ContactLoanOfficerView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final loanOfficer = args?['loanOfficer'] as LoanOfficerModel?;
    final loanOfficerName = loanOfficer?.name ?? 'Loan Officer';

    return Scaffold(
      appBar: AppBar(
        title: Text(loanOfficerName),
        backgroundColor: AppTheme.lightGreen,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.successGradient,
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat, size: 80, color: AppTheme.lightGreen),
              const SizedBox(height: 20),
              Text(
                'Chat with $loanOfficerName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Start a conversation with this loan officer about financing options and rates.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.mediumGray,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  if (loanOfficer == null) {
                    Get.snackbar('Error', 'Loan officer information not available');
                    return;
                  }
                  
                  // Navigate to contact screen first
                  Get.toNamed('/contact', arguments: {
                    'userId': loanOfficer.id,
                    'userName': loanOfficer.name,
                    'userProfilePic': loanOfficer.profileImage,
                    'userRole': 'loan_officer',
                  });
                },
                icon: const Icon(Icons.chat),
                label: const Text('Start Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
