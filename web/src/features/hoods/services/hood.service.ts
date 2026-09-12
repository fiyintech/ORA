import { supabase } from "../../../lib/supabase";

export type Hood = {
  id: string;
  owner_id: string;
  name: string;
  description: string | null;
  category: string | null;
  banner: string | null;
  privacy: "public" | "private" | string;
  created_at: string;
  updated_at: string;
  member_count: number;
  is_joined: boolean;
  join_status: "none" | "pending" | "joined" | "removed";
  member_role: "member" | "moderator" | "owner" | null;
  is_owner: boolean;
  is_admin: boolean;
};

export type HoodMember = {
  hood_id: string;
  user_id: string;
  role: string;
  joined_at: string;
  profile: { username: string; display_name: string; avatar: string | null } | null;
};

export type HoodRejoinRequest = {
  id: string;
  hood_id: string;
  user_id: string;
  status: "pending" | "approved" | "declined";
  created_at: string;
  updated_at: string;
  profile: { username: string; display_name: string; avatar: string | null } | null;
};

export type HoodJoinRequest = {
  id: string;
  hood_id: string;
  user_id: string;
  status: "pending" | "approved" | "declined";
  created_at: string;
  updated_at: string;
  profile: { username: string; display_name: string; avatar: string | null } | null;
};

export type HoodPost = {
  id: string;
  hood_id: string;
  user_id: string;
  text: string;
  media_urls: string[] | null;
  created_at: string;
  profile: {
    username: string;
    display_name: string;
    avatar: string | null;
  } | null;
};

type HoodRow = Omit<Hood, "member_count" | "is_joined" | "join_status" | "member_role" | "is_owner" | "is_admin"> & {
  hood_members?: { count: number }[];
};

class HoodService {
  async getHoods(): Promise<Hood[]> {
    const { data: { session } } = await supabase.auth.getSession();
    const user = session?.user ?? null;

    const { data, error } = await supabase
      .from("hoods")
      .select(`
        id,
        owner_id,
        name,
        description,
        category,
        banner,
        privacy,
        created_at,
        updated_at,
        hood_members(count)
      `)
      .order("created_at", { ascending: false });

    if (error) throw error;

    const membershipRoles = new Map<string, string>();

    if (user) {
      const { data: memberships, error: membershipError } = await supabase
        .from("hood_members")
        .select("hood_id,role")
        .eq("user_id", user.id);

      if (membershipError) throw membershipError;
      for (const membership of memberships ?? []) membershipRoles.set(membership.hood_id, membership.role);
    }

    return ((data ?? []) as HoodRow[]).map((row) => {
      const memberRole = membershipRoles.get(row.id) as Hood["member_role"];
      return {
        ...row,
        member_count: row.hood_members?.[0]?.count ?? 0,
        is_joined: Boolean(memberRole),
        join_status: memberRole ? "joined" : "none",
        member_role: memberRole ?? null,
        is_owner: row.owner_id === user?.id,
        is_admin: row.owner_id === user?.id || memberRole === "moderator",
      };
    });
  }

  async getHood(id: string): Promise<Hood> {
    const { data, error } = await supabase.rpc("get_hood_by_id", { p_hood_id: id });
    if (error) throw error;
    const row = Array.isArray(data) ? data[0] : data;
    if (!row) throw new Error("Hood not found.");
    return {
      ...row,
      member_count: Number(row.member_count ?? 0),
      is_joined: Boolean(row.is_joined),
      join_status: row.join_status as Hood["join_status"],
      member_role: (row.member_role as Hood["member_role"]) ?? null,
      is_owner: Boolean(row.is_owner),
      is_admin: Boolean(row.is_admin),
    };
  }

  async joinHood(hoodId: string): Promise<"joined" | "pending" | "removed"> {
    const { data, error } = await supabase.rpc("request_hood_join", { p_hood_id: hoodId });
    if (error) throw error;
    return data as "joined" | "pending";
  }

  async leaveHood(hoodId: string): Promise<void> {
    const { error } = await supabase.rpc("leave_hood", { p_hood_id: hoodId });
    if (error) throw error;
  }

  async setAdmin(hoodId: string, userId: string, makeAdmin: boolean): Promise<string> {
    const { data, error } = await supabase.rpc("set_hood_admin", {
      p_hood_id: hoodId, p_user_id: userId, p_make_admin: makeAdmin,
    });
    if (error) throw error;
    return data as string;
  }

  async transferOwnership(hoodId: string, userId: string): Promise<void> {
    const { error } = await supabase.rpc("transfer_hood_ownership", {
      p_hood_id: hoodId, p_new_owner_id: userId,
    });
    if (error) throw error;
  }

  async updatePrivacy(hoodId: string, privacy: "public" | "private"): Promise<void> {
    const { error } = await supabase.rpc("update_hood_privacy", {
      p_hood_id: hoodId, p_privacy: privacy,
    });
    if (error) throw error;
  }

  async deleteHood(hoodId: string): Promise<void> {
    const { data, error } = await supabase.rpc("delete_hood", { p_hood_id: hoodId });
    if (error) throw error;
    if (!data) throw new Error("Unable to delete this Hood.");
  }

