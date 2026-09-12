export interface Post {
  id: string;
  user_id: string | null;
  content: string | null;
  media_urls: string[] | null;
  visibility: string | null;
  likes_count: number | null;
  comments_count: number | null;
  shares_count: number | null;
  created_at: string;
  updated_at: string;
}

export interface FeedPost extends Post {
  profile: {
    user_id: string;
    username: string;
    display_name: string;
    avatar: string | null;
  } | null;

  likedByCurrentUser: boolean;

  /*
   * Repost information.
   *
   * When false, this is the original post.
   * When true, this feed item represents
   * somebody reposting the original post.
   */
  isRepost: boolean;

  /*
   * The user who performed the repost.
   * Null for normal/original posts.
   */
  repostUserId: string | null;

  /*
   * Time the repost was created.
   * Null for normal/original posts.
   */
  repostCreatedAt: string | null;

  /*
   * Profile of the user who reposted.
   * This will be populated by the feed service.
   */
  repostProfile: {
    user_id: string;
    username: string;
    display_name: string;
    avatar: string | null;
  } | null;

  /*
   * Whether the currently logged-in user
   * has reposted the original post.
   */
  repostedByCurrentUser: boolean;
}
