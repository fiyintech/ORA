import { forwardRef } from "react";
import type { ButtonHTMLAttributes } from "react";

const Button = forwardRef<HTMLButtonElement, ButtonHTMLAttributes<HTMLButtonElement>>(
  ({ className = "", ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={`rounded-xl px-4 py-2 font-medium transition ${className}`}
        {...props}
      />
    );
  },
);

Button.displayName = "Button";

export default Button;