  async createHood(input: {
    name: string;
    description: string;
    category: string;
    privacy: "public" | "private";
  }): Promise<Hood> {
    const { data: { session } } = await supabase.auth.getSession();
    const user = session?.user ?? null;
    if (!user) throw new Error("You must be signed in to create a Hood.");

    const { data: hood, error } = await supabase
      .from("hoods")
      .insert({ owner_id: user.id, ...input })
      .select()
      .single();

    if (error) throw error;

    // Owner membership is created atomically by the database trigger.
    return this.getHood(hood.id);
  }

  async getHoodPosts(hoodId: string): Promise<HoodPost[]> {
    const { data, error } = await supabase
      .from("hood_posts")
      .select("id, hood_id, user_id, text, media_urls, created_at")
      .eq("hood_id", hoodId)
      .order("created_at", { ascending: false })
      .limit(30);

    if (error) throw error;

    const rows = data ?? [];
    const userIds = Array.from(new Set(rows.map((row) => row.user_id)));
    const { data: profiles, error: profilesError } = userIds.length
      ? await supabase
          .from("profiles")
          .select("user_id, username, display_name, avatar")
          .in("user_id", userIds)
      : { data: [], error: null };

    if (profilesError) throw profilesError;

    const profileMap = new Map(
      (profiles ?? []).map((profile) => [profile.user_id, profile]),
    );

    return rows.map((row) => ({
      ...row,
      profile: profileMap.get(row.user_id) ?? null,
    })) as HoodPost[];
  }

  async getMembers(hoodId: string): Promise<HoodMember[]> {
    const { data, error } = await supabase
      .from("hood_members")
      .select("hood_id,user_id,role,joined_at")
      .eq("hood_id", hoodId)
      .order("joined_at", { ascending: true });
    if (error) throw error;
    const rows = data ?? [];
    const ids = rows.map((row) => row.user_id);
    const { data: profiles, error: profilesError } = ids.length
      ? await supabase.from("profiles").select("user_id,username,display_name,avatar").in("user_id", ids)
      : { data: [], error: null };
    if (profilesError) throw profilesError;
    const map = new Map((profiles ?? []).map((profile) => [profile.user_id, profile]));
    return rows.map((row) => ({ ...row, profile: map.get(row.user_id) ?? null })) as HoodMember[];
  }

  async getPendingRequests(hoodId: string): Promise<HoodJoinRequest[]> {
    const { data, error } = await supabase
      .from("hood_join_requests")
      .select("id,hood_id,user_id,status,created_at,updated_at")
      .eq("hood_id", hoodId)
      .eq("status", "pending")
      .order("created_at", { ascending: true });
    if (error) throw error;
    const rows = data ?? [];
    const ids = rows.map((row) => row.user_id);
    const { data: profiles, error: profilesError } = ids.length
      ? await supabase.from("profiles").select("user_id,username,display_name,avatar").in("user_id", ids)
      : { data: [], error: null };
    if (profilesError) throw profilesError;
    const map = new Map((profiles ?? []).map((profile) => [profile.user_id, profile]));
    return rows.map((row) => ({ ...row, profile: map.get(row.user_id) ?? null })) as HoodJoinRequest[];
  }

  async requestRejoin(hoodId: string): Promise<string> {
    const { data, error } = await supabase.rpc("request_hood_rejoin", { p_hood_id: hoodId });
    if (error) throw error;
    return data as string;
  }

  async getPendingRejoinRequests(hoodId: string): Promise<HoodRejoinRequest[]> {
    const { data, error } = await supabase.from("hood_rejoin_requests").select("id,hood_id,user_id,status,created_at,updated_at").eq("hood_id", hoodId).eq("status", "pending").order("created_at", { ascending: true });
    if (error) throw error;
    const rows = data ?? [];
    const ids = rows.map((row) => row.user_id);
    const { data: profiles, error: profilesError } = ids.length ? await supabase.from("profiles").select("user_id,username,display_name,avatar").in("user_id", ids) : { data: [], error: null };
    if (profilesError) throw profilesError;
    const map = new Map((profiles ?? []).map((profile) => [profile.user_id, profile]));
    return rows.map((row) => ({ ...row, profile: map.get(row.user_id) ?? null })) as HoodRejoinRequest[];
  }

  async reviewRejoinRequest(requestId: string, approve: boolean): Promise<string> {
    const { data, error } = await supabase.rpc("review_hood_rejoin_request", { p_request_id: requestId, p_approve: approve });
    if (error) throw error;
    return data as string;
  }

  async reviewJoinRequest(requestId: string, approve: boolean): Promise<string> {
    const { data, error } = await supabase.rpc("review_hood_join_request", { p_request_id: requestId, p_approve: approve });
    if (error) throw error;
    return data as string;
  }

  async removeMember(hoodId: string, userId: string): Promise<void> {
    const { error } = await supabase.rpc("remove_hood_member", { p_hood_id: hoodId, p_user_id: userId });
    if (error) throw error;
  }

  async createHoodPost(hoodId: string, text: string): Promise<void> {
    const { data: { session } } = await supabase.auth.getSession();
    const user = session?.user ?? null;
    if (!user) throw new Error("You must be signed in to post in a Hood.");

    const trimmed = text.trim();
    if (!trimmed) throw new Error("Write something before posting.");

    const { error } = await supabase
      .from("hood_posts")
      .insert({ hood_id: hoodId, user_id: user.id, text: trimmed, media_urls: [] });

    if (error) throw error;
  }
}

export const hoodService = new HoodService();
