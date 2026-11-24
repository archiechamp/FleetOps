import { ClerkProvider, SignInButton, UserButton, useAuth } from "@clerk/react";
import { useEffect, useState } from "react";

import { LandingPage } from "../features/landing/LandingPage";
import { ProductionAiPanel } from "./ProductionAiPanel";

type Carrier = { id: string; name: string; permissions: string[] };
type FleetAsset = { id: string; unit_number: string; asset_type: string; make: string;
  model: string; model_year: number; ownership_type: string; status: string };
type View = "Overview" | "Fleet" | "Dispatch" | "GPS" | "Maintenance" | "Documents" | "Costs" | "Reports";
const views: View[] = ["Overview", "Fleet", "Dispatch", "GPS", "Maintenance", "Documents", "Costs", "Reports"];
const statuses = ["AVAILABLE", "ASSIGNED", "IN_TRANSIT", "MAINTENANCE", "OUT_OF_SERVICE", "INACTIVE"];

function FleetWorkspace({ openAiOnEntry, initialQuestion, onBack }: { openAiOnEntry: boolean; initialQuestion: string; onBack: () => void }) {
  const { getToken, isLoaded, isSignedIn } = useAuth();
  const [carriers, setCarriers] = useState<Carrier[]>([]);
  const [carrierId, setCarrierId] = useState("");
  const [assets, setAssets] = useState<FleetAsset[]>([]);
  const [view, setView] = useState<View>("Overview");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [aiOpen, setAiOpen] = useState(false);

  useEffect(() => {
    if (!isLoaded || !isSignedIn) {
      setCarriers([]);
      setCarrierId("");
      setAssets([]);
      setAiOpen(false);
      return;
    }
    const controller = new AbortController();
    setLoading(true);
    getToken().then((token) => fetch("/api/v1/me", {
      headers: { Authorization: `Bearer ${token ?? ""}` }, signal: controller.signal,
    })).then(async (response) => {
      if (!response.ok) throw new Error(response.status === 403
        ? "Your account has no active carrier membership." : "Could not load carrier access.");
      return (await response.json()) as { carriers: Carrier[] };
    }).then((result) => {
      setCarriers(result.carriers);
      setCarrierId(result.carriers[0]?.id ?? "");
      setError("");
    }).catch((reason: unknown) => {
      if (!controller.signal.aborted) setError(reason instanceof Error ? reason.message : "Sign-in failed");
    }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [getToken, isLoaded, isSignedIn]);

  useEffect(() => {
    setAssets([]);
    setView("Overview");
    setAiOpen(false);
    if (!carrierId || !isSignedIn) return;
    const controller = new AbortController();
    setLoading(true);
    getToken().then((token) => fetch("/api/v1/assets", {
      headers: { Authorization: `Bearer ${token ?? ""}`, "X-Tenant-Id": carrierId },
      signal: controller.signal,
    })).then(async (response) => {
      if (!response.ok) throw new Error("Could not load fleet inventory.");
      return (await response.json()) as FleetAsset[];
    }).then((rows) => { setAssets(rows); setError(""); })
      .catch((reason: unknown) => {
        if (!controller.signal.aborted) setError(reason instanceof Error ? reason.message : "Could not load fleet inventory.");
      }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [carrierId, getToken, isSignedIn]);

  useEffect(() => {
    if (openAiOnEntry && carrierId) setAiOpen(true);
  }, [carrierId, openAiOnEntry]);

  const carrier = carriers.find((item) => item.id === carrierId);
  const trucks = assets.filter((asset) => asset.asset_type === "TRACTOR");
  const trailers = assets.filter((asset) => asset.asset_type === "TRAILER");
  const available = assets.filter((asset) => asset.status === "AVAILABLE").length;

  return <main id="main-content" className="mx-auto max-w-6xl p-6 md:p-10">
    <header className="mb-8 flex flex-wrap items-start justify-between gap-4 border-b border-slate-200 pb-6">
      <div><button type="button" className="mb-3 text-sm text-blue-700 underline" onClick={onBack}>Back to FleetOps</button>
      <p className="text-sm font-bold uppercase tracking-[0.24em] text-blue-700">FleetOps · Hosted staging</p>
      <h1 className="mt-2 text-4xl font-bold tracking-tight text-slate-900">Fleet vehicles</h1>
      <p className="mt-2 text-slate-600">Inspect equipment for an authorized carrier.</p></div>
      {isSignedIn && <div className="flex items-center gap-3">
        {carrierId && <button type="button" className="rounded bg-blue-700 px-4 py-2 text-white" onClick={() => setAiOpen(true)}>Ask Fleet</button>}
        <UserButton />
      </div>}
    </header>
    {!isLoaded && <p role="status" className="mt-8">Checking sign-in…</p>}
    {isLoaded && !isSignedIn && <section className="max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 className="text-xl font-semibold">Sign in to FleetOps</h2>
      <p className="mt-2 text-sm text-slate-600">Use your authorized carrier account to explore the hosted staging workspace.</p>
      <SignInButton><button type="button" className="mt-5 w-full rounded-lg bg-blue-700 px-4 py-2 font-semibold text-white">Sign in</button></SignInButton>
    </section>}
    {isSignedIn && <>
      {carriers.length > 0 && <div className="flex flex-wrap items-center justify-between gap-4 rounded-xl bg-slate-900 p-4 text-white"><label className="text-sm">Carrier
        <select className="mt-1 block min-w-56 rounded-md border bg-white p-2 text-slate-900" value={carrierId}
          onChange={(event) => setCarrierId(event.target.value)}>
        {carriers.map((carrier) => <option key={carrier.id} value={carrier.id}>{carrier.name}</option>)}
        </select>
      </label><p className="text-xs text-slate-200">Clerk authenticated · Fleet reader</p></div>}
      {carrierId && <nav aria-label="Fleet workspace" className="my-5 flex flex-wrap gap-2">
        {views.map((item) => <button key={item} type="button" aria-current={view === item ? "page" : undefined}
          onClick={() => setView(item)} className={`rounded-lg border px-4 py-2 text-sm font-medium focus-visible:outline-2 focus-visible:outline-blue-700 ${view === item ? "border-blue-700 bg-blue-700 text-white" : "border-slate-200 bg-white text-slate-700 hover:bg-slate-50"}`}>
          {item}
        </button>)}
      </nav>}
      {loading && <p role="status" className="mt-6">Loading fleet…</p>}
      {error && <p role="alert" className="mt-6 text-red-700">{error}</p>}
      {!loading && !error && carrierId && <div className="space-y-5">
        {view === "Overview" && <>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {[["Trucks", trucks.length], ["Trailers", trailers.length], ["Available assets", available], ["Service due", "Unknown"]].map(([label, value]) =>
              <div key={label} className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"><p className="text-sm text-slate-600">{label}</p><strong className="mt-2 block text-3xl">{value}</strong></div>)}
          </div>
          <div className="grid gap-5 lg:grid-cols-2">
            <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"><h2 className="mb-4 text-lg font-semibold">Fleet status</h2><p className="mb-4 text-sm text-slate-600">Equipment by recorded operating status</p>
              {statuses.map((status) => { const count = assets.filter((asset) => asset.status === status).length;
                return <div key={status} className="mb-3 text-sm"><div className="flex justify-between"><span>{status}</span><strong>{count}</strong></div>
                  <div className="mt-1 h-2 rounded-full bg-slate-100"><div className="h-2 rounded-full bg-blue-600" style={{ width: `${assets.length ? count / assets.length * 100 : 0}%` }} /></div></div>;
              })}
            </section>
            <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"><h2 className="mb-4 text-lg font-semibold">Dispatch and GPS</h2>
              <p>Assignments and last-known positions are not connected to hosted staging yet.</p>
              <p className="mt-4 text-sm text-slate-600">Available assets reflect recorded status only. Dispatch conflicts and GPS freshness have not been verified.</p></section>
          </div>
        </>}
        {view === "Fleet" && <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"><h2 className="mb-4 text-lg font-semibold">Fleet inventory</h2>
          {assets.length === 0 ? <p>No equipment registered for this carrier.</p> : <ul className="divide-y divide-slate-200">{assets.map((asset) =>
            <li key={asset.id} className="py-3"><strong>{asset.unit_number}</strong> · {asset.asset_type === "TRACTOR" ? "Truck" : "Trailer"} · {asset.status}<br />
              <span className="text-sm text-slate-600">{asset.model_year} {asset.make} {asset.model} · {asset.ownership_type}</span></li>)}</ul>}
        </section>}
        {view === "Reports" && <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"><h2 className="mb-4 text-lg font-semibold">Fleet report</h2>
          <p className="mb-4 text-sm text-slate-600">Recorded asset counts for {carrier?.name}. Dispatch availability and service due are not included.</p>
          <table className="w-full text-left text-sm"><thead><tr><th className="pb-2">Status</th><th className="pb-2">Assets</th></tr></thead><tbody>{statuses.map((status) =>
            <tr key={status} className="border-t"><td className="py-2">{status}</td><td>{assets.filter((asset) => asset.status === status).length}</td></tr>)}</tbody></table>
        </section>}
        {view !== "Overview" && view !== "Fleet" && view !== "Reports" && <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <h2 className="mb-4 text-lg font-semibold">{view}</h2><p>{view} records are not connected to the hosted FleetOps data model yet.</p>
          <p className="mt-2 text-sm text-slate-600">This hosted staging account is read-only. No operational data is inferred from fleet status.</p></section>}
      </div>}
    </>}
  {aiOpen && carrierId && <ProductionAiPanel key={carrierId} carrierId={carrierId} initialQuestion={initialQuestion} onClose={() => setAiOpen(false)} />}
  </main>;
}

function ProductionHome() {
  const [entered, setEntered] = useState(false);
  const [openAiOnEntry, setOpenAiOnEntry] = useState(false);
  const [initialQuestion, setInitialQuestion] = useState("");

  if (!entered) return <LandingPage mode="production"
    onExplore={() => { setInitialQuestion(""); setOpenAiOnEntry(false); setEntered(true); }}
    onTryCopilot={(question) => { setInitialQuestion(question); setOpenAiOnEntry(true); setEntered(true); }} />;

  return <FleetWorkspace openAiOnEntry={openAiOnEntry} initialQuestion={initialQuestion} onBack={() => {
    setEntered(false);
    setOpenAiOnEntry(false);
  }} />;
}

export function ProductionApp() {
  const publishableKey = window.__FLEETOPS_CONFIG__?.publishableKey?.startsWith("pk_")
    ? window.__FLEETOPS_CONFIG__.publishableKey : import.meta.env.VITE_CLERK_PUBLISHABLE_KEY;
  if (!publishableKey) return <main role="alert">FleetOps sign-in is not configured.</main>;
  return <ClerkProvider publishableKey={publishableKey}><ProductionHome /></ClerkProvider>;
}
