import { supabase } from "../../../lib/supabase";

export interface CommentProfile {
  user_id: string;
  username: string;
  display_name: string;
  avatar: string | null;
}

export interface Comment {
  id: string;
  post_id: string;
  user_id: string;
  parent_id: string | null;
  content: string;
  likes_count: number;
  is_deleted: boolean;
  created_at: string;
  updated_at: string;
  is_edited: boolean;
  profile: CommentProfile | null;
  likedByCurrentUser: boolean;
}

export class CommentService {
  async getComments(postId: string): Promise<Comment[]> {
    const {
      data: {
        user,
      },
    } = await supabase.auth.getUser();

    const { data, error } = await supabase
      .from("comments")
      .select(`
        id,
        post_id,
        user_id,
        parent_id,
        content,
        likes_count,
        is_deleted,
        created_at,
        updated_at,
        is_edited,
        profile:profiles!comments_user_id_fkey(
          user_id,
          username,
          display_name,
          avatar
        )
      `)
      .eq("post_id", postId)
      .eq("is_deleted", false)
      .order("created_at", {
        ascending: true,
      });

    if (error) {
      throw error;
    }

    const comments = (data ?? []) as unknown as Omit<
      Comment,
      "likedByCurrentUser"
    >[];

    if (!user || comments.length === 0) {
      return comments.map((comment) => ({
        ...comment,
        likedByCurrentUser: false,
      }));
    }

    const commentIds = comments.map(
      (comment) => comment.id,
    );

    const {
      data: likes,
      error: likesError,
    } = await supabase
      .from("comment_likes")
      .select("comment_id")
      .eq("user_id", user.id)
      .in("comment_id", commentIds);

    if (likesError) {
      throw likesError;
    }

    const likedCommentIds = new Set(
      (likes ?? []).map(
        (like) => like.comment_id,
      ),
    );

    return comments.map((comment) => ({
      ...comment,
      likedByCurrentUser:
        likedCommentIds.has(comment.id),
    }));
  }

  async createComment(
    postId: string,
    content: string,
    parentId: string | null = null,
  ): Promise<Comment> {
    const cleanContent = content.trim();

    if (!cleanContent) {
      throw new Error(
        "Comment cannot be empty.",
      );
    }

    const { data, error } =
      await supabase.rpc(
        "create_post_comment",
        {
          p_post_id: postId,
          p_content: cleanContent,
          p_parent_id: parentId,
        },
      );

    if (error) {
      throw error;
    }

    const createdComment =
      data as unknown as Comment;

    const {
      data: profile,
      error: profileError,
    } = await supabase
      .from("profiles")
      .select(`
        user_id,
        username,
        display_name,
        avatar
      `)
      .eq(
        "user_id",
        createdComment.user_id,
      )
      .single();

    if (profileError) {
      throw profileError;
    }

    return {
      ...createdComment,
      profile:
        profile as CommentProfile,
      likedByCurrentUser: false,
    };
  }

  async deleteComment(
    commentId: string,
  ) {
    const { data, error } =
      await supabase.rpc(
        "delete_post_comment",
        {
          p_comment_id: commentId,
        },
      );

    if (error) {
      throw error;
    }

    return data as boolean;
  }

  async toggleLike(
    commentId: string,
  ): Promise<boolean> {
    const { data, error } =
      await supabase.rpc(
        "toggle_comment_like",
        {
          p_comment_id: commentId,
        },
      );

    if (error) {
      throw error;
    }

    return data as boolean;
  }
}

export const commentService =
  new CommentService();
