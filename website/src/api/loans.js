import { http } from './http';

export async function getLoans(loanOfficerId) {
  return http.get(`/loans/${encodeURIComponent(loanOfficerId)}`);
}

export async function createLoan(payload) {
  return http.post('/loans', payload);
}

export async function updateLoan(loanId, payload) {
  return http.patch(`/loans/${encodeURIComponent(loanId)}`, payload);
}

export async function deleteLoan(loanId) {
  return http.del(`/loans/${encodeURIComponent(loanId)}`);
}
