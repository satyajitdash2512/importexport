import { useQuery, type UseQueryOptions } from '@tanstack/react-query';
import { getSession, setSession, updateTokens } from '../features/auth/utils/session';

const BASE = '/api';

/** Envelope returned by the API: { data, page?, asOf }. */
interface Envelope<T> { data: T; page?: PageMeta; asOf: string }
export interface PageMeta { total: number; limit: number; offset: number }

function authHeaders(): Record<string, string> {
  const s = getSession();
  if (!s) return {};
  return { Authorization: `Bearer ${s.accessToken}`, 'X-Entity-Id': String(s.entityId) };
}

// single in-flight refresh so a burst of 401s triggers exactly one refresh
let refreshing: Promise<boolean> | null = null;
async function refreshOnce(): Promise<boolean> {
  const s = getSession();
  if (!s) return false;
  if (!refreshing) {
    refreshing = (async () => {
      try {
        const res = await fetch(`${BASE}/auth/refresh`, {
          method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ refreshToken: s.refreshToken }),
        });
        if (!res.ok) { setSession(null); return false; }
        const body = (await res.json()).data;
        updateTokens(body.accessToken, body.refreshToken);
        return true;
      } catch { setSession(null); return false; } finally { refreshing = null; }
    })();
  }
  return refreshing;
}

async function request(path: string, init: RequestInit, retry = true): Promise<Response> {
  const res = await fetch(`${BASE}${path}`, { ...init, headers: { Accept: 'application/json', ...authHeaders(), ...(init.headers ?? {}) } });
  if (res.status === 401 && retry && getSession()) {
    const ok = await refreshOnce();
    if (ok) return request(path, init, false);
  }
  return res;
}

async function unwrap<T>(res: Response): Promise<T> {
  if (!res.ok) {
    let detail = res.statusText;
    try { detail = (await res.json()).error ?? detail; } catch { /* keep statusText */ }
    throw new Error(`${res.status} · ${detail}`);
  }
  return ((await res.json()) as Envelope<T>).data;
}

export async function get<T>(path: string): Promise<T> {
  return unwrap<T>(await request(path, { method: 'GET' }));
}

/** GET that also returns the pagination meta from the envelope. */
export async function getPage<T>(path: string): Promise<{ data: T; page?: PageMeta }> {
  const res = await request(path, { method: 'GET' });
  if (!res.ok) { let d = res.statusText; try { d = (await res.json()).error ?? d; } catch { /* */ } throw new Error(`${res.status} · ${d}`); }
  const body = (await res.json()) as Envelope<T>;
  return { data: body.data, page: body.page };
}

export async function post<T>(path: string, payload: unknown): Promise<T> {
  return unwrap<T>(await request(path, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) }));
}

export function useApi<T>(key: unknown[], path: string, options?: Partial<UseQueryOptions<T>>) {
  return useQuery<T>({ queryKey: key, queryFn: () => get<T>(path), staleTime: 30_000, ...(options as any) });
}

export interface TenantOption { code: string; name: string }
export async function fetchTenants(): Promise<TenantOption[]> {
  try {
    const res = await fetch(`${BASE}/tenants`);
    if (!res.ok) return [];
    return ((await res.json()).data as TenantOption[]) ?? [];
  } catch { return []; }
}

/** Login / logout live here so components don't touch the token plumbing. */
export async function loginRequest(username: string, password: string, tenant?: string) {
  const res = await fetch(`${BASE}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ username, password, tenant }) });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(body.error ?? `${res.status} · ${res.statusText}`);
  const d = body.data;
  setSession({ accessToken: d.accessToken, refreshToken: d.refreshToken, user: d.user, entityId: d.user.entities[0] });
  return d.user;
}
export async function logoutRequest() {
  const s = getSession();
  if (s) { try { await fetch(`${BASE}/auth/logout`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ refreshToken: s.refreshToken }) }); } catch { /* ignore */ } }
  setSession(null);
}
