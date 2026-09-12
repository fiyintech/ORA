import { Bell, Search } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useState } from "react";
import { useUnreadNotificationCount } from "../../features/notifications/hooks/useUnreadNotificationCount";

export default function Topbar() {
  const navigate = useNavigate();
  const [query, setQuery] = useState("");
  const unread = useUnreadNotificationCount();

  function submit(event: React.FormEvent) {
    event.preventDefault();
    const value = query.trim();
    navigate(value ? `/search?q=${encodeURIComponent(value)}` : "/search");
  }

  return (
    <header className="ora-topbar sticky top-0 z-50 border-b backdrop-blur">
      <div className="ora-topbar-inner mx-auto flex h-14 max-w-[1440px] items-center gap-3 px-3 sm:px-5">
        <button type="button" onClick={() => navigate("/")} className="ora-topbar-logo ml-11 shrink-0 lg:ml-0 text-xl font-bold tracking-tight text-white hover:text-violet-400" aria-label="ORA home">ORA</button>

        <form onSubmit={submit} className="ora-desktop-search ml-auto w-full max-w-sm">
          <div className="flex h-10 items-center gap-2 rounded-full bg-zinc-900 px-4 ring-1 ring-transparent transition focus-within:ring-zinc-700">
            <Search size={17} className="shrink-0 text-zinc-500" />
            <input value={query} onChange={(event) => setQuery(event.target.value)} className="w-full bg-transparent text-sm text-white outline-none placeholder:text-zinc-600" placeholder="Search people on ORA" aria-label="Search ORA" />
          </div>
        </form>

        <div className="ora-topbar-actions ml-auto flex items-center gap-1">
          <button type="button" onClick={() => navigate("/search")} className="ora-mobile-search-button flex items-center justify-center text-zinc-400 transition hover:bg-zinc-900 hover:text-white" aria-label="Search ORA" title="Search">
            <Search size={19} />
          </button>
          <button type="button" onClick={() => navigate("/notifications")} aria-label={unread ? `${unread} unread notifications` : "Notifications"} title="Notifications"
            className="ora-mobile-notification-button relative flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-zinc-400 transition hover:bg-zinc-900 hover:text-white">
            <Bell size={20} />
            {unread > 0 ? <span className="absolute right-0.5 top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-violet-600 px-1 text-[8px] font-bold text-white ring-2 ring-zinc-950">{unread > 99 ? "99+" : unread}</span> : null}
          </button>
        </div>
      </div>
    </header>
  );
}
