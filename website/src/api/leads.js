import { http } from './http';

export async function createLead(payload) {
  return http.post('/buyer/createLead', payload);
}

export async function getLeadsByAgentId(agentId) {
  return http.get(`/buyer/getLeadsByAgentId/${encodeURIComponent(agentId)}`);
}

export async function respondToLead(leadId, payload) {
  return http.post(`/buyer/respondToLead/${encodeURIComponent(leadId)}`, payload);
}

export async function markLeadComplete(leadId, payload) {
  return http.post(`/buyer/markLeadComplete/${encodeURIComponent(leadId)}`, payload);
}
