import clsx from "clsx";

interface BadgeProps {
  children: React.ReactNode;
  color?: "primary" | "success" | "warning" | "danger";
}

const colors = {
  primary: "bg-violet-500/15 text-violet-400",
  success: "bg-emerald-500/15 text-emerald-400",
  warning: "bg-yellow-500/15 text-yellow-400",
  danger: "bg-red-500/15 text-red-400",
};

export default function Badge({
  children,
  color = "primary",
}: BadgeProps) {
  return (
    <span
      className={clsx(
        "inline-flex items-center rounded-full px-3 py-1 text-xs font-medium",
        colors[color]
      )}
    >
      {children}
    </span>
  );
}
