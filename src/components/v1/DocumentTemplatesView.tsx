import React, { useMemo, useRef, useState } from 'react';
import {
  Truck,
  ShoppingCart,
  FileText,
  CheckCircle2,
  Eye,
  Palette,
  Save,
  RefreshCw,
  Upload,
  Trash2,
  ImageIcon,
} from 'lucide-react';
import { Language } from '@/types/v1';
import { useDocumentTemplates } from '@/context/DocumentTemplateContext';
import { useTaxCompliance } from '@/context/TaxComplianceContext';
import {
  DocumentType,
  documentTypeLabel,
  documentTypePurpose,
} from '@/lib/documentTemplates';
import { renderDocumentPreviewHtml, samplePreviewData } from '@/lib/documentRenderer';

interface DocumentTemplatesViewProps {
  language: Language;
}

const DOC_TABS: { id: DocumentType; icon: React.ReactNode }[] = [
  { id: 'delivery_note', icon: <Truck className="w-4 h-4" /> },
  { id: 'order_note', icon: <ShoppingCart className="w-4 h-4" /> },
  { id: 'invoice', icon: <FileText className="w-4 h-4" /> },
];

export const DocumentTemplatesView: React.FC<DocumentTemplatesViewProps> = ({ language }) => {
  const isSw = language === 'sw';
  const { config, setActiveTemplate, updateBranding, uploadLogo, removeLogo, getActive, listForType } = useDocumentTemplates();
  const { settings: taxSettings, updateSettings } = useTaxCompliance();
  const [activeType, setActiveType] = useState<DocumentType>('delivery_note');
  const [previewId, setPreviewId] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [logoError, setLogoError] = useState('');
  const [logoBusy, setLogoBusy] = useState(false);
  const logoInputRef = useRef<HTMLInputElement>(null);

  const templates = listForType(activeType);
  const activeId = config.activeTemplateIds[activeType];
  const previewTpl = templates.find(t => t.id === (previewId ?? activeId)) ?? getActive(activeType);

  const previewHtml = useMemo(() => {
    const data = samplePreviewData(activeType);
    data.showDiscount = taxSettings.showDiscountOnDocuments && taxSettings.discountEnabled;
    return renderDocumentPreviewHtml(previewTpl, data, config.branding, isSw);
  }, [activeType, previewTpl, config.branding, isSw, taxSettings]);

  const handleSaveBranding = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const handleLogoPick = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;
    setLogoError('');
    setLogoBusy(true);
    try {
      await uploadLogo(file);
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch (err) {
      setLogoError(err instanceof Error ? err.message : 'Failed to upload logo');
    } finally {
      setLogoBusy(false);
    }
  };

  const handleRemoveLogo = async () => {
    setLogoError('');
    setLogoBusy(true);
    try {
      await removeLogo();
    } catch (err) {
      setLogoError(err instanceof Error ? err.message : 'Failed to remove logo');
    } finally {
      setLogoBusy(false);
    }
  };

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="bg-white rounded-xl border border-[#E1DFDD] p-6 shadow-xs">
        <h3 className="text-lg font-bold text-[#323130] flex items-center gap-2">
          {activeType === 'delivery_note' && <Truck className="w-5 h-5 text-teal-600" />}
          {activeType === 'order_note' && <ShoppingCart className="w-5 h-5 text-orange-600" />}
          {activeType === 'invoice' && <FileText className="w-5 h-5 text-blue-600" />}
          {documentTypeLabel(activeType, isSw)} {isSw ? '— Violezo' : 'Template'}
        </h3>
        <p className="text-xs text-[#605E5C] mt-1">
          {documentTypePurpose(activeType, isSw)}
        </p>
        <p className="text-[11px] text-[#605E5C] mt-2">
          <strong>{isSw ? 'Sehemu:' : 'Sections:'}</strong>{' '}
          {isSw
            ? 'Kichwa, maelezo ya mteja, jedwali la bidhaa, jumla, saini.'
            : 'Header, customer details, line items, totals, signature.'}
        </p>
      </div>

      {/* Document type tabs */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {DOC_TABS.map(tab => (
          <button
            key={tab.id}
            type="button"
            onClick={() => { setActiveType(tab.id); setPreviewId(null); }}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all cursor-pointer ${
              activeType === tab.id
                ? 'bg-[#6264A7] text-white shadow-sm'
                : 'bg-white border border-[#E1DFDD] text-[#605E5C] hover:bg-[#F3F2F1]'
            }`}
          >
            {tab.icon}
            {documentTypeLabel(tab.id, isSw)}
          </button>
        ))}
      </div>

      {/* Template gallery — 4 cards like Copilot images */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {templates.map(tpl => {
          const isActive = tpl.id === activeId;
          const isPreviewing = tpl.id === (previewId ?? activeId);
          return (
            <div
              key={tpl.id}
              className={`rounded-2xl p-3 transition-all cursor-pointer ${
                isActive ? 'ring-2 ring-[#6264A7] ring-offset-2' : 'hover:shadow-md'
              }`}
              style={{ backgroundColor: tpl.theme.cardBg }}
              onClick={() => setPreviewId(tpl.id)}
            >
              <div
                className="rounded-xl overflow-hidden bg-white shadow-sm min-h-[180px] pointer-events-none"
                dangerouslySetInnerHTML={{
                  __html: renderDocumentPreviewHtml(
                    tpl,
                    { ...samplePreviewData(activeType), showDiscount: taxSettings.showDiscountOnDocuments },
                    config.branding,
                    isSw,
                  ),
                }}
              />
              <div className="mt-3 px-1">
                <div className="text-xs font-bold text-[#323130]">
                  {isSw ? tpl.nameSw : tpl.name}
                </div>
                <div className="text-[10px] text-[#605E5C] mt-0.5 line-clamp-2">
                  {isSw ? tpl.descriptionSw : tpl.description}
                </div>
                <div className="flex gap-2 mt-2">
                  <button
                    type="button"
                    onClick={e => { e.stopPropagation(); setPreviewId(tpl.id); }}
                    className="flex-1 py-1.5 rounded-lg bg-white/80 border border-[#E1DFDD] text-[10px] font-bold flex items-center justify-center gap-1 hover:bg-white cursor-pointer"
                  >
                    <Eye className="w-3 h-3" /> {isSw ? 'Angalia' : 'Preview'}
                  </button>
                  <button
                    type="button"
                    onClick={e => { e.stopPropagation(); setActiveTemplate(activeType, tpl.id); }}
                    className={`flex-1 py-1.5 rounded-lg text-[10px] font-bold flex items-center justify-center gap-1 cursor-pointer ${
                      isActive
                        ? 'bg-[#107C10] text-white'
                        : 'bg-[#6264A7] text-white hover:bg-[#555793]'
                    }`}
                  >
                    {isActive ? <CheckCircle2 className="w-3 h-3" /> : null}
                    {isActive ? (isSw ? 'Inatumika' : 'Active') : (isSw ? 'Chagua' : 'Use')}
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Live preview + branding */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="bg-white rounded-xl border border-[#E1DFDD] p-5 shadow-xs">
          <h4 className="text-sm font-bold text-[#323130] flex items-center gap-2 mb-4">
            <Eye className="w-4 h-4 text-[#6264A7]" />
            {isSw ? 'Onyesho la Moja kwa Moja' : 'Live Preview'}
          </h4>
          <div
            className="overflow-auto max-h-[420px] rounded-xl bg-[#F8F8F8] p-4"
            dangerouslySetInnerHTML={{ __html: previewHtml }}
          />
        </div>

        <div className="space-y-5">
          {/* Branding */}
          <div className="bg-white rounded-xl border border-[#E1DFDD] p-5 shadow-xs space-y-3">
            <h4 className="text-sm font-bold text-[#323130] flex items-center gap-2">
              <Palette className="w-4 h-4 text-[#6264A7]" />
              {isSw ? 'Chapa & Branding' : 'Branding Configuration'}
            </h4>

            {/* Logo upload */}
            <div>
              <label className="block text-[11px] font-semibold text-[#323130] mb-2">
                {isSw ? 'Nembo / Logo' : 'Business Logo'}
              </label>
              <div className="flex items-center gap-3 p-3 rounded-xl bg-[#F8F8F8] border border-[#E1DFDD]">
                <div className="w-16 h-16 rounded-xl bg-white border border-[#E1DFDD] flex items-center justify-center overflow-hidden shrink-0">
                  {config.branding.logoUrl ? (
                    <img src={config.branding.logoUrl} alt="Logo" className="max-w-full max-h-full object-contain" />
                  ) : (
                    <ImageIcon className="w-6 h-6 text-[#C8C6C4]" />
                  )}
                </div>
                <div className="flex-1 space-y-2">
                  <input
                    ref={logoInputRef}
                    type="file"
                    accept="image/png,image/jpeg,image/webp,image/gif"
                    className="hidden"
                    onChange={handleLogoPick}
                  />
                  <button
                    type="button"
                    disabled={logoBusy}
                    onClick={() => logoInputRef.current?.click()}
                    className="w-full py-2 rounded-lg bg-white border border-[#C8C6C4] text-xs font-bold flex items-center justify-center gap-2 hover:bg-[#F3F2F1] cursor-pointer disabled:opacity-60"
                  >
                    <Upload className="w-3.5 h-3.5" />
                    {logoBusy ? (isSw ? 'Inapakia...' : 'Uploading...') : (isSw ? 'Pakia Logo' : 'Upload Logo')}
                  </button>
                  {config.branding.logoUrl && (
                    <button
                      type="button"
                      disabled={logoBusy}
                      onClick={handleRemoveLogo}
                      className="w-full py-1.5 rounded-lg text-[11px] font-semibold text-rose-600 flex items-center justify-center gap-1 hover:bg-rose-50 cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      {isSw ? 'Ondoa Logo' : 'Remove Logo'}
                    </button>
                  )}
                  <p className="text-[10px] text-[#605E5C]">
                    {isSw ? 'PNG, JPG, WEBP au GIF — hadi 500 KB' : 'PNG, JPG, WEBP or GIF — max 500 KB'}
                  </p>
                  {logoError && <p className="text-[10px] text-rose-600 font-semibold">{logoError}</p>}
                </div>
              </div>
            </div>

            {[
              { key: 'companyName' as const, label: isSw ? 'Jina la biashara' : 'Company name' },
              { key: 'address' as const, label: isSw ? 'Anwani' : 'Address' },
              { key: 'phone' as const, label: isSw ? 'Simu' : 'Phone' },
              { key: 'tinNumber' as const, label: 'TIN' },
              { key: 'footerText' as const, label: isSw ? 'Maelezo ya chini (footer)' : 'Footer text' },
            ].map(field => (
              <div key={field.key}>
                <label className="block text-[11px] font-semibold text-[#323130] mb-1">{field.label}</label>
                <input
                  type="text"
                  value={config.branding[field.key] ?? ''}
                  onChange={e => updateBranding({ [field.key]: e.target.value })}
                  className="w-full px-3 py-2 bg-[#F8F8F8] border border-[#C8C6C4] rounded-lg text-xs"
                />
              </div>
            ))}
            <button
              type="button"
              onClick={handleSaveBranding}
              className="w-full py-2.5 rounded-xl bg-[#6264A7] text-white text-xs font-bold flex items-center justify-center gap-2 cursor-pointer hover:bg-[#555793]"
            >
              {saved ? <CheckCircle2 className="w-4 h-4" /> : <Save className="w-4 h-4" />}
              {saved ? (isSw ? 'Imehifadhiwa!' : 'Saved!') : (isSw ? 'Hifadhi Branding' : 'Save Branding')}
            </button>
          </div>

          {/* Discount on documents */}
          <div className="bg-white rounded-xl border border-[#E1DFDD] p-5 shadow-xs space-y-3">
            <h4 className="text-sm font-bold text-[#323130]">
              {isSw ? 'Punguzo kwenye Hati' : 'Discount on Documents'}
            </h4>
            <label className="flex items-center gap-2 text-xs font-semibold text-[#323130]">
              <input
                type="checkbox"
                checked={taxSettings.discountEnabled}
                onChange={e => updateSettings({ discountEnabled: e.target.checked })}
                className="rounded text-[#0078D4]"
              />
              {isSw ? 'Ruhusu punguzo (POS & hati)' : 'Allow discounts (POS & documents)'}
            </label>
            {taxSettings.discountEnabled && (
              <>
                <label className="flex items-center gap-2 text-xs font-semibold text-[#323130]">
                  <input
                    type="checkbox"
                    checked={taxSettings.showDiscountOnDocuments}
                    onChange={e => updateSettings({ showDiscountOnDocuments: e.target.checked })}
                    className="rounded text-[#0078D4]"
                  />
                  {isSw ? 'Onyesha punguzo kwenye ankara/noti' : 'Show discount line on invoices & notes'}
                </label>
                <label className="flex items-center gap-2 text-xs font-semibold text-[#323130]">
                  <input
                    type="checkbox"
                    checked={taxSettings.showDiscountOnReceipts}
                    onChange={e => updateSettings({ showDiscountOnReceipts: e.target.checked })}
                    className="rounded text-[#0078D4]"
                  />
                  {isSw ? 'Onyesha punguzo kwenye risiti za POS' : 'Show discount on POS receipts'}
                </label>
                <div>
                  <label className="block text-[11px] font-semibold text-[#323130] mb-1">
                    {isSw ? 'Kikomo cha punguzo (%)' : 'Max discount (%)'}
                  </label>
                  <input
                    type="number"
                    min={0}
                    max={100}
                    value={taxSettings.maxDiscountPercent}
                    onChange={e => updateSettings({ maxDiscountPercent: Number(e.target.value) })}
                    className="w-full px-3 py-2 bg-[#F8F8F8] border border-[#C8C6C4] rounded-lg text-xs"
                  />
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2 text-[11px] text-[#605E5C]">
        <RefreshCw className="w-3.5 h-3.5" />
        {isSw
          ? 'Violezo 4 vya chaguo-msingi kwa kila aina ya hati. Mabadiliko yanatumika mara moja kwenye POS, ripoti, na PDF.'
          : '4 default templates per document type. Changes apply instantly to POS, reports, and PDF exports.'}
      </div>
    </div>
  );
};
