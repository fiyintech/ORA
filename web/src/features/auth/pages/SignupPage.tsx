import { useState } from "react";
import type { FormEvent } from "react";
import { ArrowRight, Loader2, Sparkles } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { authService } from "../services/auth.service";

export default function SignupPage() {
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  async function signup(e: FormEvent) {
    e.preventDefault();

    setError("");
    setSuccess("");

    const normalizedEmail = email.trim().toLowerCase();

    if (!normalizedEmail || !password || !confirmPassword) {
      setError("Please fill in all fields.");
      return;
    }

    if (password.length < 6) {
      setError("Password must be at least 6 characters.");
      return;
    }

    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    setLoading(true);

    try {
      const { data, error: signupError } = await authService.signup(
        normalizedEmail,
        password,
      );

      if (signupError) {
        setError(signupError.message);
        return;
      }

      /*
       * Supabase intentionally hides whether an email already exists
       * when email confirmation is enabled.
       *
       * For an existing confirmed account, Supabase can return an
       * obfuscated user with an empty identities array.
       */
      if (data.user && data.user.identities?.length === 0) {
        setError(
          "An account with this email already exists. Please sign in instead.",
        );
        return;
      }

      /*
       * If a session exists, the project is configured for automatic
       * confirmation. Send the user into ORA.
       */
      if (data.session) {
        navigate("/", { replace: true });
        return;
      }

      /*
       * Normal email-confirmation flow.
       */
      setSuccess(
        "Account created! Check your email to verify your account, then sign in.",
      );
    } catch (err) {
      console.error("Signup error:", err);

      setError(
        err instanceof Error
          ? err.message
          : "Something went wrong while creating your account.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="grid min-h-screen lg:grid-cols-2">
        {/* BRANDING */}
        <section className="relative hidden flex-col justify-between overflow-hidden border-r border-zinc-900 p-12 lg:flex xl:p-16">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(124,58,237,0.14),transparent_35%),radial-gradient(circle_at_70%_80%,rgba(124,58,237,0.08),transparent_35%)]" />

          <div className="relative flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-violet-600 text-xl font-black shadow-lg shadow-violet-600/20">
              O
            </div>

            <span className="text-2xl font-bold tracking-tight">ORA</span>
          </div>

          <div className="relative max-w-xl">
            <div className="mb-6 flex items-center gap-2 text-sm font-medium text-violet-400">
              <Sparkles size={16} />
              Welcome to the next generation
            </div>

            <h1 className="text-5xl font-bold leading-[1.05] tracking-tight xl:text-6xl">
              Find your people.
              <br />
              Share your world.
              <br />
              <span className="text-violet-500">Build your aura.</span>
            </h1>

            <p className="mt-7 max-w-lg text-lg leading-8 text-zinc-400">
              Join ORA and connect with people, discover communities, share
              moments and build your presence.
            </p>
          </div>

          <p className="relative text-sm text-zinc-600">
            © {new Date().getFullYear()} ORA. Building the future, one commit
            at a time.
          </p>
        </section>

        {/* SIGNUP */}
        <section className="flex min-h-screen items-center justify-center px-6 py-12 sm:px-10 lg:px-16">
          <div className="w-full max-w-[460px]">
            {/* Mobile branding */}
            <div className="mb-10 flex items-center gap-3 lg:hidden">
              <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-violet-600 text-xl font-black shadow-lg shadow-violet-600/20">
                O
              </div>

              <span className="text-2xl font-bold">ORA</span>
            </div>

            <div className="mb-10">
              <div className="mb-7 flex items-center justify-between gap-4">
                <p className="text-sm font-medium text-violet-400">
                  Join ORA
                </p>

                <Link
                  to="/login"
                  className="inline-flex h-10 items-center justify-center rounded-xl border border-zinc-800 px-4 text-sm font-semibold text-white transition hover:border-zinc-700 hover:bg-zinc-900"
                >
                  Log in
                </Link>
              </div>

              <h2 className="text-4xl font-bold tracking-tight sm:text-5xl">
                Create your account
              </h2>

              <p className="mt-4 text-base leading-7 text-zinc-500">
                Your journey starts here.
              </p>
            </div>

            {/* ERROR */}
            {error && (
              <div className="mb-6 rounded-2xl border border-red-900/50 bg-red-950/30 px-5 py-4 text-sm leading-6 text-red-400">
                <p>{error}</p>

                {error.includes("already exists") && (
                  <Link
                    to="/login"
                    className="mt-2 inline-block font-semibold text-red-300 underline underline-offset-4 hover:text-white"
                  >
                    Go to login
                  </Link>
                )}
              </div>
            )}

            {/* SUCCESS */}
            {success && (
              <div className="mb-6 rounded-2xl border border-emerald-900/50 bg-emerald-950/30 px-5 py-4 text-sm leading-6 text-emerald-400">
                <p>{success}</p>

                <Link
                  to="/login"
                  className="mt-2 inline-block font-semibold text-emerald-300 underline underline-offset-4 hover:text-white"
                >
                  Go to login
                </Link>
              </div>
            )}

            <form onSubmit={signup} className="space-y-5">
              {/* EMAIL */}
              <div>
                <label
                  htmlFor="signup-email"
                  className="mb-2 block text-sm font-medium text-zinc-300"
                >
                  Email
                </label>

                <input
                  id="signup-email"
                  type="email"
                  autoComplete="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={loading}
                  className="h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 px-5 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20 disabled:cursor-not-allowed disabled:opacity-60"
                />
              </div>

              {/* PASSWORD */}
              <div>
                <label
                  htmlFor="signup-password"
                  className="mb-2 block text-sm font-medium text-zinc-300"
                >
                  Password
                </label>

                <input
                  id="signup-password"
                  type="password"
                  autoComplete="new-password"
                  placeholder="Create a password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                  className="h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 px-5 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20 disabled:cursor-not-allowed disabled:opacity-60"
                />
              </div>

              {/* CONFIRM PASSWORD */}
              <div>
                <label
                  htmlFor="signup-confirm-password"
                  className="mb-2 block text-sm font-medium text-zinc-300"
                >
                  Confirm password
                </label>

                <input
                  id="signup-confirm-password"
                  type="password"
                  autoComplete="new-password"
                  placeholder="Repeat your password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  disabled={loading}
                  className="h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 px-5 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20 disabled:cursor-not-allowed disabled:opacity-60"
                />
              </div>

              {/* SUBMIT */}
              <button
                type="submit"
                disabled={loading}
                className="group flex h-14 w-full items-center justify-center gap-3 rounded-2xl bg-violet-600 text-base font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {loading ? (
                  <>
                    <Loader2 size={18} className="animate-spin" />
                    Creating account…
                  </>
                ) : (
                  <>
                    Create account
                    <ArrowRight
                      size={18}
                      className="transition-transform group-hover:translate-x-1"
                    />
                  </>
                )}
              </button>
            </form>

            <div className="my-8 flex items-center gap-4">
              <div className="h-px flex-1 bg-zinc-900" />

              <span className="text-xs uppercase tracking-widest text-zinc-600">
                ORA
              </span>

              <div className="h-px flex-1 bg-zinc-900" />
            </div>

            <p className="text-center text-sm text-zinc-500">
              Already have an account?{" "}
              <Link
                to="/login"
                className="font-medium text-violet-400 hover:text-violet-300"
              >
                Sign in
              </Link>
            </p>
          </div>
        </section>
      </div>
    </main>
  );
}
