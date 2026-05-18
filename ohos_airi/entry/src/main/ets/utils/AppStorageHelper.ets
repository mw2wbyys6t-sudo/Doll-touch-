import { AppStorage } from '@kit.ArkUI';

export function safeGetAppStorageNumber(key: string, defaultValue: number): number {
  try {
    const value = AppStorage.get<number>(key);
    return value !== undefined && value !== null ? Number(value) : defaultValue;
  } catch (e) {
    return defaultValue;
  }
}

export function safeSetAppStorageNumber(key: string, value: number): void {
  try {
    AppStorage.setOrCreate<number>(key, value);
  } catch (e) {
    console.error(`AppStorageHelper: set ${key} failed:`, e);
  }
}

type FrameRequestCallback = (timestamp: number) => void;

let rafId = 0;
const rafCallbacks = new Map<number, FrameRequestCallback>();

export function requestAnimationFrame(callback: FrameRequestCallback): number {
  const id = ++rafId;
  rafCallbacks.set(id, callback);
  setTimeout(() => {
    const cb = rafCallbacks.get(id);
    if (cb) {
      rafCallbacks.delete(id);
      try {
        cb(Date.now());
      } catch (e) {
        console.error('AppStorageHelper: rAF callback failed:', e);
      }
    }
  }, 16);
  return id;
}

export function cancelAnimationFrame(id: number): void {
  rafCallbacks.delete(id);
}
