import { http } from './http';

/**
 * Submit agent post-closing survey
 * @param {Object} payload - { userId, rebateFromAgent, receivedExpectedRebate, rebateAppliedAsCreditClosing, signedRebateDisclosure, receivingRebateEasy, agentRecommended, comment?, rating }
 */
export async function submitAgentSurvey(payload) {
  return http.post('/survey/submit', payload);
}

/**
 * Submit loan officer post-closing survey
 * @param {Object} payload - { userId, loSatisfaction, loExplainedOptions, loCommunication, loRebateHelp, loEase, loProfessional, loClosedOnTime, loRecommend, rating }
 */
export async function submitLoanSurvey(payload) {
  return http.post('/survey/submitLoanSurvey', payload);
}

/**
 * Add buyer review (called after survey submit)
 * @param {Object} payload - { currentUserId, agentId (professionalId), rating, review }
 */
export async function addReview(payload) {
  return http.post('/buyer/addReview', payload);
}
