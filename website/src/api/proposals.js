import { http } from './http';

export async function getUserProposals(userId) {
  return http.get(`/proposals/user/${encodeURIComponent(userId)}`);
}

export async function getProfessionalProposals(professionalId) {
  return http.get(`/proposals/professional/${encodeURIComponent(professionalId)}`);
}

export async function acceptProposal(proposalId, payload) {
  return http.post(`/proposals/${encodeURIComponent(proposalId)}/accept`, payload);
}

export async function rejectProposal(proposalId, payload) {
  return http.post(`/proposals/${encodeURIComponent(proposalId)}/reject`, payload);
}
