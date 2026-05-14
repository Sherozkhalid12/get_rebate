import { useRef } from 'react';

function UploadGlyph({ variant }) {
  const cls = 'auth-upload__svg';
  if (variant === 'profile') {
    return (
      <svg className={cls} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
        <circle cx="12" cy="9" r="3.5" stroke="currentColor" strokeWidth="1.5" />
        <path d="M6 19.5c0-3.5 3-5.5 6-5.5s6 2 6 5.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      </svg>
    );
  }
  if (variant === 'logo') {
    return (
      <svg className={cls} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
        <rect x="4" y="4" width="16" height="16" rx="2.5" stroke="currentColor" strokeWidth="1.5" />
        <path d="M8 16l2.5-3.5 2 2.5L16 11l3 5" stroke="currentColor" strokeWidth="1.35" strokeLinecap="round" strokeLinejoin="round" />
        <circle cx="9.5" cy="9.5" r="1.25" fill="currentColor" />
      </svg>
    );
  }
  return (
    <svg className={cls} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
      <rect x="3" y="5" width="14" height="14" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M17 9l4-2v10l-4-2" fill="currentColor" opacity="0.25" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
    </svg>
  );
}

/** Same layout as signup auth-upload (profile / logo / video). */
export function MediaUploadField({
  label,
  hint,
  accept,
  variant = 'profile',
  file,
  onFileChange,
}) {
  const inputRef = useRef(null);
  const pick = (f) => onFileChange(f);
  const clear = () => {
    if (inputRef.current) inputRef.current.value = '';
    onFileChange(null);
  };

  return (
    <div className={`auth-upload auth-upload--${variant}${file ? ' auth-upload--has-file' : ''}`}>
      <div className="auth-upload__header">
        <span className="auth-upload__label">{label}</span>
        {hint ? <span className="auth-upload__hint">{hint}</span> : null}
      </div>
      <div className="auth-upload__surface">
        <input
          ref={inputRef}
          type="file"
          accept={accept}
          className="auth-upload__native"
          onChange={(e) => pick(e.target.files?.[0] ?? null)}
        />
        <div className="auth-upload__main">
          <div className="auth-upload__visual">
            <UploadGlyph variant={variant} />
          </div>
          <div className="auth-upload__content">
            {!file ? (
              <>
                <p className="auth-upload__pitch">
                  {variant === 'video'
                    ? 'MP4 or MOV — a short intro helps buyers trust you.'
                    : variant === 'logo'
                      ? 'Square PNG or SVG looks best on your profile.'
                      : 'A clear headshot helps your profile stand out.'}
                </p>
                <button type="button" className="auth-upload__cta" onClick={() => inputRef.current?.click()}>
                  Browse files
                </button>
              </>
            ) : (
              <div className="auth-upload__picked">
                <span className="auth-upload__filename" title={file.name}>{file.name}</span>
                <div className="auth-upload__picked-actions">
                  <button type="button" className="auth-upload__mini auth-upload__mini--solid" onClick={() => inputRef.current?.click()}>
                    Replace
                  </button>
                  <button type="button" className="auth-upload__mini auth-upload__mini--ghost" onClick={clear}>
                    Remove
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
