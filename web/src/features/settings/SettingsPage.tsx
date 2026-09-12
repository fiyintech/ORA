import { AlertTriangle, ArrowLeft, Camera, Image as ImageIcon, LogOut, Moon, Save, Sun, Trash2, Upload, UserRoundPlus, Zap } from "lucide-react";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { profileService, type Profile } from "../profile/services/profile.service";
import { useTheme } from "../../context/ThemeContext";
import { usePremium } from "../premium/PremiumContext";
import { InlineError, PageLoading } from "../../components/ui/PageStates";
import Avatar from "../../components/ui/Avatar";
import { getCache, setCache } from "../../lib/cache";
import { supabase } from "../../lib/supabase";
import { authService } from "../auth/services/auth.service";
import { clearCache } from "../../lib/cache";
import { removeSavedAccount } from "../../lib/account-store";

export default function SettingsPage() {
  const navigate = useNavigate();
  const [profile, setProfile] = useState<Profile | null>(null);
  const [displayName, setDisplayName] = useState("");
  const [bio, setBio] = useState("");
  const [website, setWebsite] = useState("");
  const [location, setLocation] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [saved, setSaved] = useState(false);
  const [mediaBusy, setMediaBusy] = useState<"avatar" | "banner" | null>(null);
  const [mediaError, setMediaError] = useState("");
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deleteConfirmation, setDeleteConfirmation] = useState("");
  const [deletingAccount, setDeletingAccount] = useState(false);
  const { theme, setTheme, wallpaper, setWallpaper, profileFrame, setProfileFrame } = useTheme();
  const { active: premiumActive } = usePremium();

  useEffect(() => {
    let active = true;

    async function loadSettings() {
      try {
        const { data, error: sessionError } = await supabase.auth.getSession();
        if (sessionError) throw sessionError;
        const userId = data.session?.user?.id;
        const cacheKey = userId ? `profile:${userId}` : null;
        const cached = cacheKey ? getCache<Profile>(cacheKey, 5 * 60 * 1000) : null;
        if (cached && active) {
          setProfile(cached);
          setDisplayName(cached.display_name ?? "");
          setBio(cached.bio ?? "");
          setWebsite(cached.website ?? "");
          setLocation(cached.location ?? "");
          setLoading(false);
        }

        const current = await profileService.getCurrentProfile();
        if (!active) return;
        setProfile(current);
        if (current && cacheKey) setCache(cacheKey, current);
        setDisplayName(current?.display_name ?? "");
        setBio(current?.bio ?? "");
        setWebsite(current?.website ?? "");
        setLocation(current?.location ?? "");
        setLoading(false);
      } catch (err) {
        if (!active) return;
        setError(err instanceof Error ? err.message : "Unable to load settings.");
        setLoading(false);
      }
    }

    void loadSettings();
    return () => { active = false; };
  }, []);

  async function handleMediaUpload(kind: "avatar" | "banner", file: File | undefined) {
    if (!file) return;
    try {
      setMediaBusy(kind);
      setMediaError("");
      const updated = await profileService.uploadProfileImage(kind, file);
      setProfile(updated);

    } catch (err) {
      setMediaError(err instanceof Error ? err.message : "Unable to upload image.");
    } finally {
      setMediaBusy(null);
    }
  }

  function handleSwitchAccount() {
    navigate("/switch-account");
  }

  async function handleLogout() {
    try {
      setError("");
      await authService.logout();
      clearCache("profile:");
      clearCache("conversations:");
      clearCache("notifications:");
      clearCache("messages:");
      clearCache("feed:");
      clearCache("hoods:");
      clearCache("aura:");
      navigate("/login", { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to sign out.");
    }
  }

  async function handleDeleteAccount() {
    if (deleteConfirmation !== "DELETE") return;
    try {
      setDeletingAccount(true);
      setError("");
      await authService.deleteAccount();
      if (profile?.user_id) removeSavedAccount(profile.user_id);
      clearCache("profile:");
      clearCache("conversations:");
      clearCache("notifications:");
      clearCache("messages:");
      clearCache("feed:");
      clearCache("hoods:");
      clearCache("aura:");
      navigate("/", { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to delete your account.");
      setDeletingAccount(false);
    }
  }

  async function handleSave() {
    if (!profile || !displayName.trim()) return;
    try {
      setSaving(true);
      setError("");
      setSaved(false);
      await profileService.updateProfile({
        display_name: displayName.trim(),
        bio: bio.trim(),
        website: website.trim(),
        location: location.trim(),
      });
      const updated = { ...profile, display_name: displayName.trim(), bio: bio.trim(), website: website.trim(), location: location.trim() };
      setProfile(updated);
      setCache(`profile:${profile.user_id}`, updated);
      setSaved(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to save changes.");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <main className="min-h-screen bg-black text-white">
        <div className="mx-auto max-w-2xl border-x border-zinc-900">
          <PageLoading label="Loading your profile settings…" />
        </div>
      </main>
    );
  }

  if (!profile) {
    return (
      <main className="min-h-screen bg-black text-white">
        <div className="mx-auto max-w-2xl border-x border-zinc-900">
          <InlineError message={error || "We couldn't load your profile settings."} onRetry={() => window.location.reload()} />
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="mx-auto max-w-2xl border-x border-zinc-900">
        <header className="flex h-16 items-center gap-4 border-b border-zinc-900 px-4">
          <button type="button" onClick={() => navigate(-1)} className="rounded-full p-2 text-zinc-400 hover:bg-zinc-900 hover:text-white" aria-label="Go back"><ArrowLeft size={20} /></button>
          <h1 className="text-lg font-bold">Profile settings</h1>
        </header>
        <section className="space-y-4 p-4 sm:p-6">
          {error && <div className="rounded-xl border border-red-900/50 bg-red-950/30 px-4 py-3 text-sm text-red-400">{error}</div>}
          {saved && <div className="rounded-xl border border-emerald-900/50 bg-emerald-950/30 px-4 py-3 text-sm text-emerald-400">Profile updated.</div>}
          {mediaError && <div className="rounded-xl border border-red-900/50 bg-red-950/30 px-4 py-3 text-sm text-red-400">{mediaError}</div>}

          <section className="grid gap-3 sm:grid-cols-2">
            <div className="overflow-hidden rounded-xl border border-zinc-800 bg-zinc-950">
              <div className="relative h-28 bg-gradient-to-br from-violet-950 via-zinc-900 to-black">
                {profile?.banner_url ? <img src={profile.banner_url} alt="Profile banner" className="h-full w-full object-cover" /> : null}
                <label className="absolute bottom-2 right-2 inline-flex cursor-pointer items-center gap-2 rounded-lg bg-black/75 px-3 py-2 text-xs font-semibold text-white backdrop-blur hover:bg-black">
                  <Upload size={14} /> {mediaBusy === "banner" ? "Uploading…" : "Change banner"}
                  <input type="file" accept="image/jpeg,image/png,image/webp,image/gif" hidden disabled={mediaBusy !== null} onChange={(e) => void handleMediaUpload("banner", e.target.files?.[0])} />
                </label>
              </div>
              <div className="flex items-center gap-2 px-3 py-2.5 text-xs text-zinc-500"><ImageIcon size={15} /> Banner image · max 5 MB</div>
            </div>

            <div className="flex items-center gap-3 rounded-xl border border-zinc-800 bg-zinc-950 p-3">
              <Avatar profile={profile} size={80} />
              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold text-white">Profile picture</p>
                <p className="mt-1 text-xs text-zinc-600">JPG, PNG, WebP or GIF · max 5 MB</p>
                <label className="mt-2 inline-flex cursor-pointer items-center gap-2 rounded-lg border border-zinc-700 px-3 py-2 text-xs font-semibold text-zinc-200 hover:bg-zinc-900">
                  <Camera size={14} /> {mediaBusy === "avatar" ? "Uploading…" : "Change photo"}
                  <input type="file" accept="image/jpeg,image/png,image/webp,image/gif" hidden disabled={mediaBusy !== null} onChange={(e) => void handleMediaUpload("avatar", e.target.files?.[0])} />
                </label>
              </div>
            </div>
          </section>

          <section className="ora-theme-card rounded-2xl border p-4 shadow-sm sm:p-5">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-violet-600/10 text-violet-400">{theme === "dark" ? <Moon size={18} /> : <Sun size={18} />}</div>
              <div className="min-w-0 flex-1"><h2 className="text-sm font-semibold text-white">Appearance</h2><p className="mt-1 text-xs leading-5 text-zinc-500">Choose how ORA looks on this account. Your preference is remembered on this device.</p></div>
            </div>
            <div className="mt-4 grid grid-cols-2 gap-2">
              <button type="button" onClick={() => setTheme("dark")} className={`ora-theme-option theme-graphite ${theme === "dark" ? "is-selected" : ""}`}><Moon size={16} /> Graphite</button>
              <button type="button" onClick={() => setTheme("light")} className={`ora-theme-option theme-luxe ${theme === "light" ? "is-selected" : ""}`}><Sun size={16} /> Luxe Forest</button>
            </div>
            <div className="mt-5 border-t border-zinc-800/70 pt-4">
              <p className="text-xs font-semibold uppercase tracking-[0.16em] text-zinc-500">Profile frame · Power Hour</p>
              <p className="mt-1 text-xs text-zinc-600">Give your profile avatar a temporary premium frame during your active hour.</p>
              <div className="mt-3 flex flex-wrap gap-2">
                {(["none", "halo", "orbit", "royal"] as const).map((option) => {
                  const locked = option !== "none" && !premiumActive;
                  return (
                    <button key={option} type="button" onClick={() => { if (locked) { navigate("/premium"); return; } setProfileFrame(option); }} className={`relative overflow-hidden rounded-xl border px-3 py-2 text-xs font-semibold transition ${profileFrame === option ? "border-amber-400/40 bg-amber-400/10 text-amber-200" : "border-zinc-800 bg-zinc-900/70 text-zinc-400 hover:text-zinc-200"} ${locked ? "ora-premium-locked" : ""}`}>
                      {option === "none" ? "None" : option === "halo" ? "Halo" : option === "orbit" ? "Orbit" : "Royal"}{locked ? " · Power Hour" : ""}
                    </button>
                  );
                })}
              </div>
            </div>
            <div className="mt-5 border-t border-zinc-800/70 pt-4">
              <p className="text-xs font-semibold uppercase tracking-[0.16em] text-zinc-500">Chat wallpaper</p>
              <p className="mt-1 text-xs text-zinc-600">Choose a subtle luxury pattern for your conversations.</p>
              <div className="mt-3 grid grid-cols-3 gap-2">
                {(["silk", "botanical", "stars"] as const).map((option) => {
                  const premiumOnly = option !== "silk";
                  return (
                    <button key={option} type="button" onClick={() => { if (premiumOnly && !premiumActive) { navigate("/premium"); return; } setWallpaper(option); }} className={`ora-wallpaper-option relative overflow-hidden wallpaper-${option} ${wallpaper === option ? "is-selected" : ""} ${premiumOnly && !premiumActive ? "ora-premium-locked" : ""}`}>
                      <span>{option === "silk" ? "Silk" : option === "botanical" ? "Botanical · Power Hour" : "Night sky · Power Hour"}</span>
                    </button>
                  );
                })}
              </div>
            </div>
          </section>

          <label className="block text-sm"><span className="mb-2 block text-zinc-400">Username</span><input value={profile?.username ?? ""} disabled className="w-full rounded-xl border border-zinc-800 bg-zinc-950 px-4 py-3 text-zinc-500 outline-none" /></label>
          <label className="block text-sm"><span className="mb-2 block text-zinc-400">Display name</span><input value={displayName} onChange={(e) => setDisplayName(e.target.value)} className="w-full rounded-xl border border-zinc-800 bg-zinc-950 px-4 py-3 outline-none focus:border-violet-600" /></label>
          <label className="block text-sm"><span className="mb-2 block text-zinc-400">Bio</span><textarea value={bio} onChange={(e) => setBio(e.target.value)} rows={4} className="w-full resize-none rounded-xl border border-zinc-800 bg-zinc-950 px-4 py-3 outline-none focus:border-violet-600" /></label>
          <label className="block text-sm"><span className="mb-2 block text-zinc-400">Website</span><input value={website} onChange={(e) => setWebsite(e.target.value)} className="w-full rounded-xl border border-zinc-800 bg-zinc-950 px-4 py-3 outline-none focus:border-violet-600" /></label>
          <label className="block text-sm"><span className="mb-2 block text-zinc-400">Location</span><input value={location} onChange={(e) => setLocation(e.target.value)} className="w-full rounded-xl border border-zinc-800 bg-zinc-950 px-4 py-3 outline-none focus:border-violet-600" /></label>
          <button type="button" onClick={() => void handleSave()} disabled={saving || !displayName.trim()} className="flex items-center gap-2 rounded-xl bg-violet-600 px-5 py-3 text-sm font-semibold hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-60"><Save size={16} />{saving ? "Saving..." : "Save changes"}</button>

          <section className="ora-theme-card rounded-2xl border p-4 shadow-sm sm:p-5">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-amber-400/10 text-amber-300"><Zap size={18} /></div>
              <div className="min-w-0 flex-1"><h2 className="text-sm font-semibold text-white">ORA Power Hour</h2><p className="mt-1 text-xs leading-5 text-zinc-500">Get the enhanced ORA experience for one hour. No monthly subscription.</p></div>
            </div>
            <button type="button" onClick={() => navigate("/premium")} className="mt-4 inline-flex items-center gap-2 rounded-xl bg-amber-400 px-4 py-2.5 text-sm font-black text-black hover:bg-amber-300"><Zap size={16} />View Power Hour · ₦100</button>
          </section>

          <section className="mt-8 rounded-2xl border border-zinc-800 bg-zinc-950/70 p-4 sm:p-5">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-violet-600/10 text-violet-400"><UserRoundPlus size={18} /></div>
              <div><h2 className="text-sm font-semibold text-white">Account</h2><p className="mt-1 text-xs leading-5 text-zinc-500">Manage which ORA account is active on this browser.</p></div>
            </div>
            <div className="mt-4 grid gap-2 sm:grid-cols-2">
              <button type="button" onClick={handleSwitchAccount} className="secondary-button justify-center"><UserRoundPlus size={16} />Switch account</button>
              <button type="button" onClick={() => void handleLogout()} className="secondary-button justify-center border-red-900/60 text-red-400 hover:border-red-700 hover:bg-red-950/30"><LogOut size={16} />Log out</button>
            </div>
            <p className="mt-3 text-[11px] leading-5 text-zinc-600">Switch account keeps saved sign-ins on this device for one-tap switching. Log out ends this session and takes you to sign in.</p>
          </section>

          <section className="rounded-2xl border border-red-900/60 bg-red-950/10 p-4 sm:p-5">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-red-500/10 text-red-400"><AlertTriangle size={18} /></div>
              <div className="min-w-0 flex-1"><h2 className="text-sm font-semibold text-white">Delete account</h2><p className="mt-1 text-xs leading-5 text-zinc-500">Permanently delete your ORA account, profile, posts, messages, and uploaded media. This cannot be undone.</p></div>
            </div>
            <button type="button" onClick={() => { setDeleteConfirmation(""); setDeleteOpen(true); }} className="mt-4 inline-flex items-center gap-2 rounded-xl border border-red-900/70 px-4 py-2.5 text-sm font-semibold text-red-400 hover:bg-red-950/40"><Trash2 size={16} />Delete account</button>
          </section>

          {deleteOpen && <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/75 p-4 backdrop-blur-sm">
            <div role="dialog" aria-modal="true" aria-labelledby="delete-account-title" className="w-full max-w-md rounded-2xl border border-red-900/70 bg-zinc-950 p-5 shadow-2xl">
              <div className="flex items-start gap-3">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-red-500/10 text-red-400"><AlertTriangle size={18} /></div>
                <div><h2 id="delete-account-title" className="text-base font-semibold text-white">Delete your account?</h2><p className="mt-1 text-sm leading-6 text-zinc-400">This permanently removes your account and its ORA data. There is no recovery after deletion.</p></div>
              </div>
              <label className="mt-5 block text-sm"><span className="mb-2 block text-zinc-400">Type <strong className="text-white">DELETE</strong> to confirm</span><input autoFocus value={deleteConfirmation} onChange={(e) => setDeleteConfirmation(e.target.value.toUpperCase())} disabled={deletingAccount} className="w-full rounded-xl border border-zinc-800 bg-black px-4 py-3 text-white outline-none focus:border-red-700" placeholder="DELETE" /></label>
              <div className="mt-5 flex justify-end gap-2">
                <button type="button" onClick={() => setDeleteOpen(false)} disabled={deletingAccount} className="rounded-xl border border-zinc-800 px-4 py-2.5 text-sm font-semibold text-zinc-300 hover:bg-zinc-900">Cancel</button>
                <button type="button" onClick={() => void handleDeleteAccount()} disabled={deletingAccount || deleteConfirmation !== "DELETE"} className="inline-flex items-center gap-2 rounded-xl bg-red-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-red-500 disabled:cursor-not-allowed disabled:opacity-50"><Trash2 size={16} />{deletingAccount ? "Deleting…" : "Delete permanently"}</button>
              </div>
            </div>
          </div>}
        </section>
      </div>
    </main>
  );
}
