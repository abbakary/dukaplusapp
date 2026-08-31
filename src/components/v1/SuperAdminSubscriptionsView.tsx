import React, { useState } from 'react';
import { 
  ArrowUpRight, 
  Check, 
  CheckCircle2, 
  CreditCard, 
  Download, 
  Edit, 
  FileText, 
  Plus, 
  Receipt, 
  RefreshCw, 
  Search, 
  ShieldCheck, 
  Smartphone, 
  Sparkles, 
  TrendingUp, 
  Zap 
} from 'lucide-react';
import { Language, SaaSPlan, SaaSTransaction } from '@/types/v1';
import { formatTSh } from '@/utils/translations';
import confetti from 'canvas-confetti';

interface SuperAdminSubscriptionsViewProps {
  language: Language;
  plans: SaaSPlan[];
  setPlans: React.Dispatch<React.SetStateAction<SaaSPlan[]>>;
  transactions: SaaSTransaction[];
  setTransactions: React.Dispatch<React.SetStateAction<SaaSTransaction[]>>;
}

export const SuperAdminSubscriptionsView: React.FC<SuperAdminSubscriptionsViewProps> = ({
  language,
  plans,
  setPlans,
  transactions,
  setTransactions,
}) => {
  const isSw = language === 'sw';
  const [activeSubTab, setActiveSubTab] = useState<'transactions' | 'plans'>('transactions');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isRecordModalOpen, setIsRecordModalOpen] = useState<boolean>(false);

  // New transaction form
  const [newStoreName, setNewStoreName] = useState<string>('');
  const [newAmount, setNewAmount] = useState<number>(75000);
  const [newMethod, setNewMethod] = useState<'M-Pesa' | 'Tigo Pesa' | 'Airtel Money' | 'CRDB Bank' | 'NMB Bank' | 'Selcom'>('M-Pesa');
  const [newRef, setNewRef] = useState<string>('MP-TZ-' + Math.floor(100000 + Math.random() * 900000));
  const [newCycle, setNewCycle] = useState<'monthly' | 'quarterly' | 'annual'>('monthly');

  const totalRevenue = transactions.reduce((acc, t) => acc + (t.status === 'completed' ? t.amountTzs : 0), 0);
  const mpesaRevenue = transactions.filter(t => t.paymentMethod === 'M-Pesa' && t.status === 'completed').reduce((acc, t) => acc + t.amountTzs, 0);
  const tigoRevenue = transactions.filter(t => t.paymentMethod === 'Tigo Pesa' && t.status === 'completed').reduce((acc, t) => acc + t.amountTzs, 0);

  const filteredTransactions = transactions.filter(t => 
    t.storeName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    t.reference.toLowerCase().includes(searchQuery.toLowerCase()) ||
    t.paymentMethod.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleRecordPayment = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newStoreName) return;

    const newTx: SaaSTransaction = {
      id: `tx-saas-${Date.now()}`,
      storeId: 'tenant-custom',
      storeName: newStoreName,
      plan: 'biashara_pro',
      amountTzs: newAmount,
      paymentMethod: newMethod,
      reference: newRef,
      date: new Date().toISOString().replace('T', ' ').substring(0, 16),
      status: 'completed',
      billingCycle: newCycle
    };

    setTransactions(prev => [newTx, ...prev]);
    setIsRecordModalOpen(false);
    setNewStoreName('');
    confetti({
      particleCount: 50,
      spread: 60,
      origin: { y: 0.6 }
    });
  };

  return (
    <div className="space-y-6 pb-12 font-sans">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-[#323130] tracking-tight">
              {isSw ? 'Usimamizi wa Mapato ya SaaS & Vifurushi' : 'SaaS Subscriptions & Revenue Engine'}
            </h2>
            <span className="px-2.5 py-0.5 rounded-full bg-blue-100 text-blue-800 text-xs font-bold font-mono">
              TZS BILLING
            </span>
          </div>
          <p className="text-xs text-[#605E5C]">
            {isSw 
              ? 'Dhibiti malipo ya simu (M-Pesa Lipa Namba, Tigo Pesa, Airtel Money, Selcom, Benki) na usanidi bei za vifurushi vya Duka+.'
              : 'Track mobile money SaaS subscription revenues, automated IPN webhooks, invoice records, and configure tier pricing.'
            }
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setIsRecordModalOpen(true)}
            className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-md transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>{isSw ? 'Rekodi Malipo ya Nje' : 'Record SaaS Payment'}</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <span className="text-xs font-bold uppercase tracking-wider text-[#605E5C]">
            {isSw ? 'Jumla ya Malipo Yaliyokusanywa' : 'Total SaaS Inflows'}
          </span>
          <div className="mt-2 text-2xl font-black text-emerald-700 tracking-tight">
            {formatTSh(totalRevenue)}
          </div>
          <p className="text-[11px] text-[#605E5C] mt-1">
            {transactions.length} {isSw ? 'Miamala ya usajili imerekodiwa' : 'subscription transactions'}
          </p>
        </div>

        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <span className="text-xs font-bold uppercase tracking-wider text-[#605E5C]">
            Vodacom M-Pesa & Tigo Pesa
          </span>
          <div className="mt-2 text-xl font-black text-[#323130] tracking-tight">
            {formatTSh(mpesaRevenue + tigoRevenue)}
          </div>
          <p className="text-[11px] text-emerald-600 font-semibold mt-1 flex items-center gap-1">
            <Smartphone className="w-3.5 h-3.5" /> 88.4% of total subscriptions via Mobile Money
          </p>
        </div>

        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <span className="text-xs font-bold uppercase tracking-wider text-[#605E5C]">
            {isSw ? 'Maduka Yenye Usajili Hai' : 'Paid Active Tenants'}
          </span>
          <div className="mt-2 text-2xl font-black text-[#323130] tracking-tight">
            106 / 148
          </div>
          <p className="text-[11px] text-blue-600 font-semibold mt-1">
            71.6% Conversion to Paid Tiers
          </p>
        </div>
      </div>

      {/* Sub Tabs Switcher */}
      <div className="flex items-center gap-2 border-b border-[#E1DFDD]">
        <button
          onClick={() => setActiveSubTab('transactions')}
          className={`pb-2.5 px-3 text-xs font-bold transition-all border-b-2 ${
            activeSubTab === 'transactions'
              ? 'border-emerald-600 text-emerald-700'
              : 'border-transparent text-[#605E5C] hover:text-[#323130]'
          }`}
        >
          {isSw ? 'Orodha ya Miamala ya Malipo' : 'Subscription Transactions Ledger'}
        </button>

        <button
          onClick={() => setActiveSubTab('plans')}
          className={`pb-2.5 px-3 text-xs font-bold transition-all border-b-2 ${
            activeSubTab === 'plans'
              ? 'border-emerald-600 text-emerald-700'
              : 'border-transparent text-[#605E5C] hover:text-[#323130]'
          }`}
        >
          {isSw ? 'Usanidi wa Vifurushi & Bei' : 'SaaS Pricing Plans & Features'}
        </button>
      </div>

      {/* TAB 1: TRANSACTIONS */}
      {activeSubTab === 'transactions' && (
        <div className="bg-white rounded-xl border border-[#E1DFDD] shadow-xs overflow-hidden">
          <div className="p-4 border-b border-[#F3F2F1] flex items-center justify-between gap-3">
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 text-[#605E5C] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder={isSw ? 'Tafuta kwa Jina la Duka, Namba ya Kumbukumbu, au Njia ya Malipo...' : 'Search by Store, Reference ID, or Payment Method...'}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-3 py-1.5 bg-[#F3F2F1] rounded-lg text-xs outline-none focus:bg-white focus:ring-1 focus:ring-emerald-500"
              />
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#FAF9F8] border-b border-[#E1DFDD] text-[#605E5C] uppercase font-bold text-[10px]">
                <tr>
                  <th className="py-3 px-4">{isSw ? 'Duka' : 'Store'}</th>
                  <th className="py-3 px-4">{isSw ? 'Kiasi (TZS)' : 'Amount (TZS)'}</th>
                  <th className="py-3 px-4">{isSw ? 'Njia ya Malipo & Ref' : 'Method & Reference'}</th>
                  <th className="py-3 px-4">{isSw ? 'Mzunguko' : 'Billing Cycle'}</th>
                  <th className="py-3 px-4">{isSw ? 'Tarehe' : 'Date & Time'}</th>
                  <th className="py-3 px-4">{isSw ? 'Hali' : 'Status'}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#F3F2F1]">
                {filteredTransactions.map(tx => (
                  <tr key={tx.id} className="hover:bg-[#F8F8F8] transition-colors">
                    <td className="py-3.5 px-4 font-bold text-[#323130]">{tx.storeName}</td>
                    <td className="py-3.5 px-4 font-mono font-black text-emerald-700 text-sm">
                      {formatTSh(tx.amountTzs)}
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="font-semibold text-slate-800">{tx.paymentMethod}</span>
                      <p className="text-[10px] font-mono text-slate-500">{tx.reference}</p>
                    </td>
                    <td className="py-3.5 px-4 uppercase font-semibold text-[11px] text-slate-600">
                      {tx.billingCycle}
                    </td>
                    <td className="py-3.5 px-4 text-slate-600 font-mono text-[11px]">{tx.date}</td>
                    <td className="py-3.5 px-4">
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                        tx.status === 'completed' 
                          ? 'bg-emerald-100 text-emerald-800' 
                          : 'bg-amber-100 text-amber-800'
                      }`}>
                        {tx.status.toUpperCase()}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 2: SAAS PRICING PLANS */}
      {activeSubTab === 'plans' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {plans.map(plan => (
            <div 
              key={plan.id}
              className={`bg-white rounded-2xl p-6 border transition-all relative ${
                plan.popular ? 'border-emerald-500 ring-2 ring-emerald-500/20 shadow-md' : 'border-[#E1DFDD] shadow-xs'
              }`}
            >
              {plan.popular && (
                <span className="absolute -top-3 left-1/2 -translate-x-1/2 bg-emerald-600 text-white text-[10px] font-extrabold uppercase px-3 py-0.5 rounded-full shadow-xs">
                  MOST POPULAR IN TANZANIA
                </span>
              )}

              <h3 className="text-lg font-bold text-[#323130]">{plan.name}</h3>
              <p className="text-xs text-[#605E5C] mt-1">{plan.activeSubscribersCount} active subscribers</p>

              <div className="mt-4 pb-4 border-b border-[#F3F2F1]">
                <span className="text-2xl font-black text-[#323130] font-mono">
                  {plan.priceMonthlyTzs === 0 ? 'FREE' : formatTSh(plan.priceMonthlyTzs)}
                </span>
                {plan.priceMonthlyTzs > 0 && <span className="text-xs text-slate-500"> / month</span>}
                {plan.priceYearlyTzs > 0 && (
                  <p className="text-[11px] text-emerald-700 font-semibold mt-1">
                    Annual: {formatTSh(plan.priceYearlyTzs)} / yr (Save 2 months)
                  </p>
                )}
              </div>

              <div className="mt-4 space-y-2 text-xs">
                <p className="font-bold text-slate-700">Limits & Capacity:</p>
                <div className="space-y-1 text-slate-600">
                  <p>• Max Products: <strong>{plan.maxProducts.toLocaleString()}</strong></p>
                  <p>• Max Branches: <strong>{plan.maxBranches}</strong></p>
                  <p>• Max Staff Accounts: <strong>{plan.maxStaff}</strong></p>
                </div>

                <p className="font-bold text-slate-700 pt-2">Included Modules:</p>
                <ul className="space-y-1.5">
                  {plan.features.map((feat, idx) => (
                    <li key={idx} className="flex items-start gap-2 text-slate-700">
                      <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0 mt-0.5" />
                      <span>{feat}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* RECORD PAYMENT MODAL */}
      {isRecordModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 space-y-4 animate-in fade-in zoom-in-95">
            <h3 className="text-lg font-bold text-[#323130]">
              {isSw ? 'Rekodi Malipo ya Usajili wa Duka' : 'Record Manual SaaS Payment'}
            </h3>
            <form onSubmit={handleRecordPayment} className="space-y-3 text-xs">
              <div>
                <label className="font-bold text-slate-700 block mb-1">
                  {isSw ? 'Jina la Duka' : 'Store Name'}
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Afya Bora Pharmacy"
                  value={newStoreName}
                  onChange={(e) => setNewStoreName(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg bg-slate-50 border border-slate-300 outline-none focus:bg-white focus:border-emerald-600"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">
                    {isSw ? 'Kiasi (TZS)' : 'Amount (TZS)'}
                  </label>
                  <input
                    type="number"
                    required
                    value={newAmount}
                    onChange={(e) => setNewAmount(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-lg bg-slate-50 border border-slate-300 outline-none focus:bg-white focus:border-emerald-600 font-mono"
                  />
                </div>
                <div>
                  <label className="font-bold text-slate-700 block mb-1">
                    {isSw ? 'Mzunguko' : 'Cycle'}
                  </label>
                  <select
                    value={newCycle}
                    onChange={(e) => setNewCycle(e.target.value as any)}
                    className="w-full px-3 py-2 rounded-lg bg-slate-50 border border-slate-300 outline-none font-medium"
                  >
                    <option value="monthly">Monthly</option>
                    <option value="quarterly">Quarterly</option>
                    <option value="annual">Annual</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">
                    {isSw ? 'Njia ya Malipo' : 'Payment Method'}
                  </label>
                  <select
                    value={newMethod}
                    onChange={(e) => setNewMethod(e.target.value as any)}
                    className="w-full px-3 py-2 rounded-lg bg-slate-50 border border-slate-300 outline-none font-medium"
                  >
                    <option value="M-Pesa">M-Pesa (Vodacom)</option>
                    <option value="Tigo Pesa">Tigo Pesa</option>
                    <option value="Airtel Money">Airtel Money</option>
                    <option value="CRDB Bank">CRDB Bank</option>
                    <option value="NMB Bank">NMB Bank</option>
                    <option value="Selcom">Selcom Pay</option>
                  </select>
                </div>
                <div>
                  <label className="font-bold text-slate-700 block mb-1">
                    {isSw ? 'Namba ya Kumbukumbu' : 'Reference ID'}
                  </label>
                  <input
                    type="text"
                    required
                    value={newRef}
                    onChange={(e) => setNewRef(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg bg-slate-50 border border-slate-300 outline-none font-mono"
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-3">
                <button
                  type="button"
                  onClick={() => setIsRecordModalOpen(false)}
                  className="px-3 py-2 rounded-lg bg-slate-100 text-slate-700 font-semibold"
                >
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-bold"
                >
                  {isSw ? 'Hifadhi Malipo' : 'Save Payment'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
