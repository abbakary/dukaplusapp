import type { ApiSyncResult, DashboardStats } from '@/lib/apiSync';
import { idbGet, idbSet, idbDelete } from '@/lib/idbStore';

export interface TenantCacheSnapshot extends ApiSyncResult {
  savedAt: string;
  dashboardStats?: DashboardStats | null;
}

const legacyKey = (tenantId: string) => `duka_tenant_cache_${tenantId}`;
const metaKey = (tenantId: string) => `duka_cache_meta_${tenantId}`;
const idbKey = (tenantId: string) => `tenant:${tenantId}`;

function writeMeta(tenantId: string, savedAt: string): void {
  try {
    localStorage.setItem(metaKey(tenantId), JSON.stringify({ savedAt }));
  } catch {
    /* ignore */
  }
}

export async function saveTenantCache(tenantId: string, snapshot: TenantCacheSnapshot): Promise<void> {
  if (!tenantId) return;
  try {
    await idbSet(idbKey(tenantId), snapshot);
    writeMeta(tenantId, snapshot.savedAt);
    try {
      localStorage.removeItem(legacyKey(tenantId));
    } catch {
      /* ignore */
    }
  } catch {
    try {
      localStorage.setItem(legacyKey(tenantId), JSON.stringify(snapshot));
      writeMeta(tenantId, snapshot.savedAt);
    } catch {
      /* quota exceeded */
    }
  }
}

export async function loadTenantCache(tenantId: string): Promise<TenantCacheSnapshot | null> {
  if (!tenantId) return null;
  try {
    const fromIdb = await idbGet<TenantCacheSnapshot>(idbKey(tenantId));
    if (fromIdb) return fromIdb;
  } catch {
    /* fall through */
  }
  try {
    const raw = localStorage.getItem(legacyKey(tenantId));
    if (raw) return JSON.parse(raw) as TenantCacheSnapshot;
  } catch {
    /* ignore */
  }
  return null;
}

export function loadCacheSavedAt(tenantId: string): string | null {
  try {
    const raw = localStorage.getItem(metaKey(tenantId));
    if (raw) return (JSON.parse(raw) as { savedAt: string }).savedAt ?? null;
  } catch {
    /* ignore */
  }
  return null;
}

export async function clearTenantCache(tenantId: string): Promise<void> {
  if (!tenantId) return;
  try {
    await idbDelete(idbKey(tenantId));
  } catch {
    /* ignore */
  }
  localStorage.removeItem(legacyKey(tenantId));
  localStorage.removeItem(metaKey(tenantId));
}

export function formatCacheAge(savedAt: string, isSw: boolean): string {
  const ms = Date.now() - new Date(savedAt).getTime();
  const mins = Math.floor(ms / 60000);
  if (mins < 2) return isSw ? 'Hivi punde' : 'Just now';
  if (mins < 60) return isSw ? `Dakika ${mins} zilizopita` : `${mins} min ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return isSw ? `Saa ${hrs} zilizopita` : `${hrs} hr ago`;
  const days = Math.floor(hrs / 24);
  return isSw ? `Siku ${days} zilizopita` : `${days} day(s) ago`;
}
