import { describe, it, expect } from 'vitest';
import { isBinary } from './binaryDetect';

describe('isBinary', () => {
  it('returns false for an empty buffer', () => {
    const buffer = new ArrayBuffer(0);
    expect(isBinary(buffer)).toBe(false);
  });

  it('returns false for a text-only buffer', () => {
    const text = 'Hello, world!\nLine 2\n';
    const encoder = new TextEncoder();
    const buffer = encoder.encode(text).buffer;
    expect(isBinary(buffer)).toBe(false);
  });

  it('returns true for a buffer with a null byte', () => {
    const bytes = new Uint8Array([72, 101, 108, 0, 111]);
    expect(isBinary(bytes.buffer)).toBe(true);
  });

  it('returns true when null byte is at position 0', () => {
    const bytes = new Uint8Array([0, 72, 101, 108, 108, 111]);
    expect(isBinary(bytes.buffer)).toBe(true);
  });

  it('returns true when null byte is at the scan boundary (position 8191)', () => {
    const bytes = new Uint8Array(8192);
    bytes.fill(65); // Fill with 'A'
    bytes[8191] = 0;
    expect(isBinary(bytes.buffer)).toBe(true);
  });

  it('returns false when null byte is beyond the scan window (position 8192+)', () => {
    const bytes = new Uint8Array(9000);
    bytes.fill(65); // Fill with 'A'
    bytes[8192] = 0;
    expect(isBinary(bytes.buffer)).toBe(false);
  });

  it('returns false for a small text buffer', () => {
    const bytes = new Uint8Array([65, 66, 67]); // "ABC"
    expect(isBinary(bytes.buffer)).toBe(false);
  });
});
