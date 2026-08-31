import React, { useState } from 'react';
import { 
  Activity, 
  AlertTriangle, 
  ArrowUpRight, 
  Building2, 
  CheckCircle2, 
  ChevronRight, 
  Clock, 
  CreditCard, 
  Download, 
  ExternalLink, 
  Globe, 
  HardDrive, 
  Layers, 
  PieChart, 
  Plus, 
  Radio, 
  RefreshCw, 
  Search, 
  Server, 
  ShieldAlert, 
  ShieldCheck, 
  Sparkles, 
  Store, 
  TrendingUp, 
  Users, 
  Wifi, 
  Zap
} from 'lucide-react';
import { 
  Language, 
  PlatformMetrics, 
  TenantStore, 
  VendorApplication, 
  SaaSTransaction, 
  SystemTelemetryLog,
  BusinessType
} from '@/types/v1';
import { formatTSh } from '@/utils/translations';
import confetti from 'canvas-confetti';

interface SuperAdminDashboardViewProps {
  language: Language;
  metrics?: PlatformMetrics;
  tenants?: TenantStore[];
  applications?: VendorApplication[];
  transactions?: SaaSTransaction[];
  telemetryLogs?: SystemTelemetryLog[];
  onNavigate: (view: string) => void;
  onImpersonateTenant: (tenant: TenantStore) => void;
  onOpenBroadcastModal?: () => void;
  onOpenNewTenantModal?: () => void;
  onOpenAIChat?: () => void;
}

