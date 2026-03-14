import { http } from './http';

export async function login(payload: { email: string; password: string }) {
  return http.post('/auth/login', payload);
}

export async function sendVerificationEmail(email: string) {
  return http.post('/auth/sendVerificationEmail', { email });
}

export async function verifyOtp(email: string, otp: string) {
  return http.post('/auth/verifyOtp', { email, otp });
}

export async function createUser(payload: Record<string, unknown>) {
  return http.post('/auth/createUser', payload);
}

export async function sendPasswordResetEmail(email: string) {
  return http.post('/auth/sendPasswordResetEmail', { email });
}

export async function verifyPasswordResetOtp(email: string, otp: string) {
  return http.post('/auth/verifyPasswordResetOtp', { email, otp });
}

export async function resetPassword(payload: {
  email: string;
  otp?: string;
  newPassword: string;
}) {
  return http.patch('/auth/resetPassword', payload);
}

export async function removeFcm(userId: string) {
  return http.get(`/auth/removeFCM/${encodeURIComponent(userId)}`);
}
