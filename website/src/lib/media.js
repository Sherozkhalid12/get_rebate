import { API_BASE_URL } from './constants';

function apiOrigin() {
  try {
    return new URL(API_BASE_URL).origin;
  } catch {
    return '';
  }
}

export function resolveMediaUrl(path) {
  if (!path || typeof path !== 'string') return '';
  const trimmed = path.trim();
  if (!trimmed) return '';

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return encodeURI(trimmed);
  }

  const origin = apiOrigin();
  if (!origin) return encodeURI(trimmed);
  const normalized = trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
  return encodeURI(`${origin}${normalized}`);
}

export function firstImageFromEntity(entity) {
  if (!entity || typeof entity !== 'object') return '';

  const multiFields = [
    entity.photoUrls,
    entity.propertyPhotos,
    entity.images,
    entity.photos,
  ];

  for (const field of multiFields) {
    if (Array.isArray(field) && field.length > 0) {
      const first = field.find(Boolean);
      if (first) return resolveMediaUrl(typeof first === 'string' ? first : first.url || first.path || '');
    }
  }

  const singleFields = [
    entity.profilePic,
    entity.profileImage,
    entity.image,
    entity.photo,
    entity.companyLogo,
    entity.companyLogoUrl,
    entity.thumbnail,
  ];

  for (const value of singleFields) {
    const url = resolveMediaUrl(value);
    if (url) return url;
  }

  return '';
}

export function allImagesFromEntity(entity) {
  if (!entity || typeof entity !== 'object') return [];
  const raw = [];

  const lists = [entity.photoUrls, entity.propertyPhotos, entity.images, entity.photos];
  lists.forEach((list) => {
    if (Array.isArray(list)) {
      list.forEach((item) => raw.push(typeof item === 'string' ? item : item?.url || item?.path || ''));
    }
  });

  const single = firstImageFromEntity(entity);
  if (single) raw.push(single);

  return Array.from(new Set(raw.map((x) => resolveMediaUrl(x)).filter(Boolean)));
}
