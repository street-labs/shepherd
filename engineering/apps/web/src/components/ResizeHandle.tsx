// Implements: FR-crp-panel-resize, AC-crp-panel-resize-drag,
// AC-crp-panel-resize-bounds, AC-crp-panel-resize-double-click

import { useAppStore } from '@/store/appStore';
import { useCallback, useRef, useEffect } from 'react';

export function ResizeHandle() {
  const fileBrowserWidth = useAppStore((s) => s.fileBrowserWidth);
  const setFileBrowserWidth = useAppStore((s) => s.setFileBrowserWidth);
  const resetFileBrowserWidth = useAppStore((s) => s.resetFileBrowserWidth);

  const isDragging = useRef(false);
  const rafId = useRef<number | null>(null);
  const handleRef = useRef<HTMLDivElement>(null);
  const isTransitioning = useRef(false);

  const maxWidth = Math.min(window.innerWidth * 0.5, 600);

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    isDragging.current = true;
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';

    const onMouseMove = (e: MouseEvent) => {
      if (!isDragging.current) return;
      if (rafId.current !== null) return; // throttle to one per rAF
      rafId.current = requestAnimationFrame(() => {
        rafId.current = null;
        if (!isDragging.current) return;
        setFileBrowserWidth(e.clientX);
      });
    };

    const onMouseUp = () => {
      isDragging.current = false;
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
      if (rafId.current !== null) {
        cancelAnimationFrame(rafId.current);
        rafId.current = null;
      }
    };

    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onMouseUp);
  }, [setFileBrowserWidth]);

  const handleDoubleClick = useCallback(() => {
    // Add transition class temporarily for smooth reset
    isTransitioning.current = true;
    resetFileBrowserWidth();
    // The transition is handled by the parent via the isResetting state
    setTimeout(() => {
      isTransitioning.current = false;
    }, 150);
  }, [resetFileBrowserWidth]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    switch (e.key) {
      case 'ArrowLeft':
        e.preventDefault();
        setFileBrowserWidth(fileBrowserWidth - 10);
        break;
      case 'ArrowRight':
        e.preventDefault();
        setFileBrowserWidth(fileBrowserWidth + 10);
        break;
      case 'Home':
        e.preventDefault();
        setFileBrowserWidth(180);
        break;
      case 'End':
        e.preventDefault();
        setFileBrowserWidth(maxWidth);
        break;
    }
  }, [fileBrowserWidth, setFileBrowserWidth, maxWidth]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (rafId.current !== null) {
        cancelAnimationFrame(rafId.current);
      }
    };
  }, []);

  return (
    <div
      ref={handleRef}
      role="separator"
      aria-orientation="vertical"
      aria-valuenow={fileBrowserWidth}
      aria-valuemin={180}
      aria-valuemax={maxWidth}
      aria-label="Resize file browser"
      tabIndex={0}
      onMouseDown={handleMouseDown}
      onDoubleClick={handleDoubleClick}
      onKeyDown={handleKeyDown}
      className="absolute right-0 top-0 bottom-0 w-1.5 cursor-col-resize z-10 group focus:outline-none"
    >
      {/* Visual indicator line — visible on hover/focus/drag */}
      <div className="absolute right-0 top-0 bottom-0 w-[3px] bg-transparent group-hover:bg-primary-500 group-focus-visible:bg-primary-500 transition-colors" />
    </div>
  );
}