export const SuperAdminDashboardView: React.FC<SuperAdminDashboardViewProps> = ({
  language,
  metrics = {
    totalTenants: 148,
    activeTenants: 142,
    suspendedTenants: 2,
    pendingKycTenants: 4,
    monthlySubscriptionRevenueTzs: 11100000,
    annualRunRateTzs: 133200000,
    totalPlatformGmvTzs: 842500000,
    traReceiptsProcessedToday: 4920,
    smsCreditsRemaining: 18450,
    apiUptimePercent: 99.98,
  },
  tenants = [],
  applications = [],
  transactions = [],
  telemetryLogs = [],
  onNavigate,
  onImpersonateTenant,
  onOpenBroadcastModal = () => onNavigate('super-broadcasts'),
  onOpenNewTenantModal = () => onNavigate('super-tenants'),
  onOpenAIChat,
}) => {
  const isSw = language === 'sw';
  const [selectedRegion, setSelectedRegion] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const safeApplications = applications || [];
  const safeTenants = tenants || [];
  const safeTransactions = transactions || [];
  const safeLogs = telemetryLogs || [];

  const pendingAppsCount = safeApplications.filter(a => a?.status === 'pending').length;

  const regionCounts = safeTenants.reduce((acc, t) => {
    if (t?.region) {
      acc[t.region] = (acc[t.region] || 0) + 1;
    }
    return acc;
  }, {} as Record<string, number>);

  const archetypeCounts = safeTenants.reduce((acc, t) => {
    if (t?.type) {
      acc[t.type] = (acc[t.type] || 0) + 1;
    }
    return acc;
  }, {} as Record<BusinessType, number>);

  const filteredTenants = safeTenants.filter(t => {
    if (!t) return false;
    const matchesRegion = selectedRegion === 'all' || (t.region && t.region.toLowerCase().includes(selectedRegion.toLowerCase()));
    const matchesSearch = (t.name && t.name.toLowerCase().includes(searchQuery.toLowerCase())) || 
                          (t.ownerName && t.ownerName.toLowerCase().includes(searchQuery.toLowerCase())) ||
                          (t.tinNumber && t.tinNumber.includes(searchQuery));
    return matchesRegion && matchesSearch;
  });

  const handleExportAudit = () => {
    confetti({
      particleCount: 40,
      spread: 60,
      origin: { y: 0.6 }
    });
  };

  return (
    <div className="space-y-6 pb-12 font-sans">
      {/* Top Banner: System Provider Command Center Header */}
      <div className="bg-white rounded-xl p-5 sm:p-6 border border-[#E1DFDD] shadow-xs relative overflow-hidden">
        <div className="flex flex-col lg:flex-row items-start lg:items-center justify-between gap-4 relative z-10">
          <div>
            <div className="flex items-center gap-2.5 mb-1.5 flex-wrap">
              <span className="px-2.5 py-1 rounded-md bg-emerald-50 text-emerald-800 font-mono text-[11px] font-bold border border-emerald-300 flex items-center gap-1.5">
                <Server className="w-3.5 h-3.5 text-emerald-600" />
                SYSTEM PROVIDER CONTROL PLANE
              </span>
              <span className="px-2 py-0.5 rounded bg-blue-50 text-blue-700 text-[10px] font-semibold border border-blue-200">
                Multi-Tenant Architecture
              </span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-extrabold text-[#323130] tracking-tight">
              {isSw ? 'Kituo Kikuu cha Usimamizi wa Mfumo (Super Admin)' : 'Platform Provider Command Center'}
            </h1>
            <p className="text-xs sm:text-sm text-[#605E5C] mt-1 max-w-2xl">
              {isSw 
                ? 'Usimamizi wa maduka yote ya Tanzania, uhakiki wa leseni za TMDA/BRELA, muunganisho wa TRA EFD, na mapato ya usajili (SaaS Revenue).'
                : 'Monitor all registered Tanzanian stores, verify TMDA & BRELA compliance, manage TRA fiscal queues, and track SaaS subscription revenue.'
              }
            </p>
          </div>

          <div className="flex items-center flex-wrap gap-2.5">
            <button
              onClick={onOpenBroadcastModal}
              className="flex items-center gap-2 px-3.5 py-2 rounded-xl bg-purple-600 hover:bg-purple-500 text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
            >
              <Radio className="w-4 h-4" />
              <span>{isSw ? 'Tangazo kwa Maduka Yote' : 'Broadcast to Stores'}</span>
            </button>

            <button
              onClick={onOpenNewTenantModal}
              className="flex items-center gap-2 px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>{isSw ? 'Sajili Duka Jipya' : 'Add New Tenant'}</span>
            </button>

            <button
              onClick={handleExportAudit}
              className="flex items-center gap-2 px-3 py-2 rounded-xl bg-[#F3F2F1] hover:bg-[#EDEBE9] text-[#323130] text-xs font-semibold border border-[#EDEBE9] transition-all cursor-pointer"
              title="Export Report"
            >
              <Download className="w-4 h-4 text-[#605E5C]" />
              <span className="hidden sm:inline">{isSw ? 'Ripoti' : 'Audit Report'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* KPI METRIC CARDS (High contrast, clean typography) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1: Total Tenants */}
        <div 
          onClick={() => onNavigate('super-tenants')}
          className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs hover:shadow-md transition-all cursor-pointer hover:border-emerald-500 group"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-[#605E5C]">
              {isSw ? 'Maduka Yote Tanzania' : 'Total Tenants'}
            </span>
            <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center group-hover:scale-110 transition-transform">
              <Building2 className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-2xl font-black text-[#323130] tracking-tight">{metrics.totalTenants}</span>
            <span className="text-xs font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">
              {metrics.activeTenants} {isSw ? 'Hai' : 'Active'}
            </span>
          </div>
          <div className="mt-2 text-[11px] text-[#605E5C] flex items-center justify-between border-t border-[#F3F2F1] pt-2">
            <span>{isSw ? 'Dar, Arusha, Mwanza, Dodoma' : 'All 31 Regions'}</span>
            <span className="font-semibold text-emerald-600 flex items-center gap-0.5">
              {isSw ? 'Dhibiti' : 'Manage'} <ChevronRight className="w-3 h-3" />
            </span>
          </div>
        </div>

        {/* Card 2: SaaS MRR (Subscription Revenue) */}
        <div 
          onClick={() => onNavigate('super-subscriptions')}
          className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs hover:shadow-md transition-all cursor-pointer hover:border-blue-500 group"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-[#605E5C]">
              {isSw ? 'Mapato ya Mwezi (SaaS MRR)' : 'Monthly SaaS Revenue'}
            </span>
            <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center group-hover:scale-110 transition-transform">
              <CreditCard className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-xl font-black text-[#323130] tracking-tight">
              {formatTSh(metrics.monthlySubscriptionRevenueTzs)}
            </span>
            <span className="text-[11px] font-bold text-emerald-600 flex items-center">
              <ArrowUpRight className="w-3.5 h-3.5" /> +14.2%
            </span>
          </div>
          <div className="mt-2 text-[11px] text-[#605E5C] flex items-center justify-between border-t border-[#F3F2F1] pt-2">
            <span>ARR: {formatTSh(metrics.annualRunRateTzs)}</span>
            <span className="font-semibold text-blue-600 flex items-center gap-0.5">
              {isSw ? 'Malipo' : 'Billing'} <ChevronRight className="w-3 h-3" />
            </span>
          </div>
        </div>

        {/* Card 3: Platform GMV Processed */}
        <div className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-[#605E5C]">
              {isSw ? 'Mauzo Yote ya Maduka (GMV)' : 'Total Platform GMV'}
            </span>
            <div className="w-8 h-8 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-xl font-black text-[#323130] tracking-tight">
              {formatTSh(metrics.totalPlatformGmvTzs)}
            </span>
            <span className="text-[10px] font-bold text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
              30 Days
            </span>
          </div>
          <div className="mt-2 text-[11px] text-[#605E5C] flex items-center justify-between border-t border-[#F3F2F1] pt-2">
            <span>{isSw ? 'Kupitia Duka+ POS Terminals' : 'Processed across all shops'}</span>
            <span className="font-semibold text-slate-700">142 Terminals</span>
          </div>
        </div>

        {/* Card 4: TRA EFD Fiscal API & SMS Bridge */}
        <div 
          onClick={() => onNavigate('super-telemetry')}
          className="bg-white rounded-xl p-4 border border-[#E1DFDD] shadow-xs hover:shadow-md transition-all cursor-pointer hover:border-cyan-500 group"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-[#605E5C]">
              {isSw ? 'TRA EFD & SMS Gateway' : 'TRA EFD & SMS Health'}
            </span>
            <div className="w-8 h-8 rounded-lg bg-cyan-50 text-cyan-600 flex items-center justify-center group-hover:scale-110 transition-transform">
              <Activity className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="text-2xl font-black text-[#323130] tracking-tight">
              {metrics.traReceiptsProcessedToday.toLocaleString()}
            </span>
            <span className="text-xs font-bold text-cyan-700 bg-cyan-50 px-2 py-0.5 rounded-full">
              {metrics.apiUptimePercent}% Up
            </span>
          </div>
          <div className="mt-2 text-[11px] text-[#605E5C] flex items-center justify-between border-t border-[#F3F2F1] pt-2">
            <span>SMS Salio: {metrics.smsCreditsRemaining.toLocaleString()}</span>
            <span className="font-semibold text-cyan-600 flex items-center gap-0.5">
              {isSw ? 'Hali' : 'Telemetry'} <ChevronRight className="w-3 h-3" />
            </span>
          </div>
        </div>
      </div>

      {/* PENDING KYC ALERT BAR (if any pending) */}
      {pendingAppsCount > 0 && (
        <div className="p-4 rounded-xl bg-amber-50 border border-amber-200 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-xs">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-amber-100 text-amber-800 flex items-center justify-center shrink-0">
              <ShieldAlert className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-amber-900">
                {pendingAppsCount} {isSw ? 'Maombi Mapya ya Leseni Yanasubiri Uhakiki' : 'Pending Vendor KYC Verifications'}
              </h4>
              <p className="text-xs text-amber-700">
                {isSw 
                  ? 'Maduka mapya yamesajili TIN na leseni za TMDA/BRELA. Thibitisha ili waanze kutumia mfumo.'
                  : 'New shops submitted TRA TIN and TMDA/BRELA licenses. Review and activate accounts.'
                }
              </p>
            </div>
          </div>
          <button
            onClick={() => onNavigate('super-approvals')}
            className="px-4 py-2 rounded-lg bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold shadow-xs transition-all cursor-pointer shrink-0"
          >
            {isSw ? 'Kagua Sasa (Review KYC)' : 'Review KYC Queue'}
          </button>
        </div>
      )}

      {/* 2-COLUMN MAIN CONTENT GRID */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left 2 Columns: Multi-Tenant Quick Directory & Impersonation Hub */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-xl p-5 border border-[#E1DFDD] shadow-xs">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 pb-4 border-b border-[#F3F2F1]">
              <div>
                <h3 className="text-base font-bold text-[#323130] tracking-tight">
                  {isSw ? 'Maduka Yaliyo Hai na Uigaji wa Moja kwa Moja (Live Impersonation)' : 'Live Store Directory & Impersonator'}
                </h3>
                <p className="text-xs text-[#605E5C]">
                  {isSw ? 'Ingia moja kwa moja kwenye duka lolote kuona kama muuzaji au dhibiti hali ya duka' : 'Impersonate any shop directly or manage their active subscription'}
                </p>
              </div>

              <div className="flex items-center gap-2 w-full sm:w-auto">
                <div className="relative flex-1 sm:w-48">
                  <Search className="w-3.5 h-3.5 text-[#605E5C] absolute left-2.5 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    placeholder={isSw ? 'Tafuta duka / TIN...' : 'Search store / TIN...'}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-8 pr-2.5 py-1.5 bg-[#F3F2F1] rounded-lg text-xs outline-none focus:bg-white focus:ring-1 focus:ring-emerald-500 transition-all"
                  />
                </div>
              </div>
            </div>

            {/* Region Filter Chips */}
            <div className="flex items-center gap-1.5 py-3 overflow-x-auto text-xs border-b border-[#F3F2F1]">
              <span className="text-[11px] font-bold text-[#605E5C] mr-1 uppercase">Region:</span>
              <button
                onClick={() => setSelectedRegion('all')}
                className={`px-2.5 py-1 rounded-full font-semibold transition-all ${
                  selectedRegion === 'all' 
                    ? 'bg-slate-900 text-white' 
                    : 'bg-[#F3F2F1] text-[#605E5C] hover:bg-[#EDEBE9]'
                }`}
              >
                {isSw ? 'Zote' : 'All'} ({tenants.length})
              </button>
              {Object.keys(regionCounts).map(region => (
                <button
                  key={region}
                  onClick={() => setSelectedRegion(region)}
                  className={`px-2.5 py-1 rounded-full font-semibold transition-all shrink-0 ${
                    selectedRegion === region 
                      ? 'bg-emerald-700 text-white' 
                      : 'bg-[#F3F2F1] text-[#605E5C] hover:bg-[#EDEBE9]'
                  }`}
                >
                  {region} ({regionCounts[region]})
                </button>
              ))}
            </div>

            {/* Store List */}
            <div className="divide-y divide-[#F3F2F1] mt-2">
              {filteredTenants.slice(0, 5).map(tenant => {
                const planBadge = 
                  tenant.plan === 'enterprise_chain' ? 'bg-purple-100 text-purple-800 border-purple-200' :
                  tenant.plan === 'biashara_pro' ? 'bg-blue-100 text-blue-800 border-blue-200' :
                  'bg-slate-100 text-slate-700 border-slate-200';

                const statusBadge = 
                  tenant.status === 'active' ? 'bg-emerald-100 text-emerald-800' :
                  tenant.status === 'suspended' ? 'bg-rose-100 text-rose-800' :
                  tenant.status === 'pending_kyc' ? 'bg-amber-100 text-amber-800' :
                  'bg-orange-100 text-orange-800';

                return (
                  <div key={tenant.id} className="py-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:bg-[#FAF9F8] px-2 rounded-lg transition-all">
                    <div className="flex items-start gap-3">
                      <div className="w-10 h-10 rounded-xl bg-slate-100 text-slate-800 font-bold flex items-center justify-center text-base shrink-0 border border-slate-200">
                        {tenant.type === 'pharmacy' ? '💊' :
                         tenant.type === 'hardware' ? '🔨' :
                         tenant.type === 'restaurant' ? '🍽️' :
                         tenant.type === 'retail' ? '🏪' : '✂️'}
                      </div>
                      <div>
                        <div className="flex items-center gap-2 flex-wrap">
                          <h4 className="font-bold text-sm text-[#323130]">{tenant.name}</h4>
                          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${planBadge}`}>
                            {tenant.plan.replace('_', ' ').toUpperCase()}
                          </span>
                          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${statusBadge}`}>
                            {tenant.status.toUpperCase()}
                          </span>
                        </div>
                        <p className="text-xs text-[#605E5C] mt-0.5">
                          {tenant.ownerName} • {tenant.region}, {tenant.district} • TIN: <span className="font-mono">{tenant.tinNumber}</span>
                        </p>
                        <div className="flex items-center gap-3 text-[11px] text-slate-500 mt-1">
                          <span>Branches: <strong className="text-slate-800">{tenant.branchesCount}</strong></span>
                          <span>Monthly GMV: <strong className="text-slate-800">{formatTSh(tenant.monthlyGmvTzs)}</strong></span>
                          <span>TRA EFD: <strong className="text-emerald-700 font-mono text-[10px]">{tenant.traEfdDeviceSerial}</strong></span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 self-end sm:self-center shrink-0">
                      <button
                        onClick={() => onImpersonateTenant(tenant)}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-50 hover:bg-emerald-600 text-emerald-700 hover:text-white border border-emerald-300 text-xs font-bold transition-all cursor-pointer shadow-2xs"
                        title={isSw ? 'Ingia kama duka hili (Live Impersonate)' : 'Impersonate and view as this store'}
                      >
                        <ExternalLink className="w-3.5 h-3.5" />
                        <span>{isSw ? 'Ingia Dukani' : 'Impersonate'}</span>
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="pt-3 border-t border-[#F3F2F1] text-center">
              <button
                onClick={() => onNavigate('super-tenants')}
                className="text-xs font-bold text-emerald-700 hover:text-emerald-800 transition-colors"
              >
                {isSw ? `Tazama maduka yote ${safeTenants.length} →` : `View all ${safeTenants.length} tenant stores →`}
              </button>
            </div>
          </div>

          {/* SaaS Subscriptions Live Stream */}
          <div className="bg-white rounded-xl p-5 border border-[#E1DFDD] shadow-xs">
            <div className="flex items-center justify-between pb-3 border-b border-[#F3F2F1]">
              <h3 className="text-base font-bold text-[#323130] tracking-tight">
                {isSw ? 'Malipo ya Hivi Karibuni ya Usajili (M-Pesa / Tigo / Bank)' : 'Recent SaaS Subscription Payments'}
              </h3>
              <button
                onClick={() => onNavigate('super-subscriptions')}
                className="text-xs font-bold text-blue-600 hover:text-blue-700"
              >
                {isSw ? 'Tazama Yote' : 'View All'}
              </button>
            </div>

            <div className="divide-y divide-[#F3F2F1] mt-2">
              {safeTransactions.slice(0, 4).map(tx => (
                <div key={tx.id} className="py-2.5 flex items-center justify-between text-xs">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-700 flex items-center justify-center font-bold">
                      TZ
                    </div>
                    <div>
                      <h5 className="font-bold text-[#323130]">{tx.storeName}</h5>
                      <p className="text-[11px] text-[#605E5C]">
                        {tx.paymentMethod} • Ref: <span className="font-mono">{tx.reference}</span> • {tx.date}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className="font-black text-emerald-700 font-mono text-sm">
                      +{formatTSh(tx.amountTzs)}
                    </span>
                    <p className="text-[10px] text-slate-500 font-medium">{tx.billingCycle.toUpperCase()}</p>
                  </div>
                </div>
              ))}
              {safeTransactions.length === 0 && (
                <div className="py-6 text-center text-xs text-[#605E5C]">
                  {isSw ? 'Hakuna miamala ya hivi karibuni' : 'No recent transactions recorded'}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Right 1 Column: System Telemetry & Regional Archetype Distribution */}
        <div className="space-y-6">
          {/* Archetype Breakdown */}
          <div className="bg-white rounded-xl p-5 border border-[#E1DFDD] shadow-xs">
            <h3 className="text-sm font-bold text-[#323130] uppercase tracking-wider mb-3">
              {isSw ? 'Maduka kwa Aina ya Biashara' : 'Tenants by Archetype'}
            </h3>
            
            <div className="space-y-2.5">
              <div className="flex items-center justify-between text-xs">
                <span className="flex items-center gap-2 text-slate-700 font-medium">
                  <span>💊</span> Pharmacy & Health
                </span>
                <span className="font-bold text-slate-900">{archetypeCounts.pharmacy || 0}</span>
              </div>
              <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                <div className="h-full bg-emerald-500 rounded-full" style={{ width: '38%' }}></div>
              </div>

              <div className="flex items-center justify-between text-xs">
                <span className="flex items-center gap-2 text-slate-700 font-medium">
                  <span>🔨</span> Hardware & Construction
                </span>
                <span className="font-bold text-slate-900">{archetypeCounts.hardware || 0}</span>
              </div>
              <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                <div className="h-full bg-amber-500 rounded-full" style={{ width: '28%' }}></div>
              </div>

              <div className="flex items-center justify-between text-xs">
                <span className="flex items-center gap-2 text-slate-700 font-medium">
                  <span>🏪</span> Retail & FMCG Supermarkets
                </span>
                <span className="font-bold text-slate-900">{archetypeCounts.retail || 0}</span>
              </div>
              <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                <div className="h-full bg-blue-500 rounded-full" style={{ width: '20%' }}></div>
              </div>

              <div className="flex items-center justify-between text-xs">
                <span className="flex items-center gap-2 text-slate-700 font-medium">
                  <span>🍽️</span> Restaurants & Cafes
                </span>
                <span className="font-bold text-slate-900">{archetypeCounts.restaurant || 0}</span>
              </div>
              <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                <div className="h-full bg-rose-500 rounded-full" style={{ width: '14%' }}></div>
              </div>
            </div>
          </div>

          {/* Real-Time System Telemetry Stream */}
          <div className="bg-white text-[#323130] rounded-xl p-5 border border-[#E1DFDD] shadow-xs">
            <div className="flex items-center justify-between pb-3 border-b border-[#F3F2F1]">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-ping"></span>
                <h3 className="text-sm font-bold text-[#323130] tracking-tight">
                  {isSw ? 'Matukio ya Moja kwa Moja ya Mfumo' : 'Live System Stream'}
                </h3>
              </div>
              <span className="text-[10px] text-emerald-700 font-mono font-bold bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">WS ACTIVE</span>
            </div>

            <div className="space-y-3 mt-3">
              {safeLogs.slice(0, 4).map(log => {
                const badgeColor = 
                  log.level === 'success' ? 'text-emerald-700 bg-emerald-50 border-emerald-200' :
                  log.level === 'warn' ? 'text-amber-800 bg-amber-50 border-amber-200' :
                  log.level === 'error' ? 'text-rose-800 bg-rose-50 border-rose-200' : 'text-blue-700 bg-blue-50 border-blue-200';

                return (
                  <div key={log.id} className="p-2.5 rounded-lg bg-[#FAF9F8] border border-[#EDEBE9] text-xs space-y-1">
                    <div className="flex items-center justify-between">
                      <span className={`font-mono font-bold text-[10px] px-1.5 py-0.5 rounded border ${badgeColor}`}>
                        [{log.service}]
                      </span>
                      <span className="text-[10px] text-[#605E5C] font-mono">{log.timestamp.split(' ')[1]}</span>
                    </div>
                    <p className="text-[11px] text-[#323130] leading-snug font-medium">{log.message}</p>
                    {log.details && (
                      <p className="text-[10px] text-[#605E5C] font-mono truncate">{log.details}</p>
                    )}
                  </div>
                );
              })}
            </div>

            <div className="mt-4 pt-3 border-t border-[#F3F2F1] text-center">
              <button
                onClick={() => onNavigate('super-telemetry')}
                className="text-xs font-bold text-emerald-700 hover:text-emerald-800 transition-colors"
              >
                {isSw ? 'Fungua Ukurasa wa Telemetria Kamili →' : 'Open Full Telemetry Console →'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
