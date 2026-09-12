import {
  Bell,
  House,
  MessageCircle,
  Search,
  Settings,
  Sparkles,
  User,
  Users,
} from "lucide-react";
import { useLocation, useNavigate } from "react-router-dom";
import { useUnreadMessageCount } from "../../features/messages/hooks/useUnreadMessageCount";
import { useUnreadNotificationCount } from "../../features/notifications/hooks/useUnreadNotificationCount";

const items = [
  {
    icon: House,
    label: "Home",
    path: "/",
  },
  {
    icon: Search,
    label: "Search",
    path: "/search",
  },
  {
    icon: MessageCircle,
    label: "Messages",
    path: "/messages",
  },
  {
    icon: Bell,
    label: "Notifications",
    path: "/notifications",
  },
  {
    icon: Users,
    label: "Hoods",
    path: "/hoods",
  },
  {
    icon: Sparkles,
    label: "Aura",
    path: "/aura",
  },
  {
    icon: User,
    label: "Profile",
    path: "/profile",
  },
  {
    icon: Settings,
    label: "Settings",
    path: "/settings",
  },
];

export default function Sidebar() {
  const navigate = useNavigate();
  const location = useLocation();
  const unread = useUnreadMessageCount();
  const unreadNotifications = useUnreadNotificationCount();

  return (
    <aside className="sticky top-14 h-[calc(100vh-3.5rem)] px-3 py-4">
      <div className="space-y-1">
        {items.map(({ icon: Icon, label, path }) => {
          const active =
            path === "/"
              ? location.pathname === "/"
              : location.pathname.startsWith(path);

          return (
            <button
              key={label}
              type="button"
              onClick={() => navigate(path)}
              className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition ${
                active
                  ? "border-l-2 border-violet-500 bg-zinc-900 text-white pl-[10px]"
                  : "border-l-2 border-transparent text-zinc-400 hover:bg-zinc-900 hover:text-white"
              }`}
            >
              <span className="relative shrink-0">
                <Icon size={20} />
                {label === "Messages" && unread > 0 ? (
                  <span className="absolute -right-2 -top-2 flex h-4 min-w-4 items-center justify-center rounded-full bg-violet-600 px-1 text-[9px] font-bold text-white ring-2 ring-zinc-950">
                    {unread > 99 ? "99+" : unread}
                  </span>
                ) : null}
                {label === "Notifications" && unreadNotifications > 0 ? (
                  <span className="absolute -right-2 -top-2 flex h-4 min-w-4 items-center justify-center rounded-full bg-violet-600 px-1 text-[9px] font-bold text-white ring-2 ring-zinc-950">
                    {unreadNotifications > 99 ? "99+" : unreadNotifications}
                  </span>
                ) : null}
              </span>

              <span className="min-w-0 flex-1 font-medium">
                {label}
              </span>
            </button>
          );
        })}
      </div>
    </aside>
  );
}
