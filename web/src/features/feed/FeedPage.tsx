import {
  Sparkles,
} from "lucide-react";
import Skeleton from "../../components/ui/Skeleton";
import { supabase } from "../../lib/supabase";
import {
  useCallback,
  useEffect,
  useState,
} from "react";
import PostComposer from "./components/PostComposer";
import PostCard from "./components/PostCard";
import { postService } from "../post/services/post.service";
import type { FeedPost } from "../post/types/post";
import { getCache, setCache } from "../../lib/cache";

const FEED_CACHE_KEY = "feed:current";
const FEED_CACHE_TTL = 10 * 60 * 1000;

export default function FeedPage() {
  const [posts, setPosts] =
    useState<FeedPost[]>([]);

  const [loading, setLoading] =
    useState(true);

  const [error, setError] =
    useState("");

  const loadFeed =
    useCallback(async (silent = false) => {
      setError("");

      try {
        if (!silent) setLoading(true);

        const feedPosts =
          await postService.getFeed();

        setPosts(feedPosts);
        setCache(FEED_CACHE_KEY, feedPosts);
      } catch (err) {
        console.error(
          "Feed loading failed:",
          err,
        );

        setError(
          err instanceof Error
            ? err.message
            : "Unable to load your feed.",
        );
      } finally {
        if (!silent) setLoading(false);
      }
    }, []);

  useEffect(() => {
    const cached = getCache<FeedPost[]>(FEED_CACHE_KEY, FEED_CACHE_TTL);
    if (cached) {
      setPosts(cached);
      setLoading(false);
      void loadFeed(true);
      return;
    }
    void loadFeed();
  }, [loadFeed]);

  useEffect(() => {
    if (posts.length) setCache(FEED_CACHE_KEY, posts);
  }, [posts]);

  useEffect(() => {
    const hash = window.location.hash;
    if (!hash.startsWith("#post-")) return;
    const timer = window.setTimeout(() => {
      document.getElementById(hash.slice(1))?.scrollIntoView({ behavior: "smooth", block: "center" });
    }, 150);
    return () => window.clearTimeout(timer);
  }, [posts.length]);

  // Live feed: the database publishes post/repost changes, so new content
  // appears without requiring the user to refresh the page.
  useEffect(() => {
    const channel = supabase
      .channel("ora-live-feed")
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "posts" },
        () => void loadFeed(true),
      )
      .on(
        "postgres_changes",
        { event: "UPDATE", schema: "public", table: "posts" },
        () => void loadFeed(true),
      )
      .on(
        "postgres_changes",
        { event: "DELETE", schema: "public", table: "posts" },
        () => void loadFeed(true),
      )
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "post_reposts" },
        () => void loadFeed(true),
      )
      .on(
        "postgres_changes",
        { event: "DELETE", schema: "public", table: "post_reposts" },
        () => void loadFeed(true),
      )
      .subscribe((status) => {
        if (status === "CHANNEL_ERROR" || status === "TIMED_OUT") {
          console.warn("ORA live feed subscription status:", status);
        }
      });

    return () => {
      void supabase.removeChannel(channel);
    };
  }, [loadFeed]);

  /*
   * --------------------------------------------------
   * UPDATE POST
   * --------------------------------------------------
   *
   * An original post and its reposts can have the same
   * post.id, so we must update the exact feed item.
   *
   * For reposts we identify the feed item using:
   *   - original post id
   *   - repost user
   *   - repost timestamp
   *
   * For originals we identify it using:
   *   - post id
   *   - isRepost === false
   */
  function handlePostUpdated(
    updatedPost: FeedPost,
  ) {
    setPosts((current) =>
      current.map((post) => {
        /*
         * Repost -> repost.
         */
        if (
          updatedPost.isRepost &&
          post.isRepost
        ) {
          const samePost =
            post.id ===
            updatedPost.id;

          const sameRepostUser =
            post.repostUserId ===
            updatedPost.repostUserId;

          const sameRepostTime =
            post.repostCreatedAt ===
            updatedPost.repostCreatedAt;

          if (
            samePost &&
            sameRepostUser &&
            sameRepostTime
          ) {
            return updatedPost;
          }

          return post;
        }

        /*
         * Original -> original.
         */
        if (
          !updatedPost.isRepost &&
          !post.isRepost &&
          post.id ===
            updatedPost.id
        ) {
          return updatedPost;
        }

        return post;
      }),
    );
  }

  /*
   * --------------------------------------------------
   * DELETE POST / REPOST
   * --------------------------------------------------
   *
   * IMPORTANT:
   *
   * Deleting an ORIGINAL:
   *   Remove the original and every repost of it.
   *
   * Deleting a REPOST:
   *   Remove ONLY that specific repost.
   *   Keep the original.
   *   Keep everybody else's reposts.
   */
  function handlePostDeleted(
    deletedPost: FeedPost,
  ) {
    setPosts((current) => {
      /*
       * -----------------------------------------------
       * ORIGINAL POST WAS DELETED
       * -----------------------------------------------
       *
       * Since every repost points to the same original
       * post id, removing every feed item with that id
       * correctly removes the original and all reposts.
       */
      if (
        !deletedPost.isRepost
      ) {
        return current.filter(
          (post) =>
            post.id !==
            deletedPost.id,
        );
      }

      /*
       * -----------------------------------------------
       * REPOST WAS DELETED
       * -----------------------------------------------
       *
       * Only remove the exact repost belonging to the
       * user who created it.
       *
       * The original post has:
       *   isRepost === false
       *
       * Other reposts can have the same post.id, so
       * post.id alone MUST NOT be used here.
       */
      return current.filter(
        (post) => {
          /*
           * Keep anything that isn't a repost.
           */
          if (
            !post.isRepost
          ) {
            return true;
          }

          /*
           * Keep reposts of different original posts.
           */
          if (
            post.id !==
            deletedPost.id
          ) {
            return true;
          }

          /*
           * Keep reposts made by different users.
           */
          if (
            post.repostUserId !==
            deletedPost.repostUserId
          ) {
            return true;
          }

          /*
           * Keep a different repost made by the same
           * user at another time.
           */
          if (
            post.repostCreatedAt !==
            deletedPost.repostCreatedAt
          ) {
            return true;
          }

          /*
           * This is the exact repost that was deleted.
           */
          return false;
        },
      );
    });
  }

  return (
    <main className="ora-feed-page min-h-screen bg-black text-white">
      <div className="mx-auto w-full max-w-4xl px-0 py-4 sm:px-0">
        <header className="ora-feed-header flex items-center justify-between px-4 sm:px-5">
          <div>
            <div className="flex items-center gap-2">
              <Sparkles
                size={16}
                className="text-violet-400"
              />

              <span className="text-sm font-medium text-violet-400">
                Your aura
              </span>
            </div>

            <h1 className="mt-1 text-3xl font-bold tracking-tight">
              Home
            </h1>
          </div>

          <button
            type="button"
            onClick={() =>
              void loadFeed()
            }
            disabled={loading}
            className="rounded-xl border border-zinc-800 px-3 py-2 text-sm text-zinc-400 transition hover:border-zinc-700 hover:text-white disabled:cursor-not-allowed disabled:opacity-50"
          >
            {loading
              ? "Refreshing..."
              : "Refresh"}
          </button>
        </header>

        <PostComposer
          onPostCreated={loadFeed}
        />

        {error && (
          <div className="mt-3 flex flex-col gap-3 border-y border-red-900/50 bg-red-950/30 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-sm text-red-300">{error}</p>
            <button type="button" onClick={() => void loadFeed()} className="secondary-button border-red-900/60 text-red-200 hover:bg-red-950/40">Try again</button>
          </div>
        )}

        <section className="mt-1 space-y-0">
          {loading ? (
            <div className="space-y-0" aria-live="polite" aria-busy="true">
              {[0, 1, 2].map((item) => (
                <div key={item} className="border-b border-zinc-900 px-4 py-5 sm:px-5">
                  <div className="flex gap-3">
                    <Skeleton className="h-12 w-12 shrink-0 rounded-full" />
                    <div className="min-w-0 flex-1">
                      <div className="flex gap-2"><Skeleton className="h-4 w-28" /><Skeleton className="h-3 w-12" /></div>
                      <Skeleton className="mt-4 h-4 w-11/12" />
                      <Skeleton className="mt-2 h-4 w-2/3" />
                      <Skeleton className="mt-4 h-36 w-full max-w-xl rounded-xl" />
                      <div className="mt-4 flex gap-8"><Skeleton className="h-5 w-12" /><Skeleton className="h-5 w-12" /><Skeleton className="h-5 w-12" /></div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : posts.length === 0 ? (
            <div className="border-y border-zinc-900 bg-zinc-950 px-6 py-14 text-center">
              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-violet-600/10 text-violet-400">
                <Sparkles
                  size={24}
                />
              </div>

              <h2 className="mt-5 text-lg font-semibold">
                Your feed is empty
              </h2>

              <p className="mx-auto mt-2 max-w-sm text-sm leading-6 text-zinc-500">
                Be the first to share something with the ORA community.
              </p>
            </div>
          ) : (
            posts.map(
              (
                post,
                index,
              ) => (
                <PostCard
                  /*
                   * IMPORTANT:
                   *
                   * post.id alone is not unique because an
                   * original and its reposts share the same
                   * original post id.
                   *
                   * Therefore:
                   *
                   * original:
                   *   original-post-id
                   *
                   * repost:
                   *   original-post-id +
                   *   repost-user-id +
                   *   repost-created-at
                   */
                  key={
                    post.isRepost
                      ? [
                          post.id,
                          "repost",
                          post.repostUserId ??
                            "unknown",
                          post.repostCreatedAt ??
                            index,
                        ].join("-")
                      : `${post.id}-original`
                  }
                  post={post}
                  onPostUpdated={
                    handlePostUpdated
                  }
                  onPostDeleted={
                    handlePostDeleted
                  }
                />
              ),
            )
          )}
        </section>
      </div>
    </main>
  );
}
