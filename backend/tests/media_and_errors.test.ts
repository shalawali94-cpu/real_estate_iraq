import { describe, expect, it, vi } from 'vitest';

vi.mock('server-only', () => ({}));

import { toApiError } from '@/lib/db/rpc-error';
import { ApiError } from '@/lib/http/errors';
import { isOwnMediaPath, mediaPath, sniffMime } from '@/lib/media/sniff';

const bytes = (...parts: (number[] | string)[]) => {
  const out: number[] = [];
  for (const p of parts) out.push(...(typeof p === 'string' ? [...p].map((c) => c.charCodeAt(0)) : p));
  while (out.length < 16) out.push(0);
  return new Uint8Array(out);
};

describe('sniffMime (real type from bytes, not the name)', () => {
  it.each([
    ['jpeg', bytes([0xff, 0xd8, 0xff, 0xe0]), 'image/jpeg'],
    ['png', bytes([0x89], 'PNG', [0x0d, 0x0a, 0x1a, 0x0a]), 'image/png'],
    ['webp', bytes('RIFF', [0, 0, 0, 0], 'WEBP'), 'image/webp'],
    ['heic', bytes([0, 0, 0, 0x18], 'ftypheic'), 'image/heic'],
    ['mp4', bytes([0, 0, 0, 0x20], 'ftypisom'), 'video/mp4'],
    ['mov', bytes([0, 0, 0, 0x14], 'ftypqt  '), 'video/quicktime'],
  ])('detects %s', (_n, b, expected) => {
    expect(sniffMime(b)).toBe(expected);
  });

  it('rejects a script renamed to .jpg', () => {
    expect(sniffMime(bytes('#!/bin/sh\nrm -rf /'))).toBeNull();
  });
  it('rejects a PDF', () => {
    expect(sniffMime(bytes('%PDF-1.7'))).toBeNull();
  });
});

describe('media paths', () => {
  const u = '11111111-1111-1111-1111-111111111111';
  const p = '22222222-2222-2222-2222-222222222222';
  it('builds paths inside the user/property folder', () => {
    expect(isOwnMediaPath(mediaPath(u, p, 'jpg'), u, p)).toBe(true);
  });
  it('rejects other users, traversal and odd extensions', () => {
    expect(isOwnMediaPath(`33333333-3333-3333-3333-333333333333/${p}/a.jpg`, u, p)).toBe(false);
    expect(isOwnMediaPath(`${u}/${p}/../x.jpg`, u, p)).toBe(false);
    expect(isOwnMediaPath(`${u}/${p}/abc.exe`, u, p)).toBe(false);
  });
});

describe('toApiError (SQL function errors → typed codes)', () => {
  it('maps a known code with detail', () => {
    const e = toApiError({ message: 'VALIDATION_FAILED: images', code: '22023' });
    expect(e).toBeInstanceOf(ApiError);
    expect((e as ApiError).code).toBe('VALIDATION_FAILED');
    expect((e as ApiError).details).toEqual({ reason: 'images' });
  });
  it('maps payment codes', () => {
    expect((toApiError({ message: 'PAYMENT_ALREADY_PAID', code: 'P0001' }) as ApiError).status).toBe(409);
  });
  it('maps RLS / privilege errors to FORBIDDEN', () => {
    expect((toApiError({ message: 'permission denied for table x', code: '42501' }) as ApiError).code).toBe('FORBIDDEN');
  });
  it('keeps unknown errors internal', () => {
    expect(toApiError({ message: 'connection reset', code: '08006' })).not.toBeInstanceOf(ApiError);
  });
});
