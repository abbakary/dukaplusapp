/** Shared API URL + demo accounts (Railway production backend). */

export const RAILWAY_API_BASE =
  'https://dukaplusbackend-production.up.railway.app/api/v1';

export function getApiBaseUrl(): string {
  const fromEnv =
    import.meta.env.VITE_API_BASE_URL?.trim() ||
    import.meta.env.VITE_API_URL?.trim();
  if (fromEnv) return fromEnv.replace(/\/$/, '');

  // Local dev/preview: use Vite proxy to avoid CORS against Railway.
  if (typeof window !== 'undefined') {
    const host = window.location.hostname;
    if (host === 'localhost' || host === '127.0.0.1') return '/api/v1';
  }
  if (import.meta.env.DEV) return '/api/v1';

  return RAILWAY_API_BASE;
}

export const DEMO_PASSWORD = 'demo123';

export interface DemoAccount {
  label: string;
  labelSw: string;
  email: string;
  role: string;
}

export const DEMO_ACCOUNTS: DemoAccount[] = [
  { label: 'Pharmacy', labelSw: 'Duka la Dawa', email: 'pharmacy@sample.dukaplus.co.tz', role: 'Owner' },
  { label: 'Retail', labelSw: 'Rejareja', email: 'retail@sample.dukaplus.co.tz', role: 'Owner' },
  { label: 'Restaurant', labelSw: 'Mgahawa', email: 'restaurant@sample.dukaplus.co.tz', role: 'Owner' },
  { label: 'Hardware', labelSw: 'Vifaa', email: 'hardware@sample.dukaplus.co.tz', role: 'Owner' },
  { label: 'Electronics', labelSw: 'Elektroniki', email: 'electronics@sample.dukaplus.co.tz', role: 'Owner' },
  { label: 'Supermarket', labelSw: 'Supermarket', email: 'supermarket@sample.dukaplus.co.tz', role: 'Owner' },
  { label: 'Manager', labelSw: 'Meneja', email: 'manager.kariakoo-pharmacy@sample.dukaplus.co.tz', role: 'Manager' },
  { label: 'Cashier', labelSw: 'Cashier', email: 'cashier.mbezi-retail@sample.dukaplus.co.tz', role: 'Cashier' },
  { label: 'Super Admin', labelSw: 'Msimamizi', email: 'admin@dukaplus.co.tz', role: 'Super Admin' },
];
