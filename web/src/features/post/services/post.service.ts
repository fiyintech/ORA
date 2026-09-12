import { supabase } from "../../../lib/supabase";
import type { FeedPost } from "../types/post";

const MAX_IMAGES = 4;

type Profile = {
  user_id: string;
  username: string;
  display_name: string;
  avatar: string | null;
};

type FeedRow = {
  post_id: string;
  user_id: string | null;
  content: string | null;
  media_urls: string[] | null;
  visibility: string | null;
  likes_count: number | null;
  comments_count: number | null;
  shares_count: number | null;
  created_at: string;
  updated_at: string;
  is_repost: boolean;
  repost_user_id: string | null;
  repost_created_at: string | null;
};

class PostService {
  async getFeed(limit = 20): Promise<FeedPost[]> {
    const {
      data: { session },
      error: userError,
    } = await supabase.auth.getSession();
    const user = session?.user ?? null;

    if (userError) {
      throw userError;
    }

    const { data, error } = await supabase.rpc(
      "get_public_feed",
      {
        feed_limit: limit,
      },
    );

    if (error) {
      throw error;
    }

    const rows = (data ?? []) as FeedRow[];

    if (rows.length === 0) {
      return [];
    }

    /*
     * Resolve profiles for:
     * - original post owners
     * - users who reposted
     */
    const userIds = Array.from(
      new Set(
        rows
          .flatMap((row) => [
            row.user_id,
            row.repost_user_id,
          ])
          .filter(
            (id): id is string =>
              typeof id === "string",
          ),
      ),
    );

    const {
      data: profiles,
      error: profilesError,
    } =
      userIds.length > 0
        ? await supabase
            .from("profiles")
            .select(
              `
                user_id,
                username,
                display_name,
                avatar
              `,
            )
            .in("user_id", userIds)
        : {
            data: [],
            error: null,
          };

    if (profilesError) {
      throw profilesError;
    }

    const profileMap = new Map<
      string,
      Profile
    >();

    for (const profile of profiles ?? []) {
      profileMap.set(
        profile.user_id,
        profile as Profile,
      );
    }

    /*
     * Determine which posts the current user
     * has liked and reposted.
     */
    let likedPostIds = new Set<string>();
    let repostedPostIds = new Set<string>();

    if (user) {
      const postIds = rows.map(
        (row) => row.post_id,
      );

      const [
        {
          data: likes,
          error: likesError,
        },
        {
          data: reposts,
          error: repostsError,
        },
      ] = await Promise.all([
        supabase
          .from("post_likes")
          .select("post_id")
          .eq("user_id", user.id)
          .in("post_id", postIds),

        supabase
          .from("post_reposts")
          .select("post_id")
          .eq("user_id", user.id)
          .in("post_id", postIds),
      ]);

      if (likesError) {
        throw likesError;
      }

      if (repostsError) {
        throw repostsError;
      }

      likedPostIds = new Set(
        (likes ?? []).map(
          (like) => like.post_id,
        ),
      );

      repostedPostIds = new Set(
        (reposts ?? []).map(
          (repost) => repost.post_id,
        ),
      );
    }

    return rows.map(
      (row): FeedPost => ({
        id: row.post_id,
        user_id: row.user_id,
        content: row.content,
        media_urls: row.media_urls,
        visibility: row.visibility,
        likes_count: row.likes_count,
        comments_count:
          row.comments_count,
        shares_count: row.shares_count,
        created_at: row.created_at,
        updated_at: row.updated_at,

        profile: row.user_id
          ? profileMap.get(
              row.user_id,
            ) ?? null
          : null,

        likedByCurrentUser:
          likedPostIds.has(row.post_id),

        isRepost: row.is_repost,

        repostUserId:
          row.repost_user_id,

        repostCreatedAt:
          row.repost_created_at,

        repostProfile:
          row.repost_user_id
            ? profileMap.get(
                row.repost_user_id,
              ) ?? null
            : null,

        repostedByCurrentUser:
          repostedPostIds.has(
            row.post_id,
          ),
      }),
    );
  }

