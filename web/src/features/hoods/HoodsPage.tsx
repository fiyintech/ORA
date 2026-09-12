import { useCallback, useEffect, useMemo, useState } from "react";
import { getCache, setCache } from "../../lib/cache";
import { useNavigate, useParams } from "react-router-dom";
import {
  ArrowLeft,
  Check,
  Copy,
  Globe2,
  Lock,
  Plus,
  RefreshCw,
  Shield,
  Settings2,
  Trash2,
  Users,
  X,
} from "lucide-react";
import Avatar from "../../components/ui/Avatar";
import {
  hoodService,
  type Hood,
  type HoodJoinRequest,
  type HoodMember,
  type HoodRejoinRequest,
  type HoodPost,
} from "./services/hood.service";

const HOODS_CACHE_KEY = "hoods:list";
const HOODS_CACHE_TTL = 10 * 60 * 1000;

const categoryFallbacks = ["All", "Technology", "Music", "Gaming", "School", "Sports", "Creative"];

function formatTime(value: string) {
  const date = new Date(value);
  const seconds = Math.max(1, Math.floor((Date.now() - date.getTime()) / 1000));
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  return `${days}d`;
}

function CreateHoodModal({ onClose, onCreated }: { onClose: () => void; onCreated: (hood: Hood) => void }) {
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState("Technology");
  const [privacy, setPrivacy] = useState<"public" | "private">("public");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setError("");
    setSaving(true);
    try {
      const hood = await hoodService.createHood({ name, description, category, privacy });
      onCreated(hood);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to create this Hood.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 px-4 backdrop-blur-sm" onMouseDown={onClose}>
      <form onSubmit={submit} onMouseDown={(event) => event.stopPropagation()} className="w-full max-w-lg rounded-2xl border border-zinc-800 bg-zinc-950 p-5 shadow-2xl">
        <div className="mb-5 flex items-center justify-between">
          <div><h2 className="text-xl font-bold text-white">Create a Hood</h2><p className="mt-1 text-sm text-zinc-500">Give your community a place to belong.</p></div>
          <button type="button" onClick={onClose} className="icon-button" aria-label="Close"><X size={20} /></button>
        </div>
        <div className="space-y-4">
          <label className="field-label">Hood name<input required maxLength={60} value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. ORA Tech" /></label>
          <label className="field-label">Description<textarea required maxLength={300} value={description} onChange={(e) => setDescription(e.target.value)} placeholder="What is this Hood about?" rows={4} /></label>
          <div className="grid grid-cols-2 gap-3">
            <label className="field-label">Category<select value={category} onChange={(e) => setCategory(e.target.value)}>{categoryFallbacks.slice(1).map((item) => <option key={item}>{item}</option>)}</select></label>
            <label className="field-label">Privacy<select value={privacy} onChange={(e) => setPrivacy(e.target.value as "public" | "private")}><option value="public">Public</option><option value="private">Private</option></select></label>
          </div>
          {privacy === "private" && <p className="rounded-xl bg-zinc-900 px-3 py-2.5 text-xs leading-5 text-zinc-500">Private Hoods require the owner to approve new members.</p>}
          {error && <p className="text-sm text-red-400">{error}</p>}
          <button disabled={saving} className="primary-button w-full">{saving ? "Creating…" : "Create Hood"}</button>
        </div>
      </form>
    </div>
  );
}

function HoodCard({ hood, onOpen }: { hood: Hood; onOpen: () => void }) {
  return (
    <button onClick={onOpen} className="group overflow-hidden rounded-2xl border border-zinc-800 bg-zinc-950 text-left shadow-sm transition duration-200 hover:-translate-y-0.5 hover:border-zinc-700 hover:bg-zinc-900/40 focus-visible:outline-none">
      <div className="h-24 bg-gradient-to-br from-zinc-800 via-zinc-900 to-black" style={hood.banner ? { backgroundImage: `url(${hood.banner})`, backgroundSize: "cover", backgroundPosition: "center" } : undefined} />
      <div className="p-5">
        <div className="mb-3 flex items-start justify-between gap-3">
          <div><h3 className="font-bold text-white group-hover:text-zinc-200">{hood.name}</h3><p className="mt-1 text-xs text-zinc-500">{hood.category || "Community"}</p></div>
          {hood.privacy === "private" ? <Lock size={15} className="text-zinc-600" /> : <Globe2 size={15} className="text-zinc-600" />}
        </div>
        <p className="line-clamp-2 min-h-10 text-sm leading-5 text-zinc-400">{hood.description || "A community on ORA."}</p>
        <div className="mt-4 flex items-center justify-between text-xs text-zinc-500"><span className="flex items-center gap-2"><Users size={14} /> {hood.member_count.toLocaleString()} members</span>{hood.join_status === "joined" ? <span className="text-emerald-400">Joined</span> : null}</div>
      </div>
    </button>
  );
}

