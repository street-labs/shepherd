
import { useAppStore } from '@/store/appStore';

/**
 * Two-tab switcher for the sidebar content area: "Preview" and "All Comments (N)".
 */
// Implements: FR-crp-comment-summary
export function SidebarContentTabs() {
  const sidebarTab = useAppStore((s) => s.sidebarTab);
  const setSidebarTab = useAppStore((s) => s.setSidebarTab);
  const viewMode = useAppStore((s) => s.viewMode);
  const fileCommentCount = useAppStore((s) => Object.keys(s.comments).length);
  const diffCommentCount = useAppStore((s) => Object.keys(s.diffComments).length);

  const totalComments = viewMode === 'diff' ? diffCommentCount : fileCommentCount;

  return (
    <div className="flex border-b border-border-default">
      <TabButton
        label="Preview"
        isActive={sidebarTab === 'preview'}
        onClick={() => setSidebarTab('preview')}
      />
      <TabButton
        label={totalComments > 0 ? `All Comments (${totalComments})` : 'All Comments'}
        isActive={sidebarTab === 'comments'}
        onClick={() => setSidebarTab('comments')}
      />
    </div>
  );
}

function TabButton({ label, isActive, onClick }: { label: string; isActive: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={`flex-1 px-3 py-2 text-xs font-medium transition-colors cursor-pointer ${
        isActive
          ? 'text-primary-600 border-b-2 border-primary-500'
          : 'text-text-tertiary hover:text-text-secondary'
      }`}
    >
      {label}
    </button>
  );
}