  private validateImages(
    files: File[],
    maxImages = MAX_IMAGES,
  ): void {
    if (files.length > maxImages) {
      throw new Error(
        `You can upload up to ${maxImages} images per post.`,
      );
    }

    for (const file of files) {
      if (!file.type.startsWith("image/")) {
        throw new Error(
          `"${file.name}" is not an image.`,
        );
      }
    }
  }

  private async uploadImages(
    files: File[],
    userId: string,
    maxImages = MAX_IMAGES,
  ): Promise<string[]> {
    this.validateImages(files, maxImages);

    const uploadedUrls: string[] = [];

    for (const file of files) {
      const extension =
        file.name.split(".").pop() ??
        "jpg";

      const path =
        `${userId}/${crypto.randomUUID()}.${extension}`;

      const {
        error: uploadError,
      } = await supabase.storage
        .from("posts")
        .upload(path, file, {
          cacheControl: "3600",
          upsert: false,
        });

      if (uploadError) {
        throw uploadError;
      }

      const {
        data: publicUrlData,
      } = supabase.storage
        .from("posts")
        .getPublicUrl(path);

      uploadedUrls.push(
        publicUrlData.publicUrl,
      );
    }

    return uploadedUrls;
  }

  async createPost(
    content: string,
    files: File[] = [],
  ): Promise<FeedPost> {
    const trimmedContent =
      content.trim();

    if (
      !trimmedContent &&
      files.length === 0
    ) {
      throw new Error(
        "Post cannot be empty.",
      );
    }

    const {
      data: { session },
      error: userError,
    } = await supabase.auth.getSession();
    const user = session?.user ?? null;

    if (userError) {
      throw userError;
    }

    if (!user) {
      throw new Error(
        "You must be logged in to create a post.",
      );
    }

    const { data: premiumRows, error: premiumError } = await supabase
      .from("premium_entitlements")
      .select("expires_at")
      .eq("user_id", user.id)
      .gt("expires_at", new Date().toISOString())
      .order("expires_at", { ascending: false })
      .limit(1);

    if (premiumError) throw premiumError;
    const premiumActive = Boolean(premiumRows?.[0]?.expires_at);
    const maxImages = premiumActive ? 8 : 0;
    const maxContent = premiumActive ? 1000 : 500;
    if (trimmedContent.length > maxContent) {
      throw new Error(`Post cannot exceed ${maxContent} characters${premiumActive ? " on Power Hour" : " on Standard"}.`);
    }
    if (files.length > 0 && !premiumActive) throw new Error("Image posts are a Power Hour feature. Activate Premium to add images to your post.");
    const mediaUrls =
      files.length > 0
        ? await this.uploadImages(
            files,
            user.id,
            maxImages,
          )
        : [];

    const {
      data,
      error,
    } = await supabase
      .from("posts")
      .insert({
        user_id: user.id,
        content:
          trimmedContent || null,
        media_urls:
          mediaUrls.length > 0
            ? mediaUrls
            : null,
        visibility: "public",
        likes_count: 0,
        comments_count: 0,
        shares_count: 0,
      })
      .select(
        `
          id,
          user_id,
          content,
          media_urls,
          visibility,
          likes_count,
          comments_count,
          shares_count,
          created_at,
          updated_at,
          profile:profiles!posts_user_id_fkey(
            user_id,
            username,
            display_name,
            avatar
          )
        `,
      )
      .single();

    if (error) {
      throw error;
    }

    return {
      ...(data as unknown as FeedPost),
      likedByCurrentUser: false,
      isRepost: false,
      repostUserId: null,
      repostCreatedAt: null,
      repostProfile: null,
      repostedByCurrentUser: false,
    };
  }

