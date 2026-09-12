import {
  Image,
  Send,
  X,
  Sparkles,
} from "lucide-react";
import {
  useRef,
  useState,
} from "react";
import { postService } from "../../post/services/post.service";
import { usePremium } from "../../premium/PremiumContext";
import { useNavigate } from "react-router-dom";

interface Props {
  onPostCreated?: () => void;
}

const PREMIUM_MAX_IMAGES = 8;
const MAX_IMAGE_SIZE = 10 * 1024 * 1024;
const STANDARD_MAX_CONTENT = 500;
const PREMIUM_MAX_CONTENT = 1000;

export default function PostComposer({
  onPostCreated,
}: Props) {
  const navigate = useNavigate();
  const { active: premiumActive } = usePremium();
  const maxImages = premiumActive ? PREMIUM_MAX_IMAGES : 0;
  const maxContent = premiumActive ? PREMIUM_MAX_CONTENT : STANDARD_MAX_CONTENT;

  const [
    content,
    setContent,
  ] = useState("");

  const [
    selectedFiles,
    setSelectedFiles,
  ] = useState<File[]>([]);

  const [
    previews,
    setPreviews,
  ] = useState<string[]>([]);

  const [
    loading,
    setLoading,
  ] = useState(false);

  const [
    error,
    setError,
  ] = useState("");

  const fileInputRef =
    useRef<HTMLInputElement>(null);

  function handleFiles(
    fileList: FileList | null,
  ) {
    if (!fileList) {
      return;
    }
    if (!premiumActive) {
      navigate("/premium");
      return;
    }

    setError("");

    const incomingFiles =
      Array.from(fileList);

    if (
      selectedFiles.length +
        incomingFiles.length >
      maxImages
    ) {
      setError(
        `You can upload up to ${maxImages} images per post.`,
      );
      return;
    }

    for (const file of incomingFiles) {
      if (
        !file.type.startsWith(
          "image/",
        )
      ) {
        setError(
          `"${file.name}" is not an image.`,
        );
        return;
      }

      if (
        file.size > MAX_IMAGE_SIZE
      ) {
        setError(
          `"${file.name}" is too large. Maximum image size is 10 MB.`,
        );
        return;
      }
    }

    setSelectedFiles(
      (current) => [
        ...current,
        ...incomingFiles,
      ],
    );

    setPreviews(
      (current) => [
        ...current,
        ...incomingFiles.map(
          (file) =>
            URL.createObjectURL(
              file,
            ),
        ),
      ],
    );
  }

  function removeImage(
    index: number,
  ) {
    URL.revokeObjectURL(
      previews[index],
    );

    setSelectedFiles(
      (current) =>
        current.filter(
          (_, i) =>
            i !== index,
        ),
    );

    setPreviews(
      (current) =>
        current.filter(
          (_, i) =>
            i !== index,
        ),
    );
  }

  function clearImages() {
    previews.forEach((url) =>
      URL.revokeObjectURL(url),
    );

    setSelectedFiles([]);
    setPreviews([]);
  }

  async function handleSubmit() {
    if (
      (!content.trim() &&
        selectedFiles.length === 0) ||
      loading
    ) {
      return;
    }

    setError("");
    setLoading(true);

    try {
      await postService.createPost(
        content,
        selectedFiles,
      );

      setContent("");
      clearImages();

      if (fileInputRef.current) {
        fileInputRef.current.value =
          "";
      }

      onPostCreated?.();
    } catch (err) {
      console.error(
        "Create post failed:",
        err,
      );

      setError(
        err instanceof Error
          ? err.message
          : "Something went wrong while creating your post.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="ora-feed-composer border-b border-zinc-900 bg-zinc-950 px-4 py-4 sm:px-5">
      <textarea
        value={content}
        onChange={(event) =>
          setContent(
            event.target.value,
          )
        }
        placeholder="What's happening?"
        maxLength={maxContent}
        disabled={loading}
        className="min-h-24 w-full resize-none rounded-xl border border-zinc-800 bg-zinc-900/40 px-4 py-3 text-base text-white outline-none placeholder:text-zinc-500 focus:border-violet-600 focus:ring-2 focus:ring-violet-600/10"
      />

      {previews.length > 0 && (
        <div
          className={`mt-3 grid gap-1.5 ${
            previews.length === 1
              ? "grid-cols-1"
              : previews.length === 2
                ? "grid-cols-2"
                : "grid-cols-2"
          }`}
        >
          {previews.map(
            (preview, index) => (
              <div
                key={preview}
                className="group relative overflow-hidden rounded-xl border border-zinc-800 bg-zinc-900"
              >
                <img
                  src={preview}
                  alt={`Selected image ${
                    index + 1
                  }`}
                  className={`w-full object-cover ${
                    previews.length === 1
                      ? "max-h-[420px]"
                      : "aspect-[4/3]"
                  }`}
                />

                <button
                  type="button"
                  onClick={() =>
                    removeImage(
                      index,
                    )
                  }
                  disabled={loading}
                  className="absolute right-2 top-2 flex h-8 w-8 items-center justify-center rounded-full bg-black/75 text-white opacity-0 backdrop-blur transition group-hover:opacity-100 disabled:opacity-50"
                  aria-label={`Remove image ${
                    index + 1
                  }`}
                >
                  <X
                    size={16}
                  />
                </button>
              </div>
            ),
          )}
        </div>
      )}

      {error && (
        <div className="mt-3 rounded-xl border border-red-900/50 bg-red-950/30 px-4 py-3 text-sm text-red-400">
          {error}
        </div>
      )}

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        multiple
        hidden
        onChange={(event) => {
          handleFiles(
            event.target.files,
          );

          event.target.value = "";
        }}
      />

      {premiumActive ? (
        <div className="mt-3 flex items-center gap-2 rounded-xl border border-amber-400/15 bg-amber-400/5 px-3 py-2 text-[11px] text-amber-200/80">
          <Sparkles size={13} className="text-amber-300" /> Power Hour Post Studio · 8 images · 1,000 characters
        </div>
      ) : (
        <button type="button" onClick={() => navigate("/premium")} className="mt-3 w-full rounded-xl border border-zinc-800 bg-zinc-900/50 px-3 py-2 text-left text-[11px] text-zinc-500 transition hover:border-amber-400/20 hover:text-amber-200"><span className="font-semibold text-zinc-400">🔒 Power Hour</span> unlocks image posts, up to 8 images, and 1,000-character posts · ₦100/hour</button>
      )}

      <div className="mt-4 flex items-center justify-between border-t border-zinc-900 pt-4">
        <button
          type="button"
          onClick={() =>
            fileInputRef.current?.click()
          }
          disabled={loading}
          className={`relative flex items-center gap-2 overflow-hidden rounded-xl p-2 text-zinc-400 transition hover:bg-zinc-900 hover:text-white disabled:cursor-not-allowed disabled:opacity-50 ${!premiumActive ? "ora-premium-locked" : ""}`}
          title={premiumActive ? "Add image · up to 8" : "Image posts require Power Hour"}
        >
          <Image size={20} />

          <span className="text-xs">
            {selectedFiles.length > 0
              ? `${selectedFiles.length}/${maxImages}`
              : premiumActive ? "Add image" : "🔒 Add image · Power Hour"}
          </span>
        </button>

        <div className="flex items-center gap-4">
          <span className="text-xs text-zinc-600">
            {content.length}/{maxContent}
          </span>

          <button
            type="button"
            onClick={() =>
              void handleSubmit()
            }
            disabled={
              (!content.trim() &&
                selectedFiles.length ===
                  0) ||
              loading
            }
            className="flex items-center gap-2 rounded-xl bg-violet-600 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-violet-500 disabled:cursor-not-allowed disabled:opacity-50"
          >
            <Send size={17} />

            {loading
              ? "Posting..."
              : "Post"}
          </button>
        </div>
      </div>
    </div>
  );
}
