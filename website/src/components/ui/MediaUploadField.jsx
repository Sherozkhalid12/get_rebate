import { useEffect, useRef, useState } from 'react';
import { getUploadLimitsForVariant, processFileForUpload, formatFileSize } from '../../lib/mediaUpload';

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
  onValidationError,
}) {
  const inputRef = useRef(null);
  const limits = getUploadLimitsForVariant(variant);
  const [processing, setProcessing] = useState(false);
  const [compressNote, setCompressNote] = useState('');
  const [previewUrl, setPreviewUrl] = useState('');

  useEffect(() => {
    if (!(file instanceof File) || variant === 'video') {
      setPreviewUrl('');
      return undefined;
    }
    const url = URL.createObjectURL(file);
    setPreviewUrl(url);
    return () => URL.revokeObjectURL(url);
  }, [file, variant]);

  const limitsHint = hint || limits.hint;
  const acceptAttr = accept || limits.accept;

  const clear = () => {
    if (inputRef.current) inputRef.current.value = '';
    setCompressNote('');
    onFileChange(null);
  };

  const handlePick = async (raw) => {
    if (!raw) {
      clear();
      return;
    }
    setProcessing(true);
    setCompressNote('');
    try {
      const result = await processFileForUpload(raw, variant);
      onFileChange(result.file);
      if (result.compressed && result.originalSize > result.finalSize) {
        setCompressNote(
          `Resized from ${formatFileSize(result.originalSize)} to ${formatFileSize(result.finalSize)} for upload.`,
        );
      }
    } catch (err) {
      if (inputRef.current) inputRef.current.value = '';
      const message = err?.message || 'Could not use this file.';
      if (onValidationError) onValidationError(message);
      else setCompressNote('');
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div className={`auth-upload auth-upload--${variant}${file ? ' auth-upload--has-file' : ''}`}>
      <div className="auth-upload__header">
        <span className="auth-upload__label">{label}</span>
        {hint && hint !== limits.hint ? <span className="auth-upload__hint">{hint}</span> : null}
      </div>
      <p className="upload-limits-note" role="note">
        {limitsHint}
      </p>
      <div className="auth-upload__surface">
        <input
          ref={inputRef}
          type="file"
          accept={acceptAttr}
          className="auth-upload__native"
          disabled={processing}
          onChange={(e) => handlePick(e.target.files?.[0] ?? null)}
        />
        <div className="auth-upload__main">
          <div className={`auth-upload__visual${previewUrl ? ' auth-upload__visual--preview' : ''}`}>
            {previewUrl ? (
              <img src={previewUrl} alt="" className="auth-upload__preview-img" />
            ) : (
              <UploadGlyph variant={variant} />
            )}
          </div>
          <div className="auth-upload__content">
            {processing ? (
              <p className="auth-upload__pitch">Preparing file…</p>
            ) : !file ? (
              <>
                <p className="auth-upload__pitch">
                  {variant === 'video'
                    ? 'A short intro helps buyers trust you.'
                    : variant === 'logo'
                      ? 'Square branding shows on your profile.'
                      : 'A clear headshot helps your profile stand out.'}
                </p>
                <button type="button" className="auth-upload__cta" onClick={() => inputRef.current?.click()}>
                  Browse files
                </button>
              </>
            ) : (
              <div className="auth-upload__picked">
                <span className="auth-upload__filename" title={file.name}>
                  {file.name}
                  <span className="auth-upload__filesize"> ({formatFileSize(file.size)})</span>
                </span>
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
      {compressNote ? <p className="form-hint upload-compress-note">{compressNote}</p> : null}
    </div>
  );
}