  async updatePost(
    postId: string,
    content: string,
  ): Promise<FeedPost> {
    const trimmedContent =
      content.trim();

    if (!trimmedContent) {
      throw new Error(
        "Post cannot be empty.",
      );
    }

    const {
      data: { session },
      error: userError,
    } = await supabase.auth.getSession();
    const user = session?.user ?? null;

    if (userError) {
      throw userError;
    }

    if (!user) {
      throw new Error(
        "You must be logged in to edit a post.",
      );
    }

    const {
      data,
      error,
    } = await supabase
      .from("posts")
      .update({
        content: trimmedContent,
        updated_at:
          new Date().toISOString(),
      })
      .eq("id", postId)
      .eq("user_id", user.id)
      .select(
        `
          id,
          user_id,
          content,
          media_urls,
          visibility,
          likes_count,
          comments_count,
          shares_count,
          created_at,
          updated_at,
          profile:profiles!posts_user_id_fkey(
            user_id,
            username,
            display_name,
            avatar
          )
        `,
      )
      .single();

    if (error) {
      throw error;
    }

    return {
      ...(data as unknown as FeedPost),
      likedByCurrentUser: false,
      isRepost: false,
      repostUserId: null,
      repostCreatedAt: null,
      repostProfile: null,
      repostedByCurrentUser: false,
    };
  }

  private async deleteMediaUrls(
    mediaUrls: string[] | null,
  ): Promise<void> {
    if (
      !mediaUrls ||
      mediaUrls.length === 0
    ) {
      return;
    }

    const bucketMarker =
      "/storage/v1/object/public/posts/";

    const paths = mediaUrls
      .map((url) => {
        const index =
          url.indexOf(bucketMarker);

        if (index === -1) {
          return null;
        }

        return decodeURIComponent(
          url.slice(
            index + bucketMarker.length,
          ),
        );
      })
      .filter(
        (path): path is string =>
          typeof path === "string" &&
          path.length > 0,
      );

    if (paths.length === 0) {
      return;
    }

    const { error } =
      await supabase.storage
        .from("posts")
        .remove(paths);

    if (error) {
      console.error(
        "Media cleanup failed:",
        error,
      );
    }
  }

  async deletePost(
    postId: string,
  ): Promise<void> {
    const {
      data: { session },
      error: userError,
    } = await supabase.auth.getSession();
    const user = session?.user ?? null;

    if (userError) {
      throw userError;
    }

    if (!user) {
      throw new Error(
        "You must be logged in to delete a post.",
      );
    }

    /*
     * Only the ORIGINAL POST OWNER can delete
     * the original post.
     */
    const {
      data: post,
      error: fetchError,
    } = await supabase
      .from("posts")
      .select("media_urls")
      .eq("id", postId)
      .eq("user_id", user.id)
      .single();

    if (fetchError) {
      throw fetchError;
    }

    const mediaUrls =
      post?.media_urls ?? null;

    const {
      error: deleteError,
    } = await supabase
      .from("posts")
      .delete()
      .eq("id", postId)
      .eq("user_id", user.id);

    if (deleteError) {
      throw deleteError;
    }

    await this.deleteMediaUrls(
      mediaUrls,
    );
  }

  async toggleLike(
    postId: string,
  ): Promise<boolean> {
    const {
      data,
      error,
    } = await supabase.rpc(
      "toggle_post_like",
      {
        p_post_id: postId,
      },
    );

    if (error) {
      throw error;
    }

    return data as boolean;
  }

  async toggleRepost(
    postId: string,
  ): Promise<boolean> {
    const {
      data,
      error,
    } = await supabase.rpc(
      "toggle_post_repost",
      {
        p_post_id: postId,
      },
    );

    if (error) {
      throw error;
    }

    return data as boolean;
  }

  /*
   * Deletes ONLY the current user's repost.
   *
   * This calls the database RPC:
   *
   *   delete_post_repost
   *
   * It does NOT delete the original post.
   */
  async deletePostRepost(
    postId: string,
  ): Promise<boolean> {
    const {
      data,
      error,
    } = await supabase.rpc(
      "delete_post_repost",
      {
        p_post_id: postId,
      },
    );

    if (error) {
      throw error;
    }

    return data as boolean;
  }

  /*
   * Backwards-compatible alias.
   */
  async deleteRepost(
    postId: string,
  ): Promise<boolean> {
    return this.deletePostRepost(
      postId,
    );
  }
}

export const postService =
  new PostService();
