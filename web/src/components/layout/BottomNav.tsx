import { House, Menu, MessageCircle, Search, Settings, Sparkles, User, Users, X } from "lucide-react";
import { useEffect, useState } from "react";
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
  const [open, setOpen] = useState(false);

  useEffect(() => setOpen(false), [location.pathname]);
  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => { if (event.key === "Escape") setOpen(false); };
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => { document.removeEventListener("keydown", onKey); document.body.style.overflow = ""; };
  }, [open]);

  const isActive = (path: string) => path === "/" ? location.pathname === "/" : location.pathname.startsWith(path);

  return (
    <div className="lg:hidden">
      {open ? <div className="fixed inset-0 z-[80] bg-black/60" aria-hidden="true" onClick={() => setOpen(false)} /> : null}
      <aside className={`ora-mobile-drawer fixed left-0 top-0 z-[90] flex h-full w-[min(84vw,340px)] flex-col border-r transition-transform duration-200 ${open ? "translate-x-0" : "-translate-x-full"}`} aria-label="Mobile navigation">
        <div className="flex h-16 shrink-0 items-center justify-between border-b px-5">
          <button type="button" onClick={() => { setOpen(false); navigate("/"); }} className="text-xl font-black tracking-tight text-white" aria-label="ORA home">ORA</button>
          <button type="button" onClick={() => setOpen(false)} className="icon-button h-10 w-10 rounded-full" aria-label="Close navigation"><X size={20} /></button>
        </div>
        <nav className="flex-1 overflow-y-auto px-3 py-4" aria-label="Primary navigation">
          <div className="space-y-1">
            {items.map(({ icon: Icon, label, path }) => {
              const active = isActive(path);
              const badge = label === "Messages" ? unread : 0;
              return <button key={label} type="button" onClick={() => navigate(path)} className={`flex w-full items-center gap-3 rounded-xl px-3 py-3 text-left transition ${active ? "bg-zinc-900 text-white" : "text-zinc-400 hover:bg-zinc-900/70 hover:text-white"}`}>
                <span className="relative shrink-0"><Icon size={20} strokeWidth={active ? 2.2 : 1.8} />{badge > 0 ? <span className="absolute -right-2 -top-2 flex h-4 min-w-4 items-center justify-center rounded-full bg-violet-600 px-1 text-[9px] font-bold text-white ring-2 ring-zinc-950">{badge > 99 ? "99+" : badge}</span> : null}</span>
                <span className="flex-1 font-medium">{label}</span>
              </button>;
            })}
          </div>
        </nav>
        <div className="border-t px-5 py-4 text-xs text-zinc-600">Move around ORA without the bottom bar.</div>
      </aside>
      <button type="button" onClick={() => setOpen(true)} className="ora-mobile-menu-button fixed left-3 top-[calc(env(safe-area-inset-top)+10px)] z-[70] flex h-10 w-10 items-center justify-center rounded-full" aria-label="Open navigation" title="Menu"><Menu size={20} /></button>
    </div>
  );
}
