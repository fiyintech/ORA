import { Search, UserRound, MessageCircle, X, SlidersHorizontal, LockKeyhole } from "lucide-react";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "../../lib/supabase";
import { messageService } from "../messages/services/message.service";
import { usePremium } from "../premium/PremiumContext";

type SearchProfile = {
  user_id: string;
  username: string;
  display_name: string;
  avatar: string | null;
  bio: string;
};

function getInitial(profile: SearchProfile) {
  return (profile.display_name || profile.username || "O").charAt(0).toUpperCase();
}

function ProfileAvatar({ profile }: { profile: SearchProfile }) {
  const initialAvatar = (
    <div data-search-avatar-fallback className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-violet-600 text-sm font-semibold text-white">
      {getInitial(profile)}
    </div>
  );

  if (!profile.avatar) return initialAvatar;

  return (
    <div className="relative h-12 w-12 shrink-0">
      <img
        src={profile.avatar}
        alt={profile.display_name}
        className="h-12 w-12 rounded-full object-cover"
        onError={(event) => {
          event.currentTarget.style.display = "none";
          const fallback = event.currentTarget.parentElement?.querySelector<HTMLElement>("[data-search-avatar-fallback]");
          if (fallback) fallback.hidden = false;
        }}
      />
      <div data-search-avatar-fallback hidden>{initialAvatar}</div>
    </div>
  );
}

