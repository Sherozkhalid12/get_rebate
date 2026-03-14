import { http } from './http';

export async function estimateRebate(payload) {
  return http.post('/rebate/estimate', payload);
}

export async function calculateExactRebate(payload) {
  return http.post('/rebate/calculate-exact', payload);
}

export async function calculateSellerRate(payload) {
  return http.post('/rebate/calculate-seller-rate', payload);
}
