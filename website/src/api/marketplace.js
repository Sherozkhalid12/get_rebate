import { http } from './http';

export async function getAllAgents(page = 1) {
  return http.get(`/agent/getAllAgents/${page}`);
}

export async function getAgentsByZipCode(zipCode) {
  return http.get(`/agent/getAgentsByZipCode/${encodeURIComponent(zipCode)}`);
}

export async function addAgentSearch(identifier) {
  return http.get(`/agent/addSearch/${encodeURIComponent(identifier)}`);
}

export async function addAgentContact(agentId) {
  return http.get(`/agent/addContact/${encodeURIComponent(agentId)}`);
}

export async function addAgentProfileView(agentId) {
  return http.get(`/agent/addProfileView/${encodeURIComponent(agentId)}`);
}

export async function getListings(agentId = '') {
  if (agentId) {
    return http.get(`/agent/getListings?id=${encodeURIComponent(agentId)}`);
  }
  return http.get('/agent/getListings');
}

export async function getAgentListings(agentId) {
  return http.get(`/agent/getListingByAgentId/${encodeURIComponent(agentId)}`);
}

export async function createListing(payload) {
  return http.post('/agent/createListing', payload);
}

export async function updateListing(listingId, payload) {
  return http.patch(`/agent/updateListing/${encodeURIComponent(listingId)}`, payload);
}

export async function addListingView(listingId) {
  return http.get(`/agent/addListingView/${encodeURIComponent(listingId)}`);
}

export async function addListingSearch(listingId) {
  return http.get(`/agent/addListingSearch/${encodeURIComponent(listingId)}`);
}

export async function addListingContact(listingId) {
  return http.get(`/agent/addListingContact/${encodeURIComponent(listingId)}`);
}

export async function getLoanOfficers() {
  return http.get('/loan-officers/all');
}

export async function getLoanOfficerById(loanOfficerId) {
  return http.get(`/loan-officers/${encodeURIComponent(loanOfficerId)}`);
}

export async function likeAgent(agentId) {
  return http.post(`/buyer/likeAgent/${encodeURIComponent(agentId)}`, {});
}

export async function likeListing(payload) {
  return http.post('/buyer/like', payload);
}

export async function likeLoanOfficer(loanOfficerId) {
  return http.post(`/loan-officers/${encodeURIComponent(loanOfficerId)}/like`, {});
}
