import React, { useMemo, useState } from 'react';
import {
  LayoutDashboard,
  ShoppingCart,
  Package,
  Warehouse,
  ClipboardList,
  Truck,
  FileSignature,
  FileText,
  Users,
  Wallet,
  Receipt,
  BarChart3,
  Compass,
  GitBranch,
  Clock,
  CalendarDays,
  Building2,
  Settings,
  LogOut,
  ChevronDown,
  TrendingUp,
  Store,
  Lock,
  Sparkles,
  type LucideIcon,
} from 'lucide-react';
import { BusinessType, Language, UserRole, AuthUser, StaffRole } from '@/types/v1';
import { getTranslation } from '@/utils/translations';
import { getWorkplace } from '@/lib/businessProfiles';
import { canClaimOwnDailyStipend } from '@/lib/rbac';
import { BrandLogo } from '@/components/ui/BrandLogo';

interface SidebarProps {
  currentView?: string;
  setCurrentView?: (view: string) => void;
  activeTab?: string;
  setActiveTab?: (tab: string) => void;
  role?: UserRole;
  userRole?: UserRole;
  businessType?: BusinessType;
  businessName?: string;
  language: Language;
  onLogout?: () => void;
  lowStockCount?: number;
  overdueCreditCount?: number;
  customersCount?: number;
  upcomingEventsCount?: number;
  pendingApprovalsCount?: number;
  branchesCount?: number;
  isOnline?: boolean;
  currentUser?: AuthUser | null;
  staffRole?: StaffRole;
  branchLabel?: string;
}

type NavItemDef = {
  id: string;
  labelEn: string;
  labelSw: string;
  icon: LucideIcon;
  activeWhen: (view: string) => boolean;
  visible: boolean;
  badge?: string | number;
};

