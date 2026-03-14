import { http } from './http';

/** Get user-friendly message when zip is claimed. claimedBy: "agent" | "loanOfficer" | null */
export function getZipClaimedMessage(zipcode, claimedBy) {
  if (!claimedBy) return null;
  if (claimedBy === 'agent') return `This zipcode is already claimed by an Agent.`;
  if (claimedBy === 'loanOfficer') return `This zipcode is already claimed by a Loan Officer.`;
  return `ZIP ${zipcode} is already claimed.`;
}

export async function getStateZipCodes(country, state) {
  return http.get(`/zip-codes/getstateZip/${encodeURIComponent(country)}/${encodeURIComponent(state)}`);
}

export async function validateZipCode(zipCode, state) {
  return http.get(`/zip-codes/validate/${encodeURIComponent(zipCode)}/${encodeURIComponent(state)}`);
}

export async function claimZipCode(payload) {
  return http.post('/zip-codes/claim', payload);
}

export async function releaseZipCode(payload) {
  return http.patch('/zip-codes/release', payload);
}

export async function claimLoanOfficerZipCode(payload) {
  return http.post('/loan-officer-zip-codes/claim', payload);
}

export async function releaseLoanOfficerZipCode(payload) {
  return http.patch('/loan-officer-zip-codes/release', payload);
}

export async function getZipClaimStatus(zipcode) {
  return http.post('/zip-codes/zipclaimstatus', { zipcode });
}

export async function createCheckoutSession(payload) {
  return http.post('/subscription/create-checkout-session', payload);
}

export async function verifyPaymentSuccess(sessionId, zipcode) {
  const zip = String(zipcode ?? '').trim();
  if (zip) {
    return http.get(`/subscription/paymentSuccess/${sessionId}/${zip}`);
  }
  return http.get(`/subscription/paymentSuccess/${sessionId}`);
}

export async function cancelSubscription(payload) {
  return http.post('/subscription/cancelSubscription', payload);
}
