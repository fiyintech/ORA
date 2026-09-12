import {
  ArrowLeft,
  CalendarDays,
  Edit3,
  Globe,
  Loader2,
  MapPin,
  MessageCircle,
  Settings,
  Sparkles,
} from "lucide-react";
import {
  useCallback,
  useEffect,
  useState,
} from "react";
import {
  useNavigate,
  useParams,
} from "react-router-dom";

import { supabase } from "../../lib/supabase";
import { getCache, setCache } from "../../lib/cache";
import { PageLoading } from "../../components/ui/PageStates";

import { profileService } from "./services/profile.service";
import type { Profile } from "./services/profile.service";

import type { FeedPost } from "../post/types/post";
import { usePremium } from "../premium/PremiumContext";
import { useTheme } from "../../context/ThemeContext";

import PostCard from "../feed/components/PostCard";

import {
  messageService,
} from "../messages/services/message.service";

export default function ProfilePage() {
  const navigate = useNavigate();
  const { active: premiumActive } = usePremium();
  const { profileFrame } = useTheme();
  const { username } = useParams<{
    username?: string;
  }>();

  const [currentUserId, setCurrentUserId] =
    useState<string | null>(null);

  const [profile, setProfile] =
    useState<Profile | null>(null);

  const [posts, setPosts] =
    useState<FeedPost[]>([]);

  const [loading, setLoading] =
    useState(true);

  const [loadingPosts, setLoadingPosts] =
    useState(true);

  const [messaging, setMessaging] =
    useState(false);

  const [following, setFollowing] =
    useState(false);

  const [followLoading, setFollowLoading] =
    useState(false);

  const [followersCount, setFollowersCount] = useState(0);
  const [followingCount, setFollowingCount] = useState(0);

  const [error, setError] =
    useState("");

  const [activeTab, setActiveTab] =
    useState<"posts" | "media">("posts");

  const [avatarFailed, setAvatarFailed] = useState(false);
  const [bannerFailed, setBannerFailed] = useState(false);

  /*
   * --------------------------------------------------
   * CURRENT USER
   * --------------------------------------------------
   */

  const loadCurrentUser =
    useCallback(async () => {
      const { data: { session } } = await supabase.auth.getSession();
      const user = session?.user ?? null;

      setCurrentUserId(
        user?.id ?? null,
      );

      return user;
    }, []);

  /*
   * --------------------------------------------------
   * LOAD PROFILE
   * --------------------------------------------------
   *
   * /profile
   *     -> current user's profile
   *
   * /profile/:username
   *     -> selected user's public profile
   */

  const loadProfile =
    useCallback(async () => {
      try {
        setLoading(true);
        setError("");

        const user =
          await loadCurrentUser();

        if (!user) {
          navigate(
            "/login",
            { replace: true },
          );
          return;
        }

        let loadedProfile:
          | Profile
          | null = null;
        const profileCacheKey = username ? `profile:public:${username.toLowerCase()}` : `profile:${user.id}`;
        const cachedProfile = getCache<Profile>(profileCacheKey, 10 * 60 * 1000);
        if (cachedProfile) {
          loadedProfile = cachedProfile;
          setProfile(cachedProfile);
          setLoading(false);
        }

        /*
         * No username in the URL means this
         * is the current user's profile.
         */
        if (!loadedProfile && !username) {
          loadedProfile = await profileService.getCurrentProfile();
        } else if (!loadedProfile) {
          /*
           * A username in the URL means this
           * is a public profile.
           */
          loadedProfile =
            await profileService.getProfileByUsername(
              username!,
            );
        }

        if (!loadedProfile) {
          setProfile(null);
          return;
        }

        setProfile(loadedProfile);
        setCache(profileCacheKey, loadedProfile);

        try {
          const counts = await profileService.getFollowCounts(loadedProfile.user_id);
          setFollowersCount(counts.followers);
          setFollowingCount(counts.following);
        } catch (countError) {
          console.error("Unable to load follower counts:", countError);
          setFollowersCount(0);
          setFollowingCount(0);
        }
      } catch (err) {
        console.error(
          "Profile loading failed:",
          err,
        );

        setError(
          err instanceof Error
            ? err.message
            : "Unable to load this profile.",
        );
      } finally {
        setLoading(false);
      }
    }, [
      loadCurrentUser,
      navigate,
      username,
    ]);

  /*
   * --------------------------------------------------
   * LOAD USER POSTS
   * --------------------------------------------------
   */

  const loadPosts =
    useCallback(async () => {
      try {
        setLoadingPosts(true);

        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        if (sessionError) throw sessionError;
        const user = session?.user ?? null;

        if (!user) {
          navigate(
            "/login",
            { replace: true },
          );
          return;
        }

        /*
         * Wait until the profile is available.
         */
        let targetUserId =
          user.id;

        if (username) {
          const targetProfile =
            await profileService.getProfileByUsername(
              username,
            );

          if (!targetProfile) {
            setPosts([]);
            return;
          }

          targetUserId =
            targetProfile.user_id;
        }

        /*
         * Fetch posts belonging to the
         * profile currently being viewed.
         */
        const {
          data,
          error: postsError,
        } = await supabase
          .from("posts")
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
          .eq(
            "user_id",
            targetUserId,
          )
          .order(
            "created_at",
            {
              ascending: false,
            },
          );

        if (postsError) {
          throw postsError;
        }

        /*
         * Determine which posts the
         * current user has liked/reposted.
         */
        const postIds =
          (data ?? []).map(
            (post) => post.id,
          );

        let likedIds =
          new Set<string>();

        let repostedIds =
          new Set<string>();

        if (postIds.length > 0) {
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
              .eq(
                "user_id",
                user.id,
              )
              .in(
                "post_id",
                postIds,
              ),

            supabase
              .from("post_reposts")
              .select("post_id")
              .eq(
                "user_id",
                user.id,
              )
              .in(
                "post_id",
                postIds,
              ),
          ]);

          if (likesError) {
            throw likesError;
          }

          if (repostsError) {
            throw repostsError;
          }

          likedIds =
            new Set(
              (likes ?? []).map(
                (like) =>
                  like.post_id,
              ),
            );

          repostedIds =
            new Set(
              (reposts ?? []).map(
                (repost) =>
                  repost.post_id,
              ),
            );
        }

        const formattedPosts =
          (data ?? []).map(
            (post) =>
              ({
                ...post,

                profile:
                  post.profile ?? null,

                likedByCurrentUser:
                  likedIds.has(
                    post.id,
                  ),

                isRepost: false,

                repostUserId:
                  null,

                repostCreatedAt:
                  null,

                repostProfile:
                  null,

                repostedByCurrentUser:
                  repostedIds.has(
                    post.id,
                  ),
              }) as unknown as FeedPost,
          );

        setPosts(
          formattedPosts,
        );
      } catch (err) {
        console.error(
          "Profile posts loading failed:",
          err,
        );

        setError(
          err instanceof Error
            ? err.message
            : "Unable to load posts.",
        );
      } finally {
        setLoadingPosts(false);
      }
    }, [
      navigate,
      username,
    ]);

  /*
   * --------------------------------------------------
   * INITIAL LOAD
   * --------------------------------------------------
   */

  useEffect(() => {
    setAvatarFailed(false);
    setBannerFailed(false);
    void loadProfile();
  }, [loadProfile]);

  useEffect(() => {
    void loadPosts();
  }, [
    loadPosts,
  ]);

  /*
   * --------------------------------------------------
   * MESSAGE USER
   * --------------------------------------------------
   */

  const handleMessage =
    useCallback(async () => {
      if (!profile) {
        return;
      }

      if (!currentUserId) {
        navigate(
          "/login",
          { replace: true },
        );
        return;
      }

      if (
        profile.user_id ===
        currentUserId
      ) {
        return;
      }

      try {
        setMessaging(true);
        setError("");

        /*
         * The message service handles finding
         * an existing conversation or creating
         * a new one.
         */
        const conversation =
          await messageService.getOrCreateConversation(
            profile.user_id,
          );

        navigate(
          `/messages?conversation=${encodeURIComponent(
            conversation.id,
          )}`,
        );
      } catch (err) {
        console.error(
          "Unable to open conversation:",
          err,
        );

        setError(
          err instanceof Error
            ? err.message
            : "Unable to start conversation.",
        );
      } finally {
        setMessaging(false);
      }
    }, [
      currentUserId,
      navigate,
      profile,
    ]);

  /*
   * --------------------------------------------------
   * FOLLOW STATE
   * --------------------------------------------------
   */

  const loadFollowState =
    useCallback(async () => {
      if (!profile || profile.user_id === currentUserId) {
        setFollowing(false);
        return;
      }

      try {
        setFollowing(
          await profileService.isFollowing(profile.user_id),
        );
      } catch (err) {
        console.error("Unable to load follow state:", err);
      }
    }, [currentUserId, profile]);

  useEffect(() => {
    void loadFollowState();
  }, [loadFollowState]);

  async function handleFollow() {
    if (!profile || followLoading) return;

    try {
      setFollowLoading(true);
      setError("");
      const nextFollowing = await profileService.toggleFollow(profile.user_id);
      setFollowing(nextFollowing);
      setFollowersCount((count) => Math.max(0, count + (nextFollowing ? 1 : -1)));
    } catch (err) {
      console.error("Follow action failed:", err);
      setError(
        err instanceof Error
          ? err.message
          : "Unable to update follow status.",
      );
    } finally {
      setFollowLoading(false);
    }
  }

  /*
   * --------------------------------------------------
   * POST UPDATE
   * --------------------------------------------------
   */

  function handlePostUpdated(
    updatedPost: FeedPost,
  ) {
    setPosts(
      (current) =>
        current.map(
          (post) =>
            post.id ===
            updatedPost.id
              ? updatedPost
              : post,
        ),
    );
  }

  /*
   * --------------------------------------------------
   * POST DELETE
   * --------------------------------------------------
   */

  function handlePostDeleted(
    deletedPost: FeedPost,
  ) {
    setPosts(
      (current) =>
        current.filter(
          (post) =>
            post.id !==
            deletedPost.id,
        ),
    );
  }

  /*
   * --------------------------------------------------
   * MEDIA
   * --------------------------------------------------
   */

  const mediaPosts =
    posts.filter(
      (post) =>
        post.media_urls &&
        post.media_urls.length > 0,
    );

  /*
   * --------------------------------------------------
   * LOADING
   * --------------------------------------------------
   */

  if (loading) {
    return (
      <main className="min-h-screen bg-black text-white">
        <div className="mx-auto max-w-5xl border-x border-zinc-900">
          <PageLoading label="Loading profile…" />
        </div>
      </main>
    );
  }

  /*
   * --------------------------------------------------
   * PROFILE NOT FOUND
   * --------------------------------------------------
   */

  if (!profile) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-black px-6 text-white">
        <div className="text-center">
          <h1 className="text-xl font-semibold">
            Profile not found
          </h1>

          <button
            type="button"
            onClick={() =>
              navigate("/")
            }
            className="mt-5 rounded-xl bg-violet-600 px-5 py-2.5 text-sm font-semibold transition hover:bg-violet-500"
          >
            Back to ORA
          </button>
        </div>
      </div>
    );
  }

  const isOwnProfile =
    currentUserId ===
    profile.user_id;

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="ora-profile-shell mx-auto w-full max-w-5xl border-x border-zinc-900">
        {/* ------------------------------------------------ */}
        {/* HEADER */}
        {/* ------------------------------------------------ */}

        <header className="sticky top-0 z-30 flex h-16 items-center gap-4 border-b border-zinc-900 bg-black/90 px-4 backdrop-blur">
          <button
            type="button"
            onClick={() =>
              navigate(-1)
            }
            className="rounded-full p-2 text-zinc-400 transition hover:bg-zinc-900 hover:text-white"
            aria-label="Go back"
          >
            <ArrowLeft
              size={20}
            />
          </button>

          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-base font-bold">
                {profile.display_name}
              </h1>
              {premiumActive && isOwnProfile && (
                <span className="inline-flex items-center gap-1 rounded-full border border-amber-400/20 bg-amber-400/10 px-2 py-0.5 text-[9px] font-black uppercase tracking-wider text-amber-300">
                  <Sparkles size={10} /> Power Hour
                </span>
              )}
            </div>

            <p className="text-xs text-zinc-600">
              @{profile.username}
            </p>
          </div>

          {isOwnProfile && (
            <button
              type="button"
              onClick={() =>
                navigate(
                  "/settings/profile",
                )
              }
              className="ml-auto rounded-full p-2 text-zinc-400 transition hover:bg-zinc-900 hover:text-white"
              aria-label="Profile settings"
            >
              <Settings
                size={19}
              />
            </button>
          )}
        </header>

        {/* ------------------------------------------------ */}
        {/* ERROR */}
        {/* ------------------------------------------------ */}

        {error && (
          <div className="mx-4 mt-4 rounded-xl border border-red-900/50 bg-red-950/30 px-4 py-3 text-sm text-red-400">
            {error}
          </div>
        )}

        {/* ------------------------------------------------ */}
        {/* BANNER */}
        {/* ------------------------------------------------ */}

        <div className="ora-profile-cover relative h-44 overflow-hidden bg-gradient-to-br from-violet-950 via-zinc-900 to-black sm:h-56">
          {profile.banner_url && !bannerFailed ? (
            <img
              src={
                profile.banner_url
              }
              alt="Profile banner"
              className="h-full w-full object-cover"
              onError={() => setBannerFailed(true)}
            />
          ) : (
            <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(124,58,237,0.3),transparent_35%),radial-gradient(circle_at_80%_70%,rgba(76,29,149,0.2),transparent_35%)]" />
          )}
        </div>

        {/* ------------------------------------------------ */}
        {/* PROFILE INFO */}
        {/* ------------------------------------------------ */}

        <section className="relative px-5 pb-5 sm:px-6">
          {/* Avatar + Actions */}

          <div className="-mt-16 flex items-end justify-between gap-4">
            <div className={`relative h-32 w-32 shrink-0 rounded-full ${premiumActive && isOwnProfile && profileFrame !== "none" ? `ora-profile-frame ora-profile-frame-${profileFrame}` : ""}`}>
              {profile.avatar && !avatarFailed ? (
                <img
                  src={profile.avatar}
                  alt={profile.display_name}
                  className="relative z-10 h-32 w-32 rounded-full border-4 border-black object-cover"
                  onError={() => setAvatarFailed(true)}
                />
              ) : (
                <div className="relative z-10 flex h-32 w-32 items-center justify-center rounded-full border-4 border-black bg-zinc-900 text-4xl font-bold text-zinc-400">
                  {(profile.display_name || profile.username || "O").charAt(0).toUpperCase()}
                </div>
              )}
            </div>

            <div className="mb-1 flex items-center gap-2">
              {isOwnProfile ? (
                <button
                  type="button"
                  onClick={() =>
                    navigate(
                      "/settings/profile",
                    )
                  }
                  className="flex items-center gap-2 rounded-full border border-zinc-700 px-4 py-2 text-sm font-semibold transition hover:bg-zinc-900"
                >
                  <Edit3
                    size={15}
                  />

                  Edit Profile
                </button>
              ) : (
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => void handleFollow()}
                    disabled={followLoading}
                    className={following
                      ? "rounded-full border border-zinc-700 px-4 py-2 text-sm font-semibold transition hover:bg-zinc-900 disabled:cursor-not-allowed disabled:opacity-60"
                      : "rounded-full bg-violet-600 px-4 py-2 text-sm font-semibold transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-60"}
                  >
                    {followLoading ? "Updating..." : following ? "Following" : "Follow"}
                  </button>

                  <button
                    type="button"
                    onClick={() => void handleMessage()}
                    disabled={messaging}
                    className="flex items-center gap-2 rounded-full border border-zinc-700 px-4 py-2 text-sm font-semibold transition hover:bg-zinc-900 disabled:cursor-not-allowed disabled:opacity-60"
                  >
                  {messaging ? (
                    <Loader2
                      size={15}
                      className="animate-spin"
                    />
                  ) : (
                    <MessageCircle
                      size={15}
                    />
                  )}

                  {messaging
                    ? "Opening..."
                    : "Message"}
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Name */}

          <div className="mt-4">
            <h2 className="text-2xl font-bold tracking-tight">
              {profile.display_name}
            </h2>

            <p className="mt-1 text-sm text-zinc-500">
              @{profile.username}
            </p>
          </div>

          {/* Bio */}

          {profile.bio && (
            <p className="mt-4 max-w-2xl whitespace-pre-wrap text-sm leading-6 text-zinc-300">
              {profile.bio}
            </p>
          )}

          {/* Details */}

          <div className="mt-4 flex flex-wrap gap-x-5 gap-y-2 text-xs text-zinc-500">
            {profile.location && (
              <span className="flex items-center gap-1.5">
                <MapPin
                  size={14}
                />

                {profile.location}
              </span>
            )}

            {profile.website && (
              <a
                href={
                  profile.website.startsWith(
                    "http://",
                  ) ||
                  profile.website.startsWith(
                    "https://",
                  )
                    ? profile.website
                    : `https://${profile.website}`
                }
                target="_blank"
                rel="noreferrer"
                className="flex items-center gap-1.5 text-violet-400 hover:underline"
              >
                <Globe
                  size={14}
                />

                {profile.website}
              </a>
            )}

            <span className="flex items-center gap-1.5">
              <CalendarDays
                size={14}
              />

              Joined{" "}
              {new Date(
                profile.created_at,
              ).toLocaleDateString(
                [],
                {
                  month: "long",
                  year: "numeric",
                },
              )}
            </span>
          </div>

          {/* Stats */}

          <div className="mt-4 flex flex-wrap gap-2">
            <div className="ora-profile-stat rounded-xl border border-zinc-900 bg-zinc-950 px-3 py-2.5">
              <div className="flex items-center gap-2">
                <Sparkles
                  size={16}
                  className="text-violet-400"
                />

                <span className="text-lg font-bold">
                  {profile.aura_points ??
                    0}
                </span>
              </div>

              <p className="mt-1 text-[10px] uppercase tracking-wider text-zinc-600">
                Aura
              </p>
            </div>

            <div className="ora-profile-stat rounded-xl border border-zinc-900 bg-zinc-950 px-3 py-2.5">
              <div className="text-lg font-bold">
                {profile.steeze_level ??
                  0}
              </div>

              <p className="mt-1 text-[10px] uppercase tracking-wider text-zinc-600">
                Steeze
              </p>
            </div>

            <div className="ora-profile-stat rounded-xl border border-zinc-900 bg-zinc-950 px-3 py-2.5">
              <div className="text-lg font-bold">
                {posts.length}
              </div>

              <p className="mt-1 text-[10px] uppercase tracking-wider text-zinc-600">
                Posts
              </p>
            </div>

            <div className="ora-profile-stat rounded-xl border border-zinc-900 bg-zinc-950 px-3 py-2.5">
              <div className="text-lg font-bold">{followersCount}</div>
              <p className="mt-1 text-[10px] uppercase tracking-wider text-zinc-600">Followers</p>
            </div>

            <div className="ora-profile-stat rounded-xl border border-zinc-900 bg-zinc-950 px-3 py-2.5">
              <div className="text-lg font-bold">{followingCount}</div>
              <p className="mt-1 text-[10px] uppercase tracking-wider text-zinc-600">Following</p>
            </div>
          </div>
        </section>

        {/* ------------------------------------------------ */}
        {/* TABS */}
        {/* ------------------------------------------------ */}

        <div className="grid grid-cols-2 border-y border-zinc-900">
          <button
            type="button"
            onClick={() =>
              setActiveTab("posts")
            }
            className={`relative py-4 text-sm font-semibold transition ${
              activeTab === "posts"
                ? "text-white"
                : "text-zinc-600 hover:text-zinc-300"
            }`}
          >
            Posts

            {activeTab ===
              "posts" && (
              <span className="absolute bottom-0 left-1/2 h-0.5 w-14 -translate-x-1/2 rounded-full bg-violet-500" />
            )}
          </button>

          <button
            type="button"
            onClick={() =>
              setActiveTab("media")
            }
            className={`relative py-4 text-sm font-semibold transition ${
              activeTab === "media"
                ? "text-white"
                : "text-zinc-600 hover:text-zinc-300"
            }`}
          >
            Media

            {activeTab ===
              "media" && (
              <span className="absolute bottom-0 left-1/2 h-0.5 w-14 -translate-x-1/2 rounded-full bg-violet-500" />
            )}
          </button>
        </div>

        {/* ------------------------------------------------ */}
        {/* POSTS */}
        {/* ------------------------------------------------ */}

        {activeTab === "posts" && (
          <section>
            {loadingPosts ? (
              <div className="flex items-center justify-center py-20 text-sm text-zinc-600">
                <Loader2
                  size={18}
                  className="mr-2 animate-spin"
                />

                Loading posts...
              </div>
            ) : posts.length ===
              0 ? (
              <div className="px-6 py-24 text-center">
                <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-zinc-950 text-zinc-700">
                  <Edit3
                    size={25}
                  />
                </div>

                <h3 className="mt-5 text-base font-semibold text-zinc-300">
                  No posts yet
                </h3>

                <p className="mx-auto mt-2 max-w-xs text-sm leading-6 text-zinc-600">
                  {isOwnProfile
                    ? "Share something with the ORA community and it will appear here."
                    : "This user hasn't shared any posts yet."}
                </p>

                {isOwnProfile && (
                  <button
                    type="button"
                    onClick={() =>
                      navigate("/")
                    }
                    className="mt-5 rounded-full bg-violet-600 px-5 py-2.5 text-sm font-semibold transition hover:bg-violet-500"
                  >
                    Create a post
                  </button>
                )}
              </div>
            ) : (
              <div>
                {posts.map(
                  (post) => (
                    <PostCard
                      key={post.id}
                      post={post}
                      onPostUpdated={
                        handlePostUpdated
                      }
                      onPostDeleted={
                        handlePostDeleted
                      }
                    />
                  ),
                )}
              </div>
            )}
          </section>
        )}

        {/* ------------------------------------------------ */}
        {/* MEDIA */}
        {/* ------------------------------------------------ */}

        {activeTab === "media" && (
          <section>
            {loadingPosts ? (
              <div className="flex items-center justify-center py-20 text-sm text-zinc-600">
                <Loader2
                  size={18}
                  className="mr-2 animate-spin"
                />

                Loading media...
              </div>
            ) : mediaPosts.length ===
              0 ? (
              <div className="px-6 py-24 text-center">
                <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-zinc-950 text-zinc-700">
                  <Globe
                    size={25}
                  />
                </div>

                <h3 className="mt-5 text-base font-semibold text-zinc-300">
                  No media yet
                </h3>

                <p className="mx-auto mt-2 max-w-xs text-sm leading-6 text-zinc-600">
                  {isOwnProfile
                    ? "Photos and other media from your posts will appear here."
                    : "This user hasn't shared any media yet."}
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-1 sm:grid-cols-3">
                {mediaPosts.flatMap(
                  (post) =>
                    (
                      post.media_urls ??
                      []
                    ).map(
                      (
                        mediaUrl,
                        index,
                      ) => (
                        <button
                          type="button"
                          key={`${post.id}-${index}`}
                          onClick={() =>
                            setActiveTab(
                              "posts",
                            )
                          }
                          className="group relative aspect-square overflow-hidden bg-zinc-950"
                        >
                          <img
                            src={
                              mediaUrl
                            }
                            alt="Post media"
                            className="h-full w-full object-cover transition duration-300 group-hover:scale-105"
                          />

                          <div className="absolute inset-0 bg-black/0 transition group-hover:bg-black/20" />
                        </button>
                      ),
                    ),
                )}
              </div>
            )}
          </section>
        )}
      </div>
    </main>
  );
}
