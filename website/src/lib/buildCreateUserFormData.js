import { USER_ROLES } from './constants';

function apiRole(role) {
  if (role === USER_ROLES.AGENT) return 'agent';
  if (role === USER_ROLES.LOAN_OFFICER) return 'loanofficer';
  return 'buyer/seller';
}

/**
 * Matches Flutter AuthController.signUp FormData (multipart /auth/createUser).
 * @param {Record<string, unknown>} pending - Serializable fields from signup + OTP flow
 * @param {{ profilePic?: File | null; companyLogo?: File | null; video?: File | null }} files
 */
export function buildCreateUserFormData(pending, files = {}) {
  const fd = new FormData();
  const name = pending.fullname || pending.name || '';
  fd.append('fullname', String(name));
  fd.append('email', String(pending.email || ''));
  fd.append('password', String(pending.password || ''));
  fd.append('role', apiRole(pending.role));
  if (pending.timezone) fd.append('timezone', String(pending.timezone));
  if (pending.phone) fd.append('phone', String(pending.phone));

  const licensed = pending.licensedStates;
  if (licensed != null && licensed !== '') {
    const ls = typeof licensed === 'string' ? licensed : JSON.stringify(licensed);
    if (ls && ls !== '[]') fd.append('licensedStates', ls);
  }

  const role = pending.role;

  if (role === USER_ROLES.AGENT) {
    if (pending.CompanyName) fd.append('CompanyName', String(pending.CompanyName));
    if (pending.liscenceNumber) fd.append('liscenceNumber', String(pending.liscenceNumber));
    if (pending.zipCode) fd.append('zipCode', String(pending.zipCode));

    fd.append('dualAgencyState', String(Boolean(pending.dualAgencyState ?? pending.isDualAgencyAllowedInState)));
    fd.append('dualAgencySBrokerage', String(Boolean(pending.dualAgencySBrokerage ?? pending.isDualAgencyAllowedAtBrokerage)));

    const z = pending.zipCode;
    if (z) {
      fd.append('serviceAreas', JSON.stringify([String(z)]));
    }

    if (pending.bio) fd.append('bio', String(pending.bio));

    const exp = pending.expertise || pending.areasOfExpertise;
    if (Array.isArray(exp) && exp.length > 0) {
      fd.append('areasOfExpertise', JSON.stringify(exp));
    }

    if (pending.websiteUrl) fd.append('website_link', String(pending.websiteUrl));
    if (pending.googleReviewsUrl) fd.append('google_reviews_link', String(pending.googleReviewsUrl));
    if (pending.thirdPartyReviewsUrl) fd.append('thirdPartReviewLink', String(pending.thirdPartyReviewsUrl));

    const ver = pending.verificationStatement ?? pending.agentVerificationConfirmed;
    if (ver !== undefined && ver !== null) {
      fd.append('verificationStatement', String(ver));
    }
  } else if (role === USER_ROLES.LOAN_OFFICER) {
    if (pending.CompanyName) fd.append('CompanyName', String(pending.CompanyName));
    if (pending.liscenceNumber) fd.append('liscenceNumber', String(pending.liscenceNumber));
    if (pending.zipCode) fd.append('zipCode', String(pending.zipCode));

    if (pending.bio) fd.append('bio', String(pending.bio));

    const z = pending.zipCode;
    if (z) {
      fd.append('serviceAreas', JSON.stringify([String(z)]));
    }

    const spec = pending.specialtyProducts;
    if (Array.isArray(spec) && spec.length > 0) {
      fd.append('specialtyProducts', JSON.stringify(spec));
    }

    if (pending.websiteUrl) fd.append('website_link', String(pending.websiteUrl));
    if (pending.mortgageApplicationUrl) fd.append('mortgageApplicationUrl', String(pending.mortgageApplicationUrl));
    if (pending.externalReviewsUrl) fd.append('thirdPartReviewLink', String(pending.externalReviewsUrl));

    const ver = pending.verificationStatement ?? pending.loanOfficerVerificationConfirmed;
    if (ver !== undefined && ver !== null) {
      fd.append('verificationStatement', String(ver));
    }
  }

  if (files.profilePic instanceof File) {
    fd.append('profilePic', files.profilePic, files.profilePic.name);
  }
  if (files.companyLogo instanceof File) {
    fd.append('companyLogo', files.companyLogo, files.companyLogo.name);
  }
  if (files.video instanceof File) {
    fd.append('video', files.video, files.video.name);
  }

  return fd;
}
