import {
  Check,
  Ellipsis,
  Heart,
  Loader2,
  MessageCircle,
  Repeat2,
  Share,
  Trash2,
  X,
} from "lucide-react";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { usePremium } from "../../premium/PremiumContext";
import type { FeedPost } from "../../post/types/post";
import { postService } from "../../post/services/post.service";
import CommentSection from "../../comments/components/CommentSection";
import { supabase } from "../../../lib/supabase";
import MediaLightbox from "../../../components/ui/MediaLightbox";

interface Props {
  post: FeedPost;
  onPostUpdated?: (updatedPost: FeedPost) => void;
  onPostDeleted?: (deletedPost: FeedPost) => void;
}

function formatTime(createdAt: string): string {
  const created = new Date(createdAt).getTime();
  const now = Date.now();

  const seconds = Math.max(
    0,
    Math.floor((now - created) / 1000),
  );

  if (seconds < 60) {
    return `${seconds}s`;
  }

  const minutes = Math.floor(seconds / 60);

  if (minutes < 60) {
    return `${minutes}m`;
  }

  const hours = Math.floor(minutes / 60);

  if (hours < 24) {
    return `${hours}h`;
  }

  const days = Math.floor(hours / 24);

  if (days < 7) {
    return `${days}d`;
  }

  return new Date(createdAt).toLocaleDateString();
}

function getInitial(
  displayName?: string | null,
  username?: string | null,
): string {
  return (
    displayName ||
    username ||
    "O"
  )
    .charAt(0)
    .toUpperCase();
}

