import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { storage } from '../lib/storage';
import { normalizeRole, resolveUserId, unwrapObject, extractUserFromGetUserById } from '../lib/api';
import * as authApi from '../api/auth';
import * as userApi from '../api/user';

const AuthContext = createContext(null);
const seedUser = storage.get('admin_user', null);

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
  const currentUser = normalizeUser({ ...userObj, id: userId });
  storage.set('admin_user', currentUser);
  setUser(currentUser);
  return currentUser;
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(seedUser ? normalizeUser(seedUser) : null);
  const [loading, setLoading] = useState(false);
  const [userLoaded, setUserLoaded] = useState(!storage.get('auth_token'));

  useEffect(() => {
    const token = storage.get('auth_token');
    const cached = storage.get('admin_user', null);
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
        const currentUser = normalizeUser({ ...userObj, id: userId });
        storage.set('admin_user', currentUser);
        setUser(currentUser);
      })
      .catch(() => {
        if (!live) return;
        storage.remove('auth_token');
        storage.remove('admin_user');
        setUser(null);
      })
      .finally(() => {
        if (live) setUserLoaded(true);
      });
    return () => { live = false; };
  }, []);

  const login = async ({ email, password }) => {
    setLoading(true);
    try {
      const response = await authApi.login({ email, password });
      const token = response?.token || response?.data?.token;
      const loginUser = normalizeUser(response?.user || response?.data?.user || response?.data);
      const userId = loginUser?.id ?? loginUser?._id ?? loginUser?.userId;
      if (!userId) throw new Error('Login succeeded but no user id was returned.');

      storage.set('auth_token', token || '');
      const currentUser = await fetchAndSetUser(userId, setUser);
      if (currentUser.role !== 'admin') {
        storage.remove('auth_token');
        storage.remove('admin_user');
        setUser(null);
        throw new Error('This account is not an admin. Use an admin or mainadmin login.');
      }
      return currentUser;
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    storage.remove('auth_token');
    storage.remove('admin_user');
    setUser(null);
  };

  const value = useMemo(
    () => ({
      user,
      loading,
      userLoaded,
      isAuthenticated: Boolean(user?.id),
      role: user?.role || null,
      login,
      logout,
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
