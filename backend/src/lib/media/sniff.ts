/**
 * Detects the real file type from its first bytes. Never trust the file name,
 * the extension or the client's Content-Type.
 */
export type SniffedType =
  | 'image/jpeg'
  | 'image/png'
  | 'image/webp'
  | 'image/heic'
  | 'video/mp4'
  | 'video/quicktime';

const ascii = (b: Uint8Array, start: number, len: number) =>
  String.fromCharCode(...b.subarray(start, start + len));

export function sniffMime(bytes: Uint8Array): SniffedType | null {
  if (bytes.length < 12) return null;
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return 'image/jpeg';
  if (bytes[0] === 0x89 && ascii(bytes, 1, 3) === 'PNG') return 'image/png';
  if (ascii(bytes, 0, 4) === 'RIFF' && ascii(bytes, 8, 4) === 'WEBP') return 'image/webp';
  if (ascii(bytes, 4, 4) === 'ftyp') {
    const brand = ascii(bytes, 8, 4);
    if (['heic', 'heix', 'hevc', 'heim', 'heis', 'mif1', 'msf1'].includes(brand)) return 'image/heic';
    if (brand === 'qt  ') return 'video/quicktime';
    if (['isom', 'iso2', 'iso4', 'iso5', 'iso6', 'mp41', 'mp42', 'avc1', 'M4V ', 'dash'].includes(brand)) return 'video/mp4';
  }
  return null;
}

export const MEDIA_RULES = {
  image: {
    mimes: ['image/jpeg', 'image/png', 'image/webp', 'image/heic'] as SniffedType[],
    maxBytes: 15 * 1024 * 1024,
    maxPerProperty: 20,
  },
  video: {
    mimes: ['video/mp4', 'video/quicktime'] as SniffedType[],
    maxBytes: 200 * 1024 * 1024,
    maxPerProperty: 3,
  },
} as const;

export type MediaKind = keyof typeof MEDIA_RULES;

export const extensionFor: Record<SniffedType, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/heic': 'heic',
  'video/mp4': 'mp4',
  'video/quicktime': 'mov',
};

/** Storage path for a property's media: {user}/{property}/{random}.{ext} */
export function mediaPath(userId: string, propertyId: string, ext: string): string {
  return `${userId}/${propertyId}/${crypto.randomUUID()}.${ext}`;
}

/** The path must be inside the caller's own folder for that property. */
export function isOwnMediaPath(path: string, userId: string, propertyId: string): boolean {
  return (
    path.startsWith(`${userId}/${propertyId}/`) &&
    !path.includes('..') &&
    /^[0-9a-f-]+\/[0-9a-f-]+\/[0-9a-f-]+\.(jpg|png|webp|heic|mp4|mov)$/.test(path)
  );
}
