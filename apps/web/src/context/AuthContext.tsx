import * as React from 'react';
import { getSession, subscribe, type SessionUser } from '../features/auth/utils/session';
import { loginRequest, logoutRequest } from '../lib/api';

interface AuthCtx {
  user: SessionUser | null;
  entityId: number | null;
  login: (username: string, password: string, tenant?: string) => Promise<void>;
  logout: () => Promise<void>;
  can: (perm: string) => boolean;
}

const Ctx = React.createContext<AuthCtx>(null as any);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setLocal] = React.useState(getSession());
  React.useEffect(() => subscribe(() => setLocal(getSession())), []);

  const value = React.useMemo<AuthCtx>(() => ({
    user: session?.user ?? null,
    entityId: session?.entityId ?? null,
    login: async (u, p, tenant) => { await loginRequest(u, p, tenant); },
    logout: async () => { await logoutRequest(); },
    can: (perm: string) => !!session?.user.perms.includes(perm),
  }), [session]);

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useAuth(): AuthCtx { return React.useContext(Ctx); }
