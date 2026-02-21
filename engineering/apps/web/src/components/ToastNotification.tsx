// Implements: AC-crp-copy-clipboard

import { useAppStore } from '@/store/appStore';
import { useEffect } from 'react';
import { createPortal } from 'react-dom';

const AUTO_DISMISS_MS = 3000;

export function ToastNotification() {
  const toast = useAppStore((s) => s.toast);
  const dismissToast = useAppStore((s) => s.dismissToast);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(dismissToast, AUTO_DISMISS_MS);
    return () => clearTimeout(timer);
  }, [toast, dismissToast]);

  if (!toast) return null;

  return createPortal(
    <div
      className={`fixed bottom-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg text-sm font-medium animate-slide-up ${
        toast.type === 'success'
          ? 'bg-green-600 text-white'
          : 'bg-destructive-500 text-white'
      }`}
      role="status"
      aria-live="polite"
    >
      {toast.message}
    </div>,
    document.body,
  );
}
