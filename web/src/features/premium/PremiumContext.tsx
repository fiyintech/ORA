import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { useAuth } from "../auth/hooks/useAuth";
import { premiumService, type PremiumStatus } from "./services/premium.service";

interface PremiumContextValue extends PremiumStatus {
  loading: boolean;
  refresh: () => Promise<void>;
}

const PremiumContext = createContext<PremiumContextValue | null>(null);

export function PremiumProvider({ children }: { children: ReactNode }) {
  const { isAuthenticated, user } = useAuth();
  const [status, setStatus] = useState<PremiumStatus>({ active: false, expiresAt: null, secondsRemaining: 0 });
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    if (!isAuthenticated || !user) {
      setStatus({ active: false, expiresAt: null, secondsRemaining: 0 });
      setLoading(false);
      return;
    }
    try {
      setStatus(await premiumService.getStatus());
    } finally {
      setLoading(false);
    }
  }, [isAuthenticated, user]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  useEffect(() => {
    document.documentElement.dataset.premium = status.active ? "true" : "false";
    return () => { document.documentElement.dataset.premium = "false"; };
  }, [status.active]);

  useEffect(() => {
    if (!isAuthenticated || !user) return;
    const timer = window.setInterval(() => {
      setStatus((current) => {
        const secondsRemaining = Math.max(0, current.secondsRemaining - 1);
        if (secondsRemaining === 0 && current.active) {
          void refresh();
          return { active: false, expiresAt: null, secondsRemaining: 0 };
        }
        return { ...current, secondsRemaining };
      });
    }, 1000);
    return () => window.clearInterval(timer);
  }, [isAuthenticated, user, refresh]);

  const value = useMemo(() => ({ ...status, loading, refresh }), [status, loading, refresh]);
  return <PremiumContext.Provider value={value}>{children}</PremiumContext.Provider>;
}

export function usePremium() {
  const value = useContext(PremiumContext);
  if (!value) throw new Error("usePremium must be used inside PremiumProvider");
  return value;
}
