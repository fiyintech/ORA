import { useEffect, useState } from "react";
import type { Session, User } from "@supabase/supabase-js";
import { authService } from "../services/auth.service";
import { saveSession } from "../../../lib/account-store";

let authSnapshot: { user: User | null; session: Session | null } | null = null;

export function useAuth() {
  const [loading, setLoading] = useState(authSnapshot === null);
  const [user, setUser] = useState<User | null>(authSnapshot?.user ?? null);
  const [session, setSession] = useState<Session | null>(authSnapshot?.session ?? null);

  useEffect(() => {
    let mounted = true;

    async function loadAuthState() {
      // getSession() reads the persisted Supabase session locally and is much
      // faster than making every route navigation wait for getUser(). We then
      // confirm the user in the background when a snapshot is not already warm.
      const local = await authService.session();
      if (!mounted) return;

      const localSession = local.data.session ?? null;
      const localUser = localSession?.user ?? null;
      if (localUser) {
        authSnapshot = { user: localUser, session: localSession };
        saveSession(localSession);
        setUser(localUser);
        setSession(localSession);
        setLoading(false);
      }

      try {
        const authoritative = await authService.user();
        if (!mounted) return;
        const nextUser = authoritative.data.user ?? null;
        const nextSession = nextUser ? (await authService.session()).data.session ?? null : null;
        authSnapshot = { user: nextUser, session: nextSession };
        saveSession(nextSession);
        setUser(nextUser);
        setSession(nextSession);
      } catch (error) {
        // Keep a valid persisted session usable if the background confirmation
        // is temporarily unavailable.
        console.error("Failed to confirm authenticated user:", error);
      } finally {
        if (mounted) setLoading(false);
      }
    }

    void loadAuthState();

    const { data: { subscription } } = authService.onAuthStateChange(async (_event, nextSession) => {
      if (!mounted) return;
      const nextUser = nextSession?.user ?? null;
      authSnapshot = { user: nextUser, session: nextSession };
      saveSession(nextSession);
      setSession(nextSession);
      setUser(nextUser);
      setLoading(false);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  return {
    loading,
    user,
    session,
    isAuthenticated: !!user,
  };
}
