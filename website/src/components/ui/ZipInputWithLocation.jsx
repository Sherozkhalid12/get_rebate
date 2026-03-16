import { useState } from 'react';
import { AnimatedLoader } from './AnimatedLoader';

function geolocationErrorMessage(err) {
  if (!err || typeof err.code === 'undefined') return err?.message || 'Location unavailable';
  switch (err.code) {
    case 1: return 'Location access denied. Please allow location in your browser or device settings.';
    case 2: return 'Location unavailable. Try enabling location services or use a different network.';
    case 3: return 'Location request timed out. Please try again.';
    default: return err?.message || 'Location unavailable';
  }
}

async function getZipAndStateFromLocation() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocation is not supported in this browser'));
      return;
    }
    const options = {
      enableHighAccuracy: false,
      timeout: 20000,
      maximumAge: 300000,
    };
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        try {
          const { latitude, longitude } = pos.coords;
          const res = await fetch(
            `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json&addressdetails=1`,
            { headers: { 'Accept-Language': 'en', 'User-Agent': 'GetARebate/1.0' } }
          );
          const data = await res.json();
          const zip = data?.address?.postcode || data?.address?.zip;
          const zip5 = zip ? String(zip).split('-')[0].trim().slice(0, 5) : null;
          let stateCode = data?.address?.state_code || data?.address?.['ISO3166-2-lvl4']?.split('-')[1];
          if (zip5 && !stateCode) {
            try {
              const zRes = await fetch(`https://api.zippopotam.us/us/${zip5}`);
              if (zRes.ok) {
                const zData = await zRes.json();
                stateCode = zData?.places?.[0]?.['state abbreviation'] || null;
              }
            } catch {}
          }
          resolve({ zip: zip5, state: stateCode });
        } catch (e) {
          reject(new Error(e?.message || 'Could not get address from coordinates'));
        }
      },
      (err) => reject(new Error(geolocationErrorMessage(err)))
    );
  });
}

export function ZipInputWithLocation({
  value,
  onChange,
  onKeyDown,
  placeholder = 'Office ZIP (5 digits)',
  disabled,
  required,
  onLocationError,
  onLocationPicked,
}) {
  const [loading, setLoading] = useState(false);

  const handlePickLocation = async () => {
    setLoading(true);
    try {
      const { zip, state } = await getZipAndStateFromLocation();
      if (zip) {
        onChange({ target: { name: 'zipCode', value: zip } });
        if (onLocationPicked) onLocationPicked({ zip, state });
      } else if (onLocationError) onLocationError('Could not get ZIP from location');
    } catch (err) {
      if (onLocationError) onLocationError(err.message || 'Location access denied');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="zip-input-wrap">
      <input
        name="zipCode"
        type="text"
        inputMode="numeric"
        pattern="[0-9]*"
        maxLength={5}
        value={value}
        onChange={onChange}
        onKeyDown={onKeyDown}
        placeholder={placeholder}
        disabled={disabled}
        required={required}
      />
      <button
        type="button"
        className="zip-location-btn zip-location-btn-loading"
        onClick={handlePickLocation}
        disabled={loading}
        title="Use current location"
        aria-label="Use current location"
      >
        {loading ? (
          <AnimatedLoader variant="inline" label="" />
        ) : (
          <span className="icon-glyph material-symbols-rounded">my_location</span>
        )}
      </button>
    </div>
  );
}
