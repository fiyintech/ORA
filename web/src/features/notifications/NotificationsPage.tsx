import {
  Bell,
  Check,
  Heart,
  MessageCircle,
  RefreshCw,
  UserPlus,
} from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { getCache, setCache } from "../../lib/cache";

const NOTIFICATIONS_CACHE_TTL = 10 * 60 * 1000;

import Avatar from "../../components/ui/Avatar";
import Skeleton from "../../components/ui/Skeleton";
import { useAuth } from "../auth/hooks/useAuth";
import {
  notificationService,
  type Notification,
} from "./services/notification.service";

function formatRelativeTime(value: string) {
  const date = new Date(value);
  const seconds = Math.max(0, Math.floor((Date.now() - date.getTime()) / 1000));

  if (seconds < 60) return "just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d`;
  return date.toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

function getNotificationCopy(notification: Notification) {
  const name = notification.actor?.display_name || notification.actor?.username || "Someone";

  switch (notification.type) {
    case "like":
      return { name, action: "liked your post", icon: Heart };
    case "comment":
      return { name, action: "commented on your post", icon: MessageCircle };
    case "reply":
      return { name, action: "replied to your comment", icon: MessageCircle };
    case "follow":
      return { name, action: "started following you", icon: UserPlus };
    case "message":
      return { name, action: "sent you a message", icon: MessageCircle };
    default:
      return { name, action: "interacted with you", icon: Bell };
  }
}

function NotificationRow({
  notification,
  onRead,
  onOpen,
}: {
  notification: Notification;
  onRead: (id: string) => void;
  onOpen: (notification: Notification) => void;
}) {
  const { name, action, icon: Icon } = getNotificationCopy(notification);
  const unread = !notification.is_read;

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={() => onOpen(notification)}
      onKeyDown={(event) => {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          onOpen(notification);
        }
      }}
      className={`flex w-full cursor-pointer items-start gap-4 border-b border-zinc-800 px-4 py-3 text-left transition sm:px-6 ${
        unread ? "bg-zinc-900/70" : "bg-zinc-950 hover:bg-zinc-900/40"
      }`}
    >
      <div className="relative shrink-0">
        <Avatar src={notification.actor?.avatar ?? undefined} name={name} size={44} />
        <span className="absolute -bottom-1 -right-1 flex h-6 w-6 items-center justify-center rounded-full border-2 border-zinc-950 bg-violet-600 text-white">
          <Icon size={12} />
        </span>
      </div>

      <div className="min-w-0 flex-1">
        <p className="text-sm leading-6 text-zinc-200">
          <span className="font-semibold text-white">{name}</span>{" "}
          {action}
        </p>
        <p className="mt-1 text-xs text-zinc-500">{formatRelativeTime(notification.created_at)}</p>
      </div>

      {unread ? (
        <button
          type="button"
          aria-label="Mark notification as read"
          onClick={(event) => {
            event.stopPropagation();
            onRead(notification.id);
          }}
          className="mt-1 rounded-lg p-2 text-zinc-500 transition hover:bg-zinc-800 hover:text-white"
        >
          <Check size={16} />
        </button>
      ) : null}
    </div>
  );
}

function LoadingState() {
  return (
    <div className="divide-y divide-zinc-800">
      {Array.from({ length: 7 }).map((_, index) => (
        <div key={index} className="flex gap-4 px-4 py-5 sm:px-6">
          <Skeleton className="h-11 w-11 shrink-0 rounded-full" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-3/4" />
            <Skeleton className="h-3 w-16" />
          </div>
        </div>
      ))}
    </div>
  );
}

