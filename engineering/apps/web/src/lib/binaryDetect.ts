// Implements: AC-crp-binary-file-rejected

/**
 * Checks whether an ArrayBuffer contains binary data by scanning
 * the first 8,192 bytes for null (0x00) bytes.
 */
export function isBinary(buffer: ArrayBuffer): boolean {
  const bytes = new Uint8Array(buffer, 0, Math.min(buffer.byteLength, 8192));
  for (let i = 0; i < bytes.length; i++) {
    if (bytes[i] === 0x00) {
      return true;
    }
  }
  return false;
}
