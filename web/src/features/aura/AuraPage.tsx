import { useCallback, useEffect, useState } from "react";
import { Loader2, RefreshCw, Sparkles, Trophy } from "lucide-react";
import { auraService, type AuraHistoryItem, type AuraLeaderboardEntry } from "./aura.service";
import { getCache, setCache } from "../../lib/cache";

const AURA_CACHE_KEY = "aura:current";
const AURA_CACHE_TTL = 10 * 60 * 1000;

function formatDate(value: string) {
  return new Date(value).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

export default function AuraPage() {
  const [aura, setAura] = useState({ aura_points: 0, steeze_level: 1 });
  const [history, setHistory] = useState<AuraHistoryItem[]>([]);
  const [leaderboard, setLeaderboard] = useState<AuraLeaderboardEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const [current, recent, rankings] = await Promise.all([
        auraService.getCurrentAura(),
        auraService.getHistory(),
        auraService.getLeaderboard(),
      ]);
      setAura(current);
      setHistory(recent);
      setLeaderboard(rankings);
      setCache(AURA_CACHE_KEY, { aura: current, history: recent, leaderboard: rankings });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to load Aura.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { const cached = getCache<{ aura: typeof aura; history: AuraHistoryItem[]; leaderboard: AuraLeaderboardEntry[] }>(AURA_CACHE_KEY, AURA_CACHE_TTL); if (cached) { setAura(cached.aura); setHistory(cached.history); setLeaderboard(cached.leaderboard); setLoading(false); void load(); } else { void load(); } }, [load]);

  const progress = aura.aura_points % 100;
  const nextLevel = aura.steeze_level + 1;

  return (
    <div className="mx-auto w-full max-w-6xl space-y-3 px-0 py-4 sm:px-4 sm:px-6 lg:px-8">
      <div className="flex items-center justify-between gap-4">
        <div>
          <p className="text-sm font-semibold uppercase tracking-[0.22em] text-violet-400">Reputation</p>
          <h1 className="mt-1 text-3xl font-bold text-white">Your Aura</h1>
          <p className="mt-1 text-sm text-zinc-500">Build reputation through meaningful activity on ORA.</p>
        </div>
        <button onClick={() => void load()} disabled={loading} className="rounded-xl border border-white/10 p-2.5 text-zinc-400 transition hover:bg-white/5 hover:text-white disabled:opacity-50" aria-label="Refresh Aura">
          <RefreshCw className={`h-5 w-5 ${loading ? "animate-spin" : ""}`} />
        </button>
      </div>

      {error && <div className="rounded-2xl border border-red-500/20 bg-red-500/10 px-4 py-3 text-sm text-red-300">{error}</div>}

      <div className="grid gap-3 lg:grid-cols-[1.4fr_1fr]">
        <section className="rounded-3xl border border-violet-500/20 bg-gradient-to-br from-violet-950/50 via-zinc-950 to-black p-5 shadow-2xl shadow-violet-950/20">
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-2 text-violet-300"><Sparkles className="h-5 w-5" /><span className="font-semibold">Aura Points</span></div>
              {loading ? <Loader2 className="mt-5 h-8 w-8 animate-spin text-violet-400" /> : <div className="mt-3 text-6xl font-black tracking-tight text-white">{aura.aura_points.toLocaleString()}</div>}
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-right">
              <div className="text-xs uppercase tracking-widest text-zinc-500">Steeze</div>
              <div className="text-2xl font-bold text-white">Lvl {aura.steeze_level}</div>
            </div>
          </div>
          <div className="mt-8">
            <div className="mb-2 flex justify-between text-xs text-zinc-500"><span>{progress} / 100 Aura</span><span>Next: Level {nextLevel}</span></div>
            <div className="h-2 overflow-hidden rounded-full bg-white/10"><div className="h-full rounded-full bg-violet-500 transition-all" style={{ width: `${progress}%` }} /></div>
          </div>
        </section>

        <section className="rounded-3xl border border-white/10 bg-zinc-950/80 p-5">
          <div className="flex items-center gap-2 text-white"><Trophy className="h-5 w-5 text-violet-400" /><h2 className="font-semibold">Global rankings</h2></div>
          <div className="mt-3 space-y-2">
            {loading ? <Loader2 className="h-6 w-6 animate-spin text-zinc-500" /> : leaderboard.length === 0 ? <p className="text-sm text-zinc-500">No rankings yet.</p> : leaderboard.map((entry) => (
              <div key={entry.user_id} className="flex items-center gap-3 rounded-2xl bg-white/[0.03] p-3">
                <span className="w-6 text-center text-xs font-bold text-zinc-500">{entry.rank}</span>
                <div className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-full bg-violet-500/20 font-bold text-violet-200">
                  {entry.avatar ? <img src={entry.avatar} alt="" className="h-full w-full object-cover" /> : entry.display_name?.charAt(0).toUpperCase() || "O"}
                </div>
                <div className="min-w-0 flex-1"><div className="truncate text-sm font-semibold text-white">{entry.display_name}</div><div className="truncate text-xs text-zinc-500">@{entry.username} · Lvl {entry.steeze_level}</div></div>
                <div className="text-sm font-bold text-violet-300">{entry.aura_points.toLocaleString()}</div>
              </div>
            ))}
          </div>
        </section>
      </div>

      <section className="rounded-3xl border border-white/10 bg-zinc-950/80 p-5">
        <h2 className="text-lg font-semibold text-white">Recent Aura history</h2>
        <div className="mt-4 divide-y divide-white/5">
          {loading ? <div className="flex justify-center py-8"><Loader2 className="h-6 w-6 animate-spin text-zinc-500" /></div> : history.length === 0 ? <p className="py-8 text-center text-sm text-zinc-500">Your Aura history will appear here as you build reputation.</p> : history.map((item) => (
            <div key={item.id} className="flex items-center gap-4 py-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-violet-500/10"><Sparkles className="h-4 w-4 text-violet-400" /></div>
              <div className="min-w-0 flex-1"><div className="text-sm font-medium text-white">{item.description}</div><div className="mt-1 text-xs text-zinc-600">{formatDate(item.created_at)}</div></div>
              <span className={`text-sm font-bold ${item.points > 0 ? "text-emerald-400" : "text-red-400"}`}>{item.points > 0 ? "+" : ""}{item.points}</span>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
