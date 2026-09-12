import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const BUCKETS = ["profile-media", "posts", "chat-media"] as const;

async function authenticatedUser(request: Request) {
  const auth = request.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) return null;
  const token = auth.slice("Bearer ".length);
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user;
}

async function collectPaths(bucket: string, prefix: string): Promise<string[]> {
  const { data, error } = await admin.storage.from(bucket).list(prefix, { limit: 1000, offset: 0 });
  if (error) throw error;

  const paths: string[] = [];
  for (const item of data ?? []) {
    const path = prefix ? `${prefix}/${item.name}` : item.name;
    if (item.id) paths.push(path);
    else paths.push(...await collectPaths(bucket, path));
  }
  return paths;
}

async function removeUserStorage(userId: string) {
  for (const bucket of BUCKETS) {
    const paths = await collectPaths(bucket, userId);
    if (!paths.length) continue;
    const { error } = await admin.storage.from(bucket).remove(paths);
    if (error) throw error;
  }
}

Deno.serve(async (request) => {
  try {
    if (request.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { "Content-Type": "application/json" } });
    }

    const user = await authenticatedUser(request);
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const body = await request.json().catch(() => ({}));
    if (body?.confirmation !== "DELETE") {
      return new Response(JSON.stringify({ error: "Account deletion requires confirmation." }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    await removeUserStorage(user.id);
    const { error } = await admin.auth.admin.deleteUser(user.id);
    if (error) throw error;

    return new Response(JSON.stringify({ success: true }), { headers: { "Content-Type": "application/json" } });
  } catch (error) {
    console.error("account deletion failed", error);
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Unable to delete account." }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
