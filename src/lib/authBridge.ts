import { api } from '@/lib/api';
import type { AuthUser, StaffPermissions } from '@/types/v1';

interface ApiUser {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: string;
  tenant_id?: string;
  staff_id?: string;
  business_name?: string;
  business_type?: string;
  plan?: string;
  subscription_expiry?: string;
  tin_number?: string;
  license_number?: string;
  staff_role?: string;
  permissions?: Partial<StaffPermissions>;
  language?: string;
  status?: string;
}

export function mapApiUserToAuthUser(apiUser: ApiUser): AuthUser {
  return {
    id: apiUser.id,
    name: apiUser.name,
    email: apiUser.email,
    phone: apiUser.phone || '',
    role: apiUser.role as AuthUser['role'],
    businessName: apiUser.business_name,
    businessType: apiUser.business_type as AuthUser['businessType'],
    businessId: apiUser.tenant_id,
    staffRole: apiUser.staff_role as AuthUser['staffRole'],
    staffId: apiUser.staff_id,
    staff_id: apiUser.staff_id,
    permissions: apiUser.permissions,
    status: (apiUser.status as AuthUser['status']) || 'approved',
    tinNumber: apiUser.tin_number,
    licenseNumber: apiUser.license_number,
    plan: apiUser.plan as AuthUser['plan'],
    subscriptionExpiry: apiUser.subscription_expiry,
  };
}

export async function tryRestoreSession(): Promise<AuthUser | null> {
  api.loadTokens();
  if (!localStorage.getItem('duka_access')) return null;
  try {
    const user = await api.getMe();
    return mapApiUserToAuthUser(user as unknown as ApiUser);
  } catch {
    api.clearTokens();
    return null;
  }
}
