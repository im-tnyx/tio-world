export const DEFAULT_REQUEST_DEADLINE_MS = 45_000;
export const DEFAULT_ITEM_CONCURRENCY = 3;
const MAX_ITEM_CONCURRENCY = 4;

export const ABORTED = Symbol("aborted");

export function clampItemConcurrency(value: number | undefined): number {
  if (!Number.isFinite(value)) return DEFAULT_ITEM_CONCURRENCY;
  return Math.max(1, Math.min(MAX_ITEM_CONCURRENCY, Math.floor(value!)));
}

export async function raceWithAbort<T>(
  signal: AbortSignal,
  operation: () => Promise<T>,
): Promise<T | typeof ABORTED> {
  if (signal.aborted) return ABORTED;

  let onAbort: (() => void) | undefined;
  const aborted = new Promise<typeof ABORTED>((resolve) => {
    onAbort = () => resolve(ABORTED);
    signal.addEventListener("abort", onAbort, { once: true });
  });

  try {
    return await Promise.race([Promise.resolve().then(operation), aborted]);
  } finally {
    if (onAbort !== undefined) signal.removeEventListener("abort", onAbort);
  }
}

export async function mapConcurrentOrdered<T, R>(
  items: readonly T[],
  concurrency: number,
  signal: AbortSignal,
  mapper: (item: T, index: number, signal: AbortSignal) => Promise<R>,
): Promise<readonly R[] | typeof ABORTED> {
  if (items.length === 0) return [];

  const results = new Array<R>(items.length);
  let cursor = 0;
  const workerCount = Math.min(clampItemConcurrency(concurrency), items.length);

  const workers = Array.from({ length: workerCount }, async () => {
    while (true) {
      if (signal.aborted) return ABORTED;
      const index = cursor;
      cursor += 1;
      if (index >= items.length) return null;

      const result = await raceWithAbort(
        signal,
        () => mapper(items[index], index, signal),
      );
      if (result === ABORTED) return ABORTED;
      results[index] = result;
    }
  });

  const workerResults = await Promise.all(workers);
  if (signal.aborted || workerResults.some((result) => result === ABORTED)) {
    return ABORTED;
  }
  return results;
}

export async function fetchWithTimeout(
  fetchFn: typeof fetch,
  input: RequestInfo | URL,
  init: RequestInit | undefined,
  timeoutMs: number,
  parentSignal?: AbortSignal,
): Promise<Response | null> {
  const controller = new AbortController();
  const abortFromParent = () => controller.abort();

  if (parentSignal?.aborted) {
    controller.abort();
  } else {
    parentSignal?.addEventListener("abort", abortFromParent, { once: true });
  }

  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetchFn(input, { ...init, signal: controller.signal });
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
    parentSignal?.removeEventListener("abort", abortFromParent);
  }
}
