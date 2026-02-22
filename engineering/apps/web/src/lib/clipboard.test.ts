import { describe, it, expect, vi, beforeEach } from 'vitest';
import { copyToClipboard } from './clipboard';

describe('copyToClipboard', () => {
  beforeEach(() => {
    // Reset clipboard mock
    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn(),
      },
    });
    // Reset execCommand mock
    document.execCommand = vi.fn(() => false);
  });

  it('returns true on successful clipboard write', async () => {
    vi.mocked(navigator.clipboard.writeText).mockResolvedValue(undefined);
    const result = await copyToClipboard('hello');
    expect(result).toBe(true);
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('hello');
  });

  it('falls back to execCommand when clipboard API throws', async () => {
    vi.mocked(navigator.clipboard.writeText).mockRejectedValue(new Error('denied'));
    vi.mocked(document.execCommand).mockReturnValue(true);
    const result = await copyToClipboard('fallback text');
    expect(result).toBe(true);
    expect(document.execCommand).toHaveBeenCalledWith('copy');
  });

  it('returns false when both methods fail', async () => {
    vi.mocked(navigator.clipboard.writeText).mockRejectedValue(new Error('denied'));
    vi.mocked(document.execCommand).mockReturnValue(false);
    const result = await copyToClipboard('fail text');
    expect(result).toBe(false);
  });

  it('handles empty string', async () => {
    vi.mocked(navigator.clipboard.writeText).mockResolvedValue(undefined);
    const result = await copyToClipboard('');
    expect(result).toBe(true);
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('');
  });
});
