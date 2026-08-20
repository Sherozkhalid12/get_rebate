/** Turn raw API / network errors into copy a user can act on. */

export function friendlyApiError(err, fallback = 'Something went wrong. Please try again.') {
  const msg = String(err?.message || err?.error || err || '').trim();
  const lower = msg.toLowerCase();

  if (!msg) return fallback;

  if (/endpoint issue|cannot (get|post|put|patch|delete)|not found.*endpoint|failed to fetch|network/i.test(msg)) {
    return 'The server had a brief hiccup loading this. Refresh the page and try again.';
  }

  if (/payload too large|entity too large|file (is )?too large|filesize|max.*size|413/.test(lower)) {
    return 'A file was too large to upload. Headshots and logos: 1 MB (photos are resized automatically). Intro video: 25 MB. Try a smaller file or upload media later from Edit Profile.';
  }

  if (/multipart|boundary/.test(lower)) {
    return 'Upload failed. Try a smaller photo or video, or skip media for now and add it from Edit Profile after you sign in.';
  }

  return msg;
}
