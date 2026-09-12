import { House, MessageCircle, Search, Settings, Sparkles, User, Users } from "lucide-react";
import { useLocation, useNavigate } from "react-router-dom";
import { useUnreadMessageCount } from "../../features/messages/hooks/useUnreadMessageCount";

const items = [
  { icon: House, label: "Home", path: "/" },
  { icon: Search, label: "Search", path: "/search" },
  { icon: MessageCircle, label: "Messages", path: "/messages" },
  { icon: Users, label: "Hoods", path: "/hoods" },
  { icon: Sparkles, label: "Aura", path: "/aura" },
  { icon: User, label: "Profile", path: "/profile" },
  { icon: Settings, label: "Settings", path: "/settings" },
];

export default function BottomNav() {
  const navigate = useNavigate();
  const location = useLocation();
  const unread = useUnreadMessageCount();

  return (
    <nav className="ora-bottom-nav fixed bottom-0 left-0 right-0 z-50 lg:hidden" aria-label="Primary navigation">
      <div className="grid h-[64px] grid-cols-7">
        {items.map(({ icon: Icon, label, path }) => {
          const active = path === "/" ? location.pathname === "/" : location.pathname.startsWith(path);
          const isMessages = path === "/messages";
          return (
            <button key={label} type="button" onClick={() => navigate(path)} aria-label={label}
              className={`relative flex min-w-0 flex-col items-center justify-center gap-0.5 text-[9px] font-medium transition ${active ? "text-white" : "text-zinc-500 hover:text-white"}`}>
              <span className={`relative rounded-lg p-1.5 ${active ? "bg-zinc-900 text-violet-400" : ""}`}>
                <Icon size={19} strokeWidth={active ? 2.2 : 1.8} />
                {isMessages && unread > 0 ? <span className="absolute -right-1.5 -top-1.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-violet-600 px-1 text-[8px] font-bold text-white ring-2 ring-zinc-950">{unread > 99 ? "99+" : unread}</span> : null}
              </span>
              <span className="max-w-full truncate px-0.5">{label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
