import { Navigate, Route, Routes } from 'react-router-dom';
import { RequireAuth, RequireRole } from './routes/Guards';
import { AppShell } from './components/layout/AppShell';
import { LandingPage } from './pages/public/LandingPage';

import { SplashPage } from './pages/auth/SplashPage';
import { OnboardingPage } from './pages/auth/OnboardingPage';
import { AuthPage } from './pages/auth/AuthPage';
import { VerifyOtpPage } from './pages/auth/VerifyOtpPage';
import { ForgotPasswordPage } from './pages/auth/ForgotPasswordPage';
import { ResetPasswordPage } from './pages/auth/ResetPasswordPage';

import { BuyerHomePage } from './pages/buyer/BuyerHomePage';
import { FindAgentsPage } from './pages/buyer/FindAgentsPage';
import { FavoritesPage } from './pages/buyer/FavoritesPage';
import { MessagesPage } from './pages/buyer/MessagesPage';
import { ProfilePage } from './pages/buyer/ProfilePage';
import { AgentDetailPage } from './pages/buyer/AgentDetailPage';
import { LoanOfficerDetailPage } from './pages/buyer/LoanOfficerDetailPage';

import {
  AgentBillingPage,
  AgentDashboardPage,
  AgentLeadsPage,
  AgentListingsPage,
  AgentMessagesPage,
  AgentStatsPage,
  AgentZipCodesPage,
} from './pages/agent/AgentPages';
import { AgentEditProfilePage } from './pages/agent/AgentEditProfilePage';
import {
  LoanOfficerBillingPage,
  LoanOfficerChecklistsPage,
  LoanOfficerDashboardPage,
  LoanOfficerMessagesPage,
  LoanOfficerZipCodesPage,
} from './pages/loanOfficer/LoanOfficerPages';
import { LoanOfficerEditProfilePage } from './pages/loanOfficer/LoanOfficerEditProfilePage';
import { ListingDetailPage } from './pages/buyer/ListingDetailPage';
import {
  AddListingPage,
  AddLoanPage,
  AgentChecklistPage,
  BuyerLeadFormPage,
  ChecklistPage,
  LeadDetailPage,
  LoanOfficerChecklistPage,
  NotificationsPage,
  PostClosingSurveyPage,
  ProposalsPage,
  RebateCalculatorPage,
  RebateChecklistPage,
  SellerLeadFormPage,
} from './pages/shared/CommonPages';
import {
  AboutLegalPage,
  HelpSupportPage,
  PrivacyPolicyPage,
  TermsOfServicePage,
} from './pages/legal/LegalPages';
import { PaymentCancelPage, PaymentSuccessPage } from './pages/shared/PaymentResultPages';

function App() {
  return (
    <Routes>
      <Route path="/" element={<LandingPage />} />
      <Route path="/landing" element={<Navigate to="/" replace />} />
      <Route path="/splash" element={<SplashPage />} />
      <Route path="/onboarding" element={<OnboardingPage />} />
      <Route path="/auth" element={<AuthPage />} />
      <Route path="/verify-otp" element={<VerifyOtpPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />
      <Route path="/reset-password" element={<ResetPasswordPage />} />

      <Route
        path="/"
        element={
          <RequireAuth>
            <AppShell />
          </RequireAuth>
        }
      >
        <Route path="app" element={<RequireRole role="buyerSeller"><BuyerHomePage /></RequireRole>} />
        <Route path="app/find-agents" element={<RequireRole role="buyerSeller"><FindAgentsPage /></RequireRole>} />
        <Route path="app/favorites" element={<RequireRole role="buyerSeller"><FavoritesPage /></RequireRole>} />
        <Route path="app/messages" element={<RequireRole role="buyerSeller"><MessagesPage /></RequireRole>} />
        <Route path="app/profile" element={<RequireRole role="buyerSeller"><ProfilePage /></RequireRole>} />
        <Route path="agent-detail" element={<RequireRole role="buyerSeller"><AgentDetailPage /></RequireRole>} />
        <Route path="loan-officer-detail" element={<RequireRole role="buyerSeller"><LoanOfficerDetailPage /></RequireRole>} />

        <Route path="agent" element={<RequireRole role="agent"><AgentDashboardPage /></RequireRole>} />
        <Route path="agent/edit-profile" element={<RequireRole role="agent"><AgentEditProfilePage /></RequireRole>} />
        <Route path="agent/messages" element={<RequireRole role="agent"><AgentMessagesPage /></RequireRole>} />
        <Route path="agent/zip-codes" element={<RequireRole role="agent"><AgentZipCodesPage /></RequireRole>} />
        <Route path="agent/listings" element={<RequireRole role="agent"><AgentListingsPage /></RequireRole>} />
        <Route path="agent/stats" element={<RequireRole role="agent"><AgentStatsPage /></RequireRole>} />
        <Route path="agent/billing" element={<RequireRole role="agent"><AgentBillingPage /></RequireRole>} />
        <Route path="agent/leads" element={<RequireRole role="agent"><AgentLeadsPage /></RequireRole>} />

        <Route path="loan-officer" element={<RequireRole role="loanOfficer"><LoanOfficerDashboardPage /></RequireRole>} />
        <Route path="loan-officer/edit-profile" element={<RequireRole role="loanOfficer"><LoanOfficerEditProfilePage /></RequireRole>} />
        <Route path="loan-officer/messages" element={<RequireRole role="loanOfficer"><LoanOfficerMessagesPage /></RequireRole>} />
        <Route path="loan-officer/zip-codes" element={<RequireRole role="loanOfficer"><LoanOfficerZipCodesPage /></RequireRole>} />
        <Route path="loan-officer/billing" element={<RequireRole role="loanOfficer"><LoanOfficerBillingPage /></RequireRole>} />
        <Route path="loan-officer/checklists" element={<RequireRole role="loanOfficer"><LoanOfficerChecklistsPage /></RequireRole>} />

        <Route path="payment-success" element={<PaymentSuccessPage />} />
        <Route path="payment-cancel" element={<PaymentCancelPage />} />

        <Route path="notifications" element={<NotificationsPage />} />
        <Route path="proposals" element={<ProposalsPage />} />
        <Route path="post-closing-survey" element={<PostClosingSurveyPage />} />
        <Route path="lead-detail" element={<LeadDetailPage />} />

        <Route path="rebate-calculator" element={<RebateCalculatorPage />} />
        <Route path="buyer-lead-form" element={<BuyerLeadFormPage />} />
        <Route path="seller-lead-form" element={<SellerLeadFormPage />} />
        <Route path="listing-detail" element={<ListingDetailPage />} />
        <Route path="add-listing" element={<AddListingPage />} />
        <Route path="add-loan" element={<AddLoanPage />} />

        <Route path="checklist" element={<ChecklistPage />} />
        <Route path="rebate-checklist" element={<RebateChecklistPage />} />
        <Route path="agent-checklist" element={<AgentChecklistPage />} />
        <Route path="loan-officer-checklist" element={<LoanOfficerChecklistPage />} />

        <Route path="privacy-policy" element={<PrivacyPolicyPage />} />
        <Route path="terms-of-service" element={<TermsOfServicePage />} />
        <Route path="about-legal" element={<AboutLegalPage />} />
        <Route path="help-support" element={<HelpSupportPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default App;
