import {  Pause,
  Play,
  Square, ArrowDown, ArrowLeft, Check, CheckCheck, Copy, Forward, ImagePlus, Loader2, Lock, MessageCircle, Mic, MoreVertical, Plus, Search, Send, Smile, Trash2, UserPlus, Video, X } from "lucide-react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { supabase } from "../../lib/supabase";
import { messageService, type ConversationWithDetails, type Message } from "./services/message.service";
import Avatar from "../../components/ui/Avatar";
import MediaLightbox from "../../components/ui/MediaLightbox";
import { notificationService } from "../notifications/services/notification.service";
import { getCache, setCache } from "../../lib/cache";
import { usePremium } from "../premium/PremiumContext";

type Profile = { user_id: string; username: string; display_name: string; avatar: string | null };
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const CONVERSATIONS_CACHE_TTL = 10 * 60 * 1000;
const MESSAGES_CACHE_TTL = 10 * 60 * 1000;
const STANDARD_MESSAGE_MAX = 500;
const PREMIUM_MESSAGE_MAX = 1000;

function formatListTime(timestamp?: string | null) {
  if (!timestamp) return "";
  const date = new Date(timestamp); const now = new Date();
  if (date.toDateString() === now.toDateString()) return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  const days = Math.floor((now.getTime() - date.getTime()) / 86400000);
  if (days < 7) return date.toLocaleDateString([], { weekday: "short" });
  return date.toLocaleDateString([], { month: "short", day: "numeric" });
}
function formatMessageTime(timestamp: string) { return new Date(timestamp).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }); }
function formatDaySeparator(timestamp: string) {
  const date = new Date(timestamp); const now = new Date();
  const start = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today); yesterday.setDate(today.getDate() - 1);
  if (start.getTime() === today.getTime()) return "Today";
  if (start.getTime() === yesterday.getTime()) return "Yesterday";
  return date.toLocaleDateString(undefined, { month: "long", day: "numeric", ...(date.getFullYear() === now.getFullYear() ? {} : { year: "numeric" }) });
}
function BubbleStatus({ message }: { message: Message }) { return message.deleted_at ? null : message.read_at ? <CheckCheck size={13} /> : <Check size={13} />; }

function MediaMessage({ message, own, onExpired, onCompleted }: { message: Message; own: boolean; onExpired: (message: Message) => Promise<void>; onCompleted: (message: Message) => Promise<Message | null> }) {
  const [mediaFailed, setMediaFailed] = useState(false);
  const [viewerOpen, setViewerOpen] = useState(false);
  const [completedMedia, setCompletedMedia] = useState<Message | null>(null);
  const [localExpiry, setLocalExpiry] = useState<string | null>(null);
  const [secondsLeft, setSecondsLeft] = useState<number | null>(null);
  const [revealed, setRevealed] = useState(own || Boolean(message.media_viewed_at));
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const completionSentRef = useRef(false);

  useEffect(() => { setMediaFailed(false); }, [message.media_url]);
  useEffect(() => { setRevealed(own || Boolean(message.media_viewed_at)); }, [message.media_viewed_at, own]);
  useEffect(() => {
    const expiry = localExpiry ?? completedMedia?.media_expires_at ?? message.media_expires_at ?? null;
    if (!expiry) { setSecondsLeft(null); return; }
    const update = () => setSecondsLeft(Math.max(0, Math.ceil((new Date(expiry).getTime() - Date.now()) / 1000)));
    update();
    const timer = window.setInterval(update, 250);
    return () => window.clearInterval(timer);
  }, [localExpiry, completedMedia?.media_expires_at]);
  useEffect(() => {
    if (!completedMedia?.media_expires_at || secondsLeft !== 0) return;
    void onExpired(completedMedia);
  }, [onExpired, secondsLeft, completedMedia]);

  if (!message.media_url) return null;
  if (mediaFailed) return <div className="ora-media-fallback text-xs">Shared media is unavailable</div>;

  async function completeMedia() {
    if (own || completionSentRef.current) return;
    completionSentRef.current = true;
    const updated = await onCompleted(message);
    if (!updated) { completionSentRef.current = false; return; }
    setCompletedMedia(updated);
    setLocalExpiry(updated.media_expires_at);
  }

  async function openViewer() {
    setRevealed(true);
    if (mediaType === "image" && !own && !message.media_viewed_at && !completedMedia) {
      await completeMedia();
      if (!completionSentRef.current) return;
    }
    setViewerOpen(true);
  }

  const mediaType = message.media_type === "video" ? "video" : "image";
  if (message.media_type === "audio") {
    return <div className={`ora-chat-media ${!revealed ? "blur-[1px]" : ""}`}>
      {!revealed ? <button type="button" onClick={() => setRevealed(true)} className="flex w-full items-center gap-3 text-left"><span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-violet-600/15 text-violet-300"><Mic size={17} /></span><span><span className="block text-xs font-semibold text-zinc-200">Voice note</span><span className="block text-[10px] text-zinc-500">Tap to listen · disappears 12s after playback</span></span><Lock size={14} className="ml-auto text-amber-300" /></button> : <audio
            ref={audioRef}
            src={message.media_url}
            controls
            preload="metadata"
            onPlay={() => { void completeMedia(); }}
            className="w-full"
          />}
    </div>;
  }
  return <>
    <button type="button" onClick={() => void openViewer()} className={`ora-chat-media group relative block max-w-full overflow-hidden text-left ${!own && !message.media_viewed_at ? "is-unviewed" : ""}`} aria-label={`Open ${mediaType} full screen`}>
      {mediaType === "video" ? <div className="relative"><video src={message.media_url} muted playsInline preload="metadata" className="pointer-events-none max-h-[340px] w-full object-contain transition duration-300" /><span className="ora-media-lock pointer-events-none absolute left-1/2 top-1/2 flex -translate-x-1/2 -translate-y-1/2 items-center gap-2 px-4 py-2 text-xs font-semibold text-amber-100">◉ Tap to view</span></div> : <div className="relative"><img src={message.media_url} alt="Shared photo" loading="lazy" onError={() => setMediaFailed(true)} className="max-h-[340px] w-auto max-w-full object-contain transition duration-300" /></div>}
    </button>
    {viewerOpen ? <MediaLightbox url={message.media_url} type={mediaType} title={mediaType === "video" ? "Shared video" : "Shared photo"} expiresAt={completedMedia?.media_expires_at ?? null} onEnded={mediaType === "video" ? () => void completeMedia() : undefined} onClose={() => setViewerOpen(false)} /> : null}
  </>;
}

