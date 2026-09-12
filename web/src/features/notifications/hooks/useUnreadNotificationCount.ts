import { useEffect, useState } from "react";
import { supabase } from "../../../lib/supabase";
import { notificationService } from "../services/notification.service";

export function useUnreadNotificationCount() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    let mounted = true;
    const load = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        const user = session?.user ?? null;
        if (!user) { if (mounted) setCount(0); return; }
        const params = new URLSearchParams(window.location.search);
        const activeConversation = window.location.pathname.startsWith("/messages") ? params.get("conversation") : null;
        let next = await notificationService.unreadCount(user.id);
        if (activeConversation) {
          const activeMessageCount = await supabase
            .from("notifications")
            .select("id", { count: "exact", head: true })
            .eq("recipient_id", user.id)
            .eq("conversation_id", activeConversation)
            .eq("type", "message")
            .eq("is_read", false);
          if (!activeMessageCount.error) next = Math.max(0, next - (activeMessageCount.count ?? 0));
        }
        if (mounted) setCount(next);
      } catch (error) {
        console.error("Unable to load unread notification count:", error);
      }
    };
    void load();
    const channel = supabase.channel(`ora-notification-count-${Math.random().toString(36).slice(2)}`)
      .on("postgres_changes", { event: "*", schema: "public", table: "notifications" }, () => void load())
      .subscribe();
    return () => { mounted = false; void supabase.removeChannel(channel); };
  }, []);

  return count;
}
