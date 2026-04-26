
export function DiffLoadingState() {
  // Implements: FR-diff-baseline-fetch
  return (
    <div className="flex flex-col items-center justify-center h-full gap-2">
      <div className="w-5 h-5 border-2 border-primary-500 border-t-transparent rounded-full animate-spin" />
      <p className="text-sm text-text-secondary">Loading baseline...</p>
    </div>
  );
}
