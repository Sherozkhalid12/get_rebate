/** Holds File refs between signup form and OTP; localStorage cannot store Files. */
let attachments = {
  profilePic: null,
  companyLogo: null,
  video: null,
};

export function setPendingSignupFiles(next) {
  attachments = {
    profilePic: next.profilePic ?? null,
    companyLogo: next.companyLogo ?? null,
    video: next.video ?? null,
  };
}

export function getPendingSignupFiles() {
  return { ...attachments };
}

export function clearPendingSignupFiles() {
  attachments = { profilePic: null, companyLogo: null, video: null };
}
