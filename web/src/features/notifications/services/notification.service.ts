import { supabase } from "../../../lib/supabase";

export type NotificationType = "like" | "comment" | "reply" | "follow" | "message";

export interface NotificationActor {
  user_id: string;
  username: string | null;
  display_name: string | null;
  avatar: string | null;
}

export interface Notification {
  id: string;
  recipient_id: string;
  actor_id: string;
  post_id: string | null;
  comment_id: string | null;
  conversation_id: string | null;
  type: NotificationType;
  is_read: boolean;
  created_at: string;
  actor: NotificationActor | null;
}

const notificationSelect = `
  id,
  recipient_id,
  actor_id,
  post_id,
  comment_id,
  conversation_id,
  type,
  is_read,
  created_at,
  actor:profiles!notifications_actor_id_fkey (
    user_id,
    username,
    display_name,
    avatar
  )
`;

export const notificationService = {
  async list(userId: string): Promise<Notification[]> {
    const { data, error } = await supabase
      .from("notifications")
      .select(notificationSelect)
      .eq("recipient_id", userId)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data ?? []) as unknown as Notification[];
  },

  async unreadCount(userId: string): Promise<number> {
    const { count, error } = await supabase
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .eq("recipient_id", userId)
      .eq("is_read", false);

    if (error) throw error;
    return count ?? 0;
  },

  async markAsRead(userId: string, notificationId: string): Promise<void> {
    const { error } = await supabase
      .from("notifications")
      .update({ is_read: true })
      .eq("id", notificationId)
      .eq("recipient_id", userId);

    if (error) throw error;
  },

  async markAllAsRead(userId: string): Promise<void> {
    const { error } = await supabase
      .from("notifications")
      .update({ is_read: true })
      .eq("recipient_id", userId)
      .eq("is_read", false);

    if (error) throw error;
  },

  async markMessageNotificationsRead(userId: string, conversationId: string): Promise<void> {
    const { error } = await supabase
      .from("notifications")
      .update({ is_read: true })
      .eq("recipient_id", userId)
      .eq("conversation_id", conversationId)
      .eq("type", "message")
      .eq("is_read", false);
    if (error) throw error;
  },

  subscribe(userId: string, onChange: () => void) {
    const channel = supabase
      .channel(`notifications:${userId}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "notifications",
          filter: `recipient_id=eq.${userId}`,
        },
        onChange,
      )
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  },
};
