import type { Session } from "@supabase/supabase-js";

const STORAGE_KEY = "ora:saved-accounts:v1";
export const MAX_SAVED_ACCOUNTS = 3;

type SavedAccount = {
  userId: string;
  email: string;
  accessToken: string;
  refreshToken: string;
  expiresAt: number | null;
  savedAt: number;
};

function read(): SavedAccount[] {
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed.filter((item) => item?.userId && item?.refreshToken) : [];
  } catch {
    return [];
  }
}

function write(accounts: SavedAccount[]) {
  try { window.localStorage.setItem(STORAGE_KEY, JSON.stringify(accounts.slice(0, MAX_SAVED_ACCOUNTS))); } catch { /* storage unavailable */ }
}

export function getSavedAccounts(): SavedAccount[] { return read(); }

export function saveSession(session: Session | null): void {
  if (!session?.user?.id || !session.refresh_token) return;
  const accounts = read().filter((account) => account.userId !== session.user.id);
  accounts.unshift({
    userId: session.user.id,
    email: session.user.email ?? "",
    accessToken: session.access_token,
    refreshToken: session.refresh_token,
    expiresAt: session.expires_at ?? null,
    savedAt: Date.now(),
  });
  write(accounts);
}

export function removeSavedAccount(userId: string): void {
  write(read().filter((account) => account.userId !== userId));
}

export function getSavedSession(userId: string): { access_token: string; refresh_token: string } | null {
  const account = read().find((item) => item.userId === userId);
  return account ? { access_token: account.accessToken, refresh_token: account.refreshToken } : null;
}
