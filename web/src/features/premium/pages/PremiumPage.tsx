import { Check, Clock3, CreditCard, History, Sparkles, Zap } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { premiumService, type PaymentTransaction } from "../services/premium.service";
import { usePremium } from "../PremiumContext";

const standardTools = [
  "Text messages up to 500 characters",
  "Photo messages up to 6 MB",
  "Voice notes up to 60 seconds per day (total listening-free recording time)",
  "Text-only posts on Feed and Hoods",
  "No Feed post reshares",
  "Standard search by name and username",
  "Basic profile and account controls",
];

const premiumTools = [
  "Video messages — up to 50 MB",
  "Larger messaging media — up to 50 MB",
  "Deep people search across bio and location",
  "Power Hour Post Studio: up to 8 images per post",
  "Longer posts: up to 1,000 characters",
  "Premium chat environments: Botanical and Night sky",
  "Power Hour identity treatment on your profile",
  "Premium profile frames: Halo, Orbit, and Royal",
  "Message forwarding",
  "Reshare Feed posts",
  "Long voice notes with no 60-second Standard limit — still vanish after listening",
];

function formatTime(totalSeconds: number) {
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  return [hours, minutes, seconds].map((part) => String(part).padStart(2, "0")).join(":");
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat(undefined, { dateStyle: "medium", timeStyle: "short" }).format(new Date(value));
}

