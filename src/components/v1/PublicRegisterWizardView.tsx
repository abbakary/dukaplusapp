import React, { useEffect, useState } from 'react';
import {
  ArrowLeft,
  ArrowRight,
  CheckCircle2,
  Eye,
  EyeOff,
  Lock,
  ShieldCheck,
  Store,
} from 'lucide-react';
import confetti from 'canvas-confetti';
import type { AuthUser, BusinessType, Language, SaaSPlanTier } from '@/types/v1';
import { ALL_BUSINESS_TYPES, getBusinessProfile } from '@/lib/businessEngine';
import { api } from '@/lib/api';
import { loginAndLoadUser, mapApiUserToAuthUser, persistAuthUser } from '@/lib/authBridge';
import { useSaasPlans } from '@/context/SaasPlansContext';
import { formatPlanPrice, planFeatures, planPeriod } from '@/lib/saasPlans';
import { BrandLogo } from '@/components/ui/BrandLogo';
import { TermsAcceptanceCheckbox } from '@/components/v1/TermsOfServiceView';
import { termsMustAcceptError } from '@/lib/termsOfService';

interface PublicRegisterWizardViewProps {
  language: Language;
  initialBusinessType?: BusinessType;
  initialPlan?: SaaSPlanTier;
  onBack: () => void;
  onLogin: () => void;
  onOpenTerms?: () => void;
  onRegisterSuccess: (user: AuthUser) => void;
}

const TEAL = '#0d9488';
const STEPS = ['Account', 'Business type', 'Plan', 'Shop details', 'Review'];

