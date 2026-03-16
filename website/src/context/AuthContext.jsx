import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { storage } from '../lib/storage';
import { USER_ROLES } from '../lib/constants';
import { normalizeRole, resolveUserId, unwrapObject, extractUserFromGetUserById } from '../lib/api';
import * as authApi from '../api/auth';
import * as userApi from '../api/user';
import { initSocket, disconnectSocket } from '../lib/socket';

const AuthContext = createContext(null);
const seedUser = storage.get('current_user', null);

function normalizeUser(raw) {
  const u = unwrapObject(raw, ['user']) || raw || {};
  const id = resolveUserId(u);
  return {
    ...u,
    id,
    role: normalizeRole(u.role),
  };
}

async function fetchAndSetUser(userId, setUser) {
  const fullRes = await userApi.getUserById(userId);
  const userObj = extractUserFromGetUserById(fullRes);
  const profile = userObj?.loanOfficer || userObj;
  const currentUser = normalizeUser({ ...userObj, ...profile, id: userId });
  storage.set('current_user', currentUser);
  setUser(currentUser);
  return currentUser;
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(seedUser ? normalizeUser(seedUser) : null);
  const [loading, setLoading] = useState(false);
  const [userLoaded, setUserLoaded] = useState(!storage.get('auth_token'));

  useEffect(() => {
    const token = storage.get('auth_token');
    const cached = storage.get('current_user', null);
    const userId = resolveUserId(cached);
    if (!token || !userId) {
      setUserLoaded(true);
      return;
    }
    let live = true;
    userApi.getUserById(userId)
      .then((fullRes) => {
        if (!live) return;
        const userObj = extractUserFromGetUserById(fullRes);
        const profile = userObj?.loanOfficer || userObj;
        const currentUser = normalizeUser({ ...userObj, ...profile, id: userId });
        storage.set('current_user', currentUser);
        setUser(currentUser);
      })
      .catch(() => {
        if (!live) return;
        storage.remove('auth_token');
        storage.remove('current_user');
        setUser(null);
      })
      .finally(() => {
        if (live) setUserLoaded(true);
      });
    return () => { live = false; };
  }, []);

  useEffect(() => {
    const userId = resolveUserId(user);
    if (!userId) return;
    initSocket(userId);
  }, [user]);

  const refreshUser = async () => {
    const userId = resolveUserId(user);
    if (!userId) return null;
    return fetchAndSetUser(userId, setUser);
  };

  const login = async ({ email, password }) => {
    setLoading(true);
    try {
      const response = await authApi.login({ email, password });
      const token = response?.token || response?.data?.token;
      const loginUser = normalizeUser(response?.user || response?.data?.user || response?.data);
      const userId = loginUser?.id ?? loginUser?._id ?? loginUser?.userId;
      if (!userId) throw new Error('Login succeeded but no user id was returned.');

      storage.set('auth_token', token || '');
      if (import.meta.env?.DEV) console.log('[AuthContext] login: fetching user', userId);
      const currentUser = await fetchAndSetUser(userId, setUser);
      return currentUser;
    } catch (err) {
      if (import.meta.env?.DEV) console.error('[AuthContext] login getUserById failed:', err);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const signup = async (payload) => {
    setLoading(true);
    try {
      await authApi.sendVerificationEmail(payload.email);
      storage.set('pending_signup', payload);
    } finally {
      setLoading(false);
    }
  };

  const completeOtpSignup = async ({ email, otp }) => {
    setLoading(true);
    try {
      await authApi.verifyOtp(email, otp);
      const pending = storage.get('pending_signup', null);
      if (!pending) throw new Error('Signup session expired. Please register again.');

      const result = await authApi.createUser(pending);
      const token = result?.token || result?.data?.token;
      const signupUser = normalizeUser(result?.user || result?.data?.user || result?.data);
      const signupUserId = signupUser?.id ?? signupUser?._id ?? signupUser?.userId;
      if (!signupUserId) throw new Error('Signup succeeded but no user id was returned.');

      storage.remove('pending_signup');
      storage.set('auth_token', token || '');
      const currentUser = await fetchAndSetUser(signupUserId, setUser);
      return currentUser;
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    const current = storage.get('current_user', null);
    const userId = resolveUserId(current);
    if (userId) {
      try {
        await authApi.removeFcm(userId);
      } catch {
        // Ignore logout cleanup errors.
      }
    }
    disconnectSocket();
    storage.remove('auth_token');
    storage.remove('current_user');
    storage.remove('pending_signup');
    setUser(null);
  };

  const value = useMemo(
    () => ({
      user,
      loading,
      userLoaded,
      isAuthenticated: Boolean(user?.id),
      role: user?.role || USER_ROLES.BUYER_SELLER,
      login,
      signup,
      completeOtpSignup,
      logout,
      refreshUser,
      setUser: (next) => {
        const normalized = normalizeUser(next);
        storage.set('current_user', normalized);
        setUser(normalized);
      },
    }),
    [user, loading, userLoaded],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
