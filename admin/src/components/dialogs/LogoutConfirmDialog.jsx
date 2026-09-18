/**
 * Professional confirmation dialog before logging out.
 * Shows "Are you sure?" with Yes/Cancel. On Yes, calls onConfirm (logout).
 */
export function LogoutConfirmDialog({ open, onConfirm, onCancel }) {
  if (!open) return null;

  return (
    <div
      className="modal-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="logout-confirm-title"
      onClick={onCancel}
    >
      <div className="modal-dialog glass-card logout-confirm-dialog" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3 id="logout-confirm-title">Log out</h3>
        </div>
        <div className="modal-body">
          <p>Are you sure you want to log out?</p>
          <div className="logout-confirm-actions">
            <button type="button" className="btn ghost" onClick={onCancel}>
              Cancel
            </button>
            <button type="button" className="btn primary" onClick={onConfirm}>
              Yes, log out
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
