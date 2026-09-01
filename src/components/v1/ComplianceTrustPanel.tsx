import React, { useState } from 'react';
import {
  ShieldCheck,
  Save,
  RefreshCw,
  CheckCircle2,
  AlertCircle,
  Receipt,
  ShoppingBag,
  Boxes,
  FileText,
} from 'lucide-react';
import { Language } from '@/types/v1';
import { useTaxCompliance } from '@/context/TaxComplianceContext';
import { TaxComplianceSettings } from '@/lib/taxComplianceSettings';

interface ComplianceTrustPanelProps {
  language: Language;
  businessName?: string;
  tinNumber?: string;
}

export const ComplianceTrustPanel: React.FC<ComplianceTrustPanelProps> = ({
  language,
  businessName,
  tinNumber,
}) => {
  const isSw = language === 'sw';
  const { settings, applySettings } = useTaxCompliance();
  const [draft, setDraft] = useState<TaxComplianceSettings>(() => ({
    ...settings,
    receiptBusinessName: settings.receiptBusinessName || businessName || '',
    tinNumber: settings.tinNumber || tinNumber || '',
  }));
  const [saved, setSaved] = useState(false);

  const patch = (partial: Partial<TaxComplianceSettings>) => {
    setDraft(prev => ({ ...prev, ...partial }));
    setSaved(false);
  };

  const handleApply = () => {
    applySettings({
      ...draft,
      vatRate: Math.min(Math.max(draft.vatRate, 0), 1),
      maxDiscountPercent: Math.min(Math.max(draft.maxDiscountPercent, 0), 100),
    });
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  const isTra = draft.mode === 'tra_efd';

  return (
    <div className="space-y-5">
      <div className="bg-white rounded-xl border border-[#E1DFDD] p-6 shadow-xs space-y-4">
        <div className="border-b border-[#EDEBE9] pb-4">
          <h3 className="text-base font-bold text-[#323130] flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-[#6264A7]" />
            {isSw ? 'Usimamizi wa Kodi & TRA (Ukurasa wa Uaminifu)' : 'Tax & TRA Trust Configuration'}
          </h3>
          <p className="text-xs text-[#605E5C] mt-1">
            {isSw
              ? 'Chagua TRA EFD halisi au hali ya kawaida. Mabadiliko yanatumika mara moja kwenye POS, risiti, na ripoti.'
              : 'Choose real TRA EFD integration or manual mode. Changes apply instantly across POS, receipts, and reports.'}
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <button
            type="button"
            onClick={() => patch({ mode: 'manual', showTraSignature: false })}
            className={`p-4 rounded-xl border text-left transition-all cursor-pointer ${
              draft.mode === 'manual'
                ? 'border-[#6264A7] bg-[#6264A7]/5 ring-2 ring-[#6264A7]/20'
                : 'border-[#EDEBE9] hover:border-[#C8C6C4]'
            }`}
          >
            <div className="text-sm font-bold text-[#323130]">
              {isSw ? 'Hali ya Kawaida (Manual)' : 'Manual / Normal Mode'}
            </div>
            <p className="text-[11px] text-[#605E5C] mt-1">
              {isSw
                ? 'Risiti za ndani, VAT hiari, punguzo rahisi — bila saini ya TRA.'
                : 'Internal receipts, optional VAT, simple discounts — no TRA signature.'}
            </p>
          </button>

          <button
            type="button"
            onClick={() => patch({ mode: 'tra_efd', showTraSignature: true, vatEnabled: true })}
            className={`p-4 rounded-xl border text-left transition-all cursor-pointer ${
              draft.mode === 'tra_efd'
                ? 'border-[#0078D4] bg-blue-50/60 ring-2 ring-[#0078D4]/20'
                : 'border-[#EDEBE9] hover:border-[#C8C6C4]'
            }`}
          >
            <div className="text-sm font-bold text-[#323130]">
              {isSw ? 'TRA EFD Halisi (VFD 2.0)' : 'Real TRA EFD (VFD 2.0)'}
            </div>
            <p className="text-[11px] text-[#605E5C] mt-1">
              {isSw
                ? 'Saini ya TRA, nambari ya kifaa, TIN/VRN kwenye kila risiti rasmi.'
                : 'TRA signature, device serial, TIN/VRN on every official receipt.'}
            </p>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="bg-white rounded-xl border border-[#E1DFDD] p-5 shadow-xs space-y-4">
          <h4 className="text-sm font-bold text-[#323130]">
            {isSw ? 'VAT & Punguzo' : 'VAT & Discounts'}
          </h4>

          <label className="flex items-center gap-2 text-xs font-semibold text-[#323130]">
            <input
              type="checkbox"
              checked={draft.vatEnabled}
              onChange={e => patch({ vatEnabled: e.target.checked })}
              className="rounded text-[#0078D4]"
            />
            {isSw ? 'Weka VAT kwenye mauzo' : 'Apply VAT on sales'}
          </label>

          <div>
            <label className="block text-xs font-semibold text-[#323130] mb-1">
              {isSw ? 'Kiwango cha VAT (%)' : 'VAT rate (%)'}
            </label>
            <input
              type="number"
              min={0}
              max={100}
              step={0.5}
              value={Math.round(draft.vatRate * 1000) / 10}
              onChange={e => patch({ vatRate: Number(e.target.value) / 100 })}
              className="w-full px-3 py-2 bg-[#F8F8F8] border border-[#C8C6C4] rounded-lg text-xs"
            />
          </div>

          <label className="flex items-center gap-2 text-xs font-semibold text-[#323130]">
            <input
              type="checkbox"
              checked={draft.pricesIncludeVat}
              onChange={e => patch({ pricesIncludeVat: e.target.checked })}
              className="rounded text-[#0078D4]"
            />
            {isSw ? 'Bei zilizo kwenye stoo zimejumuisha VAT' : 'Shelf prices already include VAT'}
          </label>

          <label className="flex items-center gap-2 text-xs font-semibold text-[#323130]">
            <input
              type="checkbox"
              checked={draft.discountEnabled}
              onChange={e => patch({ discountEnabled: e.target.checked })}
              className="rounded text-[#0078D4]"
            />
            {isSw ? 'Ruhusu punguzo kwenye POS' : 'Allow discounts at POS'}
          </label>

          {draft.discountEnabled && (
            <div>
              <label className="block text-xs font-semibold text-[#323130] mb-1">
                {isSw ? 'Kikomo cha punguzo (%)' : 'Max discount (%)'}
              </label>
              <input
                type="number"
                min={0}
                max={100}
                value={draft.maxDiscountPercent}
                onChange={e => patch({ maxDiscountPercent: Number(e.target.value) })}
                className="w-full px-3 py-2 bg-[#F8F8F8] border border-[#C8C6C4] rounded-lg text-xs"
              />
            </div>
          )}

          <label className="flex items-center gap-2 text-xs font-semibold text-[#323130]">
            <input
              type="checkbox"
              checked={draft.showDiscountOnReceipts}
              onChange={e => patch({ showDiscountOnReceipts: e.target.checked })}
              disabled={!draft.discountEnabled}
              className="rounded text-[#0078D4] disabled:opacity-40"
            />
            {isSw ? 'Onyesha punguzo kwenye risiti za POS' : 'Show discount on POS receipts'}
          </label>

          <label className="flex items-center gap-2 text-xs font-semibold text-[#323130]">
            <input
              type="checkbox"
              checked={draft.showDiscountOnDocuments}
              onChange={e => patch({ showDiscountOnDocuments: e.target.checked })}
              disabled={!draft.discountEnabled}
              className="rounded text-[#0078D4] disabled:opacity-40"
            />
            {isSw ? 'Onyesha punguzo kwenye ankara & noti' : 'Show discount on invoices & notes'}
          </label>
        </div>

        <div className="bg-white rounded-xl border border-[#E1DFDD] p-5 shadow-xs space-y-4">
          <h4 className="text-sm font-bold text-[#323130]">
            {isSw ? 'Taarifa za Risiti' : 'Receipt Identity'}
          </h4>

          <div>
            <label className="block text-xs font-semibold text-[#323130] mb-1">
              {isSw ? 'Jina la biashara kwenye risiti' : 'Business name on receipt'}
            </label>
            <input
              type="text"
              value={draft.receiptBusinessName}
              onChange={e => patch({ receiptBusinessName: e.target.value })}
              className="w-full px-3 py-2 bg-[#F8F8F8] border border-[#C8C6C4] rounded-lg text-xs"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-[#323130] mb-1">TIN</label>
              <input
                type="text"
                value={draft.tinNumber}
                onChange={e => patch({ tinNumber: e.target.value })}
                placeholder="108-992-451"
                className="w-full px-3 py-2 bg-[#F8F8F8] border border-[#C8C6C4] rounded-lg text-xs font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#323130] mb-1">VRN</label>
              <input
                type="text"
                value={draft.vrnNumber}
                onChange={e => patch({ vrnNumber: e.target.value })}
                placeholder="40019283-Z"
                className="w-full px-3 py-2 bg-[#F8F8F8] border border-[#C8C6C4] rounded-lg text-xs font-mono"
              />
            </div>
          </div>

          {isTra && (
            <div>
              <label className="block text-xs font-semibold text-[#323130] mb-1">
                {isSw ? 'Serial ya TRA EFD' : 'TRA EFD device serial'}
              </label>
              <input
                type="text"
                value={draft.traEfdSerial}
                onChange={e => patch({ traEfdSerial: e.target.value })}
                placeholder="TZ-EFD-2026-8819"
                className="w-full px-3 py-2 bg-[#F8F8F8] border border-[#C8C6C4] rounded-lg text-xs font-mono"
              />
            </div>
          )}

          <div>
            <label className="block text-xs font-semibold text-[#323130] mb-1">
              {isSw ? 'Maelezo ya chini ya risiti' : 'Receipt footer note'}
            </label>
            <textarea
              rows={2}
              value={draft.receiptFooterNote}
              onChange={e => patch({ receiptFooterNote: e.target.value })}
              className="w-full px-3 py-2 bg-[#F8F8F8] border border-[#C8C6C4] rounded-lg text-xs resize-none"
            />
          </div>

          <label className="flex items-center gap-2 text-xs font-semibold text-[#323130]">
            <input
              type="checkbox"
              checked={draft.showVatOnReceipt}
              onChange={e => patch({ showVatOnReceipt: e.target.checked })}
              className="rounded text-[#0078D4]"
            />
            {isSw ? 'Onyesha VAT kwenye risiti' : 'Show VAT line on receipt'}
          </label>
        </div>
      </div>

      <div className="bg-[#F8F9FC] rounded-xl border border-[#EDEBE9] p-4">
        <div className="text-xs font-bold text-[#323130] mb-2">
          {isSw ? 'Inatumika mara moja kwenye:' : 'Applies instantly to:'}
        </div>
        <div className="flex flex-wrap gap-2">
          {[
            { icon: ShoppingBag, label: 'POS' },
            { icon: Receipt, label: isSw ? 'Risiti' : 'Receipts' },
            { icon: Boxes, label: isSw ? 'Stoo' : 'Inventory' },
            { icon: FileText, label: isSw ? 'Ripoti' : 'Reports' },
          ].map(({ icon: Icon, label }) => (
            <span
              key={label}
              className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-white border border-[#E1DFDD] text-[11px] font-semibold text-[#605E5C]"
            >
              <Icon className="w-3.5 h-3.5 text-[#6264A7]" />
              {label}
            </span>
          ))}
        </div>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="text-xs text-[#605E5C] flex items-center gap-2">
          {isTra ? (
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
          ) : (
            <AlertCircle className="w-4 h-4 text-amber-600" />
          )}
          <span>
            {isTra
              ? (isSw ? 'Hali ya TRA EFD — risiti zitaonyesha saini na TIN.' : 'TRA EFD mode — receipts will show signature and TIN.')
              : (isSw ? 'Hali ya kawaida — hakuna usajili wa TRA EFD.' : 'Manual mode — no TRA EFD registration on receipts.')}
          </span>
        </div>

        <button
          type="button"
          onClick={handleApply}
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-[#6264A7] to-[#0078D4] text-white text-xs font-bold shadow-xs hover:brightness-105 cursor-pointer"
        >
          {saved ? (
            <>
              <CheckCircle2 className="w-4 h-4" />
              {isSw ? 'Imewekwa & Inatumika!' : 'Applied & Live!'}
            </>
          ) : (
            <>
              <Save className="w-4 h-4" />
              {isSw ? 'Weka & Tumia Mara Moja' : 'Save & Apply Instantly'}
            </>
          )}
        </button>
      </div>
    </div>
  );
};
