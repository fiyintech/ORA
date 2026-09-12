import { supabase } from "../../lib/supabase";

export interface AuraHistoryItem {
  id: string;
  action: string;
  points: number;
  description: string;
  created_at: string;
}

export interface AuraLeaderboardEntry {
  user_id: string;
  username: string;
  display_name: string;
  avatar: string | null;
  aura_points: number;
  steeze_level: number;
  rank: number;
}

export const auraService = {
  async getCurrentAura() {
    const { data: { session } } = await supabase.auth.getSession();
    const user = session?.user ?? null;
    if (!user) throw new Error("You must be logged in.");

    const { data, error } = await supabase
      .from("profiles")
      .select("aura_points, steeze_level")
      .eq("user_id", user.id)
      .single();

    if (error) throw error;
    return data as { aura_points: number; steeze_level: number };
  },

  async getHistory(limit = 20): Promise<AuraHistoryItem[]> {
    const { data: { session } } = await supabase.auth.getSession();
    const user = session?.user ?? null;
    if (!user) throw new Error("You must be logged in.");

    const { data, error } = await supabase
      .from("aura_history")
      .select("id, action, points, description, created_at")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(limit);

    if (error) throw error;
    return (data ?? []) as AuraHistoryItem[];
  },

  async getLeaderboard(scope = "global", _scopeValue: string | null = null, limit = 10) {
    const { data, error } = await supabase.rpc("get_aura_leaderboard", {
      p_scope: scope,
      p_limit: limit,
      p_offset: 0,
    });

    if (error) throw error;
    return (data ?? []) as AuraLeaderboardEntry[];
  },
};