export default function NotificationsPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const unreadCount = useMemo(
    () => notifications.filter((notification) => !notification.is_read).length,
    [notifications],
  );

  const loadNotifications = useCallback(async (showRefreshState = false) => {
    if (!user) return;

    if (showRefreshState) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await notificationService.list(user.id);
      setNotifications(data);
      setCache(`notifications:${user.id}`, data);
    } catch (cause) {
      console.error("Failed to load notifications:", cause);
      setError("We couldn't load your notifications. Please try again.");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [user]);

  useEffect(() => {
    if (!user) return;
    const cached = getCache<Notification[]>(`notifications:${user.id}`, NOTIFICATIONS_CACHE_TTL);
    if (cached) {
      setNotifications(cached);
      setLoading(false);
      void loadNotifications(true);
      return;
    }
    void loadNotifications();
  }, [loadNotifications, user]);

  useEffect(() => {
    if (!user) return;
    if (notifications.length) setCache(`notifications:${user.id}`, notifications);
  }, [notifications, user]);

  useEffect(() => {
    if (!user) return;

    const unsubscribe = notificationService.subscribe(user.id, () => {
      void loadNotifications();
    });

    return unsubscribe;
  }, [loadNotifications, user]);

  const markAsRead = async (notificationId: string) => {
    if (!user) return;

    setNotifications((current) =>
      current.map((notification) =>
        notification.id === notificationId
          ? { ...notification, is_read: true }
          : notification,
      ),
    );

    try {
      await notificationService.markAsRead(user.id, notificationId);
    } catch (cause) {
      console.error("Failed to mark notification as read:", cause);
      await loadNotifications();
    }
  };

  const markAllAsRead = async () => {
    if (!user || unreadCount === 0) return;

    setNotifications((current) =>
      current.map((notification) => ({ ...notification, is_read: true })),
    );

    try {
      await notificationService.markAllAsRead(user.id);
    } catch (cause) {
      console.error("Failed to mark all notifications as read:", cause);
      await loadNotifications();
    }
  };

  const openNotification = async (notification: Notification) => {
    if (!notification.is_read) {
      await markAsRead(notification.id);
    }

    if (notification.type === "message" && notification.conversation_id) {
      navigate(`/messages?conversation=${encodeURIComponent(notification.conversation_id)}`);
      return;
    }

    if (notification.type === "follow" && notification.actor?.username) {
      navigate(`/profile/${notification.actor.username}`);
      return;
    }

    // A post-detail route does not exist in the current web router yet.
    // Keep post notifications readable without inventing a route that does not exist.
    if (notification.post_id) {
      navigate(`/#post-${encodeURIComponent(notification.post_id)}`);
    }
  };

  return (
    <section className="min-h-screen bg-zinc-950 pb-20 lg:pb-8">
      <header className="sticky top-16 z-20 flex items-center justify-between border-b border-zinc-800 bg-zinc-950/95 px-4 py-4 backdrop-blur sm:px-6">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-xl font-bold tracking-tight text-white">Notifications</h1>
            {unreadCount > 0 ? (
              <span className="rounded-full bg-violet-600 px-2.5 py-0.5 text-xs font-semibold text-white">
                {unreadCount}
              </span>
            ) : null}
          </div>
          <p className="mt-1 text-sm text-zinc-500">Stay up to date with what’s happening on ORA.</p>
        </div>

        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={() => void loadNotifications(true)}
            disabled={refreshing || loading}
            aria-label="Refresh notifications"
            className="rounded-xl p-2.5 text-zinc-400 transition hover:bg-zinc-900 hover:text-white disabled:opacity-50"
          >
            <RefreshCw size={18} className={refreshing ? "animate-spin" : ""} />
          </button>
          {unreadCount > 0 ? (
            <button
              type="button"
              onClick={() => void markAllAsRead()}
              className="hidden rounded-xl px-3 py-2 text-sm font-medium text-zinc-300 transition hover:bg-zinc-900 hover:text-white sm:block"
            >
              Mark all read
            </button>
          ) : null}
        </div>
      </header>

      {loading ? <LoadingState /> : null}

      {!loading && error ? (
        <div className="mx-4 mt-8 rounded-2xl border border-red-500/20 bg-red-500/5 p-6 text-center sm:mx-6">
          <p className="text-sm font-medium text-zinc-200">Something went wrong</p>
          <p className="mt-1 text-sm text-zinc-500">{error}</p>
          <button
            type="button"
            onClick={() => void loadNotifications()}
            className="mt-4 rounded-xl bg-white px-4 py-2 text-sm font-semibold text-black transition hover:bg-zinc-200"
          >
            Try again
          </button>
        </div>
      ) : null}

      {!loading && !error && notifications.length === 0 ? (
        <div className="flex min-h-[55vh] items-center justify-center px-6">
          <div className="max-w-sm text-center">
            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-zinc-900 text-zinc-400">
              <Bell size={28} />
            </div>
            <h2 className="mt-5 text-lg font-semibold text-white">You’re all caught up</h2>
            <p className="mt-2 text-sm leading-6 text-zinc-500">
              When people interact with you on ORA, their activity will show up here.
            </p>
          </div>
        </div>
      ) : null}

      {!loading && !error && notifications.length > 0 ? (
        <div className="mx-auto max-w-3xl">
          {notifications.map((notification) => (
            <NotificationRow
              key={notification.id}
              notification={notification}
              onRead={(id) => void markAsRead(id)}
              onOpen={(item) => void openNotification(item)}
            />
          ))}
        </div>
      ) : null}
    </section>
  );
}
