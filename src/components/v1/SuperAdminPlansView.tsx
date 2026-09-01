import React, { useCallback, useEffect, useState } from 'react';
import { Save, RotateCcw, Loader2, Users } from 'lucide-react';
import { Language } from '@/types/v1';
import { useSaasPlans } from '@/context/SaasPlansContext';
import { formatPlanPrice, planPeriod, PublicPlan } from '@/lib/saasPlans';

interface Props {
  language: Language;
}

function featuresToText(list: string[]): string {
  return list.join('\n');
}

function textToFeatures(text: string): string[] {
  return text.split('\n').map(s => s.trim()).filter(Boolean);
}

export const SuperAdminPlansView: React.FC<Props> = ({ language }) => {
  const isSw = language === 'sw';
  const { plans, updatePlan, resetPlans, refreshPlans, loading } = useSaasPlans();
  const [drafts, setDrafts] = useState<Record<string, PublicPlan>>({});
  const [savingId, setSavingId] = useState<string | null>(null);
  const [savedId, setSavedId] = useState<string | null>(null);

  useEffect(() => {
    const next: Record<string, PublicPlan> = {};
    plans.forEach(p => { next[p.id] = { ...p }; });
    setDrafts(next);
  }, [plans]);

  const patchDraft = (id: string, patch: Partial<PublicPlan>) => {
    setDrafts(prev => ({ ...prev, [id]: { ...prev[id], ...patch } }));
  };

  const savePlan = useCallback(async (id: string) => {
    const draft = drafts[id];
    if (!draft) return;
    setSavingId(id);
    try {
      await updatePlan(id, {
        name: draft.name,
        nameSw: draft.nameSw,
        tagEn: draft.tagEn,
        tagSw: draft.tagSw,
        priceMonthlyTzs: draft.priceMonthlyTzs,
        priceYearlyTzs: draft.priceYearlyTzs,
        maxBranches: draft.maxBranches,
        maxStaff: draft.maxStaff,
        maxProducts: draft.maxProducts,
        features: draft.features,
        featuresSw: draft.featuresSw,
        contactUs: draft.contactUs,
        popular: draft.popular,
      });
      setSavedId(id);
      setTimeout(() => setSavedId(null), 2000);
    } finally {
      setSavingId(null);
    }
  }, [drafts, updatePlan]);

  return (
    <div className="space-y-6 pb-10">
      <header className="flex flex-wrap justify-between gap-4 items-start">
        <div>
          <p className="text-[10px] font-black uppercase tracking-widest text-[#D4AF37]">
            {isSw ? 'VIFURUSHI & BEI' : 'PLANS & PRICING'}
          </p>
          <h1 className="text-2xl font-serif font-bold text-[#003322]">
            {isSw ? 'Simamia vifurushi' : 'Manage subscription packages'}
          </h1>
          <p className="text-sm text-slate-600 mt-1">
            {isSw
              ? 'Mabadiliko yanaonekana mara moja kwenye ukurasa wa mwanzo na usajili.'
              : 'Changes apply instantly to the landing page and registration flow.'}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => void refreshPlans()}
            className="inline-flex items-center gap-1 px-3 py-2 rounded-xl border text-xs font-bold cursor-pointer bg-white"
          >
            {loading ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : null}
            {isSw ? 'Onyesha upya' : 'Refresh'}
          </button>
          <button
            type="button"
            onClick={() => void resetPlans()}
            className="inline-flex items-center gap-1 px-3 py-2 rounded-xl border text-xs font-bold cursor-pointer bg-white"
          >
            <RotateCcw className="w-3.5 h-3.5" /> {isSw ? 'Rejesha chaguo-msingi' : 'Reset defaults'}
          </button>
        </div>
      </header>

      <div className="grid lg:grid-cols-3 gap-5">
        {plans.map(plan => {
          const draft = drafts[plan.id] ?? plan;
          return (
            <div
              key={plan.id}
              className={`bg-white rounded-2xl border p-5 space-y-3 flex flex-col ${draft.popular ? 'border-[#0d9488] ring-2 ring-teal-500/20' : 'border-slate-200'}`}
            >
              <div className="flex items-center justify-between gap-2">
                {draft.popular ? (
                  <span className="text-[10px] font-black px-2 py-0.5 rounded-full bg-[#0d9488] text-white">
                    {isSw ? 'Maarufu' : 'Popular'}
                  </span>
                ) : <span />}
                <span className="text-[10px] text-slate-400 flex items-center gap-1">
                  <Users className="w-3 h-3" />
                  {plan.activeSubscribersCount ?? 0} {isSw ? 'wateja' : 'subscribers'}
                </span>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase">EN {isSw ? 'jina' : 'name'}</label>
                  <input
                    value={draft.name}
                    onChange={e => patchDraft(plan.id, { name: e.target.value })}
                    className="w-full mt-0.5 px-2 py-1.5 border rounded-lg text-sm font-semibold"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase">SW {isSw ? 'jina' : 'name'}</label>
                  <input
                    value={draft.nameSw}
                    onChange={e => patchDraft(plan.id, { nameSw: e.target.value })}
                    className="w-full mt-0.5 px-2 py-1.5 border rounded-lg text-sm font-semibold"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase">{isSw ? 'Maelezo EN' : 'Tag EN'}</label>
                  <input
                    value={draft.tagEn}
                    onChange={e => patchDraft(plan.id, { tagEn: e.target.value })}
                    className="w-full mt-0.5 px-2 py-1.5 border rounded-lg text-xs"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase">{isSw ? 'Maelezo SW' : 'Tag SW'}</label>
                  <input
                    value={draft.tagSw}
                    onChange={e => patchDraft(plan.id, { tagSw: e.target.value })}
                    className="w-full mt-0.5 px-2 py-1.5 border rounded-lg text-xs"
                  />
                </div>
              </div>

              <label className="flex items-center gap-2 text-xs font-semibold cursor-pointer">
                <input
                  type="checkbox"
                  checked={draft.contactUs ?? false}
                  onChange={e => patchDraft(plan.id, { contactUs: e.target.checked })}
                />
                {isSw ? 'Bei maalum — wasiliana (Enterprise)' : 'Custom pricing — contact us'}
              </label>

              {!draft.contactUs && (
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="text-[10px] font-bold text-slate-500 uppercase">{isSw ? 'Bei/mwezi (TZS)' : 'Monthly (TZS)'}</label>
                    <input
                      type="number"
                      value={draft.priceMonthlyTzs}
                      onChange={e => patchDraft(plan.id, { priceMonthlyTzs: Number(e.target.value) })}
                      className="w-full mt-0.5 px-2 py-1.5 border rounded-lg text-sm font-mono font-bold"
                    />
                    <p className="text-[10px] text-slate-400 mt-0.5">{formatPlanPrice(draft, isSw)}{planPeriod(isSw)}</p>
                  </div>
                  <div>
                    <label className="text-[10px] font-bold text-slate-500 uppercase">{isSw ? 'Bei/mwaka (TZS)' : 'Yearly (TZS)'}</label>
                    <input
                      type="number"
                      value={draft.priceYearlyTzs}
                      onChange={e => patchDraft(plan.id, { priceYearlyTzs: Number(e.target.value) })}
                      className="w-full mt-0.5 px-2 py-1.5 border rounded-lg text-sm font-mono font-bold"
                    />
                  </div>
                </div>
              )}

              <div className="grid grid-cols-3 gap-2">
                {[
                  { key: 'maxBranches' as const, label: isSw ? 'Matawi' : 'Branches' },
                  { key: 'maxStaff' as const, label: isSw ? 'Wafanyakazi' : 'Staff' },
                  { key: 'maxProducts' as const, label: isSw ? 'Bidhaa' : 'Products' },
                ].map(({ key, label }) => (
                  <div key={key} className="text-center">
                    <label className="text-[10px] font-bold text-slate-500">{label}</label>
                    <input
                      type="number"
                      value={draft[key]}
                      onChange={e => patchDraft(plan.id, { [key]: Number(e.target.value) })}
                      className="w-full mt-0.5 px-1 py-1.5 border rounded-lg text-sm font-black text-center"
                    />
                  </div>
                ))}
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase">{isSw ? 'Vipengele EN' : 'Features EN'}</label>
                  <textarea
                    rows={4}
                    value={featuresToText(draft.features)}
                    onChange={e => patchDraft(plan.id, { features: textToFeatures(e.target.value) })}
                    className="w-full mt-0.5 px-2 py-1.5 border rounded-lg text-xs font-mono"
                    placeholder={'POS & barcode\nInventory alerts'}
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase">{isSw ? 'Vipengele SW' : 'Features SW'}</label>
                  <textarea
                    rows={4}
                    value={featuresToText(draft.featuresSw)}
                    onChange={e => patchDraft(plan.id, { featuresSw: textToFeatures(e.target.value) })}
                    className="w-full mt-0.5 px-2 py-1.5 border rounded-lg text-xs font-mono"
                  />
                </div>
              </div>

              <label className="flex items-center gap-2 text-xs font-semibold cursor-pointer">
                <input
                  type="checkbox"
                  checked={draft.popular ?? false}
                  onChange={e => patchDraft(plan.id, { popular: e.target.checked })}
                />
                {isSw ? 'Onyesha kama maarufu kwenye tovuti' : 'Show as popular on website'}
              </label>

              <button
                type="button"
                disabled={savingId === plan.id}
                onClick={() => void savePlan(plan.id)}
                className="mt-auto w-full py-2.5 rounded-xl bg-[#003322] text-white text-xs font-bold flex items-center justify-center gap-2 cursor-pointer disabled:opacity-60"
              >
                {savingId === plan.id ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : savedId === plan.id ? (
                  <>{isSw ? 'Imehifadhiwa!' : 'Saved!'}</>
                ) : (
                  <>
                    <Save className="w-4 h-4" />
                    {isSw ? 'Hifadhi kifurushi' : 'Save plan'}
                  </>
                )}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
};
