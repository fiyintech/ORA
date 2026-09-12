import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

async function authenticatedUser(request: Request) {
  const auth = request.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) return null;
  const token = auth.slice("Bearer ".length);
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user;
}

async function removeStorage(paths: string[]) {
  const unique = Array.from(new Set(paths.filter(Boolean)));
  if (!unique.length) return;
  const { error } = await admin.storage.from("chat-media").remove(unique);
  if (error) throw error;
}

async function consumeOne(messageId: string, userId: string, listened = false) {
  const { data: message, error } = await admin
    .from("messages")
    .select("id,conversation_id,sender_id,media_path,media_type,media_viewed_at,media_expires_at")
    .eq("id", messageId)
    .maybeSingle();
  if (error) throw error;
  if (!message) return { cleaned: false, media_path: null };
  if (!message.media_path || !message.media_viewed_at || message.sender_id === userId) {
    return { cleaned: false, media_path: null };
  }

  const { data: membership, error: membershipError } = await admin
    .from("conversation_members")
    .select("user_id")
    .eq("conversation_id", message.conversation_id)
    .eq("user_id", userId)
    .maybeSingle();
  if (membershipError) throw membershipError;
  if (!membership) return { cleaned: false, media_path: null };

  const expiresAt = (message as { media_expires_at?: string | null }).media_expires_at;
  if (!expiresAt || new Date(expiresAt).getTime() > Date.now()) {
    return { cleaned: false, media_path: null };
  }

  await removeStorage([message.media_path]);
  const { error: deleteError } = await admin.from("messages").delete().eq("id", message.id);
  if (deleteError) throw deleteError;
  return { cleaned: true, media_path: message.media_path };
}

async function cleanupExpired() {
  const { data: expired, error } = await admin
    .from("messages")
    .select("id,media_path,media_type")
    .not("media_path", "is", null)
    .lte("media_expires_at", new Date().toISOString())
    .limit(100);
  if (error) throw error;

  const rows = expired ?? [];
  await removeStorage(rows.map((row) => row.media_path).filter((path): path is string => Boolean(path)));

  let cleaned = 0;
  for (const row of rows) {
    const { error: deleteError } = await admin.from("messages").delete().eq("id", row.id);
    if (!deleteError) cleaned += 1;
  }
  return { cleaned };
}

Deno.serve(async (request) => {
  try {
    const body = await request.json().catch(() => ({}));
    const messageId = typeof body?.message_id === "string" ? body.message_id : null;
    const listened = body?.listened === true;

    if (messageId) {
      const user = await authenticatedUser(request);
      if (!user) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: { "Content-Type": "application/json" } });
      const result = await consumeOne(messageId, user.id, listened);
      return new Response(JSON.stringify(result), { headers: { "Content-Type": "application/json" } });
    }

    return new Response(JSON.stringify(await cleanupExpired()), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("chat media cleanup failed", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Cleanup failed" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
