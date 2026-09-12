import { useEffect, useState } from "react";
import { supabase } from "../../../lib/supabase";
import { messageService } from "../services/message.service";

export function useUnreadMessageCount() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    let mounted = true;

    const load = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        const user = session?.user ?? null;
        if (!user) {
          if (mounted) setCount(0);
          return;
        }
        const next = await messageService.getUnreadCount();
        if (mounted) setCount(next);
      } catch (error) {
        console.error("Unable to load unread message count:", error);
      }
    };

    void load();

    const channel = supabase
      .channel(`ora-unread-message-count-${Math.random().toString(36).slice(2)}`)
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "messages" }, () => void load())
      .on("postgres_changes", { event: "UPDATE", schema: "public", table: "messages" }, () => void load())
      .subscribe();

    return () => {
      mounted = false;
      void supabase.removeChannel(channel);
    };
  }, []);

  return count;
}
