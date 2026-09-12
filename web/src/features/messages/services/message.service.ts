import { supabase } from "../../../lib/supabase";
import { env } from "../../../config/env";

export interface Conversation {
  id: string;
  created_at: string;
  updated_at: string;
}

export interface ConversationMember {
  conversation_id: string;
  user_id: string;
  joined_at: string;
}

export interface Message {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string;
  created_at: string;
  read_at: string | null;
  deleted_at: string | null;
  media_url: string | null;
  media_path: string | null;
  media_type: "image" | "video" | "audio" | null;
  media_duration_ms: number | null;
  media_viewed_at: string | null;
  media_expires_at: string | null;
}

export interface ConversationWithDetails
  extends Conversation {
  members: ConversationMember[];
  lastMessage: Message | null;
  unreadCount: number;
}

class MessageService {
  private mediaMime(file: File, type: "image" | "video" | "audio"): string {
    if (file.type) return file.type.split(";", 1)[0].trim().toLowerCase();
    const extension = file.name.split(".").pop()?.toLowerCase();
    const map: Record<string, string> = {
      jpg: "image/jpeg", jpeg: "image/jpeg", png: "image/png", webp: "image/webp", gif: "image/gif", avif: "image/avif", bmp: "image/bmp",
      mp4: "video/mp4", webm: "video/webm", mov: "video/quicktime", m4v: "video/x-m4v", mpeg: "video/mpeg", mpg: "video/mpeg", ogg: "video/ogg",
      weba: "audio/webm", oga: "audio/ogg", ogg_audio: "audio/ogg", mp3: "audio/mpeg", m4a: "audio/mp4", wav: "audio/wav",
    };
    return map[extension ?? ""] ?? (type === "image" ? "image/jpeg" : type === "audio" ? "audio/webm" : "video/mp4");
  }

  private async uploadChatMedia(path: string, file: File, contentType: string): Promise<void> {
    // Supabase recommends TUS resumable uploads for files above ~6 MB.
    // This avoids restarting a large video/image from byte zero on flaky connections.
    if (file.size <= 6 * 1024 * 1024) {
      const { error } = await supabase.storage.from("chat-media").upload(path, file, { cacheControl: "3600", upsert: false, contentType });
      if (error) throw error;
      return;
    }

    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.access_token) throw new Error("Your session expired. Please sign in again.");
    const projectRef = new URL(env.supabaseUrl).hostname.split(".")[0];
    const endpoint = `https://${projectRef}.storage.supabase.co/storage/v1/upload/resumable`;
    const encode = (value: string) => {
      const bytes = new TextEncoder().encode(value);
      let binary = "";
      for (const byte of bytes) binary += String.fromCharCode(byte);
      return btoa(binary);
    };
    const metadata = [
      `bucketName ${encode("chat-media")}`,
      `objectName ${encode(path)}`,
      `contentType ${encode(contentType)}`,
      `cacheControl ${encode("3600")}`,
    ].join(",");

    let createResponse: Response | null = null;
    for (let attempt = 0; attempt < 3; attempt += 1) {
      createResponse = await fetch(endpoint, {
        method: "POST",
        headers: {
          authorization: `Bearer ${session.access_token}`,
          "tus-resumable": "1.0.0",
          "upload-length": String(file.size),
          "upload-metadata": metadata,
          "x-upsert": "false",
        },
      });
      if (createResponse.ok) break;
      if (attempt === 2) throw new Error((await createResponse.text()) || "Unable to start media upload.");
      await new Promise((resolve) => setTimeout(resolve, 1000 * (attempt + 1)));
    }
    const uploadUrl = createResponse?.headers.get("location");
    if (!uploadUrl) throw new Error("Storage did not return an upload URL.");

