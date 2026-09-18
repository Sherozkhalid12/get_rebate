import { Navigate, Route, Routes } from 'react-router-dom';
import { RedirectIfAuthed, RequireAdmin } from './routes/Guards';
import { AdminLayout } from './pages/admin/AdminLayout';
import { AdminDashboardPage } from './pages/admin/AdminDashboardPage';
import { AdminUsersPage } from './pages/admin/AdminUsersPage';
import { AdminZipCodesPage } from './pages/admin/AdminZipCodesPage';
import { AdminPaymentsPage } from './pages/admin/AdminPaymentsPage';
import { AdminAnalyticsPage } from './pages/admin/AdminAnalyticsPage';
import { LoginPage } from './pages/LoginPage';

export default function App() {
  return (
    <Routes>
      <Route
        path="/login"
        element={
          <RedirectIfAuthed>
            <LoginPage />
          </RedirectIfAuthed>
        }
      />

      <Route
        path="/"
        element={
          <RequireAdmin>
            <AdminLayout />
          </RequireAdmin>
        }
      >
        <Route index element={<AdminDashboardPage />} />
        <Route path="users" element={<AdminUsersPage />} />
        <Route path="zip-codes" element={<AdminZipCodesPage />} />
        <Route path="payments" element={<AdminPaymentsPage />} />
        <Route path="analytics" element={<AdminAnalyticsPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
