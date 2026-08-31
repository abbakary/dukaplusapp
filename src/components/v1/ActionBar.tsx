import React from 'react';
import { 
  Plus, 
  Pencil, 
  Eye, 
  Trash2, 
  Copy, 
  Download, 
  Sparkles,
  RefreshCw,
  SlidersHorizontal
} from 'lucide-react';
import { Language } from '@/types/v1';
import { getTranslation } from '@/utils/translations';

interface ActionBarProps {
  language: Language;
  onAdd?: () => void;
  onEdit?: () => void;
  onView?: () => void;
  onDelete?: () => void;
  onCopy?: () => void;
  onExport?: () => void;
  onAISuggest?: () => void;
  customAddLabel?: string;
  selectedCount?: number;
  totalCount?: number;
  lastUpdatedText?: string;
}

export const ActionBar: React.FC<ActionBarProps> = ({
  language,
  onAdd,
  onEdit,
  onView,
  onDelete,
  onCopy,
  onExport,
  onAISuggest,
  customAddLabel,
  selectedCount = 0,
  totalCount = 342,
  lastUpdatedText = 'Today, 14:30',
}) => {
  const t = (key: any) => getTranslation(language, key);

  return (
    <div className="w-full bg-white border border-[#E1DFDD] rounded-xl p-3 shadow-xs space-y-2">
      {/* 12-Column Responsive Full-Width Action Button Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-7 gap-2">
        {/* ADD / PRIMARY */}
        <button
          id="action-btn-add"
          onClick={onAdd}
          className="flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-[#6264A7] hover:bg-[#555793] text-white font-semibold text-xs transition-all active:scale-[0.98] shadow-xs cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>{customAddLabel || t('add')}</span>
        </button>

        {/* EDIT */}
        <button
          id="action-btn-edit"
          onClick={onEdit}
          disabled={selectedCount === 0}
          className={`flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg border font-medium text-xs transition-all ${
            selectedCount > 0
              ? 'bg-white hover:bg-[#F3F2F1] text-[#323130] border-[#C8C6C4] shadow-xs active:scale-[0.98] cursor-pointer'
              : 'bg-[#F3F2F1] text-[#A19F9D] border-[#EDEBE9] cursor-not-allowed'
          }`}
        >
          <Pencil className="w-3.5 h-3.5 text-[#0078D4]" />
          <span>{t('edit')}</span>
        </button>

        {/* VIEW */}
        <button
          id="action-btn-view"
          onClick={onView}
          disabled={selectedCount === 0}
          className={`flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg border font-medium text-xs transition-all ${
            selectedCount > 0
              ? 'bg-white hover:bg-[#F3F2F1] text-[#323130] border-[#C8C6C4] shadow-xs active:scale-[0.98] cursor-pointer'
              : 'bg-[#F3F2F1] text-[#A19F9D] border-[#EDEBE9] cursor-not-allowed'
          }`}
        >
          <Eye className="w-3.5 h-3.5 text-[#6264A7]" />
          <span>{t('view')}</span>
        </button>

        {/* DELETE */}
        <button
          id="action-btn-delete"
          onClick={onDelete}
          disabled={selectedCount === 0}
          className={`flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg border font-medium text-xs transition-all ${
            selectedCount > 0
              ? 'bg-white hover:bg-rose-50 text-[#D13438] border-rose-200 shadow-xs active:scale-[0.98] cursor-pointer'
              : 'bg-[#F3F2F1] text-[#A19F9D] border-[#EDEBE9] cursor-not-allowed'
          }`}
        >
          <Trash2 className="w-3.5 h-3.5 text-[#D13438]" />
          <span>{t('delete')}</span>
        </button>

        {/* COPY */}
        <button
          id="action-btn-copy"
          onClick={onCopy}
          disabled={selectedCount === 0}
          className={`flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg border font-medium text-xs transition-all ${
            selectedCount > 0
              ? 'bg-white hover:bg-[#F3F2F1] text-[#323130] border-[#C8C6C4] shadow-xs active:scale-[0.98] cursor-pointer'
              : 'bg-[#F3F2F1] text-[#A19F9D] border-[#EDEBE9] cursor-not-allowed'
          }`}
        >
          <Copy className="w-3.5 h-3.5 text-[#605E5C]" />
          <span>{t('copy')}</span>
        </button>

        {/* EXPORT */}
        <button
          id="action-btn-export"
          onClick={onExport}
          className="flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-white hover:bg-[#F3F2F1] text-[#323130] border border-[#C8C6C4] font-medium text-xs shadow-xs active:scale-[0.98] transition-all cursor-pointer"
        >
          <Download className="w-3.5 h-3.5 text-[#107C10]" />
          <span>{t('export')}</span>
        </button>

        {/* AI INSIGHTS */}
        <button
          id="action-btn-ai"
          onClick={onAISuggest}
          className="col-span-2 sm:col-span-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-gradient-to-r from-[#0078D4] to-[#6264A7] hover:brightness-105 text-white font-semibold text-xs shadow-xs active:scale-[0.98] transition-all cursor-pointer"
        >
          <Sparkles className="w-3.5 h-3.5 text-amber-200" />
          <span>{t('aiSuggest')}</span>
        </button>
      </div>

      {/* Status Bar */}
      <div className="flex items-center justify-between text-[11px] text-[#605E5C] pt-1 px-1 border-t border-[#F3F2F1]">
        <div>
          {selectedCount > 0 ? (
            <span className="font-semibold text-[#0078D4]">{selectedCount} item(s) selected</span>
          ) : (
            <span>Showing active records (Total: {totalCount})</span>
          )}
        </div>
        <div>Last updated: {lastUpdatedText}</div>
      </div>
    </div>
  );
};
