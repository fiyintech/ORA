import { supabase } from "../../../lib/supabase";

export interface Profile {
  user_id: string;
  username: string;
  display_name: string;
  email: string;
  bio: string;
  avatar: string | null;
  banner_url: string | null;
  aura_points: number;
  steeze_level: number;
  created_at: string;
  updated_at: string;
  website: string;
  location: string;
}

export interface CreateProfileData {
  username: string;
  display_name: string;
  bio?: string;
  avatar?: string | null;
  banner_url?: string | null;
  website?: string;
  location?: string;
}

export const profileService = {
  /*
   * --------------------------------------------------
   * CURRENT USER PROFILE
   * --------------------------------------------------
   */

  async getCurrentProfile(): Promise<Profile | null> {
    const { data: { session }, error: userError } = await supabase.auth.getSession();
    const user = session?.user ?? null;
    if (userError || !user) return null;

    const {
      data,
      error,
    } = await supabase
      .from("profiles")
      .select("*")
      .eq("user_id", user.id)
      .maybeSingle();

    if (error) {
      throw error;
    }

    return data as Profile | null;
  },

  /*
   * --------------------------------------------------
   * PUBLIC PROFILE BY USERNAME
   * --------------------------------------------------
   */

  async getProfileByUsername(
    username: string,
  ): Promise<Profile | null> {
    const normalized =
      username.trim().toLowerCase();

    if (!normalized) {
      return null;
    }

    const {
      data,
      error,
    } = await supabase
      .from("profiles")
      .select("*")
      .eq("username", normalized)
      .maybeSingle();

    if (error) {
      throw error;
    }

    return data as Profile | null;
  },

  /*
   * --------------------------------------------------
   * USERNAME AVAILABILITY
   * --------------------------------------------------
   */

  async usernameAvailable(
    username: string,
  ): Promise<boolean> {
    const normalized =
      username.trim().toLowerCase();

    if (!normalized) {
      return false;
    }

    const {
      data,
      error,
    } = await supabase
      .from("profiles")
      .select("user_id")
      .eq("username", normalized)
      .maybeSingle();

    if (error) {
      throw error;
    }

    return !data;
  },

  /*
   * --------------------------------------------------
   * CREATE PROFILE
   * --------------------------------------------------
   */

  async createProfile(
    data: CreateProfileData,
  ): Promise<Profile> {
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      throw new Error(
        "You must be logged in to create a profile.",
      );
    }

    const username =
      data.username.trim().toLowerCase();

    const displayName =
      data.display_name.trim();

    if (!username) {
      throw new Error(
        "Username is required.",
      );
    }

    if (!displayName) {
      throw new Error(
        "Display name is required.",
      );
    }

    const available =
      await this.usernameAvailable(
        username,
      );

    if (!available) {
      throw new Error(
        "That username is already taken.",
      );
    }

    const {
      data: profile,
      error,
    } = await supabase
      .from("profiles")
      .insert({
        user_id: user.id,
        username,
        display_name: displayName,
        email: user.email ?? "",
        bio: data.bio?.trim() ?? "",
        avatar: data.avatar ?? null,
        banner_url:
          data.banner_url ?? null,
        website:
          data.website?.trim() ?? "",
        location:
          data.location?.trim() ?? "",
      })
      .select("*")
      .single();

    if (error) {
      if (error.code === "23505") {
        throw new Error(
          "That username or email is already in use.",
        );
      }

      throw error;
    }

    return profile as Profile;
  },

  /*
   * --------------------------------------------------
   * UPDATE PROFILE
   * --------------------------------------------------
   */


  async isFollowing(userId: string): Promise<boolean> {
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError) throw userError;
    if (!user || !userId || user.id === userId) return false;

    const { data, error } = await supabase
      .from("followers")
      .select("id")
      .eq("follower_id", user.id)
      .eq("following_id", userId)
      .maybeSingle();

    if (error) throw error;
    return Boolean(data);
  },

  async toggleFollow(userId: string): Promise<boolean> {
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError) throw userError;
    if (!user) throw new Error("You must be logged in.");
    if (!userId || user.id === userId) {
      throw new Error("You cannot follow yourself.");
    }

    const { data: existing, error: lookupError } = await supabase
      .from("followers")
      .select("id")
      .eq("follower_id", user.id)
      .eq("following_id", userId)
      .maybeSingle();

    if (lookupError) throw lookupError;

    if (existing) {
      const { error } = await supabase
        .from("followers")
        .delete()
        .eq("id", existing.id)
        .eq("follower_id", user.id);
      if (error) throw error;
      return false;
    }

    const { error } = await supabase
      .from("followers")
      .insert({
        follower_id: user.id,
        following_id: userId,
      });

    if (error) {
      if (error.code === "23505") return true;
      throw error;
    }

    return true;
  },

  async getFollowCounts(userId: string): Promise<{ followers: number; following: number }> {
    if (!userId) return { followers: 0, following: 0 };

    const [{ count: followers, error: followersError }, { count: following, error: followingError }] = await Promise.all([
      supabase
        .from("followers")
        .select("id", { count: "exact", head: true })
        .eq("following_id", userId),
      supabase
        .from("followers")
        .select("id", { count: "exact", head: true })
        .eq("follower_id", userId),
    ]);

    if (followersError) throw followersError;
    if (followingError) throw followingError;

    return { followers: followers ?? 0, following: following ?? 0 };
  },

  async uploadProfileImage(kind: "avatar" | "banner", file: File): Promise<Profile> {
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) throw new Error("You must be logged in.");

    const allowed = ["image/jpeg", "image/png", "image/webp", "image/gif"];
    if (!allowed.includes(file.type)) throw new Error("Please choose a JPG, PNG, WebP, or GIF image.");
    if (file.size > 5 * 1024 * 1024) throw new Error("Profile images must be 5 MB or smaller.");

    const ext = (file.name.split(".").pop() || "jpg").toLowerCase().replace(/[^a-z0-9]/g, "") || "jpg";
    const path = `${user.id}/${kind}-${crypto.randomUUID()}.${ext}`;

    const { error: uploadError } = await supabase.storage
      .from("profile-media")
      .upload(path, file, { cacheControl: "3600", upsert: false, contentType: file.type });

    if (uploadError) throw uploadError;

    const { data: publicData } = supabase.storage.from("profile-media").getPublicUrl(path);
    const column = kind === "avatar" ? "avatar" : "banner_url";
    return this.updateProfile({ [column]: publicData.publicUrl });
  },

  async updateProfile(
    updates: Partial<CreateProfileData>,
  ): Promise<Profile> {
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      throw new Error(
        "You must be logged in.",
      );
    }

    const {
      data,
      error,
    } = await supabase
      .from("profiles")
      .update(updates)
      .eq("user_id", user.id)
      .select("*")
      .single();

    if (error) {
      throw error;
    }

    return data as Profile;
  },
};
