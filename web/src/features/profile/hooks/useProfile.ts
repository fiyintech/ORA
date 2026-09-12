import { useCallback, useEffect, useState } from "react";
import type { Profile } from "../services/profile.service";
import { profileService } from "../services/profile.service";
import { supabase } from "../../../lib/supabase";
import { getCache, setCache, invalidateCache } from "../../../lib/cache";

const PROFILE_CACHE_TTL = 5 * 60 * 1000;
const PROFILE_CACHE_KEY_PREFIX = "profile:";

export function useProfile() {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const loadProfile = useCallback(async (force = false) => {
    setError(null);

    try {
      // getSession() is local and avoids making every protected route wait for
      // a network round-trip just to discover the already-persisted user id.
      const { data: { session }, error: sessionError } = await supabase.auth.getSession();
      if (sessionError) throw sessionError;
      const user = session?.user ?? null;
      if (!user) {
        setProfile(null);
        setLoading(false);
        invalidateCache(`${PROFILE_CACHE_KEY_PREFIX}current`);
        return;
      }

      const cacheKey = `${PROFILE_CACHE_KEY_PREFIX}${user.id}`;
      const cached = force ? null : getCache<Profile>(cacheKey, PROFILE_CACHE_TTL);
      if (cached) {
        setProfile(cached);
        setLoading(false);
      } else {
        setLoading(true);
      }

      const currentProfile = await profileService.getCurrentProfile();
      setProfile(currentProfile);
      if (currentProfile) setCache(cacheKey, currentProfile);
      else invalidateCache(cacheKey);
    } catch (err) {
      const profileError = err instanceof Error ? err : new Error("Failed to load profile.");
      setError(profileError);
      // If cached data exists, keep it visible instead of replacing the page
      // with an error after a transient network failure.
      // Keep any already-rendered profile on transient failures.
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadProfile();
  }, [loadProfile]);

  return {
    profile,
    loading,
    error,
    hasProfile: !!profile,
    reload: () => loadProfile(true),
  };
}
