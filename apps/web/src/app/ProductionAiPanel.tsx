import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport, type UIMessage } from "ai";
import { useAuth } from "@clerk/react";
import { useEffect, useMemo, useState, type FormEvent } from "react";
import { hostedErrorDetail } from "./hostedApi";

type Source = { kind: string; id: string; label: string; updated_at: string | null };
type Conversation = { id: string; title: string | null; updated_at: string };
type AiStatus = { configured: boolean; model: string; daily_limit: number; scope: string };

function sourceData(parts: UIMessage["parts"]): { records: Source[]; queried_at: string } | null {
  for (const part of parts) {
    const value = part as unknown as { type: string; data?: unknown };
    if (value.type !== "data-sources" || !value.data || typeof value.data !== "object") continue;
    const data = value.data as { records?: unknown; queried_at?: unknown };
    if (Array.isArray(data.records) && typeof data.queried_at === "string")
      return { records: data.records as Source[], queried_at: data.queried_at };
  }
  return null;
}

export function ProductionAiPanel({ carrierId, initialQuestion = "", onClose }: { carrierId: string; initialQuestion?: string; onClose: () => void }) {
  const { getToken } = useAuth();
  const [conversationId, setConversationId] = useState<string>(() => crypto.randomUUID());
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [details, setDetails] = useState<AiStatus | null>(null);
  const [input, setInput] = useState(initialQuestion);
  const [localError, setLocalError] = useState("");
  const transport = useMemo(() => new DefaultChatTransport({
    api: "/api/v1/ai/chat",
    fetch: async (url, init) => {
      const token = await getToken();
      const headers = new Headers(init?.headers);
      headers.set("Authorization", `Bearer ${token ?? ""}`);
      headers.set("X-Tenant-Id", carrierId);
      const response = await fetch(url, { ...init, headers });
      if (!response.ok) {
        const body = (await response.json().catch(() => ({}))) as { detail?: unknown };
        throw new Error(hostedErrorDetail(body.detail, `AI Fleet request failed (${response.status})`));
      }
      return response;
    },
  }), [carrierId, getToken]);
  const { messages, sendMessage, status, error, stop, setMessages, clearError } = useChat({
    id: conversationId, transport,
    onFinish: ({ isError }) => { if (!isError) void refreshConversations(); },
  });

  async function aiApi<T>(path: string, options: RequestInit = {}): Promise<T> {
    const token = await getToken();
    const response = await fetch(`/api/v1/ai${path}`, {
      ...options,
      headers: { "Authorization": `Bearer ${token ?? ""}`, "X-Tenant-Id": carrierId,
        "Content-Type": "application/json", ...options.headers },
    });
    if (!response.ok) throw new Error(`AI Fleet request failed (${response.status})`);
    return (await response.json()) as T;
  }

  async function refreshConversations() {
    const rows = await aiApi<Conversation[]>("/conversations");
    setConversations(rows);
  }

  useEffect(() => {
    let active = true;
    Promise.all([aiApi<AiStatus>("/status"), aiApi<Conversation[]>("/conversations")])
      .then(([nextStatus, rows]) => {
        if (active) { setDetails(nextStatus); setConversations(rows); }
      }).catch(() => { if (active) setLocalError("AI Fleet is unavailable."); });
    return () => { active = false; };
  }, [carrierId]);

  async function selectConversation(id: string) {
    try {
      const result = await aiApi<{ messages: UIMessage[] }>(`/conversations/${id}`);
      setConversationId(id);
      setMessages(result.messages);
      setLocalError("");
    } catch { setLocalError("Could not load this conversation."); }
  }

  async function deleteConversation() {
    try {
      if (conversations.some((item) => item.id === conversationId))
        await aiApi(`/conversations/${conversationId}`, { method: "DELETE" });
      setConversationId(crypto.randomUUID());
      setMessages([]);
      await refreshConversations();
    } catch { setLocalError("Could not delete this conversation."); }
  }

  function ask(question: string) {
    if (!question.trim() || status === "submitted" || status === "streaming") return;
    setLocalError(""); clearError(); setInput("");
    void sendMessage({ text: question.trim() });
  }

  return <aside aria-label="AI Fleet panel" className="fixed inset-y-0 right-0 z-40 flex w-full flex-col border-l bg-white shadow-2xl sm:w-[28rem]">
    <header className="border-b p-4">
      <div className="flex items-start justify-between gap-4">
        <div><p className="text-xs font-bold uppercase tracking-wide text-blue-700">Read-only beta</p>
          <h2 className="text-xl font-bold">AI Fleet</h2></div>
        <button type="button" className="rounded border px-3 py-1" onClick={onClose}>Close</button>
      </div>
      <p className="mt-2 text-sm text-slate-600">Fleet inventory questions for your selected carrier. Dispatch, GPS, maintenance and costs are not connected yet.</p>
      {details && <p className="mt-2 text-xs text-slate-600">{details.configured ? details.model : "Verified database summaries"} · {details.daily_limit} questions/day</p>}
      <div className="mt-3 flex gap-2">
        <button type="button" className="rounded border px-3 py-1" onClick={() => { setConversationId(crypto.randomUUID()); setMessages([]); }}>New chat</button>
        <button type="button" className="rounded border px-3 py-1" onClick={() => { void deleteConversation(); }}>Delete chat</button>
      </div>
      {conversations.length > 0 && <label className="mt-3 block text-sm">Recent conversations
        <select className="mt-1 w-full rounded border p-2" value={conversations.some((item) => item.id === conversationId) ? conversationId : ""}
          onChange={(event) => { void selectConversation(event.target.value); }}>
          <option value="" disabled>Select a conversation</option>
          {conversations.map((item) => <option key={item.id} value={item.id}>{item.title || "Untitled chat"}</option>)}
        </select></label>}
    </header>
    <div role="log" aria-label="AI Fleet conversation" aria-live="polite" className="min-h-0 flex-1 space-y-3 overflow-y-auto p-4">
      {messages.length === 0 && <div className="rounded bg-blue-50 p-4 text-sm">
        <p>Ask about fleet inventory recorded for this carrier.</p>
        <button type="button" className="mt-2 text-left text-blue-800 underline" onClick={() => ask("Summarize my fleet inventory")}>Summarize my fleet inventory</button>
      </div>}
      {messages.map((message) => {
        const sources = message.role === "assistant" ? sourceData(message.parts) : null;
        return <article key={message.id} className={`rounded p-3 text-sm ${message.role === "user" ? "ml-8 bg-blue-700 text-white" : "mr-4 bg-slate-100"}`}>
          <p className="mb-1 text-xs font-bold uppercase">{message.role === "user" ? "You" : "AI Fleet"}</p>
          {message.parts.map((part, index) => part.type === "text" ? <p key={index} className="whitespace-pre-wrap">{part.text}</p> : null)}
          {sources && <div className="mt-3 border-t pt-2 text-xs">
            <p>Queried {new Date(sources.queried_at).toLocaleString(undefined, { timeZoneName: "short" })}</p>
            {sources.records.map((source) => <span key={`${source.kind}:${source.id}`} className="mt-1 mr-1 inline-block rounded border px-2 py-1"
              title={`${source.kind} ${source.id}${source.updated_at ? ` · ${source.updated_at}` : ""}`}>{source.label} · {source.kind}</span>)}
          </div>}
          {message.role === "assistant" && status === "ready" && <div className="mt-2 flex gap-3 text-xs">
            {[true, false].map((helpful) => <button type="button" className="underline" key={String(helpful)}
              onClick={() => { void aiApi("/feedback", { method: "POST", body: JSON.stringify({ message_id: message.id, helpful }) })
                .catch(() => setLocalError("Could not save feedback.")); }}>{helpful ? "Helpful" : "Not helpful"}</button>)}
          </div>}
        </article>;
      })}
      {(status === "submitted" || status === "streaming") && <p role="status">AI Fleet is answering…</p>}
      {(error || localError) && <p role="alert" className="rounded bg-red-50 p-3 text-red-800">{localError || error?.message}</p>}
    </div>
    <form className="border-t p-4" onSubmit={(event: FormEvent<HTMLFormElement>) => { event.preventDefault(); ask(input); }}>
      <label htmlFor="production-ai-question" className="block text-sm font-semibold">Your question</label>
      <textarea id="production-ai-question" className="mt-1 w-full rounded border p-2" rows={3} maxLength={1000}
        value={input} onChange={(event) => setInput(event.target.value)} />
      <div className="mt-2 flex gap-2"><button type="submit" className="rounded bg-blue-700 px-4 py-2 text-white" disabled={!input.trim() || status !== "ready"}>Send</button>
        {(status === "submitted" || status === "streaming") && <button type="button" className="rounded border px-4 py-2" onClick={stop}>Stop</button>}</div>
    </form>
  </aside>;
}
