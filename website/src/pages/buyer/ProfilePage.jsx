import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { PageHeader } from '../../components/layout/PageHeader';
import { useAuth } from '../../context/AuthContext';
import { resolveUserId, extractUserFromGetUserById } from '../../lib/api';
import { firstImageFromEntity } from '../../lib/media';
import * as userApi from '../../api/user';
import { useToast } from '../../components/ui/ToastProvider';
import { IconGlyph } from '../../components/ui/IconGlyph';
import { AnimatedLoader } from '../../components/ui/AnimatedLoader';
import { LogoutConfirmDialog } from '../../components/dialogs/LogoutConfirmDialog';

export function ProfilePage() {
  const navigate = useNavigate();
  const { user, setUser, refreshUser, logout } = useAuth();
  const { showToast } = useToast();
  const userId = resolveUserId(user);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [form, setForm] = useState({
    fullname: '',
    email: '',
    phone: '',
    bio: '',
  });

  useEffect(() => {
    let live = true;
    const load = async () => {
      if (!userId) {
        setLoading(false);
        return;
      }
      try {
        const res = await userApi.getUserById(userId);
        const data = extractUserFromGetUserById(res);
        if (!live) return;
        const bio = data?.bio ?? data?.additionalData?.bio ?? '';
        setForm({
          fullname: data?.fullname || data?.name || user?.fullname || user?.name || '',
          email: data?.email || user?.email || '',
          phone: data?.phone || user?.phone || '',
          bio: typeof bio === 'string' ? bio : '',
        });
      } catch {
        if (live) {
          setForm({
            fullname: user?.fullname || user?.name || '',
            email: user?.email || '',
            phone: user?.phone || '',
            bio: '',
          });
        }
      } finally {
        if (live) setLoading(false);
      }
    };
    load();
    return () => { live = false; };
  }, [userId]);

  const handleEdit = () => setIsEditing(true);
  const handleCancel = () => {
    setIsEditing(false);
    if (userId) {
      userApi.getUserById(userId)
        .then((res) => {
          const data = extractUserFromGetUserById(res);
          const bio = data?.bio ?? data?.additionalData?.bio ?? '';
          setForm({
            fullname: data?.fullname || data?.name || '',
            email: data?.email || '',
            phone: data?.phone || '',
            bio: typeof bio === 'string' ? bio : '',
          });
        })
        .catch(() => {});
    }
  };

  const handleSave = async (e) => {
    e?.preventDefault();
    if (!userId) return;
    const trimmed = form.fullname?.trim();
    if (!trimmed) {
      showToast({ type: 'error', message: 'Please enter your name' });
      return;
    }
    if (!form.email?.trim()) {
      showToast({ type: 'error', message: 'Please enter your email' });
      return;
    }
    setSaving(true);
    try {
      const payload = {
        fullname: trimmed,
        email: form.email.trim(),
        ...(form.phone?.trim() ? { phone: form.phone.trim() } : {}),
        ...(form.bio?.trim() ? { bio: form.bio.trim() } : {}),
      };
      const res = await userApi.updateUser(userId, payload);
      const updated = res?.user || res?.data?.user || res?.data || {};
      const merged = { ...user, ...updated, fullname: trimmed, email: form.email.trim(), phone: form.phone || updated?.phone, bio: form.bio || updated?.bio };
      setUser(merged);
      await refreshUser();
      setIsEditing(false);
      showToast({ type: 'success', message: 'Profile updated successfully' });
    } catch (err) {
      showToast({ type: 'error', message: err?.message || 'Failed to update profile' });
    } finally {
      setSaving(false);
    }
  };

  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  const handleLogoutClick = () => setShowLogoutConfirm(true);

  const handleLogoutConfirm = () => {
    setShowLogoutConfirm(false);
    logout();
    navigate('/');
  };

  const displayName = form.fullname || user?.fullname || user?.name || 'User';
  const displayEmail = form.email || user?.email || '';
  const profileImage = firstImageFromEntity(user || {});

  if (loading) {
    return (
      <div className="page-body">
        <PageHeader title="Profile" subtitle="Your account information" icon="profile" />
        <AnimatedLoader variant="full" label="Loading profile..." />
      </div>
    );
  }

  return (
    <div className="page-body">
      <LogoutConfirmDialog
        open={showLogoutConfirm}
        onConfirm={handleLogoutConfirm}
        onCancel={() => setShowLogoutConfirm(false)}
      />
      <PageHeader
        title="Profile"
        subtitle="Your account information"
        icon="profile"
        actions={
          <button
            type="button"
            className="btn ghost tiny"
            onClick={isEditing ? handleCancel : handleEdit}
            aria-label={isEditing ? 'Cancel' : 'Edit profile'}
          >
            <IconGlyph name={isEditing ? 'close' : 'edit'} />
            {isEditing ? 'Cancel' : 'Edit'}
          </button>
        }
      />

      <div className="profile-page-wrap">
        <section className="profile-header">
          <div className="profile-header-inner">
            <div className="profile-avatar-wrap">
              {profileImage ? (
                <img src={profileImage} alt="" className="profile-avatar" onError={(e) => { e.target.style.display = 'none'; e.target.nextSibling?.classList.remove('hidden'); }} />
              ) : null}
              <div className={`profile-avatar-placeholder ${profileImage ? 'hidden' : ''}`}>
                <IconGlyph name="person" />
              </div>
            </div>
            <h2 className="profile-display-name">{displayName}</h2>
            <p className="profile-display-email">{displayEmail}</p>
          </div>
        </section>

        <section className="glass-card panel profile-form-card">
          <h3 className="profile-form-title">
            <IconGlyph name="person" />
            Personal Information
          </h3>
          <form className="profile-form" onSubmit={handleSave}>
            <div className="profile-form-field">
              <label>Full Name</label>
              <input
                type="text"
                value={form.fullname}
                onChange={(e) => setForm((p) => ({ ...p, fullname: e.target.value }))}
                placeholder="Your full name"
                disabled={!isEditing}
                required
              />
            </div>
            <div className="profile-form-field">
              <label>Email</label>
              <input
                type="email"
                value={form.email}
                onChange={(e) => setForm((p) => ({ ...p, email: e.target.value }))}
                placeholder="Email"
                disabled
                required
              />
              <small className="form-hint">Email cannot be changed</small>
            </div>
            <div className="profile-form-field">
              <label>Phone Number</label>
              <input
                type="tel"
                value={form.phone}
                onChange={(e) => setForm((p) => ({ ...p, phone: e.target.value }))}
                placeholder="Phone number"
                disabled={!isEditing}
              />
            </div>
            <div className="profile-form-field">
              <label>Bio</label>
              <textarea
                value={form.bio}
                onChange={(e) => setForm((p) => ({ ...p, bio: e.target.value }))}
                placeholder="Tell us about yourself (optional)"
                rows={4}
                disabled={!isEditing}
              />
            </div>
            {isEditing && (
              <div className="profile-form-actions">
                <button type="button" className="btn ghost" onClick={handleCancel}>
                  Cancel
                </button>
                <button type="submit" className="btn primary" disabled={saving}>
                  {saving ? (
                    <span className="btn-loading-content"><AnimatedLoader variant="button" label="" /> Saving...</span>
                  ) : (
                    'Save Changes'
                  )}
                </button>
              </div>
            )}
          </form>
        </section>

        <section className="profile-logout-wrap">
          <button type="button" className="btn danger profile-logout-btn" onClick={handleLogoutClick}>
            <IconGlyph name="logout" />
            Logout
          </button>
        </section>
      </div>
    </div>
  );
}
