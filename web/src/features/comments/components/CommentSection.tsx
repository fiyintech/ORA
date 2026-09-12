import {
  Heart,
  Loader2,
  MessageCircle,
  Send,
  Trash2,
} from "lucide-react";
import {
  useEffect,
  useRef,
  useState,
} from "react";
import {
  commentService,
  type Comment,
} from "../services/comment.service";
import { supabase } from "../../../lib/supabase";

interface Props {
  postId: string;
  initialCount: number;
  onCountChange?: (count: number) => void;
}

function formatCommentTime(
  dateString: string,
): string {
  const difference = Math.max(
    0,
    Date.now() -
      new Date(dateString).getTime(),
  );

  const seconds = Math.floor(
    difference / 1000,
  );

  if (seconds < 60) {
    return `${seconds}s`;
  }

  const minutes = Math.floor(
    seconds / 60,
  );

  if (minutes < 60) {
    return `${minutes}m`;
  }

  const hours = Math.floor(
    minutes / 60,
  );

  if (hours < 24) {
    return `${hours}h`;
  }

  const days = Math.floor(
    hours / 24,
  );

  if (days < 7) {
    return `${days}d`;
  }

  return new Date(
    dateString,
  ).toLocaleDateString(
    undefined,
    {
      month: "short",
      day: "numeric",
    },
  );
}

