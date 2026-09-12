/**
 * Tiny client-side stale-while-revalidate cache.
 *
 * It keeps a memory copy for instant route-to-route navigation and mirrors
 * JSON-safe data into sessionStorage so a tab reload does not throw the user
 * back into a full loading screen. Feature pages use a stale-while-revalidate
 * pattern and the authenticated shell warms the main datasets shortly after
 * startup so the next navigation can render immediately. Cache entries are
 * scoped by key and expire automatically; mutations should invalidate or
 * replace affected data.
 */

type CacheEnvelope<T> = {
  value: T;
  savedAt: number;
};

const memory = new Map<string, CacheEnvelope<unknown>>();
const PREFIX = "ora-cache:v1:";

function readStorage<T>(key: string): CacheEnvelope<T> | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.sessionStorage.getItem(`${PREFIX}${key}`);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as CacheEnvelope<T>;
    if (!parsed || typeof parsed.savedAt !== "number") return null;
    return parsed;
  } catch {
    return null;
  }
}

export function getCache<T>(key: string, maxAgeMs: number): T | null {
  const now = Date.now();
  const memoryEntry = memory.get(key) as CacheEnvelope<T> | undefined;
  const entry = memoryEntry ?? readStorage<T>(key);
  if (!entry) return null;

  if (now - entry.savedAt > maxAgeMs) {
    invalidateCache(key);
    return null;
  }

  memory.set(key, entry as CacheEnvelope<unknown>);
  return entry.value;
}

export function setCache<T>(key: string, value: T): void {
  const entry: CacheEnvelope<T> = { value, savedAt: Date.now() };
  memory.set(key, entry as CacheEnvelope<unknown>);
  if (typeof window === "undefined") return;
  try {
    window.sessionStorage.setItem(`${PREFIX}${key}`, JSON.stringify(entry));
  } catch {
    // Cache is an enhancement. Storage quota/private-mode failures must not
    // affect the actual application request.
  }
}

export function invalidateCache(key: string): void {
  memory.delete(key);
  if (typeof window === "undefined") return;
  try {
    window.sessionStorage.removeItem(`${PREFIX}${key}`);
  } catch {
    // Ignore storage failures.
  }
}

export function clearCache(prefix?: string): void {
  const keys = Array.from(memory.keys()).filter((key) => !prefix || key.startsWith(prefix));
  keys.forEach((key) => invalidateCache(key));
  if (typeof window === "undefined" || !prefix) return;
  try {
    const fullPrefix = `${PREFIX}${prefix}`;
    for (let index = window.sessionStorage.length - 1; index >= 0; index -= 1) {
      const key = window.sessionStorage.key(index);
      if (key?.startsWith(fullPrefix)) window.sessionStorage.removeItem(key);
    }
  } catch {
    // Ignore storage failures.
  }
}
