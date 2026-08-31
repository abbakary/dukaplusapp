import React from 'react';
import { 
  Activity, 
  Building2, 
  CheckCircle2, 
  ChevronRight, 
  CreditCard, 
  Film, 
  HardDrive, 
  Layers, 
  LayoutDashboard, 
  LogOut, 
  Radio, 
  RadioTower, 
  Server, 
  ShieldAlert, 
  ShieldCheck, 
  Store, 
  TrendingUp, 
  UserCheck, 
  Users, 
  Wifi, 
  Zap
} from 'lucide-react';
import { Language, UserRole } from '@/types/v1';

interface SuperAdminSidebarProps {
  currentView?: string;
  setCurrentView?: (view: string) => void;
  activeTab?: string;
  setActiveTab?: (view: string) => void;
  language: Language;
  onLogout: () => void;
  pendingApprovalsCount?: number;
  totalTenantsCount?: number;
  tenantsCount?: number;
  telemetryErrorsCount?: number;
  onSwitchToVendorMode?: () => void;
  onGoToLanding?: () => void;
}

export const SuperAdminSidebar: React.FC<SuperAdminSidebarProps> = ({
  currentView,
  setCurrentView,
  activeTab,
  setActiveTab,
  language = 'sw',
  onLogout,
  pendingApprovalsCount = 6,
  totalTenantsCount,
  tenantsCount = 148,
  telemetryErrorsCount = 0,
  onSwitchToVendorMode,
  onGoToLanding
}) => {
  const isSw = language === 'sw';
  const selectedTab = activeTab || currentView || 'super-dashboard';
  const handleNav = (tab: string) => {
    if (setActiveTab) setActiveTab(tab);
    if (setCurrentView) setCurrentView(tab);
  };
  const countTenants = tenantsCount ?? totalTenantsCount ?? 148;

  return (
    <aside 
      id="super-admin-sidebar" 
      className="w-[21rem] min-w-[21rem] h-[calc(100dvh-1.5rem)] flex flex-col rounded-[1.75rem] overflow-hidden bg-gradient-to-b from-[#2a2f58] via-[#24284A] to-[#151833] text-white shadow-[0_28px_60px_-16px_rgba(0,0,0,0.55),0_0_0_1px_rgba(255,255,255,0.08)] select-none transition-all duration-300 font-sans"
    >
      {/* Top Header: Platform Provider Branding */}
      <div className="p-5 border-b border-[#323762]">
        <div className="flex items-center gap-3.5">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-emerald-500 via-teal-600 to-cyan-700 flex items-center justify-center text-white font-bold text-xl shadow-xl ring-2 ring-white/10 shrink-0">
            <Server className="w-6 h-6 text-white" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="font-black text-2xl text-white tracking-tight leading-none">Duka+ Cloud</h1>
              <span className="text-[10px] uppercase font-black px-2 py-0.5 rounded-full bg-emerald-500/30 text-emerald-300 border border-emerald-400/40">
                PROVIDER
              </span>
            </div>
            <p className="text-xs text-slate-300 font-medium truncate mt-1">
              {isSw ? 'Mtoa Huduma wa Mfumo' : 'SaaS System Provider'}
            </p>
          </div>
        </div>

        {/* Live Infrastructure Health Bar */}
        <div className="mt-4 flex items-center justify-between px-4 py-2.5 rounded-2xl bg-[#30355D] border border-white/10 text-xs shadow-inner">
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
            <span className="text-xs font-mono text-emerald-300 font-bold">tz-dar-cluster-1</span>
          </div>
          <span className="text-xs px-2.5 py-0.5 rounded-md bg-emerald-950 text-emerald-300 font-mono font-black border border-emerald-700">
            99.98% OK
          </span>
        </div>
      </div>

      {/* Navigation Links Scrollable Area */}
      <div className="flex-1 overflow-y-auto px-4 py-5 space-y-6">
        {/* SECTION 1: PLATFORM INTELLIGENCE */}
        <div>
          <div className="px-3 mb-2 text-xs font-black text-slate-300/80 tracking-wider uppercase">
            {isSw ? 'Uangalizi wa Mfumo' : 'Platform Intelligence'}
          </div>
          <div className="space-y-2">
            <button
              id="super-nav-dashboard"
              onClick={() => handleNav('super-dashboard')}
              className={`w-full flex items-center justify-between px-4 py-3 rounded-2xl text-[15px] font-bold transition-all cursor-pointer ${
                selectedTab === 'super-dashboard'
                  ? 'bg-emerald-600 text-white shadow-lg font-extrabold ring-1 ring-white/20'
                  : 'text-slate-200 hover:bg-[#30355D] hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3.5">
                <div className={`p-2 rounded-xl ${selectedTab === 'super-dashboard' ? 'bg-white/20' : 'bg-white/5'}`}>
                  <LayoutDashboard className="w-5 h-5" />
                </div>
                <span>{isSw ? 'Dashibodi Kuu ya Mfumo' : 'Provider Dashboard'}</span>
              </div>
              <span className="text-xs font-mono font-extrabold px-2.5 py-0.5 rounded-lg bg-emerald-900/80 text-emerald-200 border border-emerald-600/50">
                LIVE
              </span>
            </button>

            <button
              id="super-nav-telemetry"
              onClick={() => handleNav('super-telemetry')}
              className={`w-full flex items-center justify-between px-4 py-3 rounded-2xl text-[15px] font-bold transition-all cursor-pointer ${
                selectedTab === 'super-telemetry'
                  ? 'bg-emerald-600 text-white shadow-lg font-extrabold ring-1 ring-white/20'
                  : 'text-slate-200 hover:bg-[#30355D] hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3.5">
                <div className={`p-2 rounded-xl ${selectedTab === 'super-telemetry' ? 'bg-white/20' : 'bg-white/5'}`}>
                  <Activity className="w-5 h-5 text-cyan-300" />
                </div>
                <span>{isSw ? 'Telemetria & TRA EFD' : 'API & TRA Telemetry'}</span>
              </div>
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-400"></span>
            </button>
          </div>
        </div>

        {/* SECTION 2: TENANT & STORE OPERATIONS */}
        <div>
          <div className="px-3 mb-2 text-xs font-black text-slate-300/80 tracking-wider uppercase">
            {isSw ? 'Usimamizi wa Maduka (Tenants)' : 'Tenant Management'}
          </div>
          <div className="space-y-2">
            <button
              id="super-nav-tenants"
              onClick={() => handleNav('super-tenants')}
              className={`w-full flex items-center justify-between px-4 py-3 rounded-2xl text-[15px] font-bold transition-all cursor-pointer ${
                selectedTab === 'super-tenants'
                  ? 'bg-emerald-600 text-white shadow-lg font-extrabold ring-1 ring-white/20'
                  : 'text-slate-200 hover:bg-[#30355D] hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3.5">
                <div className={`p-2 rounded-xl ${selectedTab === 'super-tenants' ? 'bg-white/20' : 'bg-white/5'}`}>
                  <Building2 className="w-5 h-5 text-blue-300" />
                </div>
                <span>{isSw ? 'Maduka Yote Tanzania' : 'Stores Directory'}</span>
              </div>
              <span className="text-xs font-bold px-2.5 py-0.5 rounded-lg bg-white/10 text-slate-200">
                {countTenants}
              </span>
            </button>

            <button
              id="super-nav-approvals"
              onClick={() => handleNav('super-approvals')}
              className={`w-full flex items-center justify-between px-4 py-3 rounded-2xl text-[15px] font-bold transition-all cursor-pointer ${
                selectedTab === 'super-approvals' || selectedTab === 'admin-approvals'
                  ? 'bg-emerald-600 text-white shadow-lg font-extrabold ring-1 ring-white/20'
                  : 'text-slate-200 hover:bg-[#30355D] hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3.5">
                <div className={`p-2 rounded-xl ${selectedTab === 'super-approvals' || selectedTab === 'admin-approvals' ? 'bg-white/20' : 'bg-white/5'}`}>
                  <ShieldCheck className="w-5 h-5 text-amber-300" />
                </div>
                <span>{isSw ? 'Uthibitishaji wa Leseni (KYC)' : 'KYC & Approvals'}</span>
              </div>
              {pendingApprovalsCount > 0 && (
                <span className="w-6 h-6 rounded-full bg-amber-500 text-slate-900 text-xs font-black flex items-center justify-center shadow-xs">
                  {pendingApprovalsCount}
                </span>
              )}
            </button>
          </div>
        </div>

        {/* SECTION 3: BILLING & SAAS MONETIZATION */}
        <div>
          <div className="px-3 mb-2 text-xs font-black text-slate-300/80 tracking-wider uppercase">
            {isSw ? 'Mapato ya SaaS & Vifurushi' : 'Billing & Monetization'}
          </div>
          <div className="space-y-2">
            <button
              id="super-nav-subscriptions"
              onClick={() => handleNav('super-subscriptions')}
              className={`w-full flex items-center justify-between px-4 py-3 rounded-2xl text-[15px] font-bold transition-all cursor-pointer ${
                selectedTab === 'super-subscriptions'
                  ? 'bg-emerald-600 text-white shadow-lg font-extrabold ring-1 ring-white/20'
                  : 'text-slate-200 hover:bg-[#30355D] hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3.5">
                <div className={`p-2 rounded-xl ${selectedTab === 'super-subscriptions' ? 'bg-white/20' : 'bg-white/5'}`}>
                  <CreditCard className="w-5 h-5 text-emerald-300" />
                </div>
                <span>{isSw ? 'Usajili & Malipo ya M-Pesa' : 'Subscriptions & Revenue'}</span>
              </div>
              <span className="text-xs text-emerald-300 font-mono font-black">TZS</span>
            </button>
          </div>
        </div>

        {/* SECTION 4: PLATFORM GOVERNANCE & COMMS */}
        <div>
          <div className="px-3 mb-2 text-xs font-black text-slate-300/80 tracking-wider uppercase">
            {isSw ? 'Mawasiliano & Wafanyakazi' : 'Comms & Operations'}
          </div>
          <div className="space-y-2">
            <button
              id="super-nav-broadcasts"
              onClick={() => handleNav('super-broadcasts')}
              className={`w-full flex items-center justify-between px-4 py-3 rounded-2xl text-[15px] font-bold transition-all cursor-pointer ${
                selectedTab === 'super-broadcasts'
                  ? 'bg-emerald-600 text-white shadow-lg font-extrabold ring-1 ring-white/20'
                  : 'text-slate-200 hover:bg-[#30355D] hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3.5">
                <div className={`p-2 rounded-xl ${selectedTab === 'super-broadcasts' ? 'bg-white/20' : 'bg-white/5'}`}>
                  <Radio className="w-5 h-5 text-purple-300" />
                </div>
                <span>{isSw ? 'Matangazo ya Mfumo (SMS)' : 'Global Broadcasts'}</span>
              </div>
              <span className="text-xs px-2 py-0.5 rounded-lg bg-purple-950 text-purple-300 border border-purple-800 font-bold">
                SMS/App
              </span>
            </button>

            <button
              id="super-nav-showcase"
              onClick={() => handleNav('super-showcase')}
              className={`w-full flex items-center justify-between px-4 py-3 rounded-2xl text-[15px] font-bold transition-all cursor-pointer ${
                selectedTab === 'super-showcase'
                  ? 'bg-emerald-600 text-white shadow-lg font-extrabold ring-1 ring-white/20'
                  : 'text-slate-200 hover:bg-[#30355D] hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3.5">
                <div className={`p-2 rounded-xl ${selectedTab === 'super-showcase' ? 'bg-white/20' : 'bg-white/5'}`}>
                  <Film className="w-5 h-5 text-teal-300" />
                </div>
                <span>{isSw ? 'Onyesha — Ukurasa wa Mwanzo' : 'Landing Showcase'}</span>
              </div>
              <span className="text-xs px-2 py-0.5 rounded-lg bg-teal-950 text-teal-300 border border-teal-800 font-bold">
                Video/Ads
              </span>
            </button>

            <button
              id="super-nav-operators"
              onClick={() => handleNav('super-operators')}
              className={`w-full flex items-center justify-between px-4 py-3 rounded-2xl text-[15px] font-bold transition-all cursor-pointer ${
                selectedTab === 'super-operators'
                  ? 'bg-emerald-600 text-white shadow-lg font-extrabold ring-1 ring-white/20'
                  : 'text-slate-200 hover:bg-[#30355D] hover:text-white'
              }`}
            >
              <div className="flex items-center gap-3.5">
                <div className={`p-2 rounded-xl ${selectedTab === 'super-operators' ? 'bg-white/20' : 'bg-white/5'}`}>
                  <UserCheck className="w-5 h-5 text-indigo-300" />
                </div>
                <span>{isSw ? 'Wafanyakazi wa Mfumo (RBAC)' : 'Provider Staff RBAC'}</span>
              </div>
              <span className="text-xs text-slate-300 font-bold">4 Admins</span>
            </button>
          </div>
        </div>

        {/* SECTION 5: MODE SWITCHER & QUICK ACTIONS */}
        <div className="pt-3 border-t border-[#323762]">
          <div className="px-3 mb-2 text-xs font-black text-amber-300 tracking-wider uppercase flex items-center gap-1.5">
            <Zap className="w-3.5 h-3.5 text-amber-300" />
            <span>{isSw ? 'Kubadili Hali (Mode Switch)' : 'Mode Switch'}</span>
          </div>

          <div className="space-y-2">
            {onSwitchToVendorMode && (
              <button
                id="super-switch-vendor-mode"
                onClick={onSwitchToVendorMode}
                className="w-full flex items-center justify-between px-4 py-3 rounded-2xl text-xs sm:text-sm font-bold bg-[#30355D] hover:bg-[#3B4272] text-amber-300 border border-amber-400/30 transition-all cursor-pointer group shadow-sm"
              >
                <div className="flex items-center gap-3">
                  <Store className="w-5 h-5 text-amber-300 group-hover:scale-110 transition-transform" />
                  <span>{isSw ? 'Fungua Tovuti ya Duka (Shop View)' : 'Switch to Shop Portal'}</span>
                </div>
                <ChevronRight className="w-4 h-4 text-amber-300" />
              </button>
            )}

            {onGoToLanding && (
              <button
                id="super-nav-landing"
                onClick={onGoToLanding}
                className="w-full flex items-center gap-3.5 px-4 py-3 rounded-2xl text-[15px] font-bold text-slate-200 hover:bg-[#30355D] hover:text-white transition-all cursor-pointer"
              >
                <div className="p-2 rounded-xl bg-white/5">
                  <Building2 className="w-5 h-5 text-blue-300" />
                </div>
                <span>{isSw ? 'Ukurasa wa Mwanzo (Landing)' : 'Landing Page'}</span>
              </button>
            )}

            <button
              id="super-nav-logout"
              onClick={onLogout}
              className="w-full flex items-center gap-3.5 px-4 py-3 rounded-2xl text-[15px] font-black text-rose-300 hover:bg-rose-900/30 hover:text-rose-200 transition-all cursor-pointer mt-2"
            >
              <div className="p-2 rounded-xl bg-rose-500/20 text-rose-400">
                <LogOut className="w-5 h-5" />
              </div>
              <span>{isSw ? 'Ondoka kwenye Mfumo (Logout)' : 'Sign Out'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Bottom Footer: Super Admin Operator Badge & Node */}
      <div className="p-4 border-t border-[#323762] bg-[#1E213E] text-xs flex items-center justify-between text-slate-300">
        <div className="flex items-center gap-2.5">
          <div className="w-3 h-3 rounded-full bg-emerald-400 ring-2 ring-emerald-500/30"></div>
          <span className="font-extrabold text-slate-200">System Operator #1</span>
        </div>
        <span className="text-xs text-emerald-300 font-mono font-black">PROV-TZ</span>
      </div>
    </aside>
  );
};
