/** Upload rules aligned with the mobile app (1024px, ~85% JPEG quality). */

export const UPLOAD_LIMITS = {
  profileImage: {
    label: 'Profile photo',
    accept: 'image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp',
    types: ['image/jpeg', 'image/png', 'image/webp'],
    extensions: ['.jpg', '.jpeg', '.png', '.webp'],
    maxBytes: 1024 * 1024,
    maxInputBytes: 20 * 1024 * 1024,
    maxDimension: 1024,
    quality: 0.85,
    compress: true,
    hint: 'JPG, PNG, or WebP · Max 1 MB · Large photos are auto-resized (same as the app)',
  },
  logo: {
    label: 'Company logo',
    accept: 'image/jpeg,image/png,image/webp,image/svg+xml,.jpg,.jpeg,.png,.webp,.svg',
    types: ['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'],
    extensions: ['.jpg', '.jpeg', '.png', '.webp', '.svg'],
    maxBytes: 1024 * 1024,
    maxInputBytes: 5 * 1024 * 1024,
    maxDimension: 1024,
    quality: 0.85,
    compress: true,
    hint: 'JPG, PNG, WebP, or SVG · Max 1 MB · Square logos work best',
  },
  video: {
    label: 'Intro video',
    accept: 'video/mp4,video/quicktime,video/webm,.mp4,.mov,.webm',
    types: ['video/mp4', 'video/quicktime', 'video/webm'],
    extensions: ['.mp4', '.mov', '.webm'],
    maxBytes: 25 * 1024 * 1024,
    maxInputBytes: 25 * 1024 * 1024,
    compress: false,
    hint: 'MP4, MOV, or WebM · Max 25 MB · Keep clips short (under 2 min)',
  },
};

export function formatFileSize(bytes) {
  if (bytes == null || Number.isNaN(bytes)) return '';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

export function getUploadLimitsForVariant(variant) {
  if (variant === 'logo') return UPLOAD_LIMITS.logo;
  if (variant === 'video') return UPLOAD_LIMITS.video;
  return UPLOAD_LIMITS.profileImage;
}

function extensionOf(name) {
  const i = String(name || '').lastIndexOf('.');
  return i >= 0 ? String(name).slice(i).toLowerCase() : '';
}

function isAllowedType(file, limits) {
  const type = (file.type || '').toLowerCase();
  if (limits.types.includes(type)) return true;
  const ext = extensionOf(file.name);
  return limits.extensions.includes(ext);
}

function isSvg(file) {
  const type = (file.type || '').toLowerCase();
  return type === 'image/svg+xml' || extensionOf(file.name) === '.svg';
}

/**
 * Resize/compress raster images (matches Flutter image_picker 1024 + quality 85).
 * @returns {Promise<File>}
 */
export async function compressImageFile(file, limits = UPLOAD_LIMITS.profileImage) {
  if (isSvg(file)) {
    if (file.size > limits.maxBytes) {
      throw new Error(
        `${limits.label} must be ${formatFileSize(limits.maxBytes)} or smaller (yours is ${formatFileSize(file.size)}).`,
      );
    }
    return file;
  }

  let bitmap;
  try {
    bitmap = await createImageBitmap(file);
  } catch {
    throw new Error('Could not read this image. Use JPG or PNG, or try a different file.');
  }

  const maxW = limits.maxDimension || 1024;
  const maxH = limits.maxDimension || 1024;
  let { width, height } = bitmap;
  const scale = Math.min(1, maxW / width, maxH / height);
  const w = Math.max(1, Math.round(width * scale));
  const h = Math.max(1, Math.round(height * scale));

  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d');
  if (!ctx) {
    bitmap.close?.();
    throw new Error('Could not process image in this browser.');
  }
  ctx.drawImage(bitmap, 0, 0, w, h);
  bitmap.close?.();

  let quality = limits.quality ?? 0.85;
  const maxOut = limits.maxBytes;

  const toBlob = (q) =>
    new Promise((resolve) => {
      canvas.toBlob((b) => resolve(b), 'image/jpeg', q);
    });

  let blob = await toBlob(quality);
  while (blob && blob.size > maxOut && quality > 0.45) {
    quality -= 0.08;
    blob = await toBlob(quality);
  }

  if (!blob) throw new Error('Could not compress image. Try another file.');
  if (blob.size > maxOut) {
    throw new Error(
      `Image is still too large after compression (${formatFileSize(blob.size)}). Use a simpler photo or crop it smaller.`,
    );
  }

  const base = String(file.name || 'photo').replace(/\.[^.]+$/i, '') || 'photo';
  return new File([blob], `${base}.jpg`, { type: 'image/jpeg', lastModified: Date.now() });
}

/**
 * Validate and optionally compress before upload.
 * @returns {Promise<{ file: File, compressed: boolean, originalSize: number, finalSize: number }>}
 */
export async function processFileForUpload(file, variant = 'profile') {
  const limits = getUploadLimitsForVariant(variant);
  if (!file) throw new Error('No file selected.');

  if (!isAllowedType(file, limits)) {
    throw new Error(
      `${limits.label}: use ${limits.extensions.join(', ').replace(/\./g, '').toUpperCase()} only.`,
    );
  }

  if (file.size > limits.maxInputBytes) {
    throw new Error(
      `File is too large (${formatFileSize(file.size)}). Maximum before processing is ${formatFileSize(limits.maxInputBytes)}.`,
    );
  }

  if (!limits.compress) {
    if (file.size > limits.maxBytes) {
      throw new Error(
        `${limits.label} must be ${formatFileSize(limits.maxBytes)} or smaller (yours is ${formatFileSize(file.size)}).`,
      );
    }
    return { file, compressed: false, originalSize: file.size, finalSize: file.size };
  }

  const originalSize = file.size;
  const needsCompress = !isSvg(file) && (file.size > limits.maxBytes || file.type !== 'image/jpeg');
  const alwaysResizeRaster = !isSvg(file);

  if (!needsCompress && !alwaysResizeRaster && file.size <= limits.maxBytes) {
    return { file, compressed: false, originalSize, finalSize: file.size };
  }

  const out = await compressImageFile(file, limits);
  return {
    file: out,
    compressed: out.size !== originalSize || out.name !== file.name,
    originalSize,
    finalSize: out.size,
  };
}

export function networkUploadErrorMessage(err) {
  const msg = String(err?.message || '');
  if (/failed to fetch|network|load failed/i.test(msg)) {
    return 'Upload failed — the file may be too large or your connection dropped. Photos are limited to 1 MB (we resize large images automatically). Try again on Wi‑Fi or pick a smaller file.';
  }
  return msg || 'Upload failed.';
}