function AdminPanel({ hood, onChanged }: { hood: Hood; onChanged: () => void }) {
  const [members, setMembers] = useState<HoodMember[]>([]);
  const [requests, setRequests] = useState<HoodJoinRequest[]>([]);
  const [rejoinRequests, setRejoinRequests] = useState<HoodRejoinRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState("");
  const [error, setError] = useState("");
  const [privacy, setPrivacy] = useState<"public" | "private">(hood.privacy === "private" ? "private" : "public");

  const load = useCallback(async () => {
    setLoading(true); setError("");
    try {
      const [nextMembers, nextRequests, nextRejoinRequests] = await Promise.all([hoodService.getMembers(hood.id), hoodService.getPendingRequests(hood.id), hood.is_owner ? hoodService.getPendingRejoinRequests(hood.id) : Promise.resolve([] as HoodRejoinRequest[])]);
      setMembers(nextMembers); setRequests(nextRequests); setRejoinRequests(nextRejoinRequests); setPrivacy(hood.privacy === "private" ? "private" : "public");
    } catch (err) { setError(err instanceof Error ? err.message : "Unable to load Hood management."); }
    finally { setLoading(false); }
  }, [hood.id, hood.privacy]);

  useEffect(() => { void load(); }, [load]);

  async function review(id: string, approve: boolean) {
    setBusyId(id); setError("");
    try { await hoodService.reviewJoinRequest(id, approve); await load(); onChanged(); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to update request."); }
    finally { setBusyId(""); }
  }

  async function reviewRejoin(id: string, approve: boolean) {
    setBusyId(id); setError("");
    try { await hoodService.reviewRejoinRequest(id, approve); await load(); onChanged(); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to update rejoin request."); }
    finally { setBusyId(""); }
  }

  async function remove(userId: string) {
    if (!window.confirm("Remove this member from the Hood?")) return;
    setBusyId(userId); setError("");
    try { await hoodService.removeMember(hood.id, userId); await load(); onChanged(); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to remove member."); }
    finally { setBusyId(""); }
  }

  async function toggleAdmin(member: HoodMember) {
    const makeAdmin = member.role !== "moderator";
    const name = member.profile?.display_name || member.profile?.username || "this member";
    if (!window.confirm(makeAdmin ? `Make ${name} a mini admin?` : `Revoke ${name}'s mini admin role?`)) return;
    setBusyId(member.user_id); setError("");
    try { await hoodService.setAdmin(hood.id, member.user_id, makeAdmin); await load(); onChanged(); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to update admin role."); }
    finally { setBusyId(""); }
  }

  async function transfer(member: HoodMember) {
    const name = member.profile?.display_name || member.profile?.username || "this member";
    if (!window.confirm(`Transfer ownership of ${hood.name} to ${name}? You will become a mini admin.`)) return;
    setBusyId(member.user_id); setError("");
    try { await hoodService.transferOwnership(hood.id, member.user_id); await load(); onChanged(); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to transfer ownership."); }
    finally { setBusyId(""); }
  }

  async function changePrivacy(next: "public" | "private") {
    if (next === privacy) return;
    setBusyId("privacy"); setError("");
    try { await hoodService.updatePrivacy(hood.id, next); setPrivacy(next); onChanged(); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to change Hood privacy."); }
    finally { setBusyId(""); }
  }

  async function deleteHood() {
    if (!window.confirm(`Delete ${hood.name} permanently? This removes the Hood, its members, requests and posts.`)) return;
    setBusyId("delete"); setError("");
    try { await hoodService.deleteHood(hood.id); window.location.assign("/hoods"); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to delete this Hood."); setBusyId(""); }
  }

  const ownerControls = hood.is_owner;
  return (
    <section className="mt-2 border-y border-zinc-800 bg-zinc-950">
      <div className="flex items-center justify-between px-4 py-3 sm:px-5">
        <div><p className="flex items-center gap-2 text-sm font-semibold text-white"><Shield size={16} className="text-violet-400" /> Hood management</p><p className="mt-1 text-xs text-zinc-600">{ownerControls ? "You are the owner. Manage admins, membership and Hood settings." : "Mini admin tools for membership and join requests."}</p></div>
        <button onClick={() => void load()} className="icon-button" aria-label="Refresh management"><RefreshCw size={16} className={loading ? "animate-spin" : ""} /></button>
      </div>
      {error && <p className="px-4 pb-3 text-sm text-red-400 sm:px-5">{error}</p>}
      {loading ? <div className="mx-4 mb-4 h-24 animate-pulse rounded-xl bg-zinc-900" /> : <div className="grid gap-0 border-t border-zinc-900 md:grid-cols-2">
        <div className="p-4 sm:p-5">
          <h3 className="text-xs font-semibold uppercase tracking-wider text-zinc-600">Join requests · {requests.length}</h3>
          {requests.length === 0 ? <p className="mt-3 text-sm text-zinc-600">No pending requests.</p> : <div className="mt-2 space-y-1">{requests.map((request) => { const name = request.profile?.display_name || request.profile?.username || "ORA user"; return <div key={request.id} className="flex items-center gap-3 border-b border-zinc-900 px-2 py-2.5"><Avatar src={request.profile?.avatar} name={name} size="sm" /><div className="min-w-0 flex-1"><p className="truncate text-sm font-medium text-white">{name}</p><p className="truncate text-xs text-zinc-600">@{request.profile?.username || "user"}</p></div><button disabled={busyId === request.id} onClick={() => void review(request.id, true)} className="admin-icon-button text-emerald-400" aria-label="Approve request"><Check size={16} /></button><button disabled={busyId === request.id} onClick={() => void review(request.id, false)} className="admin-icon-button text-red-400" aria-label="Decline request"><X size={16} /></button></div>; })}</div>}
          {ownerControls && <div className="mt-5 border-t border-zinc-900 pt-4"><h3 className="text-xs font-semibold uppercase tracking-wider text-amber-300">Rejoin requests · {rejoinRequests.length}</h3><p className="mt-1 text-xs leading-5 text-zinc-600">People removed from this Hood must be personally approved by you before they can return.</p>{rejoinRequests.length === 0 ? <p className="mt-3 text-sm text-zinc-600">No pending rejoin requests.</p> : <div className="mt-2 space-y-1">{rejoinRequests.map((request) => { const name = request.profile?.display_name || request.profile?.username || "ORA user"; return <div key={request.id} className="flex items-center gap-3 border-b border-zinc-900 px-2 py-2.5"><Avatar src={request.profile?.avatar} name={name} size="sm" /><div className="min-w-0 flex-1"><p className="truncate text-sm font-medium text-white">{name}</p><p className="truncate text-xs text-zinc-600">@{request.profile?.username || "user"}</p></div><button disabled={busyId === request.id} onClick={() => void reviewRejoin(request.id, true)} className="admin-icon-button text-emerald-400" aria-label="Approve rejoin request"><Check size={16} /></button><button disabled={busyId === request.id} onClick={() => void reviewRejoin(request.id, false)} className="admin-icon-button text-red-400" aria-label="Decline rejoin request"><X size={16} /></button></div>; })}</div>}</div>}
        </div>
        <div className="border-t border-zinc-900 p-4 sm:p-5 md:border-l md:border-t-0">
          <h3 className="text-xs font-semibold uppercase tracking-wider text-zinc-600">Members · {members.length}</h3>
          <div className="mt-2 space-y-1">{members.map((member) => { const name = member.profile?.display_name || member.profile?.username || "ORA user"; const owner = member.role === "owner"; const admin = member.role === "moderator"; return <div key={member.user_id} className="flex items-center gap-3 border-b border-zinc-900 px-2 py-2.5"><Avatar src={member.profile?.avatar} name={name} size="sm" /><div className="min-w-0 flex-1"><p className="truncate text-sm font-medium text-white">{name}</p><p className="truncate text-xs text-zinc-600">@{member.profile?.username || "user"}{owner ? " · Owner" : admin ? " · Mini admin" : " · Member"}</p></div>{!owner && <div className="flex items-center gap-1">{ownerControls && <button disabled={busyId === member.user_id} onClick={() => void toggleAdmin(member)} className={`admin-icon-button ${admin ? "text-amber-300" : "text-zinc-500 hover:text-violet-300"}`} aria-label={admin ? `Revoke admin from ${name}` : `Make ${name} a mini admin`} title={admin ? "Revoke mini admin" : "Make mini admin"}><Shield size={15} /></button>}<button disabled={busyId === member.user_id || (admin && !ownerControls)} onClick={() => void remove(member.user_id)} className="admin-icon-button text-zinc-500 hover:text-red-400" aria-label={`Remove ${name}`} title="Remove member"><Trash2 size={15} /></button>{ownerControls && <button disabled={busyId === member.user_id} onClick={() => void transfer(member)} className="admin-icon-button text-zinc-500 hover:text-violet-300" aria-label={`Transfer ownership to ${name}`} title="Transfer ownership"><Users size={15} /></button>}</div>}</div>; })}</div>
        </div>
      </div>}
      {ownerControls && <div className="border-t border-zinc-900 p-4 sm:p-5">
        <div className="grid gap-3 md:grid-cols-2">
          <div className="rounded-xl border border-zinc-800 bg-zinc-900/30 p-4"><div className="flex items-center gap-2"><Settings2 size={16} className="text-violet-400" /><p className="text-sm font-semibold text-white">Hood privacy</p></div><p className="mt-1 text-xs leading-5 text-zinc-600">Switch between public discovery and private approval-only membership at any time.</p><div className="mt-3 flex gap-2"><button disabled={busyId === "privacy"} onClick={() => void changePrivacy("public")} className={privacy === "public" ? "primary-button" : "secondary-button"}>Public</button><button disabled={busyId === "privacy"} onClick={() => void changePrivacy("private")} className={privacy === "private" ? "primary-button" : "secondary-button"}>Private</button></div></div>
          <div className="rounded-xl border border-red-950/70 bg-red-950/10 p-4"><p className="text-sm font-semibold text-white">Danger zone</p><p className="mt-1 text-xs leading-5 text-zinc-600">Deleting a Hood is permanent. Transfer ownership first if you want someone else to take over.</p><button disabled={busyId === "delete"} onClick={() => void deleteHood()} className="mt-3 rounded-lg border border-red-900/60 px-3 py-2 text-sm font-medium text-red-400 transition hover:bg-red-950/40">{busyId === "delete" ? "Deleting…" : "Delete Hood"}</button></div>
        </div>
      </div>}
    </section>
  );
}

function HoodDetail({ hoodId }: { hoodId: string }) {
  const navigate = useNavigate();
  const [hood, setHood] = useState<Hood | null>(null);
  const [posts, setPosts] = useState<HoodPost[]>([]);
  const [text, setText] = useState("");
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [manageOpen, setManageOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  const load = useCallback(async () => {
    setLoading(true); setError("");
    try {
      const nextHood = await hoodService.getHood(hoodId);
      const nextPosts = nextHood.is_joined || nextHood.privacy === "public"
        ? await hoodService.getHoodPosts(hoodId)
        : [];
      setHood(nextHood);
      setPosts(nextPosts);
    }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to load this Hood."); }
    finally { setLoading(false); }
  }, [hoodId]);

  useEffect(() => { void load(); }, [load]);

  async function toggleMembership() {
    if (!hood) return;
    setBusy(true); setError("");
    try {
      if (hood.join_status === "joined") {
        await hoodService.leaveHood(hood.id);
        setHood({ ...hood, is_joined: false, join_status: "none", member_count: Math.max(0, hood.member_count - 1) });
      } else {
        const status = await hoodService.joinHood(hood.id);
        setHood({ ...hood, is_joined: status === "joined", join_status: status, member_count: hood.member_count + (status === "joined" ? 1 : 0) });
      }
    } catch (err) { setError(err instanceof Error ? err.message : "Unable to update membership."); }
    finally { setBusy(false); }
  }

  async function publish(event: React.FormEvent) {
    event.preventDefault(); if (!text.trim()) return;
    setBusy(true); setError("");
    try { await hoodService.createHoodPost(hoodId, text); setText(""); setPosts(await hoodService.getHoodPosts(hoodId)); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to publish your post."); }
    finally { setBusy(false); }
  }

  async function requestRejoin() {
    setBusy(true); setError("");
    try { await hoodService.requestRejoin(hoodId); setHood((current) => current ? { ...current, join_status: "pending" } : current); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to send rejoin request."); }
    finally { setBusy(false); }
  }

  async function shareHood() {
    const url = window.location.href;
    try {
      if (navigator.share) await navigator.share({ title: hood?.name || "ORA Hood", text: `Join ${hood?.name || "this Hood"} on ORA`, url });
      else { await navigator.clipboard.writeText(url); setCopied(true); window.setTimeout(() => setCopied(false), 1800); }
    } catch { /* User cancelled native share. */ }
  }

  if (loading) return <div className="mx-auto max-w-4xl px-4 py-6"><div className="h-44 animate-pulse rounded-2xl bg-zinc-900" /></div>;
  if (error && !hood) return <div className="mx-auto max-w-3xl px-4 py-10 text-center"><p className="text-red-400">{error}</p><button onClick={() => void load()} className="secondary-button mt-4">Try again</button></div>;
  if (!hood) return null;

  return <main className="mx-auto max-w-4xl px-0 py-4 sm:px-4 sm:py-6">
    <button onClick={() => navigate("/hoods")} className="mb-4 flex items-center gap-2 px-1 text-sm text-zinc-500 hover:text-white"><ArrowLeft size={17} /> Hoods</button>
    <section className="overflow-hidden rounded-2xl border border-zinc-800 bg-zinc-950">
      <div className="h-32 bg-gradient-to-br from-violet-950 via-zinc-900 to-black sm:h-44" style={hood.banner ? { backgroundImage: `url(${hood.banner})`, backgroundSize: "cover", backgroundPosition: "center" } : undefined} />
      <div className="p-4 sm:p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div><div className="flex items-center gap-2"><h1 className="text-2xl font-bold text-white">{hood.name}</h1>{hood.privacy === "private" ? <Lock size={16} className="text-zinc-600" /> : <Globe2 size={16} className="text-zinc-600" />}</div><p className="mt-1 text-sm text-zinc-500">{hood.category || "Community"} · {hood.member_count.toLocaleString()} members · {hood.privacy === "private" ? "Private" : "Public"}</p></div>
          <div className="flex flex-wrap gap-2">
            <button onClick={() => void shareHood()} className="secondary-button"><Copy size={15} /> {copied ? "Link copied" : "Share"}</button>
            {hood.join_status === "removed" ? <button disabled={busy} onClick={() => void requestRejoin()} className="primary-button">Request to rejoin</button> : <button disabled={busy} onClick={() => void toggleMembership()} className={hood.join_status === "joined" ? "secondary-button" : "primary-button"}>{hood.join_status === "joined" ? (hood.is_owner ? "Owner" : "Joined") : hood.join_status === "pending" ? "Request pending" : hood.privacy === "private" ? "Request to join" : "Join Hood"}</button>}
          </div>
        </div>
        {hood.description && <p className="mt-4 max-w-2xl text-sm leading-6 text-zinc-400">{hood.description}</p>}
      </div>
    </section>

    {hood.join_status === "joined" && <form onSubmit={publish} className="mt-2 border-b border-zinc-800 bg-zinc-950 p-4"><textarea value={text} onChange={(e) => setText(e.target.value)} placeholder={`Share something with ${hood.name}…`} rows={3} maxLength={1000} /><div className="mt-3 flex justify-end"><button disabled={busy || !text.trim()} className="primary-button">Post</button></div></form>}
    {hood.join_status === "pending" && <div className="mt-2 rounded-xl border border-amber-900/30 bg-amber-950/10 px-4 py-3 text-sm text-amber-300">Your request is waiting for a Hood admin to approve it.</div>}
    {hood.join_status === "removed" && <div className="mt-2 rounded-xl border border-red-900/30 bg-red-950/10 px-4 py-3 text-sm text-red-300">You were removed from this Hood. You can only return if the owner approves a rejoin request.</div>}
    {error && <p className="mt-3 text-sm text-red-400">{error}</p>}

    {/* Owner admin controls are rendered after the member query confirms owner role. */}
    {hood.is_admin && <div className="mt-2"><button onClick={() => setManageOpen(!manageOpen)} className="secondary-button w-full justify-between"><span className="flex items-center gap-2"><Shield size={15} /> {hood.is_owner ? "Manage Hood" : "Admin tools"}</span><span className="text-xs text-zinc-600">{manageOpen ? "Hide" : "Open"}</span></button>{manageOpen && <AdminPanel hood={hood} onChanged={() => void load()} />}</div>}

    <div className="mt-2 space-y-0">{posts.length === 0 ? <div className="rounded-2xl border border-dashed border-zinc-800 px-6 py-12 text-center"><Users className="mx-auto text-zinc-700" /><p className="mt-3 font-medium text-zinc-300">No posts yet</p><p className="mt-1 text-sm text-zinc-600">Be the first to start the conversation.</p></div> : posts.map((post) => <article key={post.id} className="border-b border-zinc-800 bg-zinc-950 p-4"><div className="flex items-center gap-3"><Avatar src={post.profile?.avatar} name={post.profile?.display_name || post.profile?.username || "U"} /><div><p className="text-sm font-semibold text-white">{post.profile?.display_name || post.profile?.username || "ORA user"}</p><p className="text-xs text-zinc-600">@{post.profile?.username || "user"} · {formatTime(post.created_at)}</p></div></div><p className="mt-3 whitespace-pre-wrap text-sm leading-6 text-zinc-300">{post.text}</p></article>)}</div>
  </main>;
}


export default function HoodsPage() {
  const { hoodId } = useParams();
  const navigate = useNavigate();
  const [hoods, setHoods] = useState<Hood[]>([]);
  const [category, setCategory] = useState("All");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [showCreate, setShowCreate] = useState(false);

  const load = useCallback(async (silent = false) => { if (!silent) setLoading(true); setError(""); try { const data = await hoodService.getHoods(); setHoods(data); setCache(HOODS_CACHE_KEY, data); } catch (err) { setError(err instanceof Error ? err.message : "Unable to load Hoods."); } finally { setLoading(false); } }, []);
  useEffect(() => { const cached = getCache<Hood[]>(HOODS_CACHE_KEY, HOODS_CACHE_TTL); if (cached) { setHoods(cached); setLoading(false); void load(true); } else { void load(); } }, [load]);
  useEffect(() => { if (hoods.length) setCache(HOODS_CACHE_KEY, hoods); }, [hoods]);
  const categories = useMemo(() => ["All", ...Array.from(new Set(hoods.map((hood) => hood.category).filter(Boolean) as string[]))], [hoods]);
  const visible = category === "All" ? hoods : hoods.filter((hood) => hood.category === category);
  if (hoodId) return <HoodDetail hoodId={hoodId} />;

  return <main className="mx-auto max-w-5xl px-0 py-4 sm:px-4 sm:py-6">
    <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between"><div><p className="text-sm font-semibold uppercase tracking-[0.18em] text-zinc-600">Communities</p><h1 className="mt-1 text-3xl font-bold tracking-tight text-white">Hoods</h1><p className="mt-2 max-w-xl text-sm leading-6 text-zinc-500">Find your people, share what matters, and build a community around your interests.</p></div><button onClick={() => setShowCreate(true)} className="primary-button"><Plus size={17} /> Create Hood</button></div>
    {hoods.length > 0 && <div className="mt-4 flex gap-1 overflow-x-auto pb-1" aria-label="Hood categories">{categories.map((item) => <button key={item} onClick={() => setCategory(item)} className={`whitespace-nowrap rounded-full px-3.5 py-2 text-sm transition ${category === item ? "bg-white text-black" : "text-zinc-500 hover:bg-zinc-900 hover:text-white"}`}>{item}</button>)}</div>}
    {loading ? <div className="mt-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-3">{[1,2,3].map((item) => <div key={item} className="overflow-hidden rounded-2xl border border-zinc-900 bg-zinc-950" aria-hidden="true"><div className="h-24 animate-pulse bg-zinc-900" /><div className="space-y-3 p-5"><div className="h-4 w-2/3 animate-pulse rounded bg-zinc-900" /><div className="h-3 w-1/3 animate-pulse rounded bg-zinc-900" /><div className="h-10 w-full animate-pulse rounded bg-zinc-900" /><div className="h-3 w-1/2 animate-pulse rounded bg-zinc-900" /></div></div>)}</div> : error ? <div className="mt-4 rounded-2xl border border-red-950 bg-red-950/20 p-8 text-center"><p className="text-sm text-red-400">{error}</p><button onClick={() => void load()} className="secondary-button mt-4">Try again</button></div> : visible.length === 0 ? <div className="mt-4 rounded-2xl border border-dashed border-zinc-800 px-6 py-16 text-center"><Users className="mx-auto text-zinc-700" size={30} /><h2 className="mt-4 font-semibold text-zinc-300">No Hoods yet</h2><p className="mx-auto mt-2 max-w-sm text-sm leading-6 text-zinc-600">There aren't any visible Hoods in this category yet. Create one and give people a place to connect.</p><button onClick={() => setShowCreate(true)} className="primary-button mt-5">Create a Hood</button></div> : <div className="mt-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-3">{visible.map((hood) => <HoodCard key={hood.id} hood={hood} onOpen={() => navigate(`/hoods/${hood.id}`)} />)}</div>}
    {showCreate && <CreateHoodModal onClose={() => setShowCreate(false)} onCreated={(hood) => { setShowCreate(false); navigate(`/hoods/${hood.id}`); }} />}
  </main>;
}
