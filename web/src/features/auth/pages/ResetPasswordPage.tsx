import { useState, type FormEvent } from "react";
import { ArrowRight, CheckCircle2 } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { authService } from "../services/auth.service";

export default function ResetPasswordPage() {
  const navigate = useNavigate();
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setError("");
    if (password.length < 6) {
      setError("Password must be at least 6 characters.");
      return;
    }
    if (password !== confirm) {
      setError("Passwords do not match.");
      return;
    }
    setLoading(true);
    try {
      const { error: updateError } = await authService.updatePassword(password);
      if (updateError) throw updateError;
      setSuccess(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to update your password.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen bg-black text-white">
      <section className="mx-auto flex min-h-screen max-w-lg items-center px-6 py-12">
        <div className="w-full">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-violet-600 text-xl font-black">O</div>
            <span className="text-2xl font-bold tracking-tight">ORA</span>
          </div>
          {success ? (
            <div className="mt-12 rounded-3xl border border-emerald-900/50 bg-emerald-950/20 p-7 text-center">
              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-emerald-500/10 text-emerald-400"><CheckCircle2 size={26} /></div>
              <h1 className="mt-5 text-2xl font-bold">Password updated</h1>
              <p className="mt-2 text-sm leading-6 text-zinc-500">Your password has been changed successfully.</p>
              <button type="button" onClick={() => navigate("/", { replace: true })} className="primary-button mt-6 w-full">Continue to ORA <ArrowRight size={16} /></button>
            </div>
          ) : (
            <>
              <div className="mt-12">
                <p className="text-sm font-medium text-violet-400">Account recovery</p>
                <h1 className="mt-2 text-4xl font-bold tracking-tight">Set a new password</h1>
                <p className="mt-4 text-sm leading-6 text-zinc-500">Choose a new password for your ORA account.</p>
              </div>
              {error && <div className="mt-6 rounded-2xl border border-red-900/50 bg-red-950/30 px-4 py-3 text-sm text-red-300" role="alert">{error}</div>}
              <form onSubmit={submit} className="mt-8 space-y-5">
                <label className="block text-sm font-medium text-zinc-300">New password<input type="password" autoComplete="new-password" value={password} onChange={(e) => setPassword(e.target.value)} disabled={loading} placeholder="At least 6 characters" className="mt-2 h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 px-5 text-base text-white outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20" /></label>
                <label className="block text-sm font-medium text-zinc-300">Confirm new password<input type="password" autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} disabled={loading} placeholder="Repeat your password" className="mt-2 h-14 w-full rounded-2xl border border-zinc-800 bg-zinc-950 px-5 text-base text-white outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-500/20" /></label>
                <button type="submit" disabled={loading} className="primary-button h-14 w-full">{loading ? "Updating…" : <>Update password <ArrowRight size={18} /></>}</button>
              </form>
              <p className="mt-8 text-center text-sm text-zinc-500">Remembered your password? <Link to="/login" className="font-semibold text-violet-400 hover:text-violet-300">Sign in</Link></p>
            </>
          )}
        </div>
      </section>
    </main>
  );
}
