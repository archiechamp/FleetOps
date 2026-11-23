import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport, type UIMessage } from "ai";
import { useEffect, useMemo, useState, type FormEvent } from "react";

import type { DemoView } from "../demo/DemoWorkspace";

type SourceRecord = { kind: string; id: string; label: string; view: DemoView; updated_at: string | null };
type Conversation = { id: string; title: string | null; updated_at: string };
type Status = { configured: boolean; provider: string; model: string; daily_limit: number; retention_days: number };

const views: DemoView[] = ["Overview", "Fleet", "Dispatch", "GPS", "Maintenance", "Documents", "Costs", "Reports"];

async function aiApi<T>(path: string, carrierId: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(`/api/v1/ai${path}`, {
    ...options,
    headers: { "Content-Type": "application/json", "X-Tenant-Id": carrierId,
      "X-Demo-Request": "fleetops-ui", ...options.headers },
  });
  if (!response.ok) throw new Error(`AI Fleet request failed (${response.status})`);
  return (await response.json()) as T;
}

function sourcesFrom(parts: UIMessage["parts"]): { records: SourceRecord[]; queried_at: string } | null {
  for (const part of parts) {
    const candidate = part as unknown as { type: string; data?: unknown };
    if (candidate.type !== "data-sources" || typeof candidate.data !== "object" || !candidate.data) continue;
    const data = candidate.data as { records?: unknown; queried_at?: unknown };
    if (Array.isArray(data.records) && typeof data.queried_at === "string")
      return { records: data.records as SourceRecord[], queried_at: data.queried_at };
  }
  return null;
}

