import clsx from "clsx";
import { useState } from "react";

interface AvatarProfile {
  avatar?: string | null;
  display_name?: string | null;
  username?: string | null;
}

interface AvatarProps {
  src?: string | null;
  name?: string | null;
  profile?: AvatarProfile | null;
  size?: number | "sm" | "md";
  className?: string;
}

export default function Avatar({
  src,
  name,
  profile,
  size = 44,
  className,
}: AvatarProps) {
  const resolvedSrc = src ?? profile?.avatar ?? undefined;
  const [failed, setFailed] = useState(false);
  const resolvedName =
    name ?? profile?.display_name ?? profile?.username ?? "ORA User";
  const initial = resolvedName.trim().charAt(0).toUpperCase() || "O";
  const numericSize =
    typeof size === "number" ? size : size === "sm" ? 36 : 44;

  const fallback = (
    <div
      aria-hidden="true"
      className={clsx(
        "flex shrink-0 items-center justify-center rounded-full bg-violet-600 font-semibold text-white",
        className,
      )}
      style={{ width: numericSize, height: numericSize }}
    >
      {initial}
    </div>
  );

  if (!resolvedSrc || failed) return fallback;

  return (
    <img
      src={resolvedSrc}
      alt={resolvedName}
      className={clsx("shrink-0 rounded-full object-cover", className)}
      style={{ width: numericSize, height: numericSize }}
      onError={() => setFailed(true)}
    />
  );
}
