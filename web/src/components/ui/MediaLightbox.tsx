import { Download, X } from "lucide-react";
import { useEffect, useState } from "react";

type Props = {
  url: string;
  type?: "image" | "video";
  title?: string;
  expiresAt?: string | null;
  onClose: () => void;
  onEnded?: () => void;
};


function looksLikeVideo(url: string) {
  return /\.(mp4|webm|mov|m4v)(?:$|\?)/i.test(url);
}

async function downloadUrl(url: string, filename: string) {
  const response = await fetch(url, { mode: "cors", credentials: "omit" });
  if (!response.ok) throw new Error("Unable to download this media.");
  const blob = await response.blob();
  const objectUrl = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = objectUrl;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  window.setTimeout(() => URL.revokeObjectURL(objectUrl), 1000);
}

export default function MediaLightbox({ url, type, title = "Media", expiresAt, onEnded, onClose }: Props) {
  const [downloading, setDownloading] = useState(false);
  const [downloadError, setDownloadError] = useState("");
  const [secondsLeft, setSecondsLeft] = useState<number | null>(null);
  const resolvedType = type ?? (looksLikeVideo(url) ? "video" : "image");

  useEffect(() => {
    if (!expiresAt) {
      setSecondsLeft(null);
      return;
    }
    const update = () => {
      const remaining = Math.max(0, Math.ceil((new Date(expiresAt).getTime() - Date.now()) / 1000));
      setSecondsLeft(remaining);
    };
    update();
    const timer = window.setInterval(update, 250);
    return () => window.clearInterval(timer);
  }, [expiresAt]);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = previousOverflow;
    };
  }, [onClose]);

  async function handleDownload() {
    if (downloading || secondsLeft === 0) return;
    setDownloading(true);
    setDownloadError("");
    try {
      const extension = resolvedType === "video" ? "mp4" : "jpg";
      await downloadUrl(url, `ora-${Date.now()}.${extension}`);
    } catch (error) {
      setDownloadError(error instanceof Error ? error.message : "Unable to download this media.");
    } finally {
      setDownloading(false);
    }
  }

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/95 p-3 sm:p-6" role="dialog" aria-modal="true" aria-label={title} onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
      <div className="absolute inset-x-0 top-0 flex items-center justify-between p-3 sm:p-5">
        <div className="min-w-0">
          {expiresAt && secondsLeft !== null ? (
            <p className="rounded-full bg-black/70 px-3 py-1.5 text-xs font-medium text-white backdrop-blur">
              {secondsLeft > 0 ? `Disappears in ${secondsLeft}s` : "Disappearing…"}
            </p>
          ) : null}
        </div>
        <button type="button" onClick={onClose} className="icon-button h-11 w-11 rounded-full bg-white/10 text-white hover:bg-white/20" aria-label="Close media viewer">
          <X size={21} />
        </button>
      </div>

      <div className="relative flex max-h-full max-w-full flex-col items-center justify-center">
        {resolvedType === "video" ? (
          <video src={url} controls autoPlay playsInline preload="metadata" onEnded={onEnded} className="max-h-[82vh] max-w-[95vw] rounded-xl object-contain" />
        ) : (
          <img src={url} alt={title} className="max-h-[82vh] max-w-[95vw] rounded-xl object-contain" />
        )}

        <div className="mt-3 flex flex-col items-center gap-2 sm:flex-row">
          {(!expiresAt || (secondsLeft !== null && secondsLeft > 0)) && (
            <button type="button" onClick={() => void handleDownload()} disabled={downloading} className="primary-button min-w-32">
              <Download size={16} />
              {downloading ? "Saving…" : "Save"}
              {expiresAt && secondsLeft !== null ? ` · ${secondsLeft}s` : ""}
            </button>
          )}
          <button type="button" onClick={onClose} className="secondary-button min-w-24">Close</button>
        </div>
        {downloadError ? <p className="mt-2 max-w-sm text-center text-xs text-red-300">{downloadError}</p> : null}
      </div>
    </div>
  );
}