export default function SearchPage() {
  const navigate = useNavigate();
  const { active: premiumActive } = usePremium();
  const [query, setQuery] = useState("");
  const [deepSearch, setDeepSearch] = useState(false);
  const [results, setResults] = useState<SearchProfile[]>([]);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!premiumActive) setDeepSearch(false);
  }, [premiumActive]);

  useEffect(() => {
    const normalized = query.trim();

    if (!normalized) {
      setResults([]);
      setSearched(false);
      setError("");
      setLoading(false);
      return;
    }

    const timer = window.setTimeout(async () => {
      setLoading(true);
      setSearched(true);
      setError("");

      try {
        const pattern = `%${normalized}%`;
        const { data, error: searchError } = await supabase
          .from("profiles")
          .select("user_id,username,display_name,avatar,bio,location")
          .or(premiumActive && deepSearch
            ? `username.ilike.${pattern},display_name.ilike.${pattern},bio.ilike.${pattern},location.ilike.${pattern}`
            : `username.ilike.${pattern},display_name.ilike.${pattern}`)
          .order("display_name", { ascending: true })
          .limit(24);

        if (searchError) {
          throw searchError;
        }

        setResults((data ?? []) as SearchProfile[]);
      } catch (err) {
        console.error("Profile search failed:", err);
        setResults([]);
        setError(
          err instanceof Error
            ? err.message
            : "Unable to search right now.",
        );
      } finally {
        setLoading(false);
      }
    }, 300);

    return () => window.clearTimeout(timer);
  }, [query, premiumActive, deepSearch]);

  function openProfile(username: string) {
    navigate(`/profile/${encodeURIComponent(username)}`);
  }

  async function startConversation(userId: string) {
    try {
      setError("");
      const conversation =
        await messageService.getOrCreateConversation(userId);

      navigate(
        `/messages?conversation=${encodeURIComponent(conversation.id)}`,
      );
    } catch (err) {
      console.error("Conversation creation failed:", err);
      setError(
        err instanceof Error
          ? err.message
          : "Unable to start a conversation.",
      );
    }
  }

  return (
    <section className="min-h-screen">
      <header className="sticky top-0 z-10 border-b border-zinc-900 bg-zinc-950/95 px-4 py-4 backdrop-blur md:px-6">
        <div className="mx-auto max-w-2xl">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-zinc-900 text-zinc-300">
              <Search size={20} />
            </div>
            <div>
              <h1 className="text-lg font-semibold">Search</h1>
              <p className="text-xs text-zinc-500">Find people on ORA</p>
            </div>
          </div>

          <div className="relative mt-4">
            <Search
              size={18}
              className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-zinc-500"
            />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search by name or username"
              aria-label="Search by name or username"
              autoComplete="off"
              className="h-12 w-full rounded-2xl border border-zinc-800 bg-zinc-900 pl-11 pr-11 text-sm text-white outline-none transition placeholder:text-zinc-600 focus:border-zinc-700 focus:ring-2 focus:ring-violet-500/20"
            />
            {query && (
              <button
                type="button"
                onClick={() => setQuery("")}
                aria-label="Clear search"
                className="absolute right-3 top-1/2 flex h-8 w-8 -translate-y-1/2 items-center justify-center rounded-lg text-zinc-500 transition hover:bg-zinc-800 hover:text-white"
              >
                <X size={16} />
              </button>
            )}
          </div>

          <div className="mt-3 flex items-center justify-between gap-3">
            <button
              type="button"
              onClick={() => {
                if (!premiumActive) { navigate("/premium"); return; }
                setDeepSearch((value) => !value);
              }}
              className={`relative inline-flex items-center gap-2 overflow-hidden rounded-xl border px-3 py-2 text-xs font-semibold transition ${deepSearch && premiumActive ? "border-amber-400/30 bg-amber-400/10 text-amber-200" : "border-zinc-800 bg-zinc-900/70 text-zinc-400 hover:text-zinc-200"} ${!premiumActive ? "ora-premium-locked" : ""}`}
            >
              {premiumActive ? <SlidersHorizontal size={14} /> : <LockKeyhole size={14} />}
              {premiumActive ? (deepSearch ? "Deep search on" : "Deep search") : "Unlock deep search · ₦100"}
            </button>
            {premiumActive && deepSearch && <span className="text-[11px] text-zinc-600">Searches bio and location too</span>}
          </div>
        </div>
      </header>

      <div className="mx-auto max-w-2xl px-0 py-4 sm:px-4 md:px-6">
        {error && (
          <div className="mb-4 rounded-2xl border border-red-900/60 bg-red-950/30 px-4 py-3 text-sm text-red-300">
            {error}
          </div>
        )}

        {!searched && (
          <div className="rounded-3xl border border-zinc-900 bg-zinc-950 px-6 py-16 text-center">
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-violet-500/10 text-violet-400">
              <UserRound size={24} />
            </div>
            <h2 className="mt-5 text-lg font-semibold">Find your people</h2>
            <p className="mx-auto mt-2 max-w-sm text-sm leading-6 text-zinc-500">
              Search for people by their display name or username and open their ORA profile.
            </p>
          </div>
        )}

        {searched && loading && (
          <div className="space-y-0" aria-live="polite" aria-busy="true">
            {[0, 1, 2, 3].map((item) => (
              <div key={item} className="flex animate-pulse items-center gap-4 rounded-2xl border border-zinc-900 bg-zinc-950 p-4">
                <div className="h-12 w-12 rounded-full bg-zinc-900" />
                <div className="flex-1 space-y-2">
                  <div className="h-4 w-32 rounded bg-zinc-900" />
                  <div className="h-3 w-24 rounded bg-zinc-900" />
                </div>
              </div>
            ))}
          </div>
        )}

        {searched && !loading && !error && results.length === 0 && (
          <div className="rounded-3xl border border-zinc-900 bg-zinc-950 px-6 py-16 text-center">
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-zinc-900 text-zinc-500">
              <Search size={24} />
            </div>
            <h2 className="mt-5 text-lg font-semibold">No people found</h2>
            <p className="mt-2 text-sm text-zinc-500">
              Try another name or username.
            </p>
          </div>
        )}

        {searched && !loading && results.length > 0 && (
          <div>
            <div className="mb-3 flex items-center justify-between px-1">
              <h2 className="text-sm font-semibold text-zinc-300">People</h2>
              <span className="text-xs text-zinc-600">{results.length} result{results.length === 1 ? "" : "s"}</span>
            </div>

            <div className="divide-y divide-zinc-900 overflow-hidden rounded-2xl border border-zinc-900 bg-zinc-950">
              {results.map((profile) => (
                <div key={profile.user_id} className="flex items-center gap-4 p-4 transition hover:bg-zinc-900/40">
                  <button
                    type="button"
                    onClick={() => openProfile(profile.username)}
                    className="shrink-0 rounded-full focus:outline-none focus:ring-2 focus:ring-violet-500/50"
                    aria-label={`Open ${profile.display_name}'s profile`}
                  >
                    <ProfileAvatar profile={profile} />
                  </button>

                  <button
                    type="button"
                    onClick={() => openProfile(profile.username)}
                    className="min-w-0 flex-1 text-left"
                  >
                    <p className="truncate text-sm font-semibold text-white">
                      {profile.display_name || profile.username}
                    </p>
                    <p className="mt-0.5 truncate text-xs text-zinc-500">@{profile.username}</p>
                    {profile.bio && (
                      <p className="mt-2 line-clamp-2 text-xs leading-5 text-zinc-500">{profile.bio}</p>
                    )}
                  </button>

                  <button
                    type="button"
                    onClick={() => void startConversation(profile.user_id)}
                    className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-zinc-800 text-zinc-400 transition hover:border-zinc-700 hover:bg-zinc-900 hover:text-white"
                    aria-label={`Message ${profile.display_name}`}
                    title="Message"
                  >
                    <MessageCircle size={17} />
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