function ChatThread({ conversationId, existing, carrierId, canFinance, initialQuestion, onSaved,
  onNavigate }: { conversationId: string; existing: boolean; carrierId: string;
    canFinance: boolean; initialQuestion: string | null; onSaved: () => void;
    onNavigate: (view: DemoView) => void }) {
  const [input, setInput] = useState(initialQuestion ?? "");
  const [ready, setReady] = useState(!existing);
  const [localError, setLocalError] = useState("");
  const [feedbackNote, setFeedbackNote] = useState("");
  const transport = useMemo(() => new DefaultChatTransport({
    api: "/api/v1/ai/chat",
    headers: { "X-Tenant-Id": carrierId, "X-Demo-Request": "fleetops-ui" },
    credentials: "same-origin",
    fetch: async (input, init) => {
      const response = await fetch(input, init);
      if (!response.ok) {
        const body = (await response.json().catch(() => ({}))) as { detail?: string };
        throw new Error(body.detail || `AI Fleet request failed (${response.status})`);
      }
      return response;
    },
  }), [carrierId]);
  const { messages, sendMessage, status, error, stop, setMessages, clearError } = useChat({
    id: conversationId, transport,
    onFinish: ({ isError }) => { if (!isError) onSaved(); },
  });

  useEffect(() => {
    if (!existing) return;
    const controller = new AbortController();
    aiApi<{ messages: UIMessage[] }>(`/conversations/${conversationId}`, carrierId, {
      signal: controller.signal,
    }).then((result) => { if (!controller.signal.aborted) setMessages(result.messages); })
      .catch(() => { if (!controller.signal.aborted) setLocalError("Could not load this conversation."); })
      .finally(() => { if (!controller.signal.aborted) setReady(true); });
    return () => controller.abort();
  }, [carrierId, conversationId, existing, setMessages]);

  const busy = status === "submitted" || status === "streaming";
  const suggestions = ["What equipment is available?", "Which trucks need service?",
    "Where was DEMO-101 last seen?", ...(canFinance ? ["What costs are recorded for this carrier?"] : [])];

  function ask(question: string) {
    if (!question.trim() || !ready || busy) return;
    setLocalError(""); clearError(); setInput("");
    void sendMessage({ text: question.trim() });
  }

  async function rate(messageId: string, helpful: boolean) {
    try {
      await aiApi("/feedback", carrierId, { method: "POST",
        body: JSON.stringify({ message_id: messageId, helpful }) });
      setFeedbackNote("Feedback saved for this answer.");
    } catch { setFeedbackNote("Could not save feedback."); }
  }

  return <div className="flex min-h-0 flex-1 flex-col">
    <div className="min-h-0 flex-1 space-y-4 overflow-y-auto px-4 py-4" role="log" aria-label="AI Fleet conversation" aria-live="polite">
      {!ready && <p role="status">Loading conversation…</p>}
      {ready && messages.length === 0 && <div className="rounded-xl bg-blue-50 p-4 text-sm text-slate-700">
        <p className="font-semibold">Ask about this demo carrier</p>
        <p className="mt-1">AI Fleet reads saved records. GPS is last known, and recorded costs may be incomplete.</p>
        <div className="mt-3 grid gap-2">{suggestions.map((suggestion) => <button key={suggestion}
          type="button" className="rounded-lg border border-blue-200 bg-white px-3 py-2 text-left text-blue-800 hover:bg-blue-100"
          onClick={() => ask(suggestion)}>{suggestion}</button>)}</div>
      </div>}
      {messages.map((message) => {
        const sources = message.role === "assistant" ? sourcesFrom(message.parts) : null;
        return <article key={message.id} className={`rounded-xl p-3 text-sm ${message.role === "user" ? "ml-8 bg-blue-700 text-white" : "mr-4 bg-slate-100 text-slate-900"}`}>
          <p className="mb-1 text-xs font-bold uppercase tracking-wider">{message.role === "user" ? "You" : "AI Fleet"}</p>
          {message.parts.map((part, index) => part.type === "text" ?
            <p key={index} className="whitespace-pre-wrap">{part.text}</p> : null)}
          {sources && <div className="mt-3 border-t border-slate-300 pt-2 text-xs">
            <p className="text-slate-600">Queried {new Date(sources.queried_at).toLocaleString(undefined, { timeZoneName: "short" })} · {sources.records.length} source record(s)</p>
            <div className="mt-2 flex flex-wrap gap-1">{sources.records.slice(0, 12).map((source) =>
              <button type="button" key={`${source.kind}:${source.id}`}
                className="rounded border border-slate-300 bg-white px-2 py-1 text-left text-blue-800 hover:bg-blue-50"
                title={`${source.kind} ${source.id}${source.updated_at ? ` · ${source.updated_at}` : ""}`}
                onClick={() => { if (views.includes(source.view)) onNavigate(source.view); }}>
                {source.label} · {source.kind}
              </button>)}</div>
          </div>}
          {message.role === "assistant" && status === "ready" && <div className="mt-2 flex gap-2 text-xs">
            <button type="button" className="underline" onClick={() => { void rate(message.id, true); }}>Helpful</button>
            <button type="button" className="underline" onClick={() => { void rate(message.id, false); }}>Not helpful</button>
          </div>}
        </article>;
      })}
      {busy && <p role="status" className="text-sm text-slate-600">AI Fleet is answering…</p>}
      {(error || localError) && <p role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-800">{localError || error?.message || "AI Fleet could not answer."}</p>}
      {feedbackNote && <p role="status" className="text-xs text-slate-600">{feedbackNote}</p>}
    </div>
    <form className="border-t border-slate-200 p-4" onSubmit={(event: FormEvent<HTMLFormElement>) => {
      event.preventDefault(); ask(input);
    }}>
      <label htmlFor="copilot-question" className="block text-sm font-semibold">Your question</label>
      <textarea id="copilot-question" className="mt-1 w-full rounded-lg border border-slate-300 p-2 text-sm focus-visible:outline-2 focus-visible:outline-blue-700"
        rows={3} maxLength={1000} value={input} onChange={(event) => setInput(event.target.value)}
        placeholder="Ask about trucks, dispatch, maintenance, or recorded costs" disabled={!ready} />
      <div className="mt-2 flex gap-2"><button type="submit" className="rounded-lg bg-blue-700 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
        disabled={!input.trim() || !ready || busy}>Send</button>
        {busy && <button type="button" className="rounded-lg border px-4 py-2 text-sm" onClick={stop}>Stop</button>}</div>
    </form>
  </div>;
}

export function CopilotPanel({ carrierId, carrierName, canFinance, initialQuestion = null, onClose, onNavigate }: {
  carrierId: string; carrierName: string; canFinance: boolean; initialQuestion?: string | null;
  onClose: () => void; onNavigate: (view: DemoView) => void;
}) {
  const [status, setStatus] = useState<Status | null>(null);
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [conversationId, setConversationId] = useState<string>(() => crypto.randomUUID());
  const [existing, setExisting] = useState(false);
  const [loadError, setLoadError] = useState("");
  const [promptToPrefill, setPromptToPrefill] = useState(initialQuestion);

  async function refresh() {
    const rows = await aiApi<Conversation[]>("/conversations", carrierId);
    setConversations(rows);
  }

  useEffect(() => {
    const controller = new AbortController();
    Promise.all([
      aiApi<Status>("/status", carrierId, { signal: controller.signal }),
      aiApi<Conversation[]>("/conversations", carrierId, { signal: controller.signal }),
    ]).then(([details, rows]) => {
      if (controller.signal.aborted) return;
      setStatus(details); setConversations(rows);
      if (rows[0]) { setConversationId(rows[0].id); setExisting(true); }
    }).catch(() => { if (!controller.signal.aborted) setLoadError("AI Fleet is unavailable."); });
    return () => controller.abort();
  }, [carrierId]);

  async function removeConversation() {
    if (!existing) { setConversationId(crypto.randomUUID()); return; }
    try {
      await aiApi(`/conversations/${conversationId}`, carrierId, { method: "DELETE" });
      setConversationId(crypto.randomUUID()); setExisting(false);
      await refresh();
    } catch { setLoadError("Could not delete this conversation."); }
  }

  return <aside aria-label="AI Fleet panel" className="fixed inset-y-0 right-0 z-40 flex w-full flex-col border-l border-slate-200 bg-white shadow-2xl sm:w-[26rem]">
    <header className="border-b border-slate-200 p-4">
      <div className="flex items-start justify-between gap-3"><div>
        <p className="text-xs font-bold uppercase tracking-widest text-blue-700">Read-only beta</p>
        <h2 className="text-xl font-bold">AI Fleet</h2>
        <p className="text-sm text-slate-600">{carrierName}</p>
      </div><button type="button" className="rounded-lg border px-3 py-1 text-sm focus-visible:outline-2 focus-visible:outline-blue-700" onClick={onClose}>Close</button></div>
      {status && <p className="mt-2 text-xs text-slate-600">{status.configured ? `${status.provider} · ${status.model}` : "Database answers available; AI provider not configured"} · {status.daily_limit} questions/day · {status.retention_days} day history</p>}
      {loadError && <p role="alert" className="mt-2 text-sm text-red-700">{loadError}</p>}
      <div className="mt-3 flex gap-2"><button type="button" className="rounded-lg border px-3 py-1 text-sm" onClick={() => { setPromptToPrefill(null); setConversationId(crypto.randomUUID()); setExisting(false); }}>New chat</button>
        <button type="button" className="rounded-lg border px-3 py-1 text-sm" onClick={() => { void removeConversation(); }}>Delete current chat</button></div>
      {conversations.length > 0 && <label className="mt-3 block text-xs font-semibold">Recent conversations
        <select className="mt-1 w-full rounded-lg border p-2 text-sm" value={existing ? conversationId : ""}
          onChange={(event) => { setPromptToPrefill(null); setConversationId(event.target.value); setExisting(true); }}>
          <option value="" disabled>Select a conversation</option>
          {conversations.map((item) => <option key={item.id} value={item.id}>{item.title || "Untitled chat"}</option>)}
        </select></label>}
    </header>
    {status ? <ChatThread key={conversationId} conversationId={conversationId} existing={existing}
      carrierId={carrierId} canFinance={canFinance} initialQuestion={promptToPrefill}
      onSaved={() => { setPromptToPrefill(null); void refresh(); }} onNavigate={onNavigate} /> :
      <p role="status" className="p-4 text-sm">Checking AI Fleet…</p>}
  </aside>;
}
