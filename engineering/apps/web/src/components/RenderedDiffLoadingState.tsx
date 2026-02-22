// Implements: FR-mr-rendered-diff

export function RenderedDiffLoadingState() {
  return (
    <div className="flex-1 flex flex-col items-center justify-center gap-3 text-text-secondary">
      <div className="w-5 h-5 border-2 border-primary-500 border-t-transparent rounded-full animate-spin" />
      <p className="text-sm">Computing rendered diff...</p>
    </div>
  );
}