export const PublicRegisterWizardView: React.FC<PublicRegisterWizardViewProps> = ({
  language,
  initialBusinessType,
  initialPlan,
  onBack,
  onLogin,
  onOpenTerms,
  onRegisterSuccess,
}) => {
  const isSw = language === 'sw';
  const { plans } = useSaasPlans();
  const [step, setStep] = useState(1);
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const [fullName, setFullName] = useState('');
  const [regEmail, setRegEmail] = useState('');
  const [regPhone, setRegPhone] = useState('+255 7');
  const [regPassword, setRegPassword] = useState('');
  const [regPasswordConfirm, setRegPasswordConfirm] = useState('');
  const [businessType, setBusinessType] = useState<BusinessType>(initialBusinessType ?? 'retail');
  const [selectedPlan, setSelectedPlan] = useState<SaaSPlanTier>(initialPlan ?? 'biashara_pro');
  const [businessName, setBusinessName] = useState('');
  const [location, setLocation] = useState('Kariakoo, Dar es Salaam');
  const [tinNumber, setTinNumber] = useState('');
  const [licenseNumber, setLicenseNumber] = useState('');
  const [acceptedTerms, setAcceptedTerms] = useState(false);

  useEffect(() => {
    if (initialBusinessType) setBusinessType(initialBusinessType);
  }, [initialBusinessType]);

  useEffect(() => {
    if (initialPlan) setSelectedPlan(initialPlan);
  }, [initialPlan]);

  const selectedPlanMeta = plans.find(p => p.tier === selectedPlan) ?? plans[0];

  const validateStep = (s: number): boolean => {
    setError('');
    if (s === 1) {
      if (!fullName.trim()) { setError(isSw ? 'Weka jina kamili.' : 'Enter full name.'); return false; }
      if (!regEmail.trim()) { setError(isSw ? 'Weka barua pepe.' : 'Enter email.'); return false; }
      if (regPassword.length < 6) { setError(isSw ? 'Nenosiri angalau herufi 6.' : 'Password min 6 chars.'); return false; }
      if (regPassword !== regPasswordConfirm) { setError(isSw ? 'Nenosiri halilingani.' : 'Passwords mismatch.'); return false; }
    }
    if (s === 3 && !selectedPlan) {
      setError(isSw ? 'Chagua kifurushi.' : 'Select a plan.');
      return false;
    }
    if (s === 4 && !businessName.trim()) {
      setError(isSw ? 'Weka jina la biashara.' : 'Enter business name.');
      return false;
    }
    return true;
  };

  const next = () => {
    if (!validateStep(step)) return;
    setStep(s => Math.min(5, s + 1));
  };

  const submit = async () => {
    if (!validateStep(4)) { setStep(4); return; }
    if (!acceptedTerms) {
      setError(termsMustAcceptError(isSw));
      return;
    }
    setLoading(true);
    setError('');
    try {
      await api.register({
        business_name: businessName.trim(),
        owner_name: fullName.trim(),
        email: regEmail.trim(),
        phone: regPhone.trim().replace(/\s+/g, '') || '+255700000000',
        password: regPassword,
        business_type: businessType,
        tin_number: tinNumber.trim(),
        license_number: licenseNumber.trim(),
        region: 'Dar es Salaam',
        district: location.trim() || 'Ilala',
        plan_tier: selectedPlan,
      });
      const tokens = await api.login(regEmail.trim(), regPassword);
      api.setTokens(tokens.access_token, tokens.refresh_token, tokens.expires_in_days);
      const me = await api.getMe();
      const user = mapApiUserToAuthUser(me as Parameters<typeof mapApiUserToAuthUser>[0]);
      persistAuthUser(user);
      confetti({ particleCount: 40, spread: 60, origin: { y: 0.6 } });
      onRegisterSuccess(user);
    } catch (err) {
      setError(isSw ? `Usajili umeshindikana: ${(err as Error).message}` : `Registration failed: ${(err as Error).message}`);
    } finally {
      setLoading(false);
    }
  };

  const profile = getBusinessProfile(businessType);
  const inputCls = 'w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm outline-none focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20';

  return (
    <div className="min-h-screen bg-[#f4f6f5]">
      <header className="max-w-2xl mx-auto px-4 pt-6 flex items-center justify-between">
        <button type="button" onClick={onBack} className="flex items-center gap-2 text-sm text-slate-600 cursor-pointer">
          <ArrowLeft className="w-4 h-4" /> {isSw ? 'Rudi' : 'Back'}
        </button>
        <button type="button" onClick={onLogin} className="text-sm font-medium cursor-pointer" style={{ color: TEAL }}>
          {isSw ? 'Tayari una akaunti? Ingia' : 'Already have an account? Sign in'}
        </button>
      </header>

      <div className="max-w-2xl mx-auto px-4 py-8">
        <div className="text-center mb-8">
          <BrandLogo height={44} className="mb-4 mx-auto" />
          <h1 className="text-2xl font-serif font-bold text-slate-900">{isSw ? 'Sajili biashara yako' : 'Register your business'}</h1>
          <p className="text-sm text-slate-500 mt-1">{isSw ? `Hatua ${step} kati ya 5` : `Step ${step} of 5`}</p>
        </div>

        <div className="flex gap-2 mb-6">
          {STEPS.map((label, i) => (
            <div key={label} className="flex-1">
              <div className={`h-1.5 rounded-full ${i + 1 <= step ? 'bg-teal-600' : 'bg-slate-200'}`} />
              <p className={`text-[10px] mt-1 hidden sm:block ${i + 1 === step ? 'font-bold text-teal-700' : 'text-slate-400'}`}>{label}</p>
            </div>
          ))}
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 sm:p-8">
          {error && <div className="mb-4 p-3 rounded-xl bg-rose-50 text-rose-700 text-sm">{error}</div>}

          {step === 1 && (
            <div className="space-y-4">
              <h2 className="font-bold text-lg">{isSw ? 'Akaunti yako' : 'Your account'}</h2>
              <input className={inputCls} placeholder={isSw ? 'Jina kamili' : 'Full name'} value={fullName} onChange={e => setFullName(e.target.value)} />
              <div className="grid sm:grid-cols-2 gap-4">
                <input className={inputCls} type="email" placeholder="Email" value={regEmail} onChange={e => setRegEmail(e.target.value)} />
                <input className={inputCls} type="tel" placeholder="+255 7xx xxx xxx" value={regPhone} onChange={e => setRegPhone(e.target.value)} />
              </div>
              <div className="grid sm:grid-cols-2 gap-4">
                <div className="relative">
                  <Lock className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                  <input className={`${inputCls} pl-10 pr-10`} type={showPassword ? 'text' : 'password'} placeholder={isSw ? 'Nenosiri' : 'Password'} value={regPassword} onChange={e => setRegPassword(e.target.value)} />
                  <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 cursor-pointer text-slate-400">
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
                <input className={inputCls} type={showPassword ? 'text' : 'password'} placeholder={isSw ? 'Thibitisha' : 'Confirm'} value={regPasswordConfirm} onChange={e => setRegPasswordConfirm(e.target.value)} />
              </div>
            </div>
          )}

          {step === 2 && (
            <div className="space-y-4">
              <h2 className="font-bold text-lg">{isSw ? 'Chagua aina ya biashara' : 'Choose business type'}</h2>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 max-h-80 overflow-y-auto">
                {ALL_BUSINESS_TYPES.map(type => {
                  const p = getBusinessProfile(type);
                  return (
                    <button
                      key={type}
                      type="button"
                      onClick={() => setBusinessType(type)}
                      className={`p-3 rounded-xl border text-left cursor-pointer transition-all ${businessType === type ? 'border-teal-500 bg-teal-50 ring-1 ring-teal-500' : 'border-slate-200 hover:border-slate-300'}`}
                    >
                      <span className="text-xl">{p.icon}</span>
                      <div className="text-xs font-bold mt-1">{isSw ? p.label_sw : p.label_en}</div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {step === 3 && (
            <div className="space-y-4">
              <h2 className="font-bold text-lg">{isSw ? 'Chagua kifurushi cha usajili' : 'Choose your subscription plan'}</h2>
              <p className="text-sm text-slate-500">
                {isSw
                  ? 'Bei inaonyeshwa kulingana na mipango ya sasa — inasimamiwa na mtoa huduma.'
                  : 'Pricing reflects current provider-managed packages.'}
              </p>
              <div className="space-y-3">
                {plans.map(plan => (
                  <button
                    key={plan.id}
                    type="button"
                    onClick={() => setSelectedPlan(plan.tier)}
                    className={`w-full text-left p-4 rounded-xl border transition-all cursor-pointer ${
                      selectedPlan === plan.tier ? 'border-teal-500 bg-teal-50 ring-1 ring-teal-500' : 'border-slate-200 hover:border-slate-300'
                    }`}
                  >
                    <div className="flex flex-wrap items-start justify-between gap-2">
                      <div>
                        <div className="font-bold text-slate-900">{isSw ? plan.nameSw : plan.name}</div>
                        <div className="text-xs text-slate-500 mt-0.5">{isSw ? plan.tagSw : plan.tagEn}</div>
                      </div>
                      <div className="text-right">
                        <div className="font-black text-teal-700">{formatPlanPrice(plan, isSw)}</div>
                        {!plan.contactUs && (
                          <div className="text-[10px] text-slate-500">{planPeriod(isSw)}</div>
                        )}
                      </div>
                    </div>
                    <ul className="mt-2 flex flex-wrap gap-x-3 gap-y-1">
                      {planFeatures(plan, language).slice(0, 3).map(f => (
                        <li key={f} className="text-[10px] text-slate-600">• {f}</li>
                      ))}
                    </ul>
                  </button>
                ))}
              </div>
            </div>
          )}

          {step === 4 && (
            <div className="space-y-4">
              <h2 className="font-bold text-lg">{isSw ? 'Maelezo ya duka & TRA' : 'Shop & compliance details'}</h2>
              <input className={inputCls} placeholder={isSw ? 'Jina la biashara' : 'Business name'} value={businessName} onChange={e => setBusinessName(e.target.value)} />
              <input className={inputCls} placeholder={isSw ? 'Mahali / mtaa' : 'Location'} value={location} onChange={e => setLocation(e.target.value)} />
              <div className="grid sm:grid-cols-2 gap-4">
                <input className={inputCls} placeholder="TRA TIN" value={tinNumber} onChange={e => setTinNumber(e.target.value)} />
                <input className={inputCls} placeholder={isSw ? 'Leseni (hiari)' : 'License (optional)'} value={licenseNumber} onChange={e => setLicenseNumber(e.target.value)} />
              </div>
            </div>
          )}

          {step === 5 && (
            <div className="space-y-4">
              <h2 className="font-bold text-lg">{isSw ? 'Hakiki & tuma' : 'Review & submit'}</h2>
              <div className="rounded-xl bg-slate-50 border border-slate-100 p-4 space-y-3 text-sm">
                <div className="flex items-center gap-3">
                  <Store className="w-5 h-5 text-teal-600" />
                  <div><div className="font-bold">{businessName}</div><div className="text-slate-500">{isSw ? profile.label_sw : profile.label_en}</div></div>
                </div>
                <div><span className="text-slate-500">{isSw ? 'Mmiliki:' : 'Owner:'}</span> {fullName}</div>
                <div><span className="text-slate-500">Email:</span> {regEmail}</div>
                <div><span className="text-slate-500">{isSw ? 'Mahali:' : 'Location:'}</span> {location}</div>
                {tinNumber && <div><span className="text-slate-500">TIN:</span> {tinNumber}</div>}
                <div className="pt-2 border-t border-slate-200">
                  <span className="text-slate-500">{isSw ? 'Kifurushi:' : 'Plan:'}</span>{' '}
                  <strong>{selectedPlanMeta ? (isSw ? selectedPlanMeta.nameSw : selectedPlanMeta.name) : selectedPlan}</strong>
                  {!selectedPlanMeta?.contactUs && (
                    <span className="text-slate-500"> — {formatPlanPrice(selectedPlanMeta, isSw)}{planPeriod(isSw)}</span>
                  )}
                </div>
              </div>
              <div className="flex items-start gap-2 text-xs text-slate-500">
                <ShieldCheck className="w-4 h-4 text-teal-600 shrink-0 mt-0.5" />
                {isSw ? 'Data yako inalindwa na inafuata kanuni za biashara Tanzania.' : 'Your data is secured and aligned with Tanzania business compliance.'}
              </div>
              <TermsAcceptanceCheckbox
                language={language}
                checked={acceptedTerms}
                onChange={setAcceptedTerms}
                onOpenTerms={onOpenTerms}
              />
            </div>
          )}

          <div className="flex gap-3 mt-8">
            {step > 1 && (
              <button type="button" onClick={() => setStep(s => s - 1)} className="px-5 py-2.5 rounded-full border border-slate-200 text-sm font-bold cursor-pointer">
                {isSw ? 'Rudi' : 'Back'}
              </button>
            )}
            {step < 5 ? (
              <button type="button" onClick={next} className="flex-1 py-2.5 rounded-full text-sm font-bold text-white cursor-pointer flex items-center justify-center gap-2" style={{ background: TEAL }}>
                {isSw ? 'Endelea' : 'Continue'} <ArrowRight className="w-4 h-4" />
              </button>
            ) : (
              <button type="button" disabled={loading || !acceptedTerms} onClick={() => void submit()} className="flex-1 py-2.5 rounded-full text-sm font-bold text-white cursor-pointer flex items-center justify-center gap-2 disabled:opacity-60" style={{ background: TEAL }}>
                <CheckCircle2 className="w-4 h-4" />
                {loading ? (isSw ? 'Inasajili…' : 'Creating…') : (isSw ? 'Unda akaunti' : 'Create account')}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