function DukaLogo() {
  return <BrandLogo height={36} className="max-w-[10rem]" />;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentView,
  setCurrentView,
  activeTab,
  setActiveTab,
  role,
  userRole,
  businessType = 'retail',
  businessName = 'Your Business',
  language = 'sw',
  onLogout = () => {},
  lowStockCount = 0,
  overdueCreditCount = 0,
  customersCount = 0,
  upcomingEventsCount = 0,
  branchesCount = 1,
  isOnline = true,
  currentUser,
  staffRole,
  branchLabel,
}) => {
  const [moreOpen, setMoreOpen] = useState(false);
  const effectiveView = currentView || activeTab || 'dashboard';
  const handleSetView = (v: string) => {
    if (setCurrentView) setCurrentView(v);
    if (setActiveTab) setActiveTab(v);
  };

  const currentRole = role || userRole || currentUser?.role || 'vendor_owner';
  const effectiveStaffRole: StaffRole =
    staffRole || currentUser?.staffRole || (currentRole === 'vendor_owner' ? 'Owner' : 'Cashier');
  const activeLang: Language = language === 'en' ? 'en' : 'sw';
  const isSw = activeLang === 'sw';
  const workplace = getWorkplace(businessType, activeLang);
  const t = (key: Parameters<typeof getTranslation>[1]) => getTranslation(activeLang, key);

  const isOwner = currentRole === 'vendor_owner' || effectiveStaffRole === 'Owner';
  const isManager = isOwner || effectiveStaffRole === 'Manager';
  const isPharmacist = effectiveStaffRole === 'Pharmacist';
  const isCashier = effectiveStaffRole === 'Cashier';
  const isStorekeeper = effectiveStaffRole === 'Storekeeper';
  const isAccountant = effectiveStaffRole === 'Accountant';

  const canSeeDashboard = isOwner || isManager || isAccountant;
  const canSeePOS = isOwner || isManager || isCashier || isPharmacist;
  const canSeeCustomers = isOwner || isManager || isCashier || isAccountant || isPharmacist;
  const canSeeInventory = isOwner || isManager || isStorekeeper || isPharmacist;
  const canSeeSuppliers = isOwner || isManager || isStorekeeper || isAccountant;
  const canSeeBI = isOwner || isManager || isAccountant;
  const canSeeReceivables = isOwner || isManager || isCashier || isAccountant;
  const canSeeBranches = isOwner || isManager;
  const canSeeExpenses = isOwner || isManager || isAccountant;
  const canSeePredictive = isOwner || isManager || isStorekeeper || isPharmacist;
  const canSeeReports = isOwner || isManager || isAccountant;
  const canSeeDocuments = isOwner || isManager || isAccountant;
  const canSeeCalendar = isOwner || isManager || isPharmacist || isStorekeeper;
  const canSeeAccountSettings = isOwner;

  const branchName = branchLabel || currentUser?.branch || (isSw ? 'Tawi Kuu' : 'Main Branch');
  const branchSubtitle = `${branchName} · ${isSw ? workplace.label_sw : workplace.label_en}`;

  const primaryNav: NavItemDef[] = useMemo(
    () => [
      {
        id: 'dashboard',
        labelEn: 'Dashboard',
        labelSw: 'Dashibodi',
        icon: LayoutDashboard,
        activeWhen: v => v === 'dashboard',
        visible: canSeeDashboard,
        badge: lowStockCount > 0 ? lowStockCount : undefined,
      },
      {
        id: 'pos',
        labelEn: 'Sales',
        labelSw: 'Mauzo',
        icon: ShoppingCart,
        activeWhen: v => v === 'pos',
        visible: canSeePOS,
      },
      {
        id: 'inventory',
        labelEn: 'Products',
        labelSw: 'Bidhaa',
        icon: Package,
        activeWhen: v => v === 'inventory',
        visible: canSeeInventory,
      },
      {
        id: 'inventory',
        labelEn: 'Stock',
        labelSw: 'Stoo',
        icon: Warehouse,
        activeWhen: v => v === 'inventory',
        visible: canSeeInventory,
        badge: lowStockCount > 0 ? `${lowStockCount} low` : undefined,
      },
      {
        id: 'suppliers',
        labelEn: 'Purchases',
        labelSw: 'Manunuzi',
        icon: ClipboardList,
        activeWhen: v => v === 'suppliers',
        visible: canSeeSuppliers,
      },
      {
        id: 'suppliers',
        labelEn: 'Suppliers',
        labelSw: 'Wasambazaji',
        icon: Truck,
        activeWhen: v => v === 'suppliers',
        visible: canSeeSuppliers,
      },
      {
        id: 'reports',
        labelEn: 'Quotations',
        labelSw: 'Nukuu Bei',
        icon: FileSignature,
        activeWhen: v => v === 'reports' || v === 'analytics',
        visible: canSeeReports,
      },
      {
        id: 'customers',
        labelEn: 'Customers',
        labelSw: 'Wateja',
        icon: Users,
        activeWhen: v => v === 'customers',
        visible: canSeeCustomers,
        badge: customersCount > 0 ? customersCount : undefined,
      },
      {
        id: 'receivables-payables',
        labelEn: 'Credit',
        labelSw: 'Mikopo',
        icon: Wallet,
        activeWhen: v =>
          v === 'receivables-payables' ||
          v === 'debts' ||
          v === 'receivables' ||
          v === 'payables',
        visible: canSeeReceivables,
        badge: overdueCreditCount > 0 ? overdueCreditCount : undefined,
      },
      {
        id: 'expenses-payroll',
        labelEn: 'Expenses',
        labelSw: 'Matumizi',
        icon: Receipt,
        activeWhen: v =>
          v === 'expenses-payroll' || v === 'expenses' || v === 'payroll',
        visible: canSeeExpenses,
      },
    ],
    [
      canSeeDashboard,
      canSeePOS,
      canSeeInventory,
      canSeeSuppliers,
      canSeeReports,
      canSeeCustomers,
      canSeeReceivables,
      canSeeExpenses,
      lowStockCount,
      customersCount,
      overdueCreditCount,
    ],
  );

  const moreNav: NavItemDef[] = useMemo(
    () => [
      {
        id: 'documents',
        labelEn: 'Documents',
        labelSw: 'Hati',
        icon: FileText,
        activeWhen: v => v === 'documents',
        visible: canSeeDocuments,
      },
      {
        id: 'pending-transactions',
        labelEn: 'Uncompleted Sales',
        labelSw: 'Mauzo Yasiyokamilika',
        icon: Clock,
        activeWhen: v => v === 'pending-transactions',
        visible: canSeePOS,
      },
      {
        id: 'bi-analytics',
        labelEn: 'Profit BI',
        labelSw: 'Uchambuzi wa Faida',
        icon: BarChart3,
        activeWhen: v => v === 'bi-analytics' || v === 'bi',
        visible: canSeeBI,
      },
      {
        id: 'product-geo-matrix',
        labelEn: 'Geo Matrix',
        labelSw: 'Ramani ya Mauzo',
        icon: Compass,
        activeWhen: v => v === 'product-geo-matrix' || v === 'geo-analytics',
        visible: canSeeBI,
      },
      {
        id: 'predictive',
        labelEn: 'AI Restock',
        labelSw: 'Utabiri wa Stoo',
        icon: TrendingUp,
        activeWhen: v => v === 'predictive' || v === 'forecasting',
        visible: canSeePredictive,
      },
      {
        id: 'branches',
        labelEn: 'Branches',
        labelSw: 'Matawi',
        icon: GitBranch,
        activeWhen: v => v === 'branches' || v === 'branch-management',
        visible: canSeeBranches,
        badge: branchesCount,
      },
      {
        id: 'calendar',
        labelEn: 'Calendar',
        labelSw: 'Kalenda',
        icon: CalendarDays,
        activeWhen: v => v === 'calendar',
        visible: canSeeCalendar,
        badge: upcomingEventsCount > 0 ? upcomingEventsCount : undefined,
      },
      {
        id: 'staff-site',
        labelEn: 'Staff Station',
        labelSw: 'Kituo cha Mhudumu',
        icon: Building2,
        activeWhen: v => v === 'staff-site',
        visible: canClaimOwnDailyStipend(currentUser) || canSeeExpenses || canSeePOS,
      },
      ...workplace.nav_extra.map(extra => ({
        id: `workplace-${extra.id}`,
        labelEn: extra.label_en,
        labelSw: extra.label_sw,
        icon: Sparkles,
        activeWhen: (v: string) => v === `workplace-${extra.id}`,
        visible: canSeePOS,
      })),
    ],
    [
      canSeePOS,
      canSeeBI,
      canSeeDocuments,
      canSeePredictive,
      canSeeBranches,
      canSeeCalendar,
      branchesCount,
      upcomingEventsCount,
      workplace.nav_extra,
    ],
  );

  const visiblePrimary = primaryNav.filter(n => n.visible);
  const visibleMore = moreNav.filter(n => n.visible);
  const moreActive = visibleMore.some(n => n.activeWhen(effectiveView));

  const renderNavButton = (item: NavItemDef, index: number) => {
    const active = item.activeWhen(effectiveView);
    const Icon = item.icon;
    const label = isSw ? item.labelSw : item.labelEn;

    return (
      <button
        key={`${item.id}-${item.labelEn}-${index}`}
        id={`nav-${item.id}-${item.labelEn.toLowerCase().replace(/\s+/g, '-')}`}
        type="button"
        onClick={() => handleSetView(item.id)}
        className={`group relative w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-left transition-all duration-150 cursor-pointer ${
          active
            ? 'bg-white/[0.08] text-white'
            : 'text-slate-300 hover:bg-white/[0.05] hover:text-white'
        }`}
      >
        {active && (
          <span className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-6 rounded-r-full bg-[#f97316]" />
        )}
        <Icon
          className={`w-[1.125rem] h-[1.125rem] shrink-0 ${
            active ? 'text-[#f97316]' : 'text-slate-400 group-hover:text-slate-200'
          }`}
          strokeWidth={active ? 2.25 : 1.75}
        />
        <span className={`flex-1 text-[0.9375rem] truncate ${active ? 'font-semibold' : 'font-medium'}`}>
          {label}
        </span>
        {item.badge !== undefined && item.badge !== 0 && (
          <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-md bg-white/10 text-slate-200 shrink-0">
            {item.badge}
          </span>
        )}
      </button>
    );
  };

  return (
    <aside
      id="duka-sidebar"
      className="w-[15.5rem] min-w-[15.5rem] h-full flex flex-col bg-[#1a2832] text-white select-none border-r border-[#243844]"
    >
      {/* Brand */}
      <div className="px-4 pt-5 pb-4">
        <DukaLogo />
      </div>

      {/* Branch selector */}
      {canSeeBranches && (
        <div className="px-3 pb-4">
          <button
            type="button"
            onClick={() => handleSetView('branches')}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl bg-[#243844] hover:bg-[#2a424f] border border-[#2f4a58] transition-colors cursor-pointer text-left"
          >
            <div className="w-9 h-9 rounded-lg bg-[#f97316]/15 flex items-center justify-center shrink-0">
              <Store className="w-4 h-4 text-[#f97316]" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-sm font-semibold text-white truncate">{branchName}</div>
              <div className="text-[11px] text-slate-400 truncate">{branchSubtitle}</div>
            </div>
            <ChevronDown className="w-4 h-4 text-slate-500 shrink-0" />
          </button>
        </div>
      )}

      {/* Primary navigation */}
      <nav className="flex-1 overflow-y-auto px-2 pb-2 scrollbar-thin">
        <div className="space-y-0.5">
          {visiblePrimary.map((item, i) => renderNavButton(item, i))}
        </div>

        {visibleMore.length > 0 && (
          <div className="mt-4 pt-3 border-t border-[#2a3f4d]">
            <button
              type="button"
              onClick={() => setMoreOpen(o => !o)}
              className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-bold uppercase tracking-wider cursor-pointer ${
                moreActive ? 'text-[#f97316]' : 'text-slate-500 hover:text-slate-300'
              }`}
            >
              <span>{isSw ? 'Zaidi' : 'More tools'}</span>
              <ChevronDown className={`w-3.5 h-3.5 transition-transform ${moreOpen ? 'rotate-180' : ''}`} />
            </button>
            {(moreOpen || moreActive) && (
              <div className="mt-1 space-y-0.5">
                {visibleMore.map((item, i) => renderNavButton(item, i))}
              </div>
            )}
          </div>
        )}
      </nav>

      {/* Footer */}
      <div className="p-3 border-t border-[#2a3f4d] space-y-1">
        {canSeeAccountSettings ? (
          <button
            id="nav-profile"
            type="button"
            onClick={() => handleSetView('profile')}
            className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg cursor-pointer transition-colors ${
              effectiveView === 'profile' || effectiveView === 'settings'
                ? 'bg-white/[0.08] text-white'
                : 'text-slate-400 hover:text-white hover:bg-white/[0.05]'
            }`}
          >
            <Settings className="w-4 h-4 shrink-0" />
            <span className="text-sm font-medium truncate">{isSw ? 'Mipangilio' : 'Settings'}</span>
          </button>
        ) : (
          <div className="px-3 py-2 text-xs text-slate-500 flex items-center gap-2">
            <Lock className="w-3.5 h-3.5" />
            <span className="truncate">{isSw ? 'Mipangilio — Mmiliki' : 'Settings — Owner'}</span>
          </div>
        )}

        <button
          id="nav-logout"
          type="button"
          onClick={onLogout}
          className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-slate-400 hover:text-rose-300 hover:bg-rose-950/30 transition-colors cursor-pointer"
        >
          <LogOut className="w-4 h-4 shrink-0" />
          <span className="text-sm font-medium truncate">{t('logout')}</span>
        </button>

        <div className="flex items-center gap-2.5 px-3 py-2.5 mt-1 rounded-xl bg-[#243844]/80">
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#f97316] to-[#ea580c] flex items-center justify-center text-xs font-bold text-white shrink-0">
            {currentUser?.name?.slice(0, 1).toUpperCase() || 'U'}
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-xs font-semibold text-white truncate">{currentUser?.name || 'User'}</div>
            <div className="text-[10px] text-slate-400 truncate">{effectiveStaffRole}</div>
          </div>
          <span
            className={`w-2 h-2 rounded-full shrink-0 ${isOnline ? 'bg-emerald-500' : 'bg-rose-500'}`}
            title={isOnline ? 'Online' : 'Offline'}
          />
        </div>
      </div>
    </aside>
  );
};
