import type { ReactNode } from "react";
import { useLocation } from "react-router-dom";
import Sidebar from "./Sidebar";
import Topbar from "./Topbar";
import BottomNav from "./BottomNav";
import { useAuth } from "../../features/auth/hooks/useAuth";
import { useEffect } from "react";
import { getCache, setCache } from "../../lib/cache";
import { postService } from "../../features/post/services/post.service";
import { hoodService } from "../../features/hoods/services/hood.service";
import { auraService } from "../../features/aura/aura.service";
import { messageService } from "../../features/messages/services/message.service";
import { notificationService } from "../../features/notifications/services/notification.service";

interface AppShellProps {
  children: ReactNode;
}

const SHELL_EXCLUDED_PATHS = new Set([
  "/login",
  "/signup",
  "/setup-profile",
  "/reset-password",
  "/switch-account",
  "/add-account",
]);

export default function AppShell({ children }: AppShellProps) {
  const { pathname } = useLocation();
  const { loading: authLoading, isAuthenticated, user } = useAuth();
  const hideShell = SHELL_EXCLUDED_PATHS.has(pathname) || (pathname === "/" && (authLoading || !isAuthenticated));

  useEffect(() => {
    if (authLoading || !isAuthenticated || !user) return;
    let cancelled = false;
    const timer = window.setTimeout(() => {
      if (cancelled) return;
      const warm = async () => {
        const tasks: Promise<unknown>[] = [];
        if (!getCache("feed:current", 10 * 60 * 1000)) tasks.push(postService.getFeed().then((value) => { setCache("feed:current", value); return value; }));
        if (!getCache("hoods:list", 10 * 60 * 1000)) tasks.push(hoodService.getHoods().then((value) => { setCache("hoods:list", value); return value; }));
        if (!getCache("aura:current", 10 * 60 * 1000)) tasks.push(Promise.all([auraService.getCurrentAura(), auraService.getHistory(), auraService.getLeaderboard()]).then(([aura, history, leaderboard]) => { const value = { aura, history, leaderboard }; setCache("aura:current", value); return value; }));
        if (!getCache(`conversations:${user.id}`, 10 * 60 * 1000)) tasks.push(messageService.getConversations().then((value) => { setCache(`conversations:${user.id}`, value); return value; }));
        if (!getCache(`notifications:${user.id}`, 10 * 60 * 1000)) tasks.push(notificationService.list(user.id).then((value) => { setCache(`notifications:${user.id}`, value); return value; }));
        // The feature pages own their cache writes; this warmer only starts
        // requests that are otherwise needed for the next navigation.
        await Promise.allSettled(tasks);
      };
      void warm();
    }, 1200);
    return () => { cancelled = true; window.clearTimeout(timer); };
  }, [authLoading, isAuthenticated, user]);
  const isMessages = pathname.startsWith("/messages");

  if (hideShell) {
    return <>{children}</>;
  }

  return (
    <div className="min-h-screen bg-zinc-950 text-white">
      <Topbar />

      <div className={`mx-auto flex w-full ${isMessages ? "max-w-none" : "max-w-[1440px]"}`}>
        {/* Desktop Sidebar */}
        <aside className="hidden w-60 shrink-0 border-r border-zinc-800 lg:block">
          <Sidebar />
        </aside>

        {/* Main Content */}
        <main className={`min-h-screen min-w-0 flex-1 ${isMessages ? "border-0" : "border-x border-zinc-800"}`}>
          {children}
        </main>

      </div>

      {/* Mobile Navigation */}
      <BottomNav />
    </div>
  );
}