export default function MessagesPage() {
  const { active: premiumActive } = usePremium();
  const maxMessageLength = premiumActive ? PREMIUM_MESSAGE_MAX : STANDARD_MESSAGE_MAX;
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();
  const urlConversation = searchParams.get("conversation");
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [conversations, setConversations] = useState<ConversationWithDetails[]>([]);
  const [profiles, setProfiles] = useState<Record<string, Profile>>({});
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState("");
  const [search, setSearch] = useState("");
  const [attachments, setAttachments] = useState<File[]>([]);
  const [recording, setRecording] = useState(false);
  const [recordingPaused, setRecordingPaused] = useState(false);
  const [recordingSeconds, setRecordingSeconds] = useState(0);
  const [recordingDurationMs, setRecordingDurationMs] = useState(0);
  const recordingDurationMsRef = useRef(0);
  const [voiceRemainingMs, setVoiceRemainingMs] = useState<number | null>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const recordingChunksRef = useRef<Blob[]>([]);
  const recordingStartedRef = useRef(0);
  const recordingTimerRef = useRef<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");
  const [menuId, setMenuId] = useState<string | null>(null);
  const [forwardingMessage, setForwardingMessage] = useState<Message | null>(null);
  const [composerPanel, setComposerPanel] = useState<"emoji" | "actions" | null>(null);
  const [mobileChatOpen, setMobileChatOpen] = useState(false);
  const fileRef = useRef<HTMLInputElement | null>(null);
  const emojiPanelRef = useRef<HTMLDivElement | null>(null);
  const endRef = useRef<HTMLDivElement | null>(null);
  const chatBodyRef = useRef<HTMLDivElement | null>(null);
  const stickToBottomRef = useRef(true);
  const [showJumpToLatest, setShowJumpToLatest] = useState(false);
  const conversationsRef = useRef<ConversationWithDetails[]>([]);

  function navigateToSearch() { navigate("/search"); }

  const loadProfiles = useCallback(async (list: ConversationWithDetails[]) => {
    const ids = Array.from(new Set(list.flatMap((c) => c.members.map((m) => m.user_id))));
    if (!ids.length || !currentUserId) return;
    const cacheKey = `conversation-profiles:${currentUserId}`;
    const cached = getCache<Record<string, Profile>>(cacheKey, 10 * 60 * 1000);
    if (cached) setProfiles((current) => ({ ...cached, ...current }));
    const missing = ids.filter((id) => !cached?.[id]);
    if (!missing.length) return;
    const { data, error: profileError } = await supabase.from("profiles").select("user_id,username,display_name,avatar").in("user_id", missing);
    if (profileError) throw profileError;
    const next: Record<string, Profile> = { ...(cached ?? {}) };
    for (const row of data ?? []) next[row.user_id] = row as Profile;
    setProfiles((current) => ({ ...current, ...next }));
    setCache(cacheKey, next);
  }, [currentUserId]);
  const loadConversations = useCallback(async () => {
    setLoading(true); setError("");
    try { const list = await messageService.getConversations(); setConversations(list); setCache(`conversations:${currentUserId}`, list); await loadProfiles(list); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to load conversations."); }
    finally { setLoading(false); }
  }, [currentUserId, loadProfiles]);

  useEffect(() => { let active = true; void supabase.auth.getSession().then(({ data, error: authError }) => { if (!active) return; if (authError) setError(authError.message); setCurrentUserId(data.session?.user?.id ?? null); }); return () => { active = false; }; }, []);
  useEffect(() => { if (!currentUserId) return; const cached = getCache<ConversationWithDetails[]>(`conversations:${currentUserId}`, CONVERSATIONS_CACHE_TTL); if (cached) { setConversations(cached); setLoading(false); void loadConversations(); } else { void loadConversations(); } }, [currentUserId, loadConversations]);
  useEffect(() => {
    if (!menuId) return;
    const close = () => setMenuId(null);
    document.addEventListener("mousedown", close);
    document.addEventListener("scroll", close, true);
    return () => {
      document.removeEventListener("mousedown", close);
      document.removeEventListener("scroll", close, true);
    };
  }, [menuId]);

  useEffect(() => {
    if (!selectedId) { void messageService.clearConversationPresence().catch(() => undefined); return; }
    void messageService.setConversationPresence(selectedId).catch(() => undefined);
    const timer = window.setInterval(() => { void messageService.setConversationPresence(selectedId).catch(() => undefined); }, 10000);
    return () => {
      window.clearInterval(timer);
      void messageService.clearConversationPresence().catch(() => undefined);
    };
  }, [selectedId]);

  useEffect(() => { conversationsRef.current = conversations; }, [conversations]);
  useEffect(() => {
    if (!currentUserId) return;
    return messageService.subscribeToAllMessages((incoming) => {
      if (incoming.sender_id === currentUserId) return;

      const exists = conversationsRef.current.some((conversation) => conversation.id === incoming.conversation_id);
      if (!exists) {
        void loadConversations();
        return;
      }

      setConversations((current) =>
        current
          .map((conversation) =>
            conversation.id === incoming.conversation_id
              ? {
                  ...conversation,
                  lastMessage: incoming,
                  unreadCount: conversation.id === selectedId ? 0 : conversation.unreadCount + 1,
                  updated_at: incoming.created_at,
                }
              : conversation,
          )
          .sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()),
      );
    });
  }, [currentUserId, loadConversations, selectedId]);
  const selectConversation = useCallback((id: string) => { setSelectedId(id); setMobileChatOpen(true); setError(""); const next = new URLSearchParams(searchParams); next.set("conversation", id); setSearchParams(next, { replace: true }); }, [searchParams, setSearchParams]);
  useEffect(() => { if (!urlConversation || !UUID_REGEX.test(urlConversation) || loading) return; if (conversations.some((c) => c.id === urlConversation)) { setSelectedId(urlConversation); setMobileChatOpen(true); } else if (conversations.length) { const next = new URLSearchParams(searchParams); next.delete("conversation"); setSearchParams(next, { replace: true }); } }, [conversations, loading, searchParams, setSearchParams, urlConversation]);
  useEffect(() => { if (!loading && !selectedId && conversations.length) setSelectedId(conversations[0].id); }, [conversations, loading, selectedId]);
  const selectedConversation = useMemo(() => conversations.find((c) => c.id === selectedId) ?? null, [conversations, selectedId]);
  const otherProfile = useMemo(() => { if (!selectedConversation || !currentUserId) return null; const other = selectedConversation.members.find((m) => m.user_id !== currentUserId); return other ? profiles[other.user_id] ?? null : null; }, [currentUserId, profiles, selectedConversation]);
  const filteredConversations = useMemo(() => { const term = search.trim().toLowerCase(); if (!term) return conversations; return conversations.filter((c) => { const m = c.members.find((x) => x.user_id !== currentUserId); const p = m ? profiles[m.user_id] : null; return `${p?.display_name ?? ""} ${p?.username ?? ""}`.toLowerCase().includes(term); }); }, [conversations, currentUserId, profiles, search]);

  const loadMessages = useCallback(async (id: string) => {
    setLoadingMessages(true); setError("");
    try { const data = await messageService.getMessages(id); setMessages(data); setCache(`messages:${id}`, data); await messageService.markConversationAsRead(id); if (currentUserId) await notificationService.markMessageNotificationsRead(currentUserId, id); setConversations((current) => current.map((c) => c.id === id ? { ...c, unreadCount: 0 } : c)); }
    catch (err) { setError(err instanceof Error ? err.message : "Unable to load messages."); }
    finally { setLoadingMessages(false); }
  }, [currentUserId]);
  useEffect(() => { if (!selectedId) { setMessages([]); return; } const cached = getCache<Message[]>(`messages:${selectedId}`, MESSAGES_CACHE_TTL); if (cached) { setMessages(cached); setLoadingMessages(false); void loadMessages(selectedId); } else { void loadMessages(selectedId); } }, [loadMessages, selectedId]);
  useEffect(() => { if (selectedId) setCache(`messages:${selectedId}`, messages); }, [messages, selectedId]);
  useEffect(() => {
    if (!selectedId) return;

    return messageService.subscribeToMessages(selectedId, (incoming) => {
      setMessages((current) =>
        current.some((m) => m.id === incoming.id)
          ? current
          : [...current, incoming],
      );

      setConversations((current) =>
        current
          .map((conversation) =>
            conversation.id === selectedId
              ? {
                  ...conversation,
                  lastMessage: incoming,
                  unreadCount: incoming.sender_id === currentUserId ? conversation.unreadCount : 0,
                  updated_at: incoming.created_at,
                }
              : conversation,
          )
          .sort((a, b) =>
            new Date(b.updated_at).getTime() -
            new Date(a.updated_at).getTime(),
          ),
      );

      if (incoming.sender_id !== currentUserId) {
        void messageService.markConversationAsRead(selectedId);
        if (currentUserId) void notificationService.markMessageNotificationsRead(currentUserId, selectedId);
      }
    });
  }, [currentUserId, selectedId]);
  useEffect(() => {
    if (!selectedId) return;
    return messageService.subscribeToMessageUpdates(selectedId, (updated, event) => {
      if (event === "DELETE" || updated.deleted_at) {
        setMessages((current) => current.filter((m) => m.id !== updated.id));
        return;
      }
      setMessages((current) => current.map((m) => (m.id === updated.id ? updated : m)));
    });
  }, [selectedId]);
  const handleChatScroll = () => {
    const el = chatBodyRef.current;
    if (!el) return;

    const distanceFromBottom =
      el.scrollHeight - el.scrollTop - el.clientHeight;

    const atBottom = distanceFromBottom <= 48;

    stickToBottomRef.current = atBottom;
    setShowJumpToLatest(!atBottom);
  };

  const jumpToLatest = () => {
    const el = chatBodyRef.current;
    if (!el) return;

    stickToBottomRef.current = true;
    setShowJumpToLatest(false);

    el.scrollTo({
      top: el.scrollHeight,
      behavior: "smooth",
    });
  };

  useEffect(() => {
    if (stickToBottomRef.current) {
      endRef.current?.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages]);
  useEffect(() => { void refreshVoiceAllowance(); }, [premiumActive]);

  async function refreshVoiceAllowance(): Promise<number | null> {
    if (premiumActive) { setVoiceRemainingMs(null); return null; }
    const { data, error } = await supabase.rpc("get_voice_note_daily_remaining");
    if (error) {
      setVoiceRemainingMs(null);
      return null;
    }
    const remaining = Math.max(0, typeof data === "number" ? data : Number(data ?? 0));
    setVoiceRemainingMs(remaining);
    return remaining;
  }

  const chooseAttachments = (files?: FileList | File[]) => {
    if (!files) return;
    const selected = Array.from(files);
    if (!selected.length) return;

    const extensionOf = (file: File) => file.name.split(".").pop()?.toLowerCase() ?? "";
    const imageExtensions = new Set(["jpg", "jpeg", "png", "webp", "gif", "avif", "bmp"]);
    const videoExtensions = new Set(["mp4", "webm", "mov", "m4v", "mpeg", "mpg", "ogg"]);
    const audioExtensions = new Set(["webm", "ogg", "mp3", "m4a", "wav"]);

    const classify = (file: File) => {
      const extension = extensionOf(file);
      const isImage = file.type.startsWith("image/") || (!file.type && imageExtensions.has(extension));
      const isVideo = file.type.startsWith("video/") || (!file.type && videoExtensions.has(extension));
      const isAudio = file.type.startsWith("audio/") || (!file.type && audioExtensions.has(extension));
      return { isImage, isVideo, isAudio };
    };

    const kinds = selected.map(classify);
    if (selected.length > 1 && (!premiumActive || kinds.some(({ isImage, isVideo, isAudio }) => !isImage || isVideo || isAudio))) {
      setError("Multiple image uploads are a Power Hour feature. Select images only.");
      return;
    }

    const invalid = kinds.findIndex(({ isImage, isVideo, isAudio }) => !isImage && !isVideo && !isAudio);
    if (invalid !== -1) {
      setError("Choose an image, video, or audio file.");
      return;
    }

    const maxBytes = premiumActive ? 50 * 1024 * 1024 : 6 * 1024 * 1024;
    for (let index = 0; index < selected.length; index += 1) {
      const file = selected[index];
      const { isImage, isVideo, isAudio } = kinds[index];
      if (isVideo && !premiumActive) {
        navigate("/premium");
        return;
      }
      if (isAudio && !premiumActive) {
        setError("Voice notes are available on Standard within your daily allowance.");
        return;
      }
      if (file.size > maxBytes) {
        setError(`${isImage ? "Images" : isVideo ? "Videos" : "Voice notes"} must be ${premiumActive ? 50 : 6} MB or smaller.`);
        return;
      }
    }

    setError("");
    setAttachments(selected);
  };

  const removeAttachment = (index: number) => {
    setAttachments((current) => current.filter((_, itemIndex) => itemIndex !== index));
  };

  function clearRecordingTimer() {
    if (recordingTimerRef.current !== null) {
      window.clearInterval(recordingTimerRef.current);
      recordingTimerRef.current = null;
    }
  }

  function getActiveRecordingMs() {
    const current = recordingDurationMsRef.current;
    const startedAt = recordingStartedRef.current;
    if (!startedAt) return current;
    return current + Math.max(0, Date.now() - startedAt);
  }

  function stopRecording() {
    const recorder = mediaRecorderRef.current;
    if (!recorder || recorder.state === "inactive") return;
    recordingDurationMsRef.current = getActiveRecordingMs();
    setRecordingDurationMs(recordingDurationMsRef.current);
    recorder.stop();
    clearRecordingTimer();
  }

  function pauseRecording() {
    const recorder = mediaRecorderRef.current;
    if (!recorder || recorder.state !== "recording") return;

    recordingDurationMsRef.current = getActiveRecordingMs();
    setRecordingDurationMs(recordingDurationMsRef.current);
    recorder.pause();
    recordingStartedRef.current = 0;
    setRecordingPaused(true);
  }

  function resumeRecording() {
    const recorder = mediaRecorderRef.current;
    if (!recorder || recorder.state !== "paused") return;

    recordingStartedRef.current = Date.now();
    recorder.resume();
    setRecordingPaused(false);
  }

  async function startRecording() {
    if (recording || sending) return;

    let remainingAtStart = voiceRemainingMs;
    if (!premiumActive) {
      if (remainingAtStart === null) remainingAtStart = await refreshVoiceAllowance();
      if (remainingAtStart === null) {
        setError("Unable to check your daily voice-note allowance. Please try again.");
        return;
      }
      if (remainingAtStart <= 0) {
        setError("Your 60-second Standard voice-note allowance has been used for today. It resets tomorrow.");
        return;
      }
    }

    if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === "undefined") {
      setError("Voice notes are not supported by this browser.");
      return;
    }

    try {
      setError("");

      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const preferred = [
        "audio/webm;codecs=opus",
        "audio/webm",
        "audio/mp4",
        "audio/ogg",
      ].find((type) => MediaRecorder.isTypeSupported(type));

      const recorder = preferred
        ? new MediaRecorder(stream, { mimeType: preferred })
        : new MediaRecorder(stream);

      recordingChunksRef.current = [];
      recordingStartedRef.current = Date.now();
      recordingDurationMsRef.current = 0;

      setRecordingDurationMs(0);
      setRecordingSeconds(0);
      setRecordingPaused(false);
      setRecording(true);
      mediaRecorderRef.current = recorder;

      recorder.ondataavailable = (event) => {
        if (event.data.size) recordingChunksRef.current.push(event.data);
      };

      recorder.onstop = () => {
        if (recordingStartedRef.current) {
          recordingDurationMsRef.current = getActiveRecordingMs();
        }

        const durationMs = !premiumActive && remainingAtStart !== null
          ? Math.min(
              recordingDurationMsRef.current,
              Math.max(0, remainingAtStart),
            )
          : recordingDurationMsRef.current;

        recordingDurationMsRef.current = durationMs;
        setRecordingDurationMs(durationMs);
        setRecordingSeconds(Math.floor(durationMs / 1000));

        stream.getTracks().forEach((track) => track.stop());

        const mime = recorder.mimeType || preferred || "audio/webm";
        const blob = new Blob(recordingChunksRef.current, { type: mime });
        const extension = mime.includes("mp4")
          ? "m4a"
          : mime.includes("ogg")
            ? "ogg"
            : "webm";

        if (blob.size > 50 * 1024 * 1024) {
          setError("Voice note is too large. Keep it under 50 MB.");
        } else if (blob.size > 0) {
          setAttachments([
            new File([blob], `voice-note.${extension}`, { type: mime }),
          ]);
          setError("");
        }

        setRecording(false);
        setRecordingPaused(false);
        mediaRecorderRef.current = null;
        recordingChunksRef.current = [];
        recordingStartedRef.current = 0;
        clearRecordingTimer();
      };

      recorder.start(250);

      const allowanceAtStartMs = premiumActive
        ? null
        : Math.max(0, remainingAtStart ?? 0);

      clearRecordingTimer();
      recordingTimerRef.current = window.setInterval(() => {
        const activeMs = getActiveRecordingMs();

        setRecordingDurationMs(activeMs);
        setRecordingSeconds(Math.floor(activeMs / 1000));

        if (
          !premiumActive &&
          allowanceAtStartMs !== null &&
          activeMs >= allowanceAtStartMs
        ) {
          stopRecording();
        }
      }, 100);
    } catch (err) {
      setRecording(false);
      setRecordingPaused(false);
      mediaRecorderRef.current = null;

      setError(
        err instanceof DOMException && err.name === "NotAllowedError"
          ? "Microphone access was denied. Allow microphone access to record a voice note."
          : "Unable to start voice recording.",
      );
    }
  }

  async function sendMessage() {
    if (!selectedId || sending || (!text.trim() && attachments.length === 0)) return;
    const body = text.trim();
    const files = [...attachments];
    setSending(true);
    setError("");
    setText("");
    setAttachments([]);
    let sentCount = 0;

    try {
      for (let index = 0; index < files.length; index += 1) {
        const file = files[index];
        const isVideo = file.type.startsWith("video/");
        const isAudio = file.type.startsWith("audio/");
        const sent = await messageService.sendMessage(
          selectedId,
          index === 0 ? body : "",
          {
            file,
            type: isVideo ? "video" : isAudio ? "audio" : "image",
            durationMs: isAudio ? (recordingDurationMsRef.current || recordingDurationMs) : undefined,
          },
        );
        sentCount += 1;
        setMessages((current) => {
          const exists = current.some((m) => m.id === sent.id);
          return exists ? current.map((m) => (m.id === sent.id ? sent : m)) : [...current, sent];
        });
      }

      if (files.length === 0) {
        const sent = await messageService.sendMessage(selectedId, body);
        sentCount = 1;
        setMessages((current) => {
          const exists = current.some((m) => m.id === sent.id);
          return exists ? current.map((m) => (m.id === sent.id ? sent : m)) : [...current, sent];
        });
      }

      await refreshVoiceAllowance();
      const refreshed = await messageService.getConversations();
      setConversations(refreshed);
      if (currentUserId) setCache(`conversations:${currentUserId}`, refreshed);
      await loadProfiles(refreshed);
    } catch (err) {
      setText(body);
      setAttachments(files.slice(sentCount));
      setError(err instanceof Error ? err.message : "Unable to send message.");
    } finally {
      setSending(false);
    }
  }
  async function deleteForMe(message: Message) {
    try {
      await messageService.deleteForMe(message.id);
      setMessages((current) => current.filter((item) => item.id !== message.id));
      setMenuId(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to delete message for you.");
    }
  }

  async function deleteForEveryone(message: Message) {
    try {
      await messageService.deleteForEveryone(message.id, message.media_path);
      setMessages((current) => current.map((item) => item.id === message.id ? { ...item, deleted_at: new Date().toISOString(), content: "", media_url: null, media_path: null, media_type: null, media_viewed_at: null, media_expires_at: null } : item));
      setMenuId(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to delete message for everyone.");
    }
  }

  async function copyMessage(message: Message) {
    if (!message.content) return;
    try { await navigator.clipboard.writeText(message.content); setMenuId(null); }
    catch { setError("Unable to copy this message."); }
  }

  async function forwardMessage(message: Message, targetId: string) {
    try {
      await messageService.forwardMessage(message, targetId);
      setForwardingMessage(null);
      setMenuId(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to forward this message.");
    }
  }
  const expireViewedMedia = useCallback(async (message: Message) => {
    setMessages((current) => current.filter((m) => m.id !== message.id));
    try { await messageService.consumeViewedMedia(message.id); } catch (err) { console.error("Unable to consume viewed chat media", err); }
  }, []);
  function profileForConversation(c: ConversationWithDetails) { if (!currentUserId) return null; const other = c.members.find((m) => m.user_id !== currentUserId); return other ? profiles[other.user_id] ?? null : null; }
  useEffect(() => {
    if (!composerPanel) return;
    const handlePointerDown = (event: PointerEvent) => {
      const target = event.target as Node;
      if (emojiPanelRef.current?.contains(target) || (target as HTMLElement).closest(".ora-composer-actions")) return;
      setComposerPanel(null);
    };
    document.addEventListener("pointerdown", handlePointerDown);
    return () => document.removeEventListener("pointerdown", handlePointerDown);
  }, [composerPanel]);
  const emojiCategories = {
    "Smileys & emotion": ["😀","😃","😄","😁","😆","😅","😂","🤣","🥲","☺️","😊","😇","🙂","🙃","😉","😌","😍","🥰","😘","😗","😙","😚","😋","😛","😝","😜","🤪","🤨","🧐","🤓","😎","🤩","🥳","😏","😒","😞","😔","😟","😕","🙁","☹️","😣","😖","😫","😩","🥺","😢","😭","😤","😠","😡","🤬","🤯","😳","🥵","🥶","😱","😨","😰","😥","😓","🫣","🤗","🤔","🫡","🤭","🤫","🤥","😶","😐","😑","😬","🙄","😯","😦","😧","😮","😲","🥱","😴","🤤","😪","😵","🤐","🥴","🤢","🤮","🤧","😷","🤒","🤕","🤑","🤠","😈","👿","👹","👺","🤡","💩","👻","💀","☠️","👽","👾","🤖","🎃","😺","😸","😹","😻","😼","😽","🙀","😿","😾"],
    "People & body": ["👋","🤚","🖐️","✋","🖖","👌","🤌","🤏","✌️","🤞","🤟","🤘","🤙","👈","👉","👆","👇","☝️","👍","👎","✊","👊","🤛","🤜","👏","🙌","👐","🤲","🤝","🙏","✍️","💅","🤳","💪","🦵","🦶","👂","👃","🧠","🫀","🫁","🦷","🦴","👀","👁️","👅","👄","💋","🫦","👶","🧒","👦","👧","🧑","👱","👨","👩","🧔","👵","👴","🧓","🙍","🙎","🙅","🙆","💁","🙋","🧏","🙇","🤦","🤷","👮","🕵️","💂","🥷","👷","🤴","👸","👳","👲","🧕","🤵","👰","🤰","🫃","🫄","🧘","🧍","🧎","🚶","🏃","💃","🕺","🕴️","👯","🗣️","👤","👥"],
    "Animals & nature": ["🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷","🐸","🐵","🙈","🙉","🙊","🐒","🐔","🐧","🐦","🐤","🐣","🐥","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦄","🐝","🪲","🐛","🦋","🐌","🐞","🐜","🪰","🕷️","🦂","🐢","🐍","🦎","🦖","🦕","🐙","🦑","🦀","🦞","🦐","🐠","🐟","🐡","🦈","🐳","🐋","🐊","🐅","🐆","🦓","🦍","🦧","🐘","🦏","🦛","🐪","🐫","🦒","🦘","🦬","🐄","🐎","🐖","🐏","🐑","🦙","🐐","🦌","🐕","🐈","🐓","🦃","🦚","🦜","🦢","🦩","🕊️","🐇","🦔","🐿️","🦫","🦦","🦥","🌵","🎄","🌲","🌳","🌴","🌱","🌿","☘️","🍀","🍁","🍂","🍃","🍄","🌷","🌹","🌺","🌸","🌼","🌻","🌞","🌝","🌚","🌙","⭐","🌟","✨","⚡","🔥","🌈","☀️","🌤️","⛅","🌧️","⛈️","❄️","☃️","🌊"],
    "Food & drink": ["🍏","🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🫐","🍈","🍒","🍑","🥭","🍍","🥥","🥝","🍅","🍆","🥑","🥦","🥬","🥒","🌶️","🫑","🌽","🥕","🫒","🧄","🧅","🥔","🍠","🥐","🥯","🍞","🥖","🥨","🧀","🥚","🍳","🧈","🥞","🧇","🥓","🥩","🍗","🍖","🌭","🍔","🍟","🍕","🫓","🥪","🥙","🧆","🌮","🌯","🫔","🥗","🥘","🫕","🍝","🍜","🍲","🍛","🍣","🍱","🥟","🦪","🍤","🍙","🍚","🍘","🍥","🥠","🍡","🍧","🍨","🍦","🥧","🧁","🍰","🎂","🍪","🍩","🍫","🍬","🍭","🍮","🍯","☕","🫖","🍵","🧃","🥤","🧋","🍶","🍺","🍻","🥂","🍷","🥃","🍸","🍹","🧉","🍾"],
    "Travel & places": ["🚗","🚕","🚙","🚌","🚎","🏎️","🚓","🚑","🚒","🚐","🛻","🚚","🚛","🚜","🛵","🏍️","🚲","🛴","🛹","🚨","🚔","🚍","🚘","🚖","✈️","🛫","🛬","🛩️","🚁","🚀","🛸","🚢","⛵","🚤","🛥️","🚂","🚆","🚇","🚊","🚉","🗺️","🗿","🗽","🗼","🏰","🏯","🏟️","🎡","🎢","🎠","⛱️","🏖️","🏝️","🏜️","🏕️","⛰️","🏔️","🌋","🗻","🏙️","🌃","🌆","🌇","🌉","🌌","🏠","🏡","🏢","🏬","🏭","🏫","⛪","🕌","🛕","🕍","⛩️","🕋"],
    "Activities": ["⚽","🏀","🏈","⚾","🥎","🎾","🏐","🏉","🥏","🎱","🪀","🏓","🏸","🏒","🏑","🥍","🏏","⛳","🏹","🎣","🥊","🥋","🎽","🛹","🛼","🛷","⛸️","🥌","🎿","⛷️","🏂","🪂","🏋️","🤼","🤸","⛹️","🤺","🤾","🏌️","🏇","🧘","🏄","🏊","🤽","🚣","🧗","🚵","🚴","🎯","🎮","🕹️","🎰","🎲","🧩","♟️","🎭","🎨","🎬","🎤","🎧","🎼","🎹","🥁","🎷","🎺","🎸","🎻","🎹","🪕","🎪"],
    "Objects": ["⌚","📱","💻","⌨️","🖥️","🖨️","🖱️","💽","💾","💿","📷","📸","📹","🎥","📞","☎️","📺","📻","🎙️","💡","🔦","🏮","🪔","📚","📖","📝","✏️","🖊️","🖋️","📌","📍","📎","✂️","🔒","🔓","🔑","🗝️","🔨","🪓","⚒️","🛠️","🧰","🧲","🔬","🔭","📡","💰","💎","⚖️","🔗","🧪","🧬","🩺","💊","🚪","🪑","🛏️","🛋️","🚿","🧴","🧸","🪆","🎁","🎈","🎉","🎊","🏆","🥇","🥈","🥉","⚽","🎵","🎶","🔔","📣","📢","💬","🗨️","📩","📨","📦","✉️","❤️‍🔥","💔","❣️","💕","💞","💓","💗","💖","💘","💝","💟","☮️","✝️","☪️","🕉️","☯️","☢️","☣️","♻️","✅","❌","⚠️","❗","❓","‼️","⁉️","⭕","🚫","💯","💢","💥","💫","💦","💨","🕳️"],
    "Symbols": ["❤️","🧡","💛","💚","💙","💜","🖤","🩷","🩵","🤍","🤎","🩶","💋","💯","💢","💥","💦","💨","✨","⭐","🌟","⚡","🔥","🎉","🎊","💫","☑️","✔️","✖️","➕","➖","➗","♾️","💲","#️⃣","*️⃣","0️⃣","1️⃣","2️⃣","3️⃣","4️⃣","5️⃣","6️⃣","7️⃣","8️⃣","9️⃣","🔟","▶️","⏸️","⏯️","⏹️","⏺️","⏭️","⏮️","🔀","🔁","🔂","🔝","🔜","🔙","🔛","🔚","⬆️","↗️","➡️","↘️","⬇️","↙️","⬅️","↖️","↕️","↔️","🔄","🔃","🎵","🎶","©️","®️","™️","#️⃣","*️⃣"]
  } as const;
  const emojiCategoryNames = Object.keys(emojiCategories) as Array<keyof typeof emojiCategories>;
  const [emojiCategory, setEmojiCategory] = useState<keyof typeof emojiCategories>("Smileys & emotion");

  return <main className="ora-messages h-[calc(100vh-3.5rem)] min-h-[520px] text-white">
    <div className="flex h-full w-full overflow-hidden">
      <aside className={`ora-chat-list flex w-full shrink-0 flex-col border-r md:w-[320px] lg:w-[360px] ${mobileChatOpen ? "hidden md:flex" : "flex"}`}>
        <div className="ora-chat-list-header border-b px-4 py-3.5">
          <div className="flex items-center justify-between"><div><h1 className="text-lg font-semibold">Messages</h1><p className="mt-0.5 text-xs text-zinc-600">Private chats</p></div><div className="flex items-center gap-1"><button type="button" onClick={() => navigateToSearch()} className="icon-button" aria-label="Start a new message" title="New message"><UserPlus size={17} /></button><button type="button" onClick={() => void loadConversations()} className="icon-button" aria-label="Refresh chats"><Loader2 className={loading ? "animate-spin" : ""} size={17} /></button></div></div>
          <div className="ora-chat-search mt-3 flex items-center gap-2 px-3"><Search size={16} className="text-zinc-600" /><input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search chats" className="min-w-0 flex-1 bg-transparent text-sm text-white outline-none placeholder:text-zinc-600" />{search && <button type="button" onClick={() => setSearch("")} className="text-zinc-600 hover:text-white" aria-label="Clear search"><X size={15} /></button>}</div>
        </div>
        {error && !selectedConversation && <div className="m-3 rounded-lg bg-red-950/30 px-3 py-2 text-xs text-red-400">{error}</div>}
        <div className="min-h-0 flex-1 overflow-y-auto">
          {loading ? <div className="space-y-1 p-2"><div className="h-16 animate-pulse rounded-xl bg-zinc-900" /><div className="h-16 animate-pulse rounded-xl bg-zinc-900" /><div className="h-16 animate-pulse rounded-xl bg-zinc-900" /></div> : filteredConversations.length === 0 ? <div className="flex h-full flex-col items-center justify-center px-8 text-center"><MessageCircle size={30} className="text-zinc-700" /><h2 className="mt-3 text-sm font-medium text-zinc-300">{search ? "No chats found" : "No conversations yet"}</h2><p className="mt-1 text-xs leading-5 text-zinc-600">{search ? "Try another name or username." : "Open someone's profile and tap Message to start chatting."}</p></div> : filteredConversations.map((conversation) => { const profile = profileForConversation(conversation); const active = conversation.id === selectedId; const last = conversation.lastMessage; const preview = last?.deleted_at ? "Message deleted" : last?.media_type ? `${last.sender_id === currentUserId ? "You: " : ""}${last.media_type === "video" ? "Video" : "Photo"}${last.content ? ` · ${last.content}` : ""}` : last?.content ? `${last.sender_id === currentUserId ? "You: " : ""}${last.content}` : "Start chatting"; return <button key={conversation.id} type="button" onClick={() => selectConversation(conversation.id)} className={`ora-chat-item flex w-full items-center gap-3 px-4 py-2.5 text-left transition ${active ? "is-active" : ""}`}><Avatar profile={profile} /><div className="min-w-0 flex-1"><div className="flex items-center gap-2"><span className="min-w-0 flex-1 truncate text-sm font-semibold text-zinc-100">{profile?.display_name || `@${profile?.username || "user"}`}</span><span className="shrink-0 text-[10px] text-zinc-600">{formatListTime(last?.created_at)}</span></div><div className="mt-1 flex items-center gap-2"><p className={`min-w-0 flex-1 truncate text-xs ${conversation.unreadCount ? "font-medium text-zinc-300" : "text-zinc-600"}`}>{preview}</p>{conversation.unreadCount > 0 && <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-violet-600 px-1.5 text-[10px] font-bold text-white">{conversation.unreadCount > 99 ? "99+" : conversation.unreadCount}</span>}</div></div></button>; })}
        </div>
      </aside>

      <section className={`ora-chat-window relative min-w-0 flex-1 flex-col ${mobileChatOpen ? "flex" : "hidden md:flex"}`}>
        {!selectedConversation ? <div className="flex h-full flex-col items-center justify-center text-center"><div className="flex h-16 w-16 items-center justify-center rounded-full bg-violet-600/10 text-violet-400"><MessageCircle size={28} /></div><h2 className="mt-4 text-lg font-semibold">Your messages</h2><p className="mt-1 max-w-xs text-sm text-zinc-600">Select a chat to start talking.</p></div> : <>
          <header className="ora-chat-header flex h-[64px] shrink-0 items-center gap-3 border-b px-3 sm:px-4"><button type="button" onClick={() => setMobileChatOpen(false)} className="icon-button md:hidden" aria-label="Back to chats"><ArrowLeft size={20} /></button><Avatar profile={otherProfile} /><div className="min-w-0 flex-1"><h2 className="truncate text-sm font-semibold text-white">{otherProfile?.display_name || "ORA user"}</h2><p className="truncate text-xs text-zinc-600">{otherProfile ? `@${otherProfile.username}` : "Conversation"}</p></div></header>
          {error && <div className="mx-3 mt-2 rounded-lg bg-red-950/30 px-3 py-2 text-xs text-red-400 sm:mx-4">{error}</div>}
          <div
            ref={chatBodyRef}
            onScroll={handleChatScroll}
            className="ora-chat-body min-h-0 flex-1 overflow-y-auto px-3 py-4 sm:px-5"
          >
            {loadingMessages ? <div className="flex h-full items-center justify-center text-xs text-zinc-600"><Loader2 size={18} className="mr-2 animate-spin" />Loading messages...</div> : messages.length === 0 ? <div className="flex h-full flex-col items-center justify-center text-center"><Avatar profile={otherProfile} /><h3 className="mt-3 text-sm font-semibold text-zinc-300">Start a conversation</h3><p className="mt-1 text-xs text-zinc-600">Say hello to {otherProfile?.display_name || "this person"}.</p></div> : <div className="mx-auto flex w-full max-w-3xl flex-col gap-2">{messages.map((message, index) => { const own = message.sender_id === currentUserId; const deleted = Boolean(message.deleted_at); const previous = messages[index - 1]; const dayChanged = !previous || new Date(previous.created_at).toDateString() !== new Date(message.created_at).toDateString(); return <div key={message.id}>{dayChanged ? <div className="my-4 flex items-center gap-3 px-2"><div className="h-px flex-1 bg-zinc-900" /><span className="shrink-0 text-[10px] font-medium uppercase tracking-[0.12em] text-zinc-600">{formatDaySeparator(message.created_at)}</span><div className="h-px flex-1 bg-zinc-900" /></div> : null}<div className={`ora-message-row group flex ${own ? "justify-end" : "justify-start"}`} onContextMenu={(event) => { if (deleted) return; event.preventDefault(); setMenuId(message.id); }}><div className={`relative flex max-w-[82%] flex-col ${own ? "items-end" : "items-start"}`}><div className={`ora-bubble text-sm ${deleted ? "border border-zinc-800 bg-zinc-900/70 italic text-zinc-600" : own ? "ora-bubble-out" : "ora-bubble-in"}`}>{deleted ? <p className="italic text-zinc-500">This message was deleted</p> : <>{message.media_url && <MediaMessage message={message} own={own} onExpired={expireViewedMedia} onCompleted={async (item) => { try { const updated = await messageService.markMediaViewed(item.id); setMessages((current) => current.map((m) => m.id === updated.id ? updated : m)); return updated; } catch (err) { setError(err instanceof Error ? err.message : "Unable to start media expiry."); return null; } }} />}{message.content && <p className={message.media_url ? "mt-2 whitespace-pre-wrap" : "whitespace-pre-wrap"}>{message.content}</p>}</>}</div><div className={`mt-0.5 flex items-center gap-1 px-1 text-[10px] text-zinc-600 ${own ? "justify-end" : "justify-start"}`}><span>{formatMessageTime(message.created_at)}</span>{own && <span className={message.read_at ? "text-violet-400" : "text-zinc-600"}><BubbleStatus message={message} /></span>} {!deleted && <div className="relative"><button type="button" onMouseDown={(event) => event.stopPropagation()} onClick={() => setMenuId((value) => value === message.id ? null : message.id)} className="rounded p-1 text-zinc-600 hover:bg-zinc-900 hover:text-white" aria-label="Message options"><MoreVertical size={13} /></button>{menuId === message.id && <div onMouseDown={(event) => event.stopPropagation()} className="ora-message-menu absolute bottom-7 right-0 z-30 w-48 overflow-hidden rounded-2xl border border-zinc-700 bg-zinc-950/95 p-1.5 shadow-2xl backdrop-blur"><button type="button" onClick={() => { if (!premiumActive) { setMenuId(null); navigate("/premium"); return; } setForwardingMessage(message); setMenuId(null); }} className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs ${premiumActive ? "text-zinc-200 hover:bg-zinc-800" : "ora-premium-locked text-amber-200"}`}><Forward size={15} />{premiumActive ? "Forward" : "Forward · Power Hour"}</button>{message.content ? <button type="button" onClick={() => void copyMessage(message)} className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs text-zinc-200 hover:bg-zinc-800"><Copy size={15} />Copy</button> : null}<div className="my-1 border-t border-zinc-800" />{own ? <><button type="button" onClick={() => void deleteForMe(message)} className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs text-zinc-300 hover:bg-zinc-800"><Trash2 size={15} />Delete for me</button><button type="button" onClick={() => void deleteForEveryone(message)} className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs text-red-400 hover:bg-red-950/30"><Trash2 size={15} />Delete for everyone</button></> : <button type="button" onClick={() => void deleteForMe(message)} className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs text-red-400 hover:bg-red-950/30"><Trash2 size={15} />Delete for me</button>}</div>}</div>}</div></div></div></div>; })}<div ref={endRef} /></div>}
          </div>
          {showJumpToLatest ? (
            <button
              type="button"
              onClick={jumpToLatest}
              className="absolute bottom-20 left-1/2 z-20 flex h-10 w-10 -translate-x-1/2 items-center justify-center rounded-full border border-white/10 bg-zinc-900/80 text-zinc-200 shadow-lg backdrop-blur-md transition hover:bg-zinc-800/90 hover:text-white"
              aria-label="Jump to latest message"
              title="Jump to latest message"
            >
              <ArrowDown size={18} />
            </button>
          ) : null}
          <div className="ora-composer shrink-0 border-t px-3 py-2.5 sm:px-4">
            {recording && (
              <div className="mx-auto mb-2 flex max-w-3xl items-center gap-3 rounded-xl border border-red-900/40 bg-red-950/20 px-3 py-2">
                <div className="flex min-w-0 flex-1 items-center gap-2.5">
                  <span className={`h-2.5 w-2.5 shrink-0 rounded-full ${recordingPaused ? "bg-amber-400" : "bg-red-500 animate-pulse"}`} />
                  <div className="min-w-0">
                    <p className="truncate text-xs font-medium text-red-200">
                      {recordingPaused ? "Voice note paused" : "Recording voice note"}
                    </p>
                    <p className="text-[10px] text-red-300/70">
                      {recordingSeconds}s
                      {!premiumActive
                        ? ` / ${Math.max(0, Math.floor((voiceRemainingMs ?? 60000) / 1000))}s remaining today`
                        : ""}
                    </p>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={recordingPaused ? resumeRecording : pauseRecording}
                  className="flex h-9 shrink-0 items-center gap-1.5 rounded-lg border border-zinc-700 bg-zinc-900 px-3 text-xs font-medium text-zinc-200 transition hover:bg-zinc-800"
                  aria-label={recordingPaused ? "Resume recording" : "Pause recording"}
                  title={recordingPaused ? "Resume recording" : "Pause recording"}
                >
                  {recordingPaused ? <Play size={14} /> : <Pause size={14} />}
                  {recordingPaused ? "Resume" : "Pause"}
                </button>

                <button
                  type="button"
                  onClick={stopRecording}
                  className="flex h-9 shrink-0 items-center gap-1.5 rounded-lg bg-red-600 px-3 text-xs font-semibold text-white transition hover:bg-red-500"
                  aria-label="Stop recording"
                  title="Stop recording"
                >
                  <Square size={13} fill="currentColor" />
                  Stop
                </button>
              </div>
            )}
            {attachments.length > 0 && <div className="mx-auto mb-2 max-w-3xl rounded-xl border border-zinc-800 bg-zinc-900/70 p-2.5">
              <div className="mb-2 flex items-center justify-between gap-3 px-1">
                <div className="min-w-0">
                  <p className="text-xs font-medium text-zinc-200">{attachments.length === 1 ? attachments[0].name : `${attachments.length} images selected`}</p>
                  <p className="text-[10px] text-zinc-600">{attachments.reduce((total, file) => total + file.size, 0) / 1024 / 1024 < 0.1 ? "Less than 0.1" : (attachments.reduce((total, file) => total + file.size, 0) / 1024 / 1024).toFixed(1)} MB total · {attachments.length === 1 && attachments[0].type.startsWith("audio/") ? "voice note" : attachments.length > 1 ? "Power Hour · sends as separate messages" : attachments[0].type.startsWith("video/") ? "Power Hour video" : premiumActive ? "Power Hour image" : "Standard image"}</p>
                </div>
                <button type="button" onClick={() => setAttachments([])} className="icon-button h-8 w-8 shrink-0" aria-label="Remove all attachments"><X size={16} /></button>
              </div>
              <div className="flex flex-wrap gap-1.5">
                {attachments.map((file, index) => <button key={`${file.name}-${file.lastModified}-${index}`} type="button" onClick={() => removeAttachment(index)} className="flex max-w-full items-center gap-1.5 rounded-lg border border-zinc-800 bg-zinc-950/70 px-2 py-1.5 text-left text-[10px] text-zinc-400 hover:border-zinc-700 hover:text-zinc-200" title="Remove this attachment"><span className="shrink-0 text-violet-300">{file.type.startsWith("video/") ? <Video size={13} /> : file.type.startsWith("audio/") ? <Mic size={13} /> : <ImagePlus size={13} />}</span><span className="max-w-[180px] truncate">{file.name}</span><X size={11} className="shrink-0 text-zinc-600" /></button>)}
              </div>
            </div>}
            {composerPanel === "emoji" ? <div ref={emojiPanelRef} className="mx-auto mb-2 max-w-3xl rounded-2xl border border-zinc-800 bg-zinc-950/95 p-3 shadow-2xl backdrop-blur"><div className="mb-2 flex items-center justify-between"><p className="text-xs font-semibold text-zinc-300">Emoji</p><button type="button" onClick={() => setComposerPanel(null)} className="icon-button h-8 w-8" aria-label="Close emoji picker"><X size={15} /></button></div><div className="mb-2 flex gap-1 overflow-x-auto border-b border-zinc-800 pb-2">{emojiCategoryNames.map((category) => <button key={category} type="button" onClick={() => setEmojiCategory(category)} className={`whitespace-nowrap rounded-full px-2.5 py-1.5 text-[11px] font-semibold ${emojiCategory === category ? "bg-zinc-800 text-white" : "text-zinc-500 hover:text-zinc-200"}`}>{category}</button>)}</div><div className="grid max-h-56 grid-cols-8 gap-1 overflow-y-auto pr-1 sm:grid-cols-12">{emojiCategories[emojiCategory].map((emoji, index) => <button key={`${emoji}-${index}`} type="button" onClick={() => setText((value) => `${value}${emoji}`)} className="flex h-9 items-center justify-center rounded-lg text-xl hover:bg-zinc-800" aria-label={`Insert ${emoji}`}>{emoji}</button>)}</div></div> : null}<form onSubmit={(e) => { e.preventDefault(); void sendMessage(); }} className="mx-auto flex max-w-3xl items-end gap-1.5"><input ref={fileRef} type="file" accept="image/jpeg,image/png,image/webp,image/gif,image/avif,image/bmp" multiple={premiumActive} hidden onChange={(e) => { chooseAttachments(e.target.files ?? undefined); e.currentTarget.value = ""; }} /><input id="ora-video-input" type="file" accept="video/mp4,video/webm,video/quicktime,video/ogg,video/mpeg,video/x-m4v" hidden onChange={(e) => { chooseAttachments(e.target.files ?? undefined); e.currentTarget.value = ""; }} /><div className="ora-composer-actions relative shrink-0">
                <button type="button" onClick={() => setComposerPanel((value) => value === "actions" ? null : "actions")} disabled={sending || recording} className={`icon-button mb-0.5 h-11 w-11 rounded-full ${composerPanel === "actions" ? "bg-zinc-800 text-violet-400" : ""}`} aria-label="More message actions" title="Attachments and tools"><Plus size={20} /></button>
                {composerPanel === "actions" ? <div className="absolute bottom-14 left-0 z-40 w-52 overflow-hidden rounded-2xl border border-zinc-800 bg-zinc-950 p-1.5 shadow-2xl">
                  <button type="button" onClick={() => { setComposerPanel("emoji"); }} className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs text-zinc-200 hover:bg-zinc-900"><Smile size={17} />Emoji</button>
                  <button type="button" onClick={() => { setComposerPanel(null); fileRef.current?.click(); }} className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs text-zinc-200 hover:bg-zinc-900"><ImagePlus size={17} />Photo{premiumActive ? "s" : ""}</button>
                  <button type="button" onClick={() => { if (!premiumActive) { navigate("/premium"); return; } setComposerPanel(null); document.getElementById("ora-video-input")?.click(); }} className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs ${premiumActive ? "text-zinc-200 hover:bg-zinc-900" : "ora-premium-locked text-amber-200"}`}><Video size={17} />Video{premiumActive ? "" : " · Power Hour"}</button>
                  <button type="button" onClick={() => { setComposerPanel(null); if (!recording) void startRecording(); }} disabled={sending || recording} className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-xs text-zinc-200 hover:bg-zinc-900 disabled:cursor-not-allowed disabled:opacity-50"><Mic size={17} />Voice note</button>
                </div> : null}
              </div><div className="min-w-0 flex-1"><textarea value={text} onChange={(e) => setText(e.target.value)} onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); void sendMessage(); } }} rows={1} maxLength={maxMessageLength} disabled={sending} placeholder={attachments.length > 0 ? "Add a caption…" : "Type a message"} className="max-h-32 min-h-11 w-full resize-none rounded-2xl border border-zinc-800 bg-zinc-900 px-4 py-2.5 text-sm text-white outline-none placeholder:text-zinc-600 focus:border-violet-600" /><div className="mt-1 flex justify-end px-1 text-[10px] text-zinc-600">{text.length}/{maxMessageLength}</div></div><button type="submit" disabled={sending || recording || (!text.trim() && attachments.length === 0)} className="mb-0.5 flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-violet-600 text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-40" aria-label="Send message">{sending ? <Loader2 size={18} className="animate-spin" /> : <Send size={18} />}</button></form>
          </div>
        </>}
      </section>
    </div>
    {forwardingMessage ? <div className="fixed inset-0 z-[90] flex items-center justify-center bg-black/70 p-4 backdrop-blur-sm" role="dialog" aria-modal="true" onMouseDown={(event) => { if (event.target === event.currentTarget) setForwardingMessage(null); }}><div className="w-full max-w-md overflow-hidden rounded-2xl border border-zinc-800 bg-zinc-950 shadow-2xl"><div className="flex items-center justify-between border-b border-zinc-800 px-4 py-3"><div><h2 className="text-sm font-semibold text-white">Forward message</h2><p className="mt-0.5 text-xs text-zinc-500">Choose a chat</p></div><button type="button" onClick={() => setForwardingMessage(null)} className="icon-button h-9 w-9"><X size={17} /></button></div><div className="max-h-[60vh] overflow-y-auto p-2">{conversations.filter((conversation) => conversation.id !== selectedId).map((conversation) => { const profile = profileForConversation(conversation); return <button key={conversation.id} type="button" onClick={() => void forwardMessage(forwardingMessage, conversation.id)} className="flex w-full items-center gap-3 rounded-xl px-3 py-3 text-left hover:bg-zinc-900"><Avatar profile={profile} /><div className="min-w-0"><p className="truncate text-sm font-semibold text-zinc-200">{profile?.display_name || `@${profile?.username || "user"}`}</p><p className="text-xs text-zinc-600">{profile?.username ? `@${profile.username}` : "ORA user"}</p></div></button>; })}</div></div></div> : null}
  </main>;
}
