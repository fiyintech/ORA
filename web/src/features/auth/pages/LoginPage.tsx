import { useState } from "react";
import type { FormEvent } from "react";
import { ArrowRight, Loader2, Sparkles } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { authService } from "../services/auth.service";
import { getSavedAccounts, saveSession } from "../../../lib/account-store";

export default function LoginPage({ allowExistingSession = false }: { allowExistingSession?: boolean }) {
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [recoveryMode, setRecoveryMode] = useState(false);
  const [recoveryEmail, setRecoveryEmail] = useState("");
  const [recoveryLoading, setRecoveryLoading] = useState(false);
  const [recoveryMessage, setRecoveryMessage] = useState("");

  async function login(e: FormEvent) {
    e.preventDefault();

    setError("");

    if (!email.trim() || !password.trim()) {
      setError("Please enter your email and password.");
      return;
    }

    setLoading(true);

    try {
      const { data, error: loginError } = await authService.login({
        email: email.trim(),
        password,
      });

      if (loginError) {
        setError(loginError.message);
        return;
      }

      if (!data.session) {
        setError("Login succeeded, but no session was created.");
        return;
      }

      saveSession(data.session);
      navigate("/", { replace: true });
    } catch (err) {
      console.error("Login error:", err);

      setError(
        err instanceof Error
          ? err.message
          : "Something went wrong while logging in.",
      );
    } finally {
      setLoading(false);
    }
  }

  async function recoverPassword() {
    const normalizedEmail = recoveryEmail.trim().toLowerCase();
    setError("");
    setRecoveryMessage("");

    if (!normalizedEmail) {
      setError("Enter your email address to reset your password.");
      return;
    }

    setRecoveryLoading(true);
    try {
      const { error: resetError } = await authService.resetPassword(normalizedEmail);
      if (resetError) throw resetError;
      setRecoveryMessage("If an account uses that email, a password reset link has been sent.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to send the reset email.");
    } finally {
      setRecoveryLoading(false);
    }
  }

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="grid min-h-screen lg:grid-cols-2">
        {/* ─────────────────────────────────────────────
            LEFT: ORA BRANDING
        ───────────────────────────────────────────── */}

        <section className="relative hidden overflow-hidden lg:flex">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_25%_35%,rgba(124,58,237,0.25),transparent_35%),radial-gradient(circle_at_70%_70%,rgba(168,85,247,0.12),transparent_30%)]" />

          <div className="relative flex w-full flex-col justify-between p-12 xl:p-16">
            <div className="flex items-center gap-3">
              <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-violet-600 text-xl font-black shadow-lg shadow-violet-600/20">
                O
              </div>

              <span className="text-2xl font-bold tracking-tight">
                ORA
              </span>
            </div>

            <div className="max-w-xl">
              <div className="mb-6 flex items-center gap-2 text-sm font-medium text-violet-400">
                <Sparkles size={16} />
                The next generation social platform
              </div>

              <h1 className="text-5xl font-bold leading-[1.05] tracking-tight xl:text-6xl">
                Your world.
                <br />
                Your people.
                <br />
                <span className="text-violet-500">
                  Your aura.
                </span>
              </h1>

              <p className="mt-7 max-w-lg text-lg leading-8 text-zinc-400">
                Connect, share, discover and build your presence
                on ORA. Everything you care about, in one place.
              </p>
            </div>

            <p className="text-sm text-zinc-600">
              © {new Date().getFullYear()} ORA. Building the future,
              one commit at a time.
            </p>
          </div>
        </section>

        {/* ─────────────────────────────────────────────
            RIGHT: LOGIN
        ───────────────────────────────────────────── */}

        <section className="flex min-h-screen items-center justify-center px-6 py-12 sm:px-10 lg:px-16">
          <div className="w-full max-w-[460px]">
            {/* Mobile logo */}

            <div className="mb-12 flex items-center gap-3 lg:hidden">
              <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-violet-600 text-xl font-black">
                O
              </div>

              <span className="text-2xl font-bold">
                ORA
              </span>
            </div>

            {/* Heading */}

            <div className="mb-10">
              <p className="mb-3 text-sm font-medium text-amber-300">
                {allowExistingSession ? "Add another account" : "Welcome back"}
              </p>

              <h2 className="text-4xl font-bold tracking-tight sm:text-5xl">
                {allowExistingSession ? "Add account" : "Sign in to ORA"}
              </h2>

              <p className="mt-4 text-base leading-7 text-zinc-500">
                {allowExistingSession ? "Sign in once and keep this account available for one-tap switching." : "Continue where you left off."}
              </p>
            </div>

            {/* Error */}

            {error && (
              <div className="mb-6 rounded-2xl border border-red-900/50 bg-red-950/30 px-5 py-4 text-sm text-red-400">
                {error}
              </div>
            )}

            {recoveryMode ? (
              <section className="rounded-2xl border border-zinc-800 bg-zinc-950 p-5" aria-label="Password recovery">
                <div className="flex items-center justify-between gap-3"><h3 className="text-base font-semibold">Reset your password</h3><button type="button" onClick={() => { setRecoveryMode(false); setError(""); setRecoveryMessage(""); }} className="text-xs font-semibold text-violet-400 hover:text-violet-300">Back to sign in</button></div>
                <p className="mt-2 text-sm leading-6 text-zinc-500">Enter your email and we’ll send you a secure reset link if an account exists.</p>
                {recoveryMessage && <div className="mt-4 rounded-xl border border-emerald-900/50 bg-emerald-950/30 px-3 py-3 text-sm text-emerald-300">{recoveryMessage}</div>}
                <div className="mt-4">
                  <label htmlFor="recovery-email" className="mb-2 block text-sm font-medium text-zinc-300">Email</label>
                  <input id="recovery-email" type="email" autoComplete="email" value={recoveryEmail} onChange={(e) => setRecoveryEmail(e.target.value)} disabled={recoveryLoading} placeholder="you@example.com" className="h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-900 px-5 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20" />
                </div>
                <button type="button" onClick={() => void recoverPassword()} disabled={recoveryLoading} className="mt-4 flex h-12 w-full items-center justify-center gap-2 rounded-xl bg-violet-600 text-sm font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-60">
                  {recoveryLoading ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" /> : null}
                  {recoveryLoading ? "Sending reset link…" : "Send reset link"}
                </button>
              </section>
            ) : (
            <>
            {/* Login form */}

            <form onSubmit={login} className="space-y-6">
              {/* Email */}

              <div>
                <label
                  htmlFor="email"
                  className="mb-2 block text-sm font-medium text-zinc-300"
                >
                  Email
                </label>

                <input
                  id="email"
                  type="email"
                  autoComplete="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={loading}
                  className="h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 px-5 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
                />
              </div>

              {/* Password */}

              <div>
                <div className="mb-2 flex items-center justify-between">
                  <label
                    htmlFor="password"
                    className="text-sm font-medium text-zinc-300"
                  >
                    Password
                  </label>

                  <button
                    type="button"
                    className="text-sm text-violet-400 transition hover:text-violet-300"
                    onClick={() => {
                      setRecoveryMode((value) => !value);
                      setRecoveryEmail(email);
                      setError("");
                      setRecoveryMessage("");
                    }}
                  >
                    {recoveryMode ? "Back to sign in" : "Forgot password?"}
                  </button>
                </div>

                <input
                  id="password"
                  type="password"
                  autoComplete="current-password"
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                  className="h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 px-5 text-base text-white outline-none transition placeholder:text-zinc-600 focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20"
                />
              </div>

              {/* Submit */}

              <button
                type="submit"
                disabled={loading}
                className="group flex h-14 w-full items-center justify-center gap-3 rounded-2xl bg-violet-600 text-base font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {loading ? (
                  <>
                    <Loader2 size={18} className="animate-spin" />
                    Signing in…
                  </>
                ) : (
                  <>
                    Sign in

                    <ArrowRight
                      size={18}
                      className="transition-transform group-hover:translate-x-1"
                    />
                  </>
                )}
              </button>
            </form>
            </>
            )}

            {/* Divider */}

            <div className="my-8 flex items-center gap-4">
              <div className="h-px flex-1 bg-zinc-900" />

              <span className="text-xs uppercase tracking-widest text-zinc-600">
                ORA
              </span>

              <div className="h-px flex-1 bg-zinc-900" />
            </div>

            {/* Signup */}

            {getSavedAccounts().length > 0 && !allowExistingSession ? (
              <p className="mb-4 text-center text-sm text-zinc-500">
                <Link to="/switch-account" className="font-medium text-amber-300 transition hover:text-amber-200">Use a saved account</Link>
              </p>
            ) : null}

            <p className="text-center text-sm text-zinc-500">
              Don't have an account?{" "}
              <Link
                to="/signup"
                className="font-medium text-violet-400 transition hover:text-violet-300"
              >
                Create one
              </Link>
            </p>
          </div>
        </section>
      </div>
    </main>
  );
}
