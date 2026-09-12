import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { ArrowRight, Check, Loader2, Sparkles, X } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { profileService } from "../services/profile.service";

export default function ProfileSetupPage() {
  const navigate = useNavigate();

  const [username, setUsername] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [bio, setBio] = useState("");
  const [location, setLocation] = useState("");
  const [website, setWebsite] = useState("");

  const [checkingUsername, setCheckingUsername] = useState(false);
  const [usernameAvailable, setUsernameAvailable] = useState<boolean | null>(
    null,
  );

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const normalized = username.trim().toLowerCase();

    setUsernameAvailable(null);

    if (normalized.length < 3) {
      return;
    }

    const timer = window.setTimeout(async () => {
      setCheckingUsername(true);

      try {
        const available = await profileService.usernameAvailable(normalized);
        setUsernameAvailable(available);
      } catch (err) {
        console.error("Username check failed:", err);
        setUsernameAvailable(null);
      } finally {
        setCheckingUsername(false);
      }
    }, 500);

    return () => window.clearTimeout(timer);
  }, [username]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();

    setError("");

    const normalizedUsername = username.trim().toLowerCase();
    const trimmedDisplayName = displayName.trim();

    if (!normalizedUsername || !trimmedDisplayName) {
      setError("Username and display name are required.");
      return;
    }

    if (!/^[a-zA-Z0-9_]+$/.test(normalizedUsername)) {
      setError(
        "Username can only contain letters, numbers, and underscores.",
      );
      return;
    }

    if (normalizedUsername.length < 3 || normalizedUsername.length > 30) {
      setError("Username must be between 3 and 30 characters.");
      return;
    }

    if (trimmedDisplayName.length > 50) {
      setError("Display name must be 50 characters or fewer.");
      return;
    }

    if (usernameAvailable === false) {
      setError("That username is already taken.");
      return;
    }

    setLoading(true);

    try {
      await profileService.createProfile({
        username: normalizedUsername,
        display_name: trimmedDisplayName,
        bio,
        location,
        website,
      });

      navigate("/", { replace: true });
    } catch (err) {
      console.error("Profile creation failed:", err);

      setError(
        err instanceof Error
          ? err.message
          : "Something went wrong while creating your profile.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="mx-auto flex min-h-screen w-full max-w-7xl">
        {/* LEFT SIDE */}
        <section className="relative hidden w-1/2 flex-col justify-between overflow-hidden border-r border-zinc-900 p-12 lg:flex xl:p-16">
          <div className="absolute -left-32 -top-32 h-96 w-96 rounded-full bg-violet-600/10 blur-3xl" />

          <div className="relative flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-violet-600 text-xl font-black shadow-lg shadow-violet-600/20">
              O
            </div>

            <span className="text-2xl font-bold tracking-tight">ORA</span>
          </div>

          <div className="relative max-w-xl">
            <div className="mb-6 flex items-center gap-2 text-sm font-medium text-violet-400">
              <Sparkles size={16} />
              One more step
            </div>

            <h1 className="text-5xl font-bold leading-[1.05] tracking-tight xl:text-6xl">
              Make ORA
              <br />
              <span className="text-violet-500">yours.</span>
            </h1>

            <p className="mt-7 max-w-lg text-lg leading-8 text-zinc-400">
              Create your identity, find your people, share your world,
              and start building your aura.
            </p>
          </div>

          <p className="relative text-sm text-zinc-600">
            © {new Date().getFullYear()} ORA. Building the future, one
            commit at a time.
          </p>
        </section>

        {/* RIGHT SIDE */}
        <section className="flex min-h-screen flex-1 items-center justify-center px-6 py-12 sm:px-10 lg:px-16">
          <div className="w-full max-w-[520px]">
            <div className="mb-8 flex items-center gap-3 lg:hidden">
              <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-violet-600 text-xl font-black">
                O
              </div>

              <span className="text-2xl font-bold">ORA</span>
            </div>

            <div className="mb-8">
              <p className="mb-3 text-sm font-medium text-violet-400">
                Welcome to ORA
              </p>

              <h2 className="text-4xl font-bold tracking-tight sm:text-5xl">
                Set up your profile
              </h2>

              <p className="mt-4 text-base leading-7 text-zinc-500">
                This is how people will see you across ORA.
              </p>
            </div>

            {error && (
              <div className="mb-6 rounded-2xl border border-red-900/50 bg-red-950/30 px-5 py-4 text-sm text-red-400">
                {error}
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-5">
              <div>
                <label
                  htmlFor="profile-username"
                  className="mb-2 block text-sm font-medium text-zinc-300"
                >
                  Username
                </label>

                <div className="relative">
                  <span className="pointer-events-none absolute left-5 top-1/2 -translate-y-1/2 text-zinc-600">
                    @
                  </span>

                  <input
                    id="profile-username"
                    type="text"
                    autoComplete="username"
                    placeholder="yourusername"
                    value={username}
                    onChange={(event) =>
                      setUsername(
                        event.target.value
                          .replace(/\s/g, "")
                          .toLowerCase(),
                      )
                    }
                    disabled={loading}
                    className="h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 pl-10 pr-14 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
                  />

                  {checkingUsername && (
                    <Loader2
                      size={18}
                      className="absolute right-5 top-1/2 -translate-y-1/2 animate-spin text-zinc-500"
                    />
                  )}

                  {!checkingUsername && usernameAvailable === true && (
                    <Check
                      size={20}
                      className="absolute right-5 top-1/2 -translate-y-1/2 text-emerald-400"
                    />
                  )}

                  {!checkingUsername && usernameAvailable === false && (
                    <X
                      size={20}
                      className="absolute right-5 top-1/2 -translate-y-1/2 text-red-400"
                    />
                  )}
                </div>

                {username.length >= 3 && !checkingUsername && (
                  <p
                    className={`mt-2 text-xs ${
                      usernameAvailable === true
                        ? "text-emerald-400"
                        : usernameAvailable === false
                          ? "text-red-400"
                          : "text-zinc-600"
                    }`}
                  >
                    {usernameAvailable === true
                      ? "Username is available."
                      : usernameAvailable === false
                        ? "Username is already taken."
                        : "Use 3–30 letters, numbers, or underscores."}
                  </p>
                )}
              </div>

              <div>
                <label
                  htmlFor="profile-display-name"
                  className="mb-2 block text-sm font-medium text-zinc-300"
                >
                  Display name
                </label>

                <input
                  id="profile-display-name"
                  type="text"
                  autoComplete="name"
                  placeholder="Fiyinfoluwa"
                  value={displayName}
                  onChange={(event) => setDisplayName(event.target.value)}
                  disabled={loading}
                  className="h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 px-5 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
                />
              </div>

              <div>
                <label
                  htmlFor="profile-bio"
                  className="mb-2 block text-sm font-medium text-zinc-300"
                >
                  Bio <span className="text-zinc-600">(optional)</span>
                </label>

                <textarea
                  id="profile-bio"
                  rows={3}
                  maxLength={160}
                  placeholder="Tell people a little about yourself..."
                  value={bio}
                  onChange={(event) => setBio(event.target.value)}
                  disabled={loading}
                  className="w-full resize-none rounded-2xl border border-zinc-800 bg-zinc-950 px-5 py-4 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
                />

                <p className="mt-1 text-right text-xs text-zinc-600">
                  {bio.length}/160
                </p>
              </div>

              <div className="grid gap-5 sm:grid-cols-2">
                <div>
                  <label
                    htmlFor="profile-location"
                    className="mb-2 block text-sm font-medium text-zinc-300"
                  >
                    Location{" "}
                    <span className="text-zinc-600">(optional)</span>
                  </label>

                  <input
                    id="profile-location"
                    type="text"
                    placeholder="Lagos, Nigeria"
                    value={location}
                    onChange={(event) => setLocation(event.target.value)}
                    disabled={loading}
                    className="h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 px-5 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
                  />
                </div>

                <div>
                  <label
                    htmlFor="profile-website"
                    className="mb-2 block text-sm font-medium text-zinc-300"
                  >
                    Website{" "}
                    <span className="text-zinc-600">(optional)</span>
                  </label>

                  <input
                    id="profile-website"
                    type="url"
                    placeholder="https://..."
                    value={website}
                    onChange={(event) => setWebsite(event.target.value)}
                    disabled={loading}
                    className="h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 px-5 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={
                  loading ||
                  checkingUsername ||
                  usernameAvailable === false
                }
                className="group mt-2 flex h-14 w-full items-center justify-center gap-3 rounded-2xl bg-violet-600 text-base font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {loading ? (
                  <>
                    <Loader2 size={18} className="animate-spin" />
                    Creating profile...
                  </>
                ) : (
                  <>
                    Continue
                    <ArrowRight
                      size={18}
                      className="transition-transform group-hover:translate-x-1"
                    />
                  </>
                )}
              </button>
            </form>
          </div>
        </section>
      </div>
    </main>
  );
}
