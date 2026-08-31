import React, { useState } from 'react';
import { 
  ShieldCheck, 
  CheckCircle2, 
  XCircle, 
  Building2, 
  MapPin, 
  FileText, 
  Phone, 
  Mail, 
  AlertCircle,
  Sparkles,
  ExternalLink,
  Store,
  Check,
  X,
  Filter,
  UserCheck
} from 'lucide-react';
import { BusinessType, Language, UserRole, VendorApplication } from '@/types/v1';
import { getTranslation } from '@/utils/translations';
import confetti from 'canvas-confetti';

interface AdminApprovalsViewProps {
  language: Language;
  applications: VendorApplication[];
  setApplications: React.Dispatch<React.SetStateAction<VendorApplication[]>>;
  onImpersonateVendor?: (app: VendorApplication) => void;
}

export const AdminApprovalsView: React.FC<AdminApprovalsViewProps> = ({
  language,
  applications,
  setApplications,
  onImpersonateVendor,
}) => {
  const [filterStatus, setFilterStatus] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [rejectionTargetId, setRejectionTargetId] = useState<string | null>(null);
  const [customRejectionReason, setCustomRejectionReason] = useState<string>('Incomplete BRELA / TMDA certification details. Please provide updated 2026 renewal.');

  const isSw = language === 'sw';
  const t = (key: any) => getTranslation(language, key);

  const handleApprove = (id: string) => {
    setApplications(prev => prev.map(app => 
      app.id === id ? { ...app, status: 'approved' } : app
    ));
    confetti({
      particleCount: 50,
      spread: 60,
      origin: { y: 0.7 },
    });
  };

  const handleApproveAll = () => {
    setApplications(prev => prev.map(app => ({ ...app, status: 'approved' })));
    confetti({
      particleCount: 80,
      spread: 90,
      origin: { y: 0.6 },
    });
  };

  const handleConfirmReject = () => {
    if (!rejectionTargetId) return;
    setApplications(prev => prev.map(app => 
      app.id === rejectionTargetId ? { ...app, status: 'rejected', rejectionReason: customRejectionReason } : app
    ));
    setRejectionTargetId(null);
  };

  const pendingCount = applications.filter(a => a.status === 'pending').length;
  const approvedCount = applications.filter(a => a.status === 'approved').length;
  const rejectedCount = applications.filter(a => a.status === 'rejected').length;

  const filteredApps = applications.filter(app => {
    if (filterStatus === 'all') return true;
    return app.status === filterStatus;
  });

  return (
    <div className="space-y-6 pb-12 font-sans">
      {/* Top Header */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-bold text-[#323130] tracking-tight">{t('adminApprovals')}</h2>
            <span className="px-2 py-0.5 rounded-full bg-[#6264A7]/10 text-[#6264A7] text-xs font-extrabold uppercase">
              Super Admin RBAC
            </span>
          </div>
          <p className="text-xs text-[#605E5C]">
            {isSw 
              ? 'Kagua leseni za maduka (BRELA, TMDA, TRA TIN), idhinisha au kataa maombi ya wauzaji, na dhibiti biashara zote'
              : 'Verify business licenses (BRELA, TMDA, TRA TIN), activate vendor accounts, or provide rejection feedback.'
            }
          </p>
        </div>

        {pendingCount > 0 && (
          <button
            onClick={handleApproveAll}
            className="px-4 py-2 bg-[#107C10] hover:bg-[#0e6b0e] text-white text-xs font-bold rounded-lg shadow-xs flex items-center gap-1.5 cursor-pointer"
          >
            <Sparkles className="w-4 h-4 text-amber-200" />
            <span>{isSw ? 'Idhinisha Maombi Yote (Approve All)' : 'Approve All Pending'}</span>
          </button>
        )}
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <div 
          onClick={() => setFilterStatus('all')}
          className={`p-4 rounded-xl border transition-all cursor-pointer ${
            filterStatus === 'all' ? 'bg-white border-[#6264A7] ring-2 ring-[#6264A7]/20 shadow-xs' : 'bg-[#F8F8F8] border-[#EDEBE9]'
          }`}
        >
          <div className="text-[11px] font-semibold text-[#605E5C]">{isSw ? 'Jumla ya Maduka' : 'Total Applications'}</div>
          <div className="text-2xl font-extrabold text-[#323130] mt-1">{applications.length}</div>
        </div>

        <div 
          onClick={() => setFilterStatus('pending')}
          className={`p-4 rounded-xl border transition-all cursor-pointer ${
            filterStatus === 'pending' ? 'bg-white border-amber-500 ring-2 ring-amber-500/20 shadow-xs' : 'bg-[#F8F8F8] border-[#EDEBE9]'
          }`}
        >
          <div className="text-[11px] font-semibold text-amber-700">{isSw ? 'Yanayosubiri Idhini' : 'Pending Review'}</div>
          <div className="text-2xl font-extrabold text-amber-600 mt-1">{pendingCount}</div>
        </div>

        <div 
          onClick={() => setFilterStatus('approved')}
          className={`p-4 rounded-xl border transition-all cursor-pointer ${
            filterStatus === 'approved' ? 'bg-white border-emerald-500 ring-2 ring-emerald-500/20 shadow-xs' : 'bg-[#F8F8F8] border-[#EDEBE9]'
          }`}
        >
          <div className="text-[11px] font-semibold text-emerald-700">{isSw ? 'Yaliyoidhinishwa' : 'Active & Approved'}</div>
          <div className="text-2xl font-extrabold text-[#107C10] mt-1">{approvedCount}</div>
        </div>

        <div 
          onClick={() => setFilterStatus('rejected')}
          className={`p-4 rounded-xl border transition-all cursor-pointer ${
            filterStatus === 'rejected' ? 'bg-white border-rose-500 ring-2 ring-rose-500/20 shadow-xs' : 'bg-[#F8F8F8] border-[#EDEBE9]'
          }`}
        >
          <div className="text-[11px] font-semibold text-rose-700">{isSw ? 'Yaliyokataliwa' : 'Rejected'}</div>
          <div className="text-2xl font-extrabold text-[#D13438] mt-1">{rejectedCount}</div>
        </div>
      </div>

      {/* Applications List */}
      <div className="space-y-3">
        {filteredApps.map(app => (
          <div 
            key={app.id} 
            className="bg-white rounded-xl border border-[#E1DFDD] p-5 shadow-xs flex flex-wrap items-center justify-between gap-4 hover:border-[#C8C6C4] transition-all"
          >
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-[#6264A7]/10 text-[#6264A7] flex items-center justify-center font-bold text-lg shrink-0">
                <Store className="w-6 h-6" />
              </div>
              <div>
                <div className="flex items-center gap-2 flex-wrap">
                  <h3 className="text-base font-bold text-[#323130]">{app.businessName}</h3>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#F3F2F1] text-[#323130] uppercase">
                    {app.type}
                  </span>
                  <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full uppercase ${
                    app.status === 'approved' ? 'bg-emerald-100 text-emerald-800' :
                    app.status === 'rejected' ? 'bg-rose-100 text-rose-800' : 'bg-amber-100 text-amber-800'
                  }`}>
                    {app.status}
                  </span>
                </div>

                <div className="flex flex-wrap items-center gap-3 text-xs text-[#605E5C] mt-1">
                  <span>👤 <strong>{app.ownerName}</strong></span>
                  <span>•</span>
                  <span className="flex items-center gap-1"><MapPin className="w-3.5 h-3.5 text-[#107C10]" /> {app.location}</span>
                  <span>•</span>
                  <span>TIN: <strong className="font-mono text-[#0078D4]">{app.tinNumber}</strong></span>
                  <span>•</span>
                  <span>License: <strong className="font-mono text-[#323130]">{app.licenseNumber}</strong></span>
                  <span>•</span>
                  <span>📅 {app.submittedDate}</span>
                </div>

                {app.status === 'rejected' && app.rejectionReason && (
                  <div className="mt-2 text-xs text-rose-800 bg-rose-50 border border-rose-200 px-3 py-1 rounded-lg">
                    <strong>Rejection Reason:</strong> {app.rejectionReason}
                  </div>
                )}
              </div>
            </div>

            <div className="flex items-center gap-2">
              {app.status === 'pending' && (
                <>
                  <button
                    onClick={() => {
                      setRejectionTargetId(app.id);
                      setCustomRejectionReason('Expired / Unverified TMDA or BRELA license certificate.');
                    }}
                    className="px-3.5 py-1.5 rounded-lg border border-rose-200 text-[#D13438] hover:bg-rose-50 text-xs font-semibold cursor-pointer"
                  >
                    Reject
                  </button>
                  <button
                    onClick={() => handleApprove(app.id)}
                    className="px-4 py-1.5 rounded-lg bg-[#107C10] hover:bg-[#0e6b0e] text-white text-xs font-bold shadow-xs cursor-pointer"
                  >
                    ✓ Approve & Activate
                  </button>
                </>
              )}

              {app.status === 'approved' && onImpersonateVendor && (
                <button
                  onClick={() => onImpersonateVendor(app)}
                  className="px-3.5 py-1.5 rounded-lg bg-[#F8F8F8] border border-[#C8C6C4] hover:bg-[#F3F2F1] text-xs font-semibold text-[#323130] flex items-center gap-1.5 cursor-pointer shadow-xs"
                  title="Switch and test this vendor's portal"
                >
                  <ExternalLink className="w-3.5 h-3.5 text-[#0078D4]" />
                  <span>{isSw ? 'Fungua Kama Mwenye Duka' : 'Log in as this Vendor'}</span>
                </button>
              )}

              {app.status === 'rejected' && (
                <button
                  onClick={() => handleApprove(app.id)}
                  className="px-3 py-1.5 rounded-lg border border-emerald-300 text-[#107C10] hover:bg-emerald-50 text-xs font-bold cursor-pointer"
                >
                  Re-approve
                </button>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Rejection Modal */}
      {rejectionTargetId && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 animate-fade-in">
          <div className="bg-white rounded-2xl border border-[#E1DFDD] shadow-2xl max-w-md w-full p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-[#EDEBE9] pb-3">
              <h3 className="text-base font-bold text-[#D13438] flex items-center gap-2">
                <XCircle className="w-5 h-5" />
                <span>Reject Vendor Application</span>
              </h3>
              <button onClick={() => setRejectionTargetId(null)} className="text-[#605E5C] hover:text-[#323130]">✕</button>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#323130] mb-1.5">
                Provide Specific Reason for Rejection (Visible to Vendor):
              </label>
              <textarea
                value={customRejectionReason}
                onChange={(e) => setCustomRejectionReason(e.target.value)}
                rows={3}
                className="w-full p-2.5 bg-[#F8F8F8] border border-[#C8C6C4] rounded-lg text-xs text-[#323130] outline-none"
              />
            </div>

            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                onClick={() => setRejectionTargetId(null)}
                className="px-3.5 py-1.5 border border-[#C8C6C4] rounded-lg text-xs font-semibold cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmReject}
                className="px-4 py-1.5 bg-[#D13438] hover:bg-rose-700 text-white rounded-lg text-xs font-bold cursor-pointer"
              >
                Confirm Rejection
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
