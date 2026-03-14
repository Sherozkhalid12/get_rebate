import { US_STATES } from '../../lib/constants';

/** Normalize state value (name or code) to 2-letter code */
function toStateCode(val) {
  const s = String(val || '').trim();
  if (s.length === 2) return s.toUpperCase();
  const found = US_STATES.find(
    (st) => st.name.toLowerCase() === s.toLowerCase() || st.code === s.toUpperCase()
  );
  return found ? found.code : null;
}

/** Parse licensed states from API (array, JSON string, or LisencedStates typo). Handles both state names ("Idaho") and codes ("ID"). */
export function parseLicensedStates(user) {
  const raw = user?.licensedStates ?? user?.LisencedStates ?? user?.additionalData?.licensedStates;
  let arr = [];
  if (Array.isArray(raw)) arr = raw;
  else if (typeof raw === 'string') {
    try {
      const parsed = JSON.parse(raw);
      arr = Array.isArray(parsed) ? parsed : [];
    } catch {
      arr = [];
    }
  }
  return arr.map(toStateCode).filter(Boolean);
}

export function StateSelect({ value, onChange, placeholder = 'Select state', className = '', states }) {
  const options = states && states.length > 0
    ? US_STATES.filter((s) => states.includes(s.code))
    : US_STATES;

  return (
    <select
      className={`dropdown-glass ${className}`.trim()}
      value={value}
      onChange={(e) => onChange(e.target.value)}
    >
      <option value="">{placeholder}</option>
      {options.map((s) => (
        <option key={s.code} value={s.code}>
          {s.name} ({s.code})
        </option>
      ))}
    </select>
  );
}
