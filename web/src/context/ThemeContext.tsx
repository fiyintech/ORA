import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { supabase } from "../lib/supabase";
import { premiumService } from "../features/premium/services/premium.service";

export type Theme = "dark" | "light";
export type Wallpaper = "silk" | "botanical" | "stars";
export type ProfileFrame = "none" | "halo" | "orbit" | "royal";

type ThemeContextValue = {
  theme: Theme;
  setTheme: (theme: Theme) => void;
  toggleTheme: () => void;
  wallpaper: Wallpaper;
  setWallpaper: (wallpaper: Wallpaper) => void;
  profileFrame: ProfileFrame;
  setProfileFrame: (frame: ProfileFrame) => void;
};

const ThemeContext = createContext<ThemeContextValue | null>(null);
const FALLBACK_KEY = "ora-theme";
const WALLPAPER_FALLBACK_KEY = "ora-wallpaper";
const FRAME_FALLBACK_KEY = "ora-profile-frame";

function storageKey(userId?: string | null) { return userId ? `ora-theme:${userId}` : FALLBACK_KEY; }
function wallpaperKey(userId?: string | null) { return userId ? `ora-wallpaper:${userId}` : WALLPAPER_FALLBACK_KEY; }
function validWallpaper(value: string | null): Wallpaper { return value === "botanical" || value === "stars" ? value : "silk"; }
function isPremiumWallpaper(value: Wallpaper) { return value === "botanical" || value === "stars"; }
function validProfileFrame(value: string | null): ProfileFrame { return value === "halo" || value === "orbit" || value === "royal" ? value : "none"; }
function frameKey(userId?: string | null) { return userId ? `ora-profile-frame:${userId}` : FRAME_FALLBACK_KEY; }

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<Theme>(() => {
    if (typeof window === "undefined") return "light";
    const saved = window.localStorage.getItem(FALLBACK_KEY);
    return saved === "dark" ? "dark" : "light";
  });
  const [wallpaper, setWallpaperState] = useState<Wallpaper>(() => {
    if (typeof window === "undefined") return "silk";
    return validWallpaper(window.localStorage.getItem(WALLPAPER_FALLBACK_KEY));
  });
  const [profileFrame, setProfileFrameState] = useState<ProfileFrame>(() => {
    if (typeof window === "undefined") return "none";
    return validProfileFrame(window.localStorage.getItem(FRAME_FALLBACK_KEY));
  });

  useEffect(() => {
    let active = true;
    const applyForUser = (userId?: string | null) => {
      const savedTheme = window.localStorage.getItem(storageKey(userId));
      const savedWallpaper = window.localStorage.getItem(wallpaperKey(userId));
      const savedFrame = window.localStorage.getItem(frameKey(userId));
      if (active) {
        setThemeState(savedTheme === "dark" ? "dark" : "light");
        setWallpaperState(validWallpaper(savedWallpaper));
        setProfileFrameState(validProfileFrame(savedFrame));
      }
    };
    void supabase.auth.getSession().then(({ data }) => applyForUser(data.session?.user?.id));
    const { data: auth } = supabase.auth.onAuthStateChange((_event, session) => applyForUser(session?.user?.id));
    return () => { active = false; auth.subscription.unsubscribe(); };
  }, []);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    document.documentElement.dataset.wallpaper = wallpaper;
    document.documentElement.style.colorScheme = "dark";
  }, [theme, wallpaper]);

  useEffect(() => {
    let cancelled = false;
    const enforceWallpaperEntitlement = async () => {
      if (!isPremiumWallpaper(wallpaper)) return;
      try {
        const status = await premiumService.getStatus();
        if (!cancelled && !status.active) {
          setWallpaperState("silk");
          const { data } = await supabase.auth.getSession();
          const key = wallpaperKey(data.session?.user?.id);
          try { window.localStorage.setItem(key, "silk"); } catch { /* current state still updates */ }
        }
      } catch {
        // Never remove a currently selected wallpaper solely because a status check failed.
      }
    };
    void enforceWallpaperEntitlement();
    const timer = window.setInterval(() => void enforceWallpaperEntitlement(), 30_000);
    return () => { cancelled = true; window.clearInterval(timer); };
  }, [wallpaper]);

  const setTheme = (next: Theme) => {
    setThemeState(next);
    void supabase.auth.getSession().then(({ data }) => {
      try {
        window.localStorage.setItem(storageKey(data.session?.user?.id), next);
        if (data.session?.user?.id) window.localStorage.setItem(FALLBACK_KEY, next);
      } catch { /* current session still updates */ }
    });
  };

  const setWallpaper = (next: Wallpaper) => {
    if (isPremiumWallpaper(next)) {
      void premiumService.getStatus().then((status) => {
        if (!status.active) return;
        setWallpaperState(next);
        void supabase.auth.getSession().then(({ data }) => {
          try {
            window.localStorage.setItem(wallpaperKey(data.session?.user?.id), next);
            if (data.session?.user?.id) window.localStorage.setItem(WALLPAPER_FALLBACK_KEY, next);
          } catch { /* current session still updates */ }
        });
      }).catch(() => undefined);
      return;
    }
    setWallpaperState(next);
    void supabase.auth.getSession().then(({ data }) => {
      try {
        window.localStorage.setItem(wallpaperKey(data.session?.user?.id), next);
        if (data.session?.user?.id) window.localStorage.setItem(WALLPAPER_FALLBACK_KEY, next);
      } catch { /* current session still updates */ }
    });
  };


  const setProfileFrame = (next: ProfileFrame) => {
    void premiumService.getStatus().then((status) => {
      if (!status.active) return;
      setProfileFrameState(next);
      void supabase.auth.getSession().then(({ data }) => {
        try {
          window.localStorage.setItem(frameKey(data.session?.user?.id), next);
          if (data.session?.user?.id) window.localStorage.setItem(FRAME_FALLBACK_KEY, next);
        } catch { /* current state still updates */ }
      });
    }).catch(() => undefined);
  };

  const value = useMemo(() => ({
    theme,
    setTheme,
    toggleTheme: () => setTheme(theme === "dark" ? "light" : "dark"),
    wallpaper,
    setWallpaper,
    profileFrame,
    setProfileFrame,
  }), [theme, wallpaper, profileFrame]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  const value = useContext(ThemeContext);
  if (!value) throw new Error("useTheme must be used inside ThemeProvider");
  return value;
}
