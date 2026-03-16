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
  const fd = new FormData();
  const fields = [
    'propertyTitle', 'description', 'price', 'BACPercentage', 'listingAgent', 'dualAgencyAllowed',
    'streetAddress', 'city', 'state', 'zipCode', 'id', 'status', 'createdByRole',
  ];
  fields.forEach((k) => {
    if (payload[k] != null) fd.append(k, String(payload[k]));
  });
  if (payload.propertyDetails) fd.append('propertyDetails', JSON.stringify(payload.propertyDetails));
  if (payload.propertyFeatures) fd.append('propertyFeatures', JSON.stringify(payload.propertyFeatures));
  if (payload.openHouses) fd.append('openHouses', JSON.stringify(payload.openHouses));
  if (payload.existingPropertyPhotos) fd.append('existingPropertyPhotos', JSON.stringify(payload.existingPropertyPhotos));
  return http.put(`/agent/updateListing/${encodeURIComponent(listingId)}`, fd);
}

export async function deleteListing(listingId) {
  return http.del(`/buyer/delete/${encodeURIComponent(listingId)}`);
}

export async function createListingCheckout(userId) {
  return http.post('/subscription/create-listing-checkout', { userId });
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

export async function likeAgent(agentId, currentUserId) {
  return http.post(`/buyer/likeAgent/${encodeURIComponent(agentId)}`, { currentUserId: currentUserId || '' });
}

export async function likeListing(payload) {
  const { userId, listingId } = payload;
  return http.post('/buyer/like', { userId, listingId });
}

export async function likeLoanOfficer(loanOfficerId, userId) {
  return http.post(`/loan-officers/${encodeURIComponent(loanOfficerId)}/like`, { currentUserId: userId });
}