export default function PostCard({
  post,
  onPostUpdated,
  onPostDeleted,
}: Props) {
  const navigate = useNavigate();
  const { active: premiumActive } = usePremium();

  const [showComments, setShowComments] =
    useState(false);

  const [liking, setLiking] =
    useState(false);

  const [reposting, setReposting] =
    useState(false);

  const [localPost, setLocalPost] =
    useState(post);

  const [currentUserId, setCurrentUserId] =
    useState<string | null>(null);

  const [menuOpen, setMenuOpen] =
    useState(false);

  const [editing, setEditing] =
    useState(false);

  const [editContent, setEditContent] =
    useState(post.content ?? "");

  const [savingEdit, setSavingEdit] =
    useState(false);

  const [deleting, setDeleting] =
    useState(false);

  const [error, setError] =
    useState("");

  const [shareStatus, setShareStatus] =
    useState<"idle" | "copied">("idle");

  const [viewerMedia, setViewerMedia] =
    useState<string | null>(null);

  useEffect(() => {
    let mounted = true;

    async function loadCurrentUser() {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      const user = session?.user ?? null;

      if (mounted) {
        setCurrentUserId(
          user?.id ?? null,
        );
      }
    }

    void loadCurrentUser();

    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    setLocalPost(post);

    if (!editing) {
      setEditContent(
        post.content ?? "",
      );
    }
  }, [post, editing]);

  /*
   * --------------------------------------------------
   * POST / REPOST DATA
   * --------------------------------------------------
   */

  const isRepost =
    localPost.isRepost === true;

  const profile =
    localPost.profile;

  const repostProfile =
    localPost.repostProfile;

  const media =
    localPost.media_urls ?? [];

  const likes =
    localPost.likes_count ?? 0;

  const comments =
    localPost.comments_count ?? 0;

  const shares =
    localPost.shares_count ?? 0;

  /*
   * A normal post is owned by post.user_id.
   *
   * A repost is owned by repostUserId.
   */
  const isOriginalOwner =
    currentUserId !== null &&
    currentUserId ===
      localPost.user_id;

  const isRepostOwner =
    isRepost &&
    currentUserId !== null &&
    currentUserId ===
      localPost.repostUserId;

  const canEdit =
    !isRepost &&
    isOriginalOwner;

  const canDelete =
    (!isRepost &&
      isOriginalOwner) ||
    isRepostOwner;

  const repostDisplayName =
    repostProfile?.display_name ??
    repostProfile?.username ??
    "ORA User";

  /*
   * --------------------------------------------------
   * PROFILE NAVIGATION
   * --------------------------------------------------
   */

  function openProfile() {
    const username =
      profile?.username;

    if (!username) {
      return;
    }

    navigate(
      `/profile/${encodeURIComponent(username)}`,
    );
  }

  /*
   * --------------------------------------------------
   * LIKE
   * --------------------------------------------------
   */

  async function handleLike() {
    if (liking) {
      return;
    }

    const previousLiked =
      localPost.likedByCurrentUser;

    const previousCount =
      localPost.likes_count ?? 0;

    const nextLiked =
      !previousLiked;

    const nextCount =
      Math.max(
        0,
        previousCount +
          (nextLiked ? 1 : -1),
      );

    const optimisticPost: FeedPost = {
      ...localPost,
      likedByCurrentUser:
        nextLiked,
      likes_count:
        nextCount,
    };

    setLocalPost(
      optimisticPost,
    );

    onPostUpdated?.(
      optimisticPost,
    );

    try {
      setLiking(true);

      const databaseLiked =
        await postService.toggleLike(
          localPost.id,
        );

      const synchronizedPost:
        FeedPost = {
          ...optimisticPost,
          likedByCurrentUser:
            databaseLiked,
        };

      setLocalPost(
        synchronizedPost,
      );

      onPostUpdated?.(
        synchronizedPost,
      );
    } catch (err) {
      console.error(
        "Post like failed:",
        err,
      );

      const rolledBackPost:
        FeedPost = {
          ...localPost,
          likedByCurrentUser:
            previousLiked,
          likes_count:
            previousCount,
        };

      setLocalPost(
        rolledBackPost,
      );

      onPostUpdated?.(
        rolledBackPost,
      );
    } finally {
      setLiking(false);
    }
  }

  /*
   * --------------------------------------------------
   * REPOST
   * --------------------------------------------------
   */

  async function handleRepost() {
    if (!premiumActive) {
      navigate("/premium");
      return;
    }
    if (
      reposting ||
      editing ||
      deleting
    ) {
      return;
    }

    const previousReposted =
      localPost.repostedByCurrentUser;

    const previousShares =
      localPost.shares_count ?? 0;

    const nextReposted =
      !previousReposted;

    const nextShares =
      Math.max(
        0,
        previousShares +
          (nextReposted ? 1 : -1),
      );

    const optimisticPost:
      FeedPost = {
        ...localPost,
        repostedByCurrentUser:
          nextReposted,
        shares_count:
          nextShares,
      };

    setLocalPost(
      optimisticPost,
    );

    onPostUpdated?.(
      optimisticPost,
    );

    try {
      setReposting(true);
      setError("");

      const databaseReposted =
        await postService.toggleRepost(
          localPost.id,
        );

      const synchronizedPost:
        FeedPost = {
          ...optimisticPost,
          repostedByCurrentUser:
            databaseReposted,
        };

      setLocalPost(
        synchronizedPost,
      );

      onPostUpdated?.(
        synchronizedPost,
      );
    } catch (err) {
      console.error(
        "Post repost failed:",
        err,
      );

      const rolledBackPost:
        FeedPost = {
          ...localPost,
          repostedByCurrentUser:
            previousReposted,
          shares_count:
            previousShares,
        };

      setLocalPost(
        rolledBackPost,
      );

      onPostUpdated?.(
        rolledBackPost,
      );

      setError(
        err instanceof Error
          ? err.message
          : "Unable to repost this post.",
      );
    } finally {
      setReposting(false);
    }
  }

  /*
   * --------------------------------------------------
   * EDIT
   * --------------------------------------------------
   */

  function startEditing() {
    if (!canEdit) {
      return;
    }

    setError("");

    setEditContent(
      localPost.content ?? "",
    );

    setEditing(true);
    setMenuOpen(false);
  }

  function cancelEditing() {
    if (savingEdit) {
      return;
    }

    setEditContent(
      localPost.content ?? "",
    );

    setEditing(false);
    setError("");
  }

  async function saveEdit() {
    if (!canEdit) {
      return;
    }

    const trimmed =
      editContent.trim();

    if (!trimmed) {
      setError(
        "Post cannot be empty.",
      );
      return;
    }

    if (savingEdit) {
      return;
    }

    try {
      setSavingEdit(true);
      setError("");

      const updatedPost =
        await postService.updatePost(
          localPost.id,
          trimmed,
        );

      const synchronizedPost:
        FeedPost = {
          ...updatedPost,
          likedByCurrentUser:
            localPost.likedByCurrentUser,
          likes_count:
            localPost.likes_count,
          isRepost:
            localPost.isRepost,
          repostUserId:
            localPost.repostUserId,
          repostCreatedAt:
            localPost.repostCreatedAt,
          repostProfile:
            localPost.repostProfile,
          repostedByCurrentUser:
            localPost.repostedByCurrentUser,
        };

      setLocalPost(
        synchronizedPost,
      );

      setEditContent(
        synchronizedPost.content ?? "",
      );

      setEditing(false);

      onPostUpdated?.(
        synchronizedPost,
      );
    } catch (err) {
      console.error(
        "Post update failed:",
        err,
      );

      setError(
        err instanceof Error
          ? err.message
          : "Unable to update post.",
      );
    } finally {
      setSavingEdit(false);
    }
  }

  /*
   * --------------------------------------------------
   * DELETE
   * --------------------------------------------------
   */

  async function handleShare() {
    const url = `${window.location.origin}${window.location.pathname}#post-${localPost.id}`;
    try {
      if (navigator.share) {
        await navigator.share({
          title: `${profile?.display_name || "ORA user"} on ORA`,
          text: localPost.content || "Check out this post on ORA.",
          url,
        });
        return;
      }

      await navigator.clipboard.writeText(url);
      setShareStatus("copied");
      window.setTimeout(() => setShareStatus("idle"), 1800);
    } catch (err) {
      if (err instanceof DOMException && err.name === "AbortError") return;
      setError(err instanceof Error ? err.message : "Unable to share this post.");
    }
  }

  async function handleDelete() {
    if (
      deleting ||
      !canDelete
    ) {
      return;
    }

    const confirmed =
      window.confirm(
        isRepost
          ? "Remove your repost? The original post will remain."
          : "Delete this post? This will also remove all reposts of it.",
      );

    if (!confirmed) {
      return;
    }

    try {
      setDeleting(true);
      setError("");
      setMenuOpen(false);

      if (isRepost) {
        await postService.deletePostRepost(
          localPost.id,
        );
      } else {
        await postService.deletePost(
          localPost.id,
        );
      }

      onPostDeleted?.(
        localPost,
      );
    } catch (err) {
      console.error(
        "Post deletion failed:",
        err,
      );

      setError(
        err instanceof Error
          ? err.message
          : "Unable to delete post.",
      );
    } finally {
      setDeleting(false);
    }
  }

  return (
    <article id={`post-${localPost.id}`} className="ora-feed-post scroll-mt-20 border-b border-zinc-900 px-4 py-4 sm:px-5">
      <div className="flex gap-3">

        {/* AVATAR */}

        <button
          type="button"
          onClick={openProfile}
          disabled={!profile?.username}
          className="shrink-0 rounded-full disabled:cursor-default"
          aria-label={`Open @${profile?.username ?? "user"} profile`}
        >
          {profile?.avatar ? (
            <img
              src={profile.avatar}
              alt={
                profile.display_name ??
                "ORA User"
              }
              className="h-12 w-12 rounded-full object-cover transition hover:opacity-80"
            />
          ) : (
            <div className="flex h-12 w-12 items-center justify-center rounded-full bg-zinc-900 text-sm font-semibold text-zinc-300 transition hover:bg-zinc-800">
              {getInitial(
                profile?.display_name,
                profile?.username,
              )}
            </div>
          )}
        </button>

        <div className="min-w-0 flex-1">

          {/* REPOST HEADER */}

          {isRepost && (
            <div className="mb-2 flex items-center gap-2 text-xs text-zinc-500">
              <Repeat2
                size={14}
                className="text-green-500"
              />

              <span>
                {currentUserId !== null &&
                localPost.repostUserId ===
                  currentUserId
                  ? "You reposted"
                  : `${repostDisplayName} reposted`}
              </span>

              {localPost.repostCreatedAt && (
                <>
                  <span className="text-zinc-700">
                    •
                  </span>

                  <span>
                    {formatTime(
                      localPost.repostCreatedAt,
                    )}
                  </span>
                </>
              )}
            </div>
          )}

          {/* HEADER */}

          <div className="flex items-start justify-between gap-3">
            <div className="flex min-w-0 flex-wrap items-center gap-2">

              <button
                type="button"
                onClick={openProfile}
                disabled={!profile?.username}
                className="font-semibold text-white transition hover:underline disabled:cursor-default"
              >
                {profile?.display_name ??
                  "ORA User"}
              </button>

              <button
                type="button"
                onClick={openProfile}
                disabled={!profile?.username}
                className="text-zinc-500 transition hover:text-zinc-300 hover:underline disabled:cursor-default"
              >
                @{profile?.username ??
                  "user"}
              </button>

              <span className="text-zinc-600">
                •
              </span>

              <span className="text-zinc-500">
                {formatTime(
                  localPost.created_at,
                )}
              </span>

              {localPost.updated_at !==
                localPost.created_at && (
                <span className="text-xs text-zinc-700">
                  edited
                </span>
              )}
            </div>

            {/* OWNER / REPOSTER OPTIONS */}

            {canDelete && (
              <div className="relative shrink-0">
                <button
                  type="button"
                  onClick={() =>
                    setMenuOpen(
                      (current) =>
                        !current,
                    )
                  }
                  disabled={
                    deleting ||
                    savingEdit ||
                    reposting
                  }
                  className="rounded-lg p-1.5 text-zinc-600 transition hover:bg-zinc-900 hover:text-white disabled:opacity-50"
                  aria-label="Post options"
                  aria-expanded={
                    menuOpen
                  }
                >
                  <Ellipsis
                    size={19}
                  />
                </button>

                {menuOpen && (
                  <div className="absolute right-0 top-9 z-20 w-40 overflow-hidden rounded-xl border border-zinc-800 bg-zinc-950 py-1 shadow-2xl">

                    {canEdit && (
                      <button
                        type="button"
                        onClick={
                          startEditing
                        }
                        className="flex w-full items-center gap-2 px-3 py-2.5 text-left text-sm text-zinc-300 transition hover:bg-zinc-900 hover:text-white"
                      >
                        <Check
                          size={15}
                        />
                        Edit
                      </button>
                    )}

                    <button
                      type="button"
                      onClick={() =>
                        void handleDelete()
                      }
                      className="flex w-full items-center gap-2 px-3 py-2.5 text-left text-sm text-red-400 transition hover:bg-red-950/30"
                    >
                      <Trash2
                        size={15}
                      />

                      {isRepost
                        ? "Remove repost"
                        : "Delete"}
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* ERROR */}

          {error && (
            <div className="mt-3 rounded-xl border border-red-900/50 bg-red-950/30 px-3 py-2 text-sm text-red-400">
              {error}
            </div>
          )}

          {/* EDITOR */}

          {editing ? (
            <div className="mt-4">
              <textarea
                value={editContent}
                onChange={(
                  event,
                ) =>
                  setEditContent(
                    event.target.value,
                  )
                }
                maxLength={premiumActive ? 1000 : 500}
                autoFocus
                disabled={
                  savingEdit
                }
                className="min-h-28 w-full resize-none rounded-xl border border-zinc-800 bg-zinc-900 px-4 py-3 text-sm leading-6 text-white outline-none placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
              />

              <div className="mt-2 flex items-center justify-between">
                <span className="text-xs text-zinc-600">
                  {editContent.length}/500
                </span>

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={
                      cancelEditing
                    }
                    disabled={
                      savingEdit
                    }
                    className="flex items-center gap-2 rounded-xl border border-zinc-800 px-3 py-2 text-sm text-zinc-400 transition hover:bg-zinc-900 hover:text-white disabled:opacity-50"
                  >
                    <X size={15} />
                    Cancel
                  </button>

                  <button
                    type="button"
                    onClick={() =>
                      void saveEdit()
                    }
                    disabled={
                      savingEdit ||
                      !editContent.trim()
                    }
                    className="flex items-center gap-2 rounded-xl bg-violet-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    {savingEdit ? (
                      <Loader2
                        size={15}
                        className="animate-spin"
                      />
                    ) : (
                      <Check
                        size={15}
                      />
                    )}

                    Save
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <>
              {/* CONTENT */}

              {localPost.content && (
                <p className="mt-3 whitespace-pre-wrap leading-7 text-zinc-200">
                  {localPost.content}
                </p>
              )}

              {/* MEDIA */}

              {media.length > 0 && (
                <div
                  className={`ora-post-media ${media.length === 1 ? "single" : "multi"} mt-3 grid gap-1.5 ${
                    media.length === 1
                      ? "grid-cols-1"
                      : "grid-cols-2"
                  }`}
                >
                  {media.map(
                    (
                      url,
                      index,
                    ) => (
                      <button
                        key={`${url}-${index}`}
                        type="button"
                        onClick={() => setViewerMedia(url)}
                        className="group block w-full overflow-hidden bg-zinc-900 text-left"
                        aria-label={`Open post image ${index + 1} full screen`}
                      >
                        <img
                          src={url}
                          alt={`Post image ${index + 1}`}
                          loading="lazy"
                          className={`w-full transition duration-300 group-hover:scale-[1.02] group-hover:brightness-90 ${
                            media.length === 1
                              ? "max-h-[500px] object-contain bg-zinc-950"
                              : "aspect-[4/3] object-cover"
                          }`}
                          onError={(event) => {
                            event.currentTarget.style.display = "none";
                            const fallback = event.currentTarget.parentElement?.querySelector<HTMLElement>("[data-media-fallback]");
                            if (fallback) fallback.hidden = false;
                          }}
                        />
                        <span data-media-fallback hidden className="ora-media-fallback text-xs">Media unavailable</span>
                      </button>
                    ),
                  )}
                </div>
              )}
            </>
          )}

          {/* ACTIONS */}

          <div className="mt-4 flex items-center justify-between text-zinc-500">

            {/* COMMENTS */}

            <button
              type="button"
              onClick={() =>
                setShowComments(
                  (current) =>
                    !current,
                )
              }
              className={`ora-social-action flex items-center gap-2 transition ${
                showComments
                  ? "text-violet-400"
                  : "hover:text-violet-400"
              }`}
              aria-label={
                showComments
                  ? "Hide comments"
                  : "Show comments"
              }
            >
              <MessageCircle
                size={18}
              />

              {comments > 0 ? <span className="tabular-nums">{comments}</span> : null}
            </button>

            {/* REPOST */}

            <button
              type="button"
              onClick={() =>
                void handleRepost()
              }
              disabled={
                reposting ||
                editing ||
                deleting
              }
              title={premiumActive ? (localPost.repostedByCurrentUser ? "Undo repost" : "Repost") : "Repost · Power Hour required"}
              className={`ora-social-action flex items-center gap-2 transition ${
                localPost.repostedByCurrentUser
                  ? "text-green-500"
                  : "text-zinc-500 hover:text-green-500"
              } ${
                reposting
                  ? "cursor-wait opacity-70"
                  : ""
              } ${
                !premiumActive ? "ora-premium-locked opacity-70" : ""
              }`}
              aria-label={
                localPost.repostedByCurrentUser
                  ? "Undo repost"
                  : "Repost"
              }
            >
              {reposting ? (
                <Loader2
                  size={18}
                  className="animate-spin"
                />
              ) : (
                <Repeat2
                  size={18}
                />
              )}

              {!premiumActive ? <span className="text-[10px] font-semibold uppercase tracking-wide text-amber-300/80">Power Hour</span> : null}

              {shares > 0 ? <span className="tabular-nums">{shares}</span> : null}
            </button>

            {/* LIKE */}

            <button
              type="button"
              onClick={() =>
                void handleLike()
              }
              disabled={
                liking ||
                editing ||
                deleting
              }
              className={`ora-social-action flex items-center gap-2 transition ${
                localPost.likedByCurrentUser
                  ? "text-green-500"
                  : "text-zinc-500 hover:text-green-500"
              } ${
                liking
                  ? "cursor-wait opacity-70"
                  : ""
              }`}
              aria-label={
                localPost.likedByCurrentUser
                  ? "Unlike post"
                  : "Like post"
              }
            >
              {liking ? (
                <Loader2
                  size={18}
                  className="animate-spin"
                />
              ) : (
                <Heart
                  size={18}
                  fill={
                    localPost.likedByCurrentUser
                      ? "currentColor"
                      : "none"
                  }
                />
              )}

              {likes > 0 ? <span className="tabular-nums">{likes}</span> : null}
            </button>

            {/* SHARE */}

            <button
              type="button"
              onClick={() => void handleShare()}
              className="ora-social-action flex items-center justify-center gap-2 transition hover:text-white"
              aria-label="Share post"
              title={shareStatus === "copied" ? "Link copied" : "Share post"}
            >
              <Share size={18} />
              {shareStatus === "copied" ? <span className="text-xs font-medium">Copied</span> : null}
            </button>
          </div>

          {/* COMMENTS */}

          {showComments && (
            <div className="mt-5 border-t border-zinc-900 pt-5">
              <CommentSection
                postId={
                  localPost.id
                }
                initialCount={
                  comments
                }
                onCountChange={(
                  count,
                ) => {
                  const updatedPost:
                    FeedPost = {
                      ...localPost,
                      comments_count:
                        count,
                    };

                  setLocalPost(
                    updatedPost,
                  );

                  onPostUpdated?.(
                    updatedPost,
                  );
                }}
              />
            </div>
          )}
        </div>
      </div>
      {viewerMedia ? <MediaLightbox url={viewerMedia} type="image" title="Post image" onClose={() => setViewerMedia(null)} /> : null}
    </article>
  );
}
