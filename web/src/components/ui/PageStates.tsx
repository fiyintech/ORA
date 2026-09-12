import { AlertCircle, Loader2, RefreshCw } from "lucide-react";

export function PageLoading({
  label = "Loading…",
}: {
  label?: string;
}) {
  return (
    <div className="ora-page-loading flex min-h-[45vh] items-center justify-center px-6 text-center" role="status" aria-live="polite">
      <div>
        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-violet-600/10 text-violet-400">
          <Loader2 size={22} className="animate-spin" />
        </div>
        <p className="mt-4 text-sm font-medium text-zinc-300">{label}</p>
        <p className="mt-1 text-xs text-zinc-600">This should only take a moment.</p>
      </div>
    </div>
  );
}

export function InlineError({
  title = "Something went wrong",
  message,
  onRetry,
}: {
  title?: string;
  message: string;
  onRetry?: () => void;
}) {
  return (
    <div className="ora-error-state mx-4 my-6 rounded-2xl border border-red-500/20 bg-red-500/5 p-6 text-center sm:mx-6" role="alert">
      <div className="mx-auto flex h-11 w-11 items-center justify-center rounded-xl bg-red-500/10 text-red-300">
        <AlertCircle size={20} />
      </div>
      <p className="mt-3 text-sm font-semibold text-zinc-100">{title}</p>
      <p className="mx-auto mt-1 max-w-md text-sm leading-6 text-zinc-500">{message}</p>
      {onRetry ? (
        <button type="button" onClick={onRetry} className="secondary-button mt-4">
          <RefreshCw size={15} /> Try again
        </button>
      ) : null}
    </div>
  );
}
