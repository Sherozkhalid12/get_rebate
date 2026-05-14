/**
 * Multipart PATCH body for /auth/updateUser/:id — mirrors Flutter AuthController.updateUserProfile.
 * @param {'agent' | 'loanOfficer' | 'buyerSeller'} role
 * @param {Record<string, unknown>} fields
 * @param {{ profilePic?: File | null; companyLogo?: File | null; video?: File | null }} files
 */
export function buildUpdateUserProfileFormData(role, fields, files = {}) {
  const fd = new FormData();

  let tz = 'UTC';
  try {
    tz = Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';
  } catch {
    /* ignore */
  }
  fd.append('timezone', tz);

  const str = (k) => {
    const v = fields[k];
    if (v == null) return '';
    const s = String(v).trim();
    return s;
  };

  const appendIf = (key, value) => {
    if (value != null && String(value).trim() !== '') fd.append(key, String(value).trim());
  };

  appendIf('fullname', str('fullname'));
  appendIf('email', str('email'));
  appendIf('phone', str('phone'));
  appendIf('bio', str('bio'));

  if (role === 'buyerSeller') {
    if (files.profilePic instanceof File) {
      fd.append('profilePic', files.profilePic, files.profilePic.name);
    }
    return fd;
  }

  if (role === 'agent') appendIf('description', str('description'));

  appendIf('liscenceNumber', str('liscenceNumber'));
  appendIf('zipCode', str('zipCode'));
  appendIf('CompanyName', str('CompanyName'));

  appendIf('website_link', str('website_link'));

  if (role === 'agent') {
    appendIf('google_reviews_link', str('google_reviews_link'));
    appendIf('thirdPartReviewLink', str('thirdPartReviewLink'));
  }

  if (role === 'loanOfficer') {
    const mort = str('mortgageApplicationUrl');
    if (mort) {
      fd.append('mortagelink', mort);
      fd.append('mortgageApplicationUrl', mort);
    }
    appendIf('thirdPartReviewLink', str('thirdPartReviewLink'));
  }

  const zip = str('zipCode');
  if (zip) fd.append('serviceAreas', JSON.stringify([zip]));

  const ls = fields.licensedStates;
  if (Array.isArray(ls) && ls.length > 0) {
    fd.append('licensedStates', JSON.stringify(ls.map((c) => String(c).toUpperCase())));
  }

  if (role === 'agent') {
    const exp = fields.areasOfExpertise;
    if (Array.isArray(exp) && exp.length > 0) {
      fd.append('areasOfExpertise', JSON.stringify(exp));
    }
    const ds = fields.dualAgencyState;
    const db = fields.dualAgencySBrokerage;
    if (ds === true || ds === false) fd.append('dualAgencyState', String(ds));
    if (db === true || db === false) fd.append('dualAgencySBrokerage', String(db));
  }

  if (role === 'loanOfficer') {
    const sp = fields.specialtyProducts;
    if (Array.isArray(sp) && sp.length > 0) {
      fd.append('specialtyProducts', JSON.stringify(sp));
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
