import { ArrowLeft, LogIn, Plus, Trash2, UserRound } from "lucide-react";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "../../../lib/supabase";
import { getSavedAccounts, removeSavedAccount, saveSession, MAX_SAVED_ACCOUNTS } from "../../../lib/account-store";

type SavedView = ReturnType<typeof getSavedAccounts>[number];

export default function AccountSwitcherPage() {
  const navigate = useNavigate();
  const [accounts, setAccounts] = useState<SavedView[]>([]);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [switching, setSwitching] = useState<string | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    void supabase.auth.getSession().then(({ data }) => {
      if (!active) return;
      setCurrentUserId(data.session?.user?.id ?? null);
      setAccounts(getSavedAccounts());
    });
    return () => { active = false; };
  }, []);

  async function switchTo(account: SavedView) {
    if (account.userId === currentUserId) {
      navigate("/", { replace: true });
      return;
    }
    try {
      setSwitching(account.userId);
      setError("");
      const { data, error: sessionError } = await supabase.auth.setSession({
        access_token: account.accessToken,
        refresh_token: account.refreshToken,
      });
      if (sessionError || !data.session) throw sessionError ?? new Error("Unable to switch to that account.");
      saveSession(data.session);
      navigate("/", { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to switch accounts.");
      setSwitching(null);
    }
  }

  function remove(account: SavedView) {
    removeSavedAccount(account.userId);
    setAccounts(getSavedAccounts());
  }

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="ora-account-switcher mx-auto flex min-h-screen w-full max-w-xl flex-col px-5 py-8 sm:px-8 sm:py-12">
        <button type="button" onClick={() => navigate(-1)} className="mb-10 inline-flex w-fit items-center gap-2 text-sm font-semibold text-zinc-400 hover:text-white"><ArrowLeft size={17} />Back</button>
        <div className="mb-8">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-amber-500/10 text-lg font-black text-amber-200 ring-1 ring-amber-400/15">O</div>
          <p className="mt-6 text-sm font-semibold uppercase tracking-[0.18em] text-amber-300">ORA accounts</p>
          <h1 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">Switch account</h1>
          <p className="mt-3 max-w-md text-sm leading-6 text-zinc-500">Choose a saved account for instant access, or add another account. You can keep up to {MAX_SAVED_ACCOUNTS} accounts on this device.</p>
        </div>

        {error && <div className="mb-4 rounded-2xl border border-red-900/60 bg-red-950/30 px-4 py-3 text-sm text-red-300">{error}</div>}

        <div className="overflow-hidden rounded-3xl border border-zinc-800 bg-zinc-950/80 shadow-2xl shadow-black/30">
          {accounts.length ? accounts.map((account, index) => (
            <div key={account.userId} className={`flex items-center gap-3 p-3 sm:p-4 ${index ? "border-t border-zinc-900" : ""}`}>
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full border border-amber-300/15 bg-gradient-to-br from-emerald-950 to-zinc-900 text-sm font-bold text-amber-100"><UserRound size={20} /></div>
              <button type="button" onClick={() => void switchTo(account)} disabled={switching !== null} className="min-w-0 flex-1 text-left">
                <p className="truncate text-sm font-semibold text-zinc-100">{account.email || "ORA account"}{account.userId === currentUserId ? <span className="ml-2 rounded-full bg-emerald-500/10 px-2 py-0.5 text-[10px] font-semibold text-emerald-300">Current</span> : null}</p>
                <p className="mt-1 text-xs text-zinc-600">{switching === account.userId ? "Switching…" : "Tap to switch"}</p>
              </button>
              <button type="button" onClick={() => remove(account)} disabled={switching !== null} className="icon-button shrink-0 text-zinc-600 hover:bg-red-950/30 hover:text-red-400" aria-label={`Remove ${account.email || "saved account"}`} title="Remove saved account"><Trash2 size={17} /></button>
            </div>
          )) : <div className="p-6 text-center"><div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-zinc-900 text-zinc-500"><UserRound size={20} /></div><h2 className="mt-3 text-sm font-semibold text-zinc-200">No saved accounts yet</h2><p className="mt-1 text-xs leading-5 text-zinc-600">Your current account will be saved here after sign-in.</p></div>}
        </div>

        <button type="button" onClick={() => navigate("/add-account")} disabled={accounts.length >= MAX_SAVED_ACCOUNTS || switching !== null} className="primary-button mt-4 w-full justify-center !rounded-2xl !bg-amber-600 hover:!bg-amber-500 disabled:opacity-40"><Plus size={17} />{accounts.length >= MAX_SAVED_ACCOUNTS ? "Maximum of 3 accounts saved" : "Add an account"}</button>
        <p className="mt-5 text-center text-[11px] leading-5 text-zinc-600">Saved accounts use the device's secure browser storage for session tokens. ORA never saves your password.</p>
        {currentUserId ? <button type="button" onClick={() => navigate("/")} className="mt-5 inline-flex items-center justify-center gap-2 text-xs font-semibold text-zinc-500 hover:text-white"><LogIn size={14} />Continue with current account</button> : null}
      </div>
    </main>
  );
}
