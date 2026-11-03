/**
 * Client session store. Holds the access token, refresh token and the user's
 * authorisation context, persisted across reloads. Kept as a tiny observable so
 * the fetch layer (non-React) and the auth context (React) share one source of
 * truth without a circular import.
 */
export interface SessionUser {
  id: number; username: string; fullName: string; tenantId: number; tenantCode: string;
  roles: string[]; perms: string[]; entities: number[]; external: boolean;
}
export interface Session {
  accessToken: string; refreshToken: string; user: SessionUser; entityId: number;
}

const KEY = 'hb-trade-session';
let current: Session | null = load();
const listeners = new Set<() => void>();

function load(): Session | null {
  try { const raw = localStorage.getItem(KEY); return raw ? (JSON.parse(raw) as Session) : null; } catch { return null; }
}
function persist() {
  try { if (current) localStorage.setItem(KEY, JSON.stringify(current)); else localStorage.removeItem(KEY); } catch { /* ignore */ }
}

export function getSession(): Session | null { return current; }
export function setSession(s: Session | null) { current = s; persist(); listeners.forEach((l) => l()); }
export function updateTokens(accessToken: string, refreshToken: string) {
  if (!current) return;
  current = { ...current, accessToken, refreshToken };
  persist();
  listeners.forEach((l) => l());
}
export function subscribe(fn: () => void): () => void { listeners.add(fn); return () => listeners.delete(fn); }
export function hasPermission(perm: string): boolean { return !!current?.user.perms.includes(perm); }
