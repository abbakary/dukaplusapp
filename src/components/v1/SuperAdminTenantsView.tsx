import React, { useState } from 'react';
import { 
  Building2, 
  CheckCircle2, 
  ChevronRight, 
  Clock, 
  CreditCard, 
  ExternalLink, 
  Filter, 
  HardDrive, 
  Layers, 
  Mail, 
  MapPin, 
  MoreVertical, 
  Phone, 
  Plus, 
  RefreshCw, 
  Search, 
  ShieldAlert, 
  ShieldCheck, 
  Store, 
  Trash2, 
  UserCheck, 
  Users, 
  X, 
  Zap
} from 'lucide-react';
import { 
  BusinessType, 
  Language, 
  SaaSPlanTier, 
  TenantStatus, 
  TenantStore 
} from '@/types/v1';
import { formatTSh } from '@/utils/translations';
import confetti from 'canvas-confetti';

interface SuperAdminTenantsViewProps {
  language: Language;
  tenants: TenantStore[];
  setTenants: React.Dispatch<React.SetStateAction<TenantStore[]>>;
  onImpersonateTenant: (tenant: TenantStore) => void;
  onOpenNewTenantModal: () => void;
}

export const SuperAdminTenantsView: React.FC<SuperAdminTenantsViewProps> = ({
  language,
  tenants,
  setTenants,
  onImpersonateTenant,
  onOpenNewTenantModal,
}) => {
  const isSw = language === 'sw';
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedType, setSelectedType] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [selectedRegion, setSelectedRegion] = useState<string>('all');
  const [selectedPlan, setSelectedPlan] = useState<string>('all');
  const [inspectingTenant, setInspectingTenant] = useState<TenantStore | null>(null);

  // Filter logic
  const filteredTenants = tenants.filter(t => {
    const matchesSearch = 
      t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.ownerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      t.ownerPhone.includes(searchQuery) ||
      t.tinNumber.includes(searchQuery) ||
      t.licenseNumber.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesType = selectedType === 'all' || t.type === selectedType;
    const matchesStatus = selectedStatus === 'all' || t.status === selectedStatus;
    const matchesRegion = selectedRegion === 'all' || t.region.toLowerCase().includes(selectedRegion.toLowerCase());
    const matchesPlan = selectedPlan === 'all' || t.plan === selectedPlan;

    return matchesSearch && matchesType && matchesStatus && matchesRegion && matchesPlan;
  });

  // Action handlers
  const handleToggleStatus = (tenantId: string) => {
    setTenants(prev => prev.map(t => {
      if (t.id !== tenantId) return t;
      const nextStatus: TenantStatus = t.status === 'active' ? 'suspended' : 'active';
      return { ...t, status: nextStatus };
    }));
    if (inspectingTenant && inspectingTenant.id === tenantId) {
      setInspectingTenant(prev => prev ? {
        ...prev,
        status: prev.status === 'active' ? 'suspended' : 'active'
      } : null);
    }
  };

  const handleExtendSubscription = (tenantId: string, days: number = 30) => {
    setTenants(prev => prev.map(t => {
      if (t.id !== tenantId) return t;
      return { 
        ...t, 
        subscriptionExpiry: '2027-04-30', 
        status: 'active' 
      };
    }));
    if (inspectingTenant && inspectingTenant.id === tenantId) {
      setInspectingTenant(prev => prev ? {
        ...prev,
        subscriptionExpiry: '2027-04-30',
        status: 'active'
      } : null);
    }
    confetti({
      particleCount: 30,
      spread: 50,
      origin: { y: 0.6 }
    });
  };

  const handleChangePlan = (tenantId: string, newPlan: SaaSPlanTier) => {
    setTenants(prev => prev.map(t => {
      if (t.id !== tenantId) return t;
      return { ...t, plan: newPlan };
    }));
    if (inspectingTenant && inspectingTenant.id === tenantId) {
      setInspectingTenant(prev => prev ? { ...prev, plan: newPlan } : null);
    }
  };

  return (
    <div className="space-y-6 pb-12 font-sans">
      {/* Top Header Bar */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-[#323130] tracking-tight">
              {isSw ? 'Usimamizi wa Maduka Yote (Tenant Directory)' : 'Tenant Stores Directory'}
            </h2>
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-xs font-bold font-mono">
              {tenants.length} STORES
            </span>
          </div>
          <p className="text-xs text-[#605E5C]">
            {isSw 
              ? 'Dhibiti biashara zilizosajiliwa kote nchini Tanzania, badili vifurushi, angalia uthibitisho wa TRA EFD, na uige duka lolote kwa mbofyo 1.'
              : 'Oversee all registered Tanzanian stores, modify subscription plans, audit TRA EFD hardware, and impersonate shop environments.'
            }
          </p>
        </div>

        <button
          onClick={onOpenNewTenantModal}
          className="flex items-center gap-2 px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-md transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>{isSw ? 'Sajili Duka Jipya (Manual Provision)' : 'Provision New Store'}</span>
        </button>
      </div>

      {/* Filter & Search Toolbar */}
      <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs space-y-3">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-2.5">
          {/* Search box */}
          <div className="relative lg:col-span-2">
            <Search className="w-4 h-4 text-[#605E5C] absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder={isSw ? 'Tafuta kwa Jina la Duka, Mwenye Duka, Simu, au TIN...' : 'Search by Store, Owner, Phone, or TIN...'}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-3 py-2 bg-[#F3F2F1] rounded-lg text-xs outline-none focus:bg-white focus:ring-1 focus:ring-emerald-500 transition-all"
            />
          </div>

          {/* Archetype Filter */}
          <div>
            <select
              value={selectedType}
              onChange={(e) => setSelectedType(e.target.value)}
              className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg text-xs outline-none text-[#323130] font-medium"
            >
              <option value="all">{isSw ? 'Aina Zote za Biashara' : 'All Archetypes'}</option>
              <option value="pharmacy">💊 Pharmacy (Duka la Dawa)</option>
              <option value="hardware">🔨 Hardware & Construction</option>
              <option value="retail">🏪 Retail & FMCG</option>
              <option value="restaurant">🍽️ Restaurant & Cafe</option>
              <option value="service">✂️ Service & Salon</option>
            </select>
          </div>

          {/* Status Filter */}
          <div>
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg text-xs outline-none text-[#323130] font-medium"
            >
              <option value="all">{isSw ? 'Hali Zote (All Statuses)' : 'All Statuses'}</option>
              <option value="active">Active (Hai)</option>
              <option value="suspended">Suspended (Imesitishwa)</option>
              <option value="pending_kyc">Pending KYC (Inasubiri Leseni)</option>
              <option value="grace_period">Grace Period (Muda wa Nyongeza)</option>
            </select>
          </div>

          {/* Plan Tier Filter */}
          <div>
            <select
              value={selectedPlan}
              onChange={(e) => setSelectedPlan(e.target.value)}
              className="w-full px-3 py-2 bg-[#F3F2F1] rounded-lg text-xs outline-none text-[#323130] font-medium"
            >
              <option value="all">{isSw ? 'Vifurushi Vyote (All Plans)' : 'All Plans'}</option>
              <option value="free_starter">Free Starter</option>
              <option value="biashara_pro">Biashara Pro (TZS 75k)</option>
              <option value="enterprise_chain">Enterprise Chain (TZS 150k)</option>
            </select>
          </div>
        </div>

        <div className="flex items-center justify-between text-xs text-[#605E5C] pt-2 border-t border-[#F3F2F1]">
          <span>
            {isSw ? `Yanaonekana: maduka ${filteredTenants.length} kati ya ${tenants.length}` : `Showing ${filteredTenants.length} of ${tenants.length} stores`}
          </span>
          {(searchQuery || selectedType !== 'all' || selectedStatus !== 'all' || selectedPlan !== 'all') && (
            <button
              onClick={() => {
                setSearchQuery('');
                setSelectedType('all');
                setSelectedStatus('all');
                setSelectedPlan('all');
              }}
              className="text-emerald-700 font-semibold hover:underline"
            >
              {isSw ? 'Weka Upya Vichujio (Reset Filters)' : 'Reset Filters'}
            </button>
          )}
        </div>
      </div>

      {/* Tenants Table Grid */}
      <div className="bg-white rounded-xl border border-[#E1DFDD] shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#FAF9F8] border-b border-[#E1DFDD] text-[#605E5C] uppercase font-bold text-[10px] tracking-wider">
              <tr>
                <th className="py-3 px-4">{isSw ? 'Jina la Duka & Aina' : 'Store & Archetype'}</th>
                <th className="py-3 px-4">{isSw ? 'Mwenye Duka & Mawasiliano' : 'Owner & Contact'}</th>
                <th className="py-3 px-4">{isSw ? 'Eneo & TIN' : 'Location & TIN'}</th>
                <th className="py-3 px-4">{isSw ? 'Kifurushi (Plan)' : 'SaaS Plan'}</th>
                <th className="py-3 px-4">{isSw ? 'Mwisho wa Usajili' : 'Subscription Expiry'}</th>
                <th className="py-3 px-4">{isSw ? 'Hali' : 'Status'}</th>
                <th className="py-3 px-4 text-right">{isSw ? 'Vitendo' : 'Actions'}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F3F2F1]">
              {filteredTenants.map(tenant => {
                const planBadge = 
                  tenant.plan === 'enterprise_chain' ? 'bg-purple-100 text-purple-800 border-purple-200' :
                  tenant.plan === 'biashara_pro' ? 'bg-blue-100 text-blue-800 border-blue-200' :
                  'bg-slate-100 text-slate-700 border-slate-200';

                const statusBadge = 
                  tenant.status === 'active' ? 'bg-emerald-100 text-emerald-800 border-emerald-200' :
                  tenant.status === 'suspended' ? 'bg-rose-100 text-rose-800 border-rose-200' :
                  tenant.status === 'pending_kyc' ? 'bg-amber-100 text-amber-800 border-amber-200' :
                  'bg-orange-100 text-orange-800 border-orange-200';

                return (
                  <tr key={tenant.id} className="hover:bg-[#F8F8F8] transition-colors">
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-2.5">
                        <span className="text-xl">
                          {tenant.type === 'pharmacy' ? '💊' :
                           tenant.type === 'hardware' ? '🔨' :
                           tenant.type === 'restaurant' ? '🍽️' :
                           tenant.type === 'retail' ? '🏪' : '✂️'}
                        </span>
                        <div>
                          <p className="font-bold text-sm text-[#323130]">{tenant.name}</p>
                          <span className="text-[11px] text-slate-500 font-mono">
                            {tenant.branchesCount} {tenant.branchesCount === 1 ? 'branch' : 'branches'} • {tenant.staffCount} staff
                          </span>
                        </div>
                      </div>
                    </td>

                    <td className="py-3.5 px-4">
                      <p className="font-semibold text-[#323130]">{tenant.ownerName}</p>
                      <p className="text-[11px] text-slate-500">{tenant.ownerPhone}</p>
                      <p className="text-[11px] text-slate-400 truncate max-w-[150px]">{tenant.ownerEmail}</p>
                    </td>

                    <td className="py-3.5 px-4">
                      <p className="font-medium text-[#323130]">{tenant.region}</p>
                      <p className="text-[11px] text-slate-500">{tenant.district}</p>
                      <p className="text-[10px] font-mono text-emerald-700 font-bold">TIN: {tenant.tinNumber}</p>
                    </td>

                    <td className="py-3.5 px-4">
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${planBadge}`}>
                        {tenant.plan.replace('_', ' ').toUpperCase()}
                      </span>
                      <p className="text-[10px] text-slate-500 mt-1 font-mono">
                        {tenant.mrrTzs > 0 ? `${formatTSh(tenant.mrrTzs)}/mo` : 'Free Tier'}
                      </p>
                    </td>

                    <td className="py-3.5 px-4">
                      <p className="font-mono text-xs font-semibold text-[#323130]">{tenant.subscriptionExpiry}</p>
                      <span className="text-[10px] text-slate-500">
                        {tenant.autoRenew ? 'Auto-renew ON' : 'Manual Renew'}
                      </span>
                    </td>

                    <td className="py-3.5 px-4">
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${statusBadge}`}>
                        {tenant.status.toUpperCase()}
                      </span>
                    </td>

                    <td className="py-3.5 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          onClick={() => onImpersonateTenant(tenant)}
                          className="px-2.5 py-1 rounded-md bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold flex items-center gap-1 transition-all cursor-pointer shadow-2xs"
                          title={isSw ? 'Ingia na uone kama duka hili' : 'Login and manage this store'}
                        >
                          <ExternalLink className="w-3 h-3" />
                          <span>{isSw ? 'Ingia' : 'Impersonate'}</span>
                        </button>

                        <button
                          onClick={() => setInspectingTenant(tenant)}
                          className="px-2 py-1 rounded-md bg-[#F3F2F1] hover:bg-[#EDEBE9] text-[#323130] text-xs font-semibold border border-[#EDEBE9] transition-all cursor-pointer"
                        >
                          {isSw ? 'Maelezo' : 'Details'}
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* INSPECT TENANT DRAWER / MODAL */}
      {inspectingTenant && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full p-6 shadow-2xl border border-slate-200 space-y-5 animate-in fade-in zoom-in-95 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <span className="text-2xl">
                  {inspectingTenant.type === 'pharmacy' ? '💊' :
                   inspectingTenant.type === 'hardware' ? '🔨' :
                   inspectingTenant.type === 'restaurant' ? '🍽️' :
                   inspectingTenant.type === 'retail' ? '🏪' : '✂️'}
                </span>
                <div>
                  <h3 className="text-lg font-bold text-[#323130]">{inspectingTenant.name}</h3>
                  <p className="text-xs text-[#605E5C]">
                    ID: <span className="font-mono">{inspectingTenant.id}</span> • Registered on {inspectingTenant.createdAt}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setInspectingTenant(null)}
                className="p-1 rounded-lg hover:bg-slate-100 text-slate-500"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Quick Metrics */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-[10px] text-slate-500 uppercase font-bold">Monthly GMV</span>
                <p className="text-sm font-bold text-slate-900 mt-0.5">{formatTSh(inspectingTenant.monthlyGmvTzs)}</p>
              </div>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-[10px] text-slate-500 uppercase font-bold">Branches & Staff</span>
                <p className="text-sm font-bold text-slate-900 mt-0.5">{inspectingTenant.branchesCount} branches / {inspectingTenant.staffCount} staff</p>
              </div>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-[10px] text-slate-500 uppercase font-bold">TRA EFD Device</span>
                <p className="text-xs font-mono font-bold text-emerald-700 mt-1">{inspectingTenant.traEfdDeviceSerial}</p>
              </div>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-[10px] text-slate-500 uppercase font-bold">Cloud Storage</span>
                <p className="text-sm font-bold text-slate-900 mt-0.5">{inspectingTenant.storageUsedMb} MB</p>
              </div>
            </div>

            {/* Regulatory & Owner Specs */}
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 text-xs space-y-2">
              <h4 className="font-bold text-slate-900 uppercase text-[11px] tracking-wider">
                {isSw ? 'Taarifa za Kisheria na Mmiliki' : 'Owner & Regulatory Identity'}
              </h4>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                <p><strong>Owner:</strong> {inspectingTenant.ownerName}</p>
                <p><strong>Phone:</strong> {inspectingTenant.ownerPhone}</p>
                <p><strong>Email:</strong> {inspectingTenant.ownerEmail}</p>
                <p><strong>Region:</strong> {inspectingTenant.region} ({inspectingTenant.district})</p>
                <p><strong>TRA TIN:</strong> <span className="font-mono font-bold">{inspectingTenant.tinNumber}</span></p>
                <p><strong>TMDA/BRELA License:</strong> <span className="font-mono">{inspectingTenant.licenseNumber}</span></p>
              </div>
            </div>

            {/* Actions Toolbar */}
            <div className="space-y-3 pt-2">
              <h4 className="font-bold text-slate-900 text-xs uppercase tracking-wider">
                {isSw ? 'Vitendo vya Super Admin' : 'Super Admin Operational Overrides'}
              </h4>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                <button
                  onClick={() => {
                    const t = inspectingTenant;
                    setInspectingTenant(null);
                    onImpersonateTenant(t);
                  }}
                  className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-md cursor-pointer transition-all"
                >
                  <ExternalLink className="w-4 h-4" />
                  <span>{isSw ? 'Ingia Moja kwa Moja kwenye Duka Hili' : 'Login As Store (Impersonate)'}</span>
                </button>

                <button
                  onClick={() => handleToggleStatus(inspectingTenant.id)}
                  className={`w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-xs font-bold shadow-xs cursor-pointer transition-all ${
                    inspectingTenant.status === 'active'
                      ? 'bg-rose-100 hover:bg-rose-200 text-rose-800 border border-rose-300'
                      : 'bg-emerald-100 hover:bg-emerald-200 text-emerald-800 border border-emerald-300'
                  }`}
                >
                  <ShieldAlert className="w-4 h-4" />
                  <span>
                    {inspectingTenant.status === 'active' 
                      ? (isSw ? 'Sitisha Duka Hili (Suspend Store)' : 'Suspend Store Access')
                      : (isSw ? 'Rejesha Duka Hili (Reactivate Store)' : 'Reactivate Store Access')
                    }
                  </span>
                </button>
              </div>

              <div className="flex items-center gap-2 pt-2">
                <button
                  onClick={() => handleExtendSubscription(inspectingTenant.id, 30)}
                  className="flex-1 py-2 rounded-lg bg-blue-50 hover:bg-blue-100 text-blue-700 text-xs font-semibold border border-blue-200 transition-all cursor-pointer"
                >
                  {isSw ? 'Ongeza Muda wa Usajili (+30 Days)' : 'Extend Expiry (+30 Days)'}
                </button>

                <button
                  onClick={() => {
                    alert(`TRA EFD queue reset for ${inspectingTenant.name}. Hardware serial ${inspectingTenant.traEfdDeviceSerial} re-authorized.`);
                  }}
                  className="flex-1 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold border border-slate-200 transition-all cursor-pointer"
                >
                  {isSw ? 'Weka Upya TRA EFD Sync' : 'Reset TRA EFD Sync'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
