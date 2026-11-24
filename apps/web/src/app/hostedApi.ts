type ApiErrorBody = { detail?: unknown };

const RETRY_DELAYS_MS = [1500, 3000];

function aborted(signal?: AbortSignal): boolean {
  return signal?.aborted === true;
}

function wait(delay: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    if (aborted(signal)) { reject(new DOMException("Request cancelled", "AbortError")); return; }
    const timer = window.setTimeout(() => { signal?.removeEventListener("abort", cancel); resolve(); }, delay);
    function cancel() {
      window.clearTimeout(timer);
      reject(new DOMException("Request cancelled", "AbortError"));
    }
    signal?.addEventListener("abort", cancel, { once: true });
  });
}

export async function hostedJson<T>(url: string, token: string | null, carrierId?: string,
  signal?: AbortSignal): Promise<T> {
  for (let attempt = 0; ; attempt += 1) {
    let response: Response;
    try {
      response = await fetch(url, { signal, headers: {
        Authorization: `Bearer ${token ?? ""}`,
        ...(carrierId ? { "X-Tenant-Id": carrierId } : {}),
      } });
    } catch (error) {
      if (aborted(signal)) throw error;
      if (attempt < RETRY_DELAYS_MS.length) { await wait(RETRY_DELAYS_MS[attempt], signal); continue; }
      throw new Error("Fleet service is temporarily unavailable. Try again.", { cause: error });
    }
    if (response.ok) return (await response.json()) as T;
    if (response.status >= 500 && attempt < RETRY_DELAYS_MS.length) {
      await wait(RETRY_DELAYS_MS[attempt], signal);
      continue;
    }
    if (response.status === 401) throw new Error("Your sign-in expired. Sign out and sign in again.");
    if (response.status === 403) {
      const body = (await response.json().catch(() => ({}))) as ApiErrorBody;
      throw new Error(typeof body.detail === "string" ? body.detail : "Carrier access denied.");
    }
    throw new Error(response.status >= 500
      ? "Fleet service is temporarily unavailable. Try again."
      : `Fleet request failed (${response.status}).`);
  }
}
