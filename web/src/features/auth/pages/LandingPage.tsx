import { ArrowRight, MessageCircle, Sparkles, Users, Zap } from "lucide-react";
import { Link } from "react-router-dom";

export default function LandingPage() {
  return (
    <main className="min-h-screen bg-black text-white">
      <div className="relative min-h-screen overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_20%,rgba(124,58,237,0.22),transparent_35%),radial-gradient(circle_at_15%_80%,rgba(124,58,237,0.12),transparent_30%)]" />

        <header className="relative mx-auto flex max-w-7xl items-center justify-between px-6 py-6 sm:px-10 lg:px-12">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-violet-600 text-xl font-black shadow-lg shadow-violet-600/20">
              O
            </div>
            <span className="text-2xl font-bold tracking-tight">ORA</span>
          </div>

          <div className="flex items-center gap-3">
            <Link
              to="/login"
              className="inline-flex h-11 items-center justify-center rounded-xl border border-zinc-800 px-5 text-sm font-semibold text-white transition hover:border-zinc-700 hover:bg-zinc-900"
            >
              Log in
            </Link>
            <Link
              to="/signup"
              className="hidden h-11 items-center justify-center rounded-xl bg-violet-600 px-5 text-sm font-semibold text-white transition hover:bg-violet-500 sm:inline-flex"
            >
              Sign up
            </Link>
          </div>
        </header>

        <section className="relative mx-auto flex min-h-[calc(100vh-92px)] max-w-5xl items-center justify-center px-6 py-20 text-center sm:px-10">
          <div className="max-w-4xl">
            <div className="mx-auto mb-7 flex w-fit items-center gap-2 rounded-full border border-violet-500/20 bg-violet-500/10 px-4 py-2 text-sm font-medium text-violet-300">
              <Sparkles size={16} />
              Welcome to ORA
            </div>

            <h1 className="text-5xl font-bold leading-[1.02] tracking-tight sm:text-7xl lg:text-8xl">
              Your world.
              <br />
              Your people.
              <br />
              <span className="text-violet-500">Your aura.</span>
            </h1>

            <p className="mx-auto mt-8 max-w-2xl text-lg leading-8 text-zinc-400 sm:text-xl">
              Connect with people, discover communities, share your moments,
              and build your presence on ORA.
            </p>

            <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
              <Link
                to="/signup"
                className="group inline-flex h-14 w-full items-center justify-center gap-3 rounded-2xl bg-violet-600 px-8 text-base font-semibold text-white transition hover:bg-violet-500 sm:w-auto"
              >
                Create your account
                <ArrowRight
                  size={18}
                  className="transition-transform group-hover:translate-x-1"
                />
              </Link>

              <Link
                to="/login"
                className="inline-flex h-14 w-full items-center justify-center rounded-2xl border border-zinc-800 px-8 text-base font-semibold text-white transition hover:border-zinc-700 hover:bg-zinc-900 sm:w-auto"
              >
                Log in
              </Link>
            </div>
          </div>
        </section>

        <section className="relative mx-auto grid max-w-5xl gap-3 px-6 pb-10 sm:grid-cols-3 sm:px-10" aria-label="ORA features">
          {[
            { icon: Users, title: "Find your people", text: "Discover communities and people who share your interests." },
            { icon: MessageCircle, title: "Stay connected", text: "Share moments and keep conversations together in one place." },
            { icon: Zap, title: "Build your Aura", text: "Grow your presence through participation and community." },
          ].map(({ icon: Icon, title, text }) => (
            <div key={title} className="rounded-2xl border border-zinc-900 bg-zinc-950/60 p-5 text-left backdrop-blur-sm">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-violet-500/10 text-violet-400"><Icon size={19} /></div>
              <h2 className="mt-4 text-sm font-semibold text-white">{title}</h2>
              <p className="mt-1.5 text-sm leading-6 text-zinc-500">{text}</p>
            </div>
          ))}
        </section>

        <p className="relative pb-6 text-center text-xs text-zinc-600">
          © {new Date().getFullYear()} ORA · Your world. Your people. Your aura.
        </p>
      </div>
    </main>
  );
}