export default function PremiumPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { active, secondsRemaining, refresh } = usePremium();
  const [starting, setStarting] = useState(false);
  const [transactions, setTransactions] = useState<PaymentTransaction[]>([]);
  const [historyLoading, setHistoryLoading] = useState(true);
  const [completeState, setCompleteState] = useState<"idle" | "checking" | "success" | "pending" | "failed">("idle");

  const reference = useMemo(() => new URLSearchParams(location.search).get("reference") ?? new URLSearchParams(location.search).get("trxref"), [location.search]);

  useEffect(() => {
    let cancelled = false;
    premiumService.listPayments().then((items) => {
      if (!cancelled) setTransactions(items);
    }).catch(() => undefined).finally(() => {
      if (!cancelled) setHistoryLoading(false);
    });
    return () => { cancelled = true; };
  }, [completeState]);

  useEffect(() => {
    if (!reference) return;
    let cancelled = false;
    setCompleteState("checking");
    const check = async () => {
      try {
        const result = await premiumService.verifyPayment(reference);
        if (cancelled) return;
        setCompleteState(result);
        if (result === "success") {
          await refresh();
          toast.success("Power Hour is active.");
        }
      } catch {
        if (!cancelled) setCompleteState("pending");
      }
    };
    void check();
    return () => { cancelled = true; };
  }, [reference, refresh]);

  async function handleActivate() {
    try {
      setStarting(true);
      const { authorizationUrl } = await premiumService.startPowerHour();
      window.location.assign(authorizationUrl);
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Unable to start payment.");
      setStarting(false);
    }
  }

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="mx-auto max-w-3xl px-4 py-8 sm:px-6">
        <button type="button" onClick={() => navigate(-1)} className="mb-5 text-sm text-zinc-500 hover:text-white">← Back</button>

        <section className="overflow-hidden rounded-3xl border border-amber-500/20 bg-gradient-to-br from-zinc-950 via-zinc-950 to-amber-950/20 p-6 shadow-2xl sm:p-8">
          <div className="flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full border border-amber-400/20 bg-amber-400/10 px-3 py-1.5 text-xs font-bold uppercase tracking-[0.16em] text-amber-300"><Zap size={13} /> ORA Power Hour</div>
              <h1 className="mt-4 text-3xl font-black tracking-tight sm:text-4xl">Premium when you need it.</h1>
              <p className="mt-3 max-w-xl text-sm leading-6 text-zinc-400">Standard ORA stays complete. Power Hour adds the enhanced tools for one focused hour, without locking you into a monthly subscription.</p>
            </div>
            <div className="shrink-0 rounded-2xl border border-amber-400/20 bg-black/30 p-4 text-center">
              <p className="text-xs font-semibold uppercase tracking-wider text-zinc-500">One hour</p>
              <p className="mt-1 text-3xl font-black text-amber-300">₦100</p>
            </div>
          </div>

          {active ? (
            <div className="mt-7 rounded-2xl border border-emerald-500/20 bg-emerald-950/20 p-4">
              <div className="flex items-center gap-3"><Clock3 size={20} className="text-emerald-300" /><div><p className="font-bold text-emerald-200">Power Hour active</p><p className="text-xs text-emerald-300/70">Enhanced ORA tools are available now.</p></div><strong className="ml-auto font-mono text-lg text-emerald-200">{formatTime(secondsRemaining)}</strong></div>
            </div>
          ) : (
            <button type="button" onClick={() => void handleActivate()} disabled={starting} className="mt-7 inline-flex w-full items-center justify-center gap-2 rounded-2xl bg-amber-400 px-5 py-3.5 text-sm font-black text-black shadow-lg shadow-amber-400/10 transition hover:bg-amber-300 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto"><CreditCard size={17} />{starting ? "Opening secure checkout…" : "Activate Power Hour · ₦100"}</button>
          )}
        </section>

        {completeState !== "idle" && (
          <div className="mt-4 rounded-2xl border border-zinc-800 bg-zinc-950 p-4 text-sm">
            {completeState === "checking" && "Confirming your payment…"}
            {completeState === "success" && "✓ Payment confirmed. Your Power Hour is active."}
            {completeState === "pending" && "Your payment is still being confirmed. This page will not grant Premium until the payment is verified."}
            {completeState === "failed" && "The payment could not be verified. If you were charged, keep your reference and contact ORA support."}
          </div>
        )}

        <section className="mt-6 rounded-2xl border border-zinc-800 bg-zinc-950 p-5"><h2 className="font-bold">Standard ORA</h2><p className="mt-1 text-xs text-zinc-500">The everyday social experience remains available without Premium.</p><div className="mt-4 grid gap-2 sm:grid-cols-2">{standardTools.map((tool) => <div key={tool} className="flex items-center gap-2 rounded-xl border border-zinc-900 bg-zinc-900/40 px-3 py-2.5 text-xs text-zinc-400"><Check size={14} className="text-zinc-600" />{tool}</div>)}</div></section>

        <section className="mt-4 grid gap-3 sm:grid-cols-2">
          {premiumTools.map((tool) => <div key={tool} className="flex items-center gap-3 rounded-2xl border border-zinc-800 bg-zinc-950/80 p-4"><span className="flex h-8 w-8 items-center justify-center rounded-xl bg-amber-400/10 text-amber-300"><Check size={16} /></span><span className="text-sm font-medium text-zinc-200">{tool}</span></div>)}
        </section>

        <section className="mt-8 rounded-2xl border border-zinc-800 bg-zinc-950 p-5">
          <div className="flex items-center gap-2"><Sparkles size={17} className="text-amber-300" /><h2 className="font-bold">Payment history</h2></div>
          {historyLoading ? <p className="mt-4 text-sm text-zinc-600">Loading…</p> : transactions.length === 0 ? <p className="mt-4 text-sm text-zinc-600">No Power Hour payments yet.</p> : <div className="mt-4 divide-y divide-zinc-900">{transactions.map((item) => <div key={item.id} className="flex items-center gap-3 py-3"><History size={15} className="text-zinc-600" /><div className="min-w-0 flex-1"><p className="text-sm font-semibold text-zinc-200">ORA Power Hour</p><p className="text-xs text-zinc-600">{formatDate(item.created_at)} · {item.reference}</p></div><span className={`rounded-full px-2.5 py-1 text-[11px] font-bold ${item.status === "success" ? "bg-emerald-500/10 text-emerald-300" : item.status === "failed" ? "bg-red-500/10 text-red-300" : "bg-zinc-800 text-zinc-400"}`}>{item.status}</span></div>)}</div>}
        </section>
      </div>
    </main>
  );
}