export default function CommentSection({
  postId,
  initialCount,
  onCountChange,
}: Props) {
  const [comments, setComments] =
    useState<Comment[]>([]);

  const [content, setContent] =
    useState("");

  const [loading, setLoading] =
    useState(true);

  const [submitting, setSubmitting] =
    useState(false);

  const [replyingTo, setReplyingTo] =
    useState<string | null>(null);

  const [replyContent, setReplyContent] =
    useState("");

  const [deletingId, setDeletingId] =
    useState<string | null>(null);

  const [likingId, setLikingId] =
    useState<string | null>(null);

  const [currentUserId, setCurrentUserId] =
    useState<string | null>(null);

  const [error, setError] =
    useState("");

  /*
   * Keep the latest callback without
   * making the comment-loading effect
   * rerun every time the parent renders.
   */
  const onCountChangeRef =
    useRef(onCountChange);

  useEffect(() => {
    onCountChangeRef.current =
      onCountChange;
  }, [onCountChange]);

  /*
   * Load comments only when the post
   * itself changes.
   *
   * This prevents the render/loading loop
   * caused by a changing callback identity.
   */
  useEffect(() => {
    let mounted = true;

    async function load() {
      try {
        setLoading(true);
        setError("");

        const [
          loadedComments,
          {
            data: { user },
          },
        ] = await Promise.all([
          commentService.getComments(
            postId,
          ),
          supabase.auth.getUser(),
        ]);

        if (!mounted) {
          return;
        }

        setComments(
          loadedComments,
        );

        setCurrentUserId(
          user?.id ?? null,
        );

        onCountChangeRef.current?.(
          loadedComments.length,
        );
      } catch (err) {
        console.error(
          "Failed to load comments:",
          err,
        );

        if (mounted) {
          setError(
            err instanceof Error
              ? err.message
              : "Unable to load comments.",
          );
        }
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    }

    void load();

    return () => {
      mounted = false;
    };
  }, [postId]);

  async function submitComment() {
    if (
      !content.trim() ||
      submitting
    ) {
      return;
    }

    try {
      setSubmitting(true);
      setError("");

      const comment =
        await commentService.createComment(
          postId,
          content,
          null,
        );

      setComments((current) => {
        const updated = [
          ...current,
          comment,
        ];

        onCountChangeRef.current?.(
          updated.length,
        );

        return updated;
      });

      setContent("");
    } catch (err) {
      console.error(
        "Failed to create comment:",
        err,
      );

      setError(
        err instanceof Error
          ? err.message
          : "Unable to create comment.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  async function submitReply(
    parentId: string,
  ) {
    if (
      !replyContent.trim() ||
      submitting
    ) {
      return;
    }

    try {
      setSubmitting(true);
      setError("");

      const reply =
        await commentService.createComment(
          postId,
          replyContent,
          parentId,
        );

      setComments((current) => {
        const updated = [
          ...current,
          reply,
        ];

        onCountChangeRef.current?.(
          updated.length,
        );

        return updated;
      });

      setReplyContent("");
      setReplyingTo(null);
    } catch (err) {
      console.error(
        "Failed to create reply:",
        err,
      );

      setError(
        err instanceof Error
          ? err.message
          : "Unable to create reply.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  async function deleteComment(
    commentId: string,
  ) {
    if (deletingId) {
      return;
    }

    try {
      setDeletingId(commentId);
      setError("");

      await commentService.deleteComment(
        commentId,
      );

      setComments((current) => {
        const idsToRemove =
          new Set<string>([
            commentId,
          ]);

        let changed = true;

        while (changed) {
          changed = false;

          for (
            const comment of current
          ) {
            if (
              comment.parent_id &&
              idsToRemove.has(
                comment.parent_id,
              ) &&
              !idsToRemove.has(
                comment.id,
              )
            ) {
              idsToRemove.add(
                comment.id,
              );

              changed = true;
            }
          }
        }

        const updated =
          current.filter(
            (comment) =>
              !idsToRemove.has(
                comment.id,
              ),
          );

        onCountChangeRef.current?.(
          updated.length,
        );

        return updated;
      });
    } catch (err) {
      console.error(
        "Failed to delete comment:",
        err,
      );

      setError(
        err instanceof Error
          ? err.message
          : "Unable to delete comment.",
      );
    } finally {
      setDeletingId(null);
    }
  }

  async function toggleCommentLike(
    commentId: string,
  ) {
    if (likingId) {
      return;
    }

    const currentComment =
      comments.find(
        (comment) =>
          comment.id === commentId,
      );

    if (!currentComment) {
      return;
    }

    const previousLiked =
      currentComment.likedByCurrentUser;

    const previousCount =
      currentComment.likes_count ?? 0;

    const nextLiked =
      !previousLiked;

    const nextCount = Math.max(
      0,
      previousCount +
        (nextLiked ? 1 : -1),
    );

    setComments((current) =>
      current.map((comment) =>
        comment.id === commentId
          ? {
              ...comment,
              likedByCurrentUser:
                nextLiked,
              likes_count:
                nextCount,
            }
          : comment,
      ),
    );

    try {
      setLikingId(commentId);

      const databaseLiked =
        await commentService.toggleLike(
          commentId,
        );

      setComments((current) =>
        current.map((comment) =>
          comment.id === commentId
            ? {
                ...comment,
                likedByCurrentUser:
                  databaseLiked,
              }
            : comment,
        ),
      );
    } catch (err) {
      console.error(
        "Comment like failed:",
        err,
      );

      setComments((current) =>
        current.map((comment) =>
          comment.id === commentId
            ? {
                ...comment,
                likedByCurrentUser:
                  previousLiked,
                likes_count:
                  previousCount,
              }
            : comment,
        ),
      );

      setError(
        err instanceof Error
          ? err.message
          : "Unable to update comment like.",
      );
    } finally {
      setLikingId(null);
    }
  }

  function renderComment(
    comment: Comment,
    depth = 0,
  ): React.ReactNode {
    const profile =
      comment.profile;

    const displayName =
      profile?.display_name ??
      "ORA user";

    const username =
      profile?.username ??
      "unknown";

    const isOwner =
      currentUserId ===
      comment.user_id;

    const children =
      comments.filter(
        (child) =>
          child.parent_id ===
          comment.id,
      );

    const isLiked =
      comment.likedByCurrentUser;

    const isLiking =
      likingId === comment.id;

    return (
      <div
        key={comment.id}
        className={
          depth > 0
            ? "ml-6 border-l border-zinc-900 pl-4"
            : ""
        }
      >
        <div className="flex gap-3">
          {profile?.avatar ? (
            <img
              src={profile.avatar}
              alt={displayName}
              className="h-9 w-9 shrink-0 rounded-full object-cover"
            />
          ) : (
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-zinc-800 text-xs font-bold text-zinc-300">
              {displayName
                .charAt(0)
                .toUpperCase()}
            </div>
          )}

          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <span className="font-semibold text-white">
                {displayName}
              </span>

              <span className="text-xs text-zinc-600">
                @{username}
              </span>

              <span className="text-xs text-zinc-700">
                •
              </span>

              <span className="text-xs text-zinc-600">
                {formatCommentTime(
                  comment.created_at,
                )}
              </span>

              {comment.is_edited && (
                <span className="text-xs text-zinc-700">
                  edited
                </span>
              )}
            </div>

            <p className="mt-1 whitespace-pre-wrap text-sm leading-6 text-zinc-300">
              {comment.content}
            </p>

            <div className="mt-2 flex items-center gap-5">
              <button
                type="button"
                onClick={() =>
                  void toggleCommentLike(
                    comment.id,
                  )
                }
                disabled={isLiking}
                className={`flex items-center gap-1.5 text-xs font-medium transition ${
                  isLiked
                    ? "text-amber-600"
                    : "text-zinc-600 hover:text-amber-500"
                }`}
                aria-label={
                  isLiked
                    ? "Unlike comment"
                    : "Like comment"
                }
              >
                {isLiking ? (
                  <Loader2
                    size={13}
                    className="animate-spin"
                  />
                ) : (
                  <Heart
                    size={13}
                    fill={
                      isLiked
                        ? "currentColor"
                        : "none"
                    }
                  />
                )}

                <span>
                  {comment.likes_count ??
                    0}
                </span>
              </button>

              <button
                type="button"
                onClick={() => {
                  setReplyingTo(
                    replyingTo ===
                      comment.id
                      ? null
                      : comment.id,
                  );

                  setReplyContent("");
                }}
                className="flex items-center gap-1.5 text-xs font-medium text-zinc-600 transition hover:text-violet-400"
              >
                <MessageCircle
                  size={13}
                />
                Reply
              </button>

              {isOwner && (
                <button
                  type="button"
                  onClick={() =>
                    void deleteComment(
                      comment.id,
                    )
                  }
                  disabled={
                    deletingId ===
                    comment.id
                  }
                  className="flex items-center gap-1.5 text-xs text-zinc-600 transition hover:text-red-400"
                >
                  {deletingId ===
                  comment.id ? (
                    <Loader2
                      size={13}
                      className="animate-spin"
                    />
                  ) : (
                    <Trash2
                      size={13}
                    />
                  )}

                  Delete
                </button>
              )}
            </div>

            {replyingTo ===
              comment.id && (
              <div className="mt-4 flex gap-2">
                <textarea
                  autoFocus
                  value={replyContent}
                  onChange={(event) =>
                    setReplyContent(
                      event.target.value,
                    )
                  }
                  onKeyDown={(event) => {
                    if (
                      event.key ===
                        "Enter" &&
                      !event.shiftKey
                    ) {
                      event.preventDefault();

                      void submitReply(
                        comment.id,
                      );
                    }
                  }}
                  maxLength={1000}
                  placeholder={`Reply to @${username}...`}
                  disabled={submitting}
                  className="min-h-16 flex-1 resize-none rounded-xl border border-zinc-800 bg-zinc-950 px-3 py-2 text-sm text-white outline-none placeholder:text-zinc-600 focus:border-violet-500"
                />

                <button
                  type="button"
                  onClick={() =>
                    void submitReply(
                      comment.id,
                    )
                  }
                  disabled={
                    submitting ||
                    !replyContent.trim()
                  }
                  className="self-end rounded-xl bg-violet-600 p-3 text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-50"
                  aria-label="Send reply"
                >
                  {submitting ? (
                    <Loader2
                      size={16}
                      className="animate-spin"
                    />
                  ) : (
                    <Send size={16} />
                  )}
                </button>
              </div>
            )}

            {children.length > 0 && (
              <div className="mt-4 space-y-5">
                {children.map(
                  (child) =>
                    renderComment(
                      child,
                      depth + 1,
                    ),
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  const topLevelComments =
    comments.filter(
      (comment) =>
        !comment.parent_id,
    );

  return (
    <div className="w-full">
      {/* COMMENT INPUT */}
      <div className="flex gap-3">
        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-violet-600 text-xs font-bold text-white">
          O
        </div>

        <div className="min-w-0 flex-1">
          <textarea
            value={content}
            onChange={(event) =>
              setContent(
                event.target.value,
              )
            }
            onKeyDown={(event) => {
              if (
                event.key ===
                  "Enter" &&
                !event.shiftKey
              ) {
                event.preventDefault();
                void submitComment();
              }
            }}
            maxLength={1000}
            placeholder="Write a comment..."
            disabled={submitting}
            className="min-h-20 w-full resize-none rounded-2xl border border-zinc-800 bg-zinc-950 px-4 py-3 text-sm text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
          />

          <div className="mt-2 flex items-center justify-between">
            <span className="text-xs text-zinc-600">
              {content.length}/1000
            </span>

            <button
              type="button"
              onClick={() =>
                void submitComment()
              }
              disabled={
                submitting ||
                !content.trim()
              }
              className="flex items-center gap-2 rounded-xl bg-violet-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {submitting ? (
                <Loader2
                  size={15}
                  className="animate-spin"
                />
              ) : (
                <Send size={15} />
              )}

              Comment
            </button>
          </div>
        </div>
      </div>

      {/* ERROR */}
      {error && (
        <div className="mt-4 rounded-xl border border-red-900/50 bg-red-950/30 px-4 py-3 text-sm text-red-400">
          {error}
        </div>
      )}

      {/* COMMENTS */}
      <div className="mt-6 space-y-5">
        {loading ? (
          <div className="flex items-center justify-center py-8 text-zinc-500">
            <Loader2
              size={20}
              className="animate-spin"
            />
          </div>
        ) : topLevelComments.length ===
          0 ? (
          <div className="py-6 text-center text-sm text-zinc-600">
            No comments yet. Be the first
            to comment.
          </div>
        ) : (
          topLevelComments.map(
            (comment) =>
              renderComment(comment),
          )
        )}
      </div>

      {!loading &&
        comments.length > 0 && (
          <p className="mt-5 text-center text-xs text-zinc-700">
            {comments.length === 1
              ? "1 comment"
              : `${comments.length} comments`}
          </p>
        )}

      {initialCount !==
        comments.length &&
        !loading && (
          <p className="mt-2 text-center text-[10px] text-zinc-800">
            Comment count synchronized
          </p>
        )}
    </div>
  );
}
