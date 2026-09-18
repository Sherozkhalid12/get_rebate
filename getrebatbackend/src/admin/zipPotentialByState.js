/**
 * Estimated payable residential ZIP / ZCTA territories in rebate-allowed states.
 * Planning targets sum to PLATFORM_ZIP_TARGET (27,150). Live "loaded" counts
 * always come from MongoDB; remaining = max(0, potential - loaded).
 */
export const PLATFORM_ZIP_TARGET = 27150;

export const ZIP_POTENTIAL_BY_STATE = {
  AZ: 443,
  AR: 579,
  CA: 2257,
  CO: 451,
  CT: 324,
  DC: 43,
  DE: 81,
  FL: 1261,
  GA: 835,
  HI: 119,
  ID: 273,
  IL: 1175,
  IN: 733,
  KY: 784,
  ME: 366,
  MD: 494,
  MA: 596,
  MI: 980,
  MN: 809,
  MT: 324,
  NE: 494,
  NV: 221,
  NH: 238,
  NJ: 613,
  NM: 324,
  NY: 1831,
  NC: 920,
  ND: 324,
  OH: 1175,
  PA: 1516,
  RI: 77,
  SC: 460,
  SD: 324,
  TX: 2215,
  UT: 273,
  VT: 238,
  VA: 835,
  WA: 613,
  WV: 630,
  WI: 750,
  WY: 152,
};

export const REBATE_ALLOWED_STATES = Object.keys(ZIP_POTENTIAL_BY_STATE);
