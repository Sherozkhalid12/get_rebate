export function networkUploadErrorMessage(err) {
  const msg = String(err?.message || err || '');
  if (/failed to fetch|networkerror|load failed|network request failed/i.test(msg)) {
    return 'Network error. Check your connection and try again.';
  }
  return msg || 'Request failed';
}