    const chunkSize = 6 * 1024 * 1024;
    let offset = Number(createResponse?.headers.get("upload-offset") ?? 0);
    while (offset < file.size) {
      const chunk = file.slice(offset, Math.min(offset + chunkSize, file.size));
      let uploaded = false;
      for (let attempt = 0; attempt < 4 && !uploaded; attempt += 1) {
        const response = await fetch(uploadUrl, {
          method: "PATCH",
          headers: {
            authorization: `Bearer ${session.access_token}`,
            "tus-resumable": "1.0.0",
            "upload-offset": String(offset),
            "content-type": "application/offset+octet-stream",
          },
          body: chunk,
        });
        if (response.ok) {
          offset = Number(response.headers.get("upload-offset") ?? offset + chunk.size);
          uploaded = true;
          break;
        }
        if (response.status === 409) {
          const head = await fetch(uploadUrl, { method: "HEAD", headers: { authorization: `Bearer ${session.access_token}`, "tus-resumable": "1.0.0" } });
          if (head.ok) { offset = Number(head.headers.get("upload-offset") ?? offset); continue; }
        }
        if (attempt === 3) throw new Error((await response.text()) || "Media upload failed.");
        await new Promise((resolve) => setTimeout(resolve, 1000 * (attempt + 1)));
      }
    }
  }

  private withFreshMediaUrl(message: Message): Message {
    if (!message.media_path) return message;
    const { data } = supabase.storage.from("chat-media").getPublicUrl(message.media_path);
    return { ...message, media_url: data.publicUrl };
  }

  /*
   * --------------------------------------------------
   * CURRENT USER
   * --------------------------------------------------
   */

  private async getCurrentUser() {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error) throw error;
    const user = session?.user ?? null;

    if (!user) {
      throw new Error(
        "You must be logged in to use chat.",
      );
    }

    return user;
  }

  /*
   * --------------------------------------------------
   * FIND OR CREATE ONE-TO-ONE CONVERSATION
   * --------------------------------------------------
   *
   * Conversation creation is handled by the
   * create_direct_conversation Supabase RPC.
   *
   * This keeps creation of the conversation and
   * both membership rows atomic and protected from
   * client-side membership manipulation.
   */

  async getOrCreateConversation(
    otherUserId: string,
  ): Promise<Conversation> {
    const user =
      await this.getCurrentUser();

    if (!otherUserId) {
      throw new Error(
        "A user is required to start a conversation.",
      );
    }

    if (user.id === otherUserId) {
      throw new Error(
        "You cannot start a conversation with yourself.",
      );
    }

    const {
      data: conversationId,
      error,
    } = await supabase.rpc(
      "create_direct_conversation",
      {
        other_user_id: otherUserId,
      },
    );

    if (error) {
      throw error;
    }

    if (!conversationId) {
      throw new Error(
        "Unable to create conversation.",
      );
    }

    const {
      data: conversation,
      error: conversationError,
    } = await supabase
      .from("conversations")
      .select(
        "id,created_at,updated_at",
      )
      .eq("id", conversationId)
      .single();

    if (conversationError) {
      throw conversationError;
    }

    return conversation;
  }

  /*
   * --------------------------------------------------
   * GET MY CONVERSATIONS
   * --------------------------------------------------
   */

  async getUnreadCount(): Promise<number> {
    const user = await this.getCurrentUser();
    const { data: memberships, error: membershipError } = await supabase
      .from("conversation_members")
      .select("conversation_id")
      .eq("user_id", user.id);
    if (membershipError) throw membershipError;
    const ids = (memberships ?? []).map((row) => row.conversation_id);
    if (!ids.length) return 0;

    const { count, error } = await supabase
      .from("messages")
      .select("id", { count: "exact", head: true })
      .in("conversation_id", ids)
      .neq("sender_id", user.id)
      .is("read_at", null);
    if (error) throw error;
    return count ?? 0;
  }

  async getConversations(): Promise<
    ConversationWithDetails[]
  > {
    const user =
      await this.getCurrentUser();

    const {
      data: memberships,
      error: membershipError,
    } = await supabase
      .from("conversation_members")
      .select(
        "conversation_id,user_id,joined_at",
      )
      .eq(
        "user_id",
        user.id,
      );

    if (membershipError) {
      throw membershipError;
    }

    if (
      !memberships ||
      memberships.length === 0
    ) {
      return [];
    }

    const conversationIds =
      memberships.map(
        (membership) =>
          membership.conversation_id,
      );

    const {
      data: conversations,
      error: conversationsError,
    } = await supabase
      .from("conversations")
      .select(
        "id,created_at,updated_at",
      )
      .in(
        "id",
        conversationIds,
      )
      .order(
        "updated_at",
        {
          ascending: false,
        },
      );

    if (conversationsError) {
      throw conversationsError;
    }

    const {
      data: allMembers,
      error: allMembersError,
    } = await supabase
      .from("conversation_members")
      .select(
        "conversation_id,user_id,joined_at",
      )
      .in(
        "conversation_id",
        conversationIds,
      );

    if (allMembersError) {
      throw allMembersError;
    }

    /*
     * Get the most recent message for each
     * conversation.
     */
    const {
      data: messages,
      error: messagesError,
    } = await supabase
      .from("messages")
      .select(
        "id,conversation_id,sender_id,content,created_at,read_at,deleted_at,media_url,media_path,media_type,media_duration_ms,media_viewed_at,media_expires_at",
      )
      .in(
        "conversation_id",
        conversationIds,
      )
      .order(
        "created_at",
        {
          ascending: false,
        },
      );

    if (messagesError) {
      throw messagesError;
    }

    const { data: hiddenRows, error: hiddenError } = await supabase
      .from("message_deletions")
      .select("message_id")
      .eq("user_id", user.id);
    if (hiddenError) throw hiddenError;
    const hiddenIds = new Set((hiddenRows ?? []).map((row) => row.message_id));
    const visibleMessages = (messages ?? []).filter((message) => !hiddenIds.has(message.id)).map((message) => this.withFreshMediaUrl(message as Message));

    return (conversations ?? []).map(
      (conversation) => {
        const conversationMembers =
          (allMembers ?? []).filter(
            (member) =>
              member.conversation_id ===
              conversation.id,
          );

        const lastMessage =
          visibleMessages.find(
            (message) =>
              message.conversation_id ===
              conversation.id,
          ) ?? null;

        const unreadCount = visibleMessages.filter(
          (message) =>
            message.conversation_id === conversation.id &&
            message.sender_id !== user.id &&
            message.read_at === null,
        ).length;

        return {
          ...conversation,
          members: conversationMembers,
          lastMessage,
          unreadCount,
        };
      },
    );
  }

  /*
   * --------------------------------------------------
   * GET MESSAGES
   * --------------------------------------------------
   */

  async getMessages(
    conversationId: string,
  ): Promise<Message[]> {
    const user =
      await this.getCurrentUser();

    /*
     * Verify membership before reading.
     */
    const {
      data: membership,
      error: membershipError,
    } = await supabase
      .from("conversation_members")
      .select("conversation_id")
      .eq(
        "conversation_id",
        conversationId,
      )
      .eq(
        "user_id",
        user.id,
      )
      .maybeSingle();

    if (membershipError) {
      throw membershipError;
    }

    if (!membership) {
      throw new Error(
        "You are not a member of this conversation.",
      );
    }

    const {
      data,
      error,
    } = await supabase
      .from("messages")
      .select(
        "id,conversation_id,sender_id,content,created_at,read_at,deleted_at,media_url,media_path,media_type,media_duration_ms,media_viewed_at,media_expires_at",
      )
      .eq(
        "conversation_id",
        conversationId,
      )
      .order(
        "created_at",
        {
          ascending: true,
        },
      );

    if (error) {
      throw error;
    }

    const { data: hiddenRows, error: hiddenError } = await supabase
      .from("message_deletions")
      .select("message_id")
      .eq("user_id", user.id);
    if (hiddenError) throw hiddenError;
    const hiddenIds = new Set((hiddenRows ?? []).map((row) => row.message_id));
    return (data ?? []).filter((message) => !hiddenIds.has(message.id)).map((message) => this.withFreshMediaUrl(message as Message));
  }

  /*
   * --------------------------------------------------
   * SEND MESSAGE
   * --------------------------------------------------
   */

  async sendMessage(
    conversationId: string,
    content: string,
    media?: { file: File; type: "image" | "video" | "audio"; durationMs?: number },
    options?: { maxBytes?: number },
  ): Promise<Message> {
    const user = await this.getCurrentUser();
    const trimmed = content.trim();
    if (!trimmed && !media) throw new Error("Message cannot be empty.");

    const { data: premiumRows, error: premiumError } = await supabase
      .from("premium_entitlements")
      .select("expires_at")
      .eq("user_id", user.id)
      .gt("expires_at", new Date().toISOString())
      .order("expires_at", { ascending: false })
      .limit(1);
    if (premiumError) throw premiumError;
    const premiumActive = Boolean(premiumRows?.[0]?.expires_at);
    const maxContent = premiumActive ? 1000 : 500;
    if (trimmed.length > maxContent) throw new Error(`Message cannot exceed ${maxContent} characters${premiumActive ? " on Power Hour" : " on Standard"}.`);
    if (media?.type === "video" && !premiumActive) throw new Error("Video messages are a Power Hour feature. Activate Premium to send videos.");
    if (media?.type === "audio" && !premiumActive && (media.durationMs ?? 0) > 60_000) throw new Error("Standard voice notes are limited to 60 seconds. Activate Power Hour for longer voice notes.");

    let uploadedPath: string | null = null;
    try {
      if (media) {
        const contentType = this.mediaMime(media.file, media.type);
        const allowed = media.type === "image"
          ? ["image/jpeg", "image/png", "image/webp", "image/gif", "image/avif", "image/bmp"]
          : media.type === "video"
            ? ["video/mp4", "video/webm", "video/quicktime", "video/ogg", "video/mpeg", "video/x-m4v"]
            : ["audio/webm", "audio/ogg", "audio/mpeg", "audio/mp4", "audio/wav"];
        if (!allowed.includes(contentType)) throw new Error(`Unsupported ${media.type} format. Use a common JPG/PNG/WebP/AVIF image, MP4/WebM/MOV video, or WebM/MP4/OGG audio.`);

        const standardMaxBytes = 6 * 1024 * 1024;
        const premiumMaxBytes = 50 * 1024 * 1024;
        const maxBytes = Math.min(
          options?.maxBytes ?? (media.type === "image" ? standardMaxBytes : premiumMaxBytes),
          media.type === "audio" ? (premiumActive ? premiumMaxBytes : standardMaxBytes) :
            media.type === "video" ? (premiumActive ? premiumMaxBytes : standardMaxBytes) :
              premiumMaxBytes,
        );
        if (media.file.size > maxBytes) {
          const maxMb = Math.floor(maxBytes / (1024 * 1024));
          const label = media.type === "image" ? "Images" : media.type === "video" ? "Videos" : "Voice notes";
          throw new Error(`${label} must be ${maxMb} MB or smaller.`);
        }
        const ext = (media.file.name.split(".").pop() || (media.type === "image" ? "jpg" : "mp4")).toLowerCase().replace(/[^a-z0-9]/g, "") || (media.type === "image" ? "jpg" : "mp4");
        uploadedPath = `${user.id}/${crypto.randomUUID()}.${ext}`;
        await this.uploadChatMedia(uploadedPath, media.file, contentType);
      }

      const { data: message, error } = await supabase.rpc("send_message", {
        p_conversation_id: conversationId,
        p_content: trimmed,
        p_media_path: uploadedPath,
        p_media_type: media?.type ?? null,
        p_media_duration_ms: media?.durationMs ?? null,
      });
      if (error) throw error;
      if (!message) throw new Error("Unable to send message.");

      let result = message as Message;
      if (uploadedPath) {
        const { data: publicData } = supabase.storage.from("chat-media").getPublicUrl(uploadedPath);
        const { data: attached, error: attachError } = await supabase.rpc("attach_message_media", { p_message_id: result.id, p_media_url: publicData.publicUrl });
        if (attachError) throw attachError;
        result = this.withFreshMediaUrl(attached as Message);
      }
      return result;
    } catch (error) {
      if (uploadedPath) void supabase.storage.from("chat-media").remove([uploadedPath]);
      throw error;
    }
  }

  async forwardMessage(message: Message, targetConversationId: string): Promise<Message> {
    const user = await this.getCurrentUser();
    const { data: premiumRows, error: premiumError } = await supabase.from("premium_entitlements").select("expires_at").eq("user_id", user.id).gt("expires_at", new Date().toISOString()).limit(1);
    if (premiumError) throw premiumError;
    if (!premiumRows?.length) throw new Error("Forwarding messages is a Power Hour feature. Activate Premium to use it.");
    if (message.media_url) {
      const response = await fetch(message.media_url, { mode: "cors", credentials: "omit" });
      if (!response.ok) throw new Error("This media is no longer available to forward.");
      const blob = await response.blob();
      if (message.media_type === "audio") throw new Error("Voice note forwarding is not available.");
      const type = message.media_type === "video" ? "video" : "image";
      const extension = type === "video" ? "mp4" : (blob.type.split("/")[1] || "jpg");
      const file = new File([blob], `forwarded.${extension}`, { type: blob.type || (type === "video" ? "video/mp4" : "image/jpeg") });
      return this.sendMessage(targetConversationId, message.content || "", { file, type });
    }
    if (!message.content) throw new Error("There is nothing to forward in this message.");
    return this.sendMessage(targetConversationId, message.content);
  }

  async markMediaViewed(messageId: string): Promise<Message> {
    const { data, error } = await supabase.rpc("mark_message_media_viewed", { p_message_id: messageId });
    if (error) throw error;
    return data as Message;
  }

  async consumeViewedMedia(messageId: string, listened = false): Promise<string | null> {
    const { data, error } = await supabase.functions.invoke("cleanup-chat-media", {
      body: { message_id: messageId, listened },
    });
    if (error) throw error;
    return typeof data?.media_path === "string" ? data.media_path : null;
  }

  /*
   * --------------------------------------------------
   * MARK CONVERSATION AS READ
   * --------------------------------------------------
   */

  async markConversationAsRead(
    conversationId: string,
  ): Promise<void> {
    const { error } = await supabase.rpc(
      "mark_conversation_messages_read",
      { p_conversation_id: conversationId },
    );
    if (error) throw error;
  }

  /*
   * --------------------------------------------------
   * DELETE MESSAGE
   * --------------------------------------------------
   */

  async deleteMessage(
    messageId: string,
  ): Promise<void> {
    const user = await this.getCurrentUser();

    const { data: message, error: lookupError } = await supabase
      .from("messages")
      .select("id,media_path")
      .eq("id", messageId)
      .eq("sender_id", user.id)
      .maybeSingle();
    if (lookupError) throw lookupError;
    if (!message) throw new Error("You can only delete your own messages.");

    const { data, error } = await supabase.rpc("delete_own_message", {
      p_message_id: messageId,
    });
    if (error) throw error;
    if (!data) throw new Error("You can only delete your own messages.");

    if (message.media_path) {
      let storageError: unknown = null;
      for (let attempt = 0; attempt < 3; attempt += 1) {
        const { error: removeError } = await supabase.storage
          .from("chat-media")
          .remove([message.media_path]);
        if (!removeError) {
          storageError = null;
          break;
        }
        storageError = removeError;
        await new Promise((resolve) => window.setTimeout(resolve, 300 * (attempt + 1)));
      }
      if (storageError) throw storageError;
    }
  }

  async deleteForMe(messageId: string): Promise<void> {
    const { error } = await supabase.rpc("delete_message_for_me", { p_message_id: messageId });
    if (error) throw error;
  }

  async deleteForEveryone(messageId: string, mediaPath?: string | null): Promise<void> {
    const { data, error } = await supabase.rpc("delete_message_for_everyone", { p_message_id: messageId });
    if (error) throw error;
    if (!data) throw new Error("You can only delete your own message for everyone.");
    if (mediaPath) {
      const { error: removeError } = await supabase.storage.from("chat-media").remove([mediaPath]);
      if (removeError) throw removeError;
    }
  }

  async setConversationPresence(conversationId: string): Promise<void> {
    const { error } = await supabase.rpc("set_conversation_presence", { p_conversation_id: conversationId });
    if (error) throw error;
  }

  async clearConversationPresence(): Promise<void> {
    const { error } = await supabase.rpc("clear_conversation_presence");
    if (error) throw error;
  }

  /*
   * --------------------------------------------------
   * REALTIME MESSAGE SUBSCRIPTION
   * --------------------------------------------------
   */

  subscribeToMessages(
    conversationId: string,
    onMessage: (
      message: Message,
    ) => void,
  ) {
    const channel =
      supabase
        .channel(
          `conversation:${conversationId}`,
        )
        .on(
          "postgres_changes",
          {
            event: "INSERT",
            schema: "public",
            table: "messages",
            filter: `conversation_id=eq.${conversationId}`,
          },
          (payload) => {
            onMessage(this.withFreshMediaUrl(payload.new as Message));
          },
        )
        .subscribe();

    return () => {
      void supabase.removeChannel(
        channel,
      );
    };
  }

  /*
   * --------------------------------------------------
   * REALTIME MESSAGE UPDATE SUBSCRIPTION
   * --------------------------------------------------
   */

  subscribeToMessageUpdates(
    conversationId: string,
    onMessage: (message: Message, event?: "UPDATE" | "DELETE") => void,
  ) {
    const channel =
      supabase
        .channel(
          `conversation-updates:${conversationId}`,
        )
        .on(
          "postgres_changes",
          {
            event: "UPDATE",
            schema: "public",
            table: "messages",
            filter: `conversation_id=eq.${conversationId}`,
          },
          (payload) => {
            onMessage(payload.new as Message, "UPDATE");
          },
        )
        .on(
          "postgres_changes",
          {
            event: "DELETE",
            schema: "public",
            table: "messages",
            filter: `conversation_id=eq.${conversationId}`,
          },
          (payload) => {
            onMessage(payload.old as Message, "DELETE");
          },
        )
        .subscribe();

    return () => {
      void supabase.removeChannel(
        channel,
      );
    };
  }
  subscribeToAllMessages(
    onMessage: (message: Message) => void,
  ) {
    const channel = supabase
      .channel("ora-messages-inbox")
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "messages",
        },
        (payload) => {
          onMessage(payload.new as Message);
        },
      )
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  }

}

export const messageService =
  new MessageService();
