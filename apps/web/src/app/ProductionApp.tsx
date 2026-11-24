import { ClerkProvider, SignInButton, UserButton, useAuth } from "@clerk/react";
import { useEffect, useState } from "react";

import { LandingPage } from "../features/landing/LandingPage";
import { ProductionAiPanel } from "./ProductionAiPanel";
import { hostedJson } from "./hostedApi";
import { CarrierBar, WorkspaceHeader, WorkspaceNav, type WorkspaceView } from "./WorkspaceChrome";

type Carrier = { id: string; name: string; permissions: string[] };
type FleetAsset = { id: string; unit_number: string; asset_type: string; make: string;
  model: string; model_year: number; ownership_type: string; status: string };
type View = WorkspaceView;
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
  const [refreshKey, setRefreshKey] = useState(0);

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
    getToken().then((token) => hostedJson<{ carriers: Carrier[] }>("/api/v1/me", token,
      undefined, controller.signal)).then((result) => {
      setCarriers(result.carriers);
      setCarrierId(result.carriers[0]?.id ?? "");
      setError("");
    }).catch((reason: unknown) => {
      if (!controller.signal.aborted) {
        setCarriers([]);
        setCarrierId("");
        setError(reason instanceof Error ? reason.message : "Sign-in failed");
      }
    }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [getToken, isLoaded, isSignedIn, refreshKey]);

  useEffect(() => {
    setAssets([]);
    setView("Overview");
    setAiOpen(false);
    if (!carrierId || !isSignedIn) return;
    const controller = new AbortController();
    setLoading(true);
    getToken().then((token) => hostedJson<FleetAsset[]>("/api/v1/assets", token,
      carrierId, controller.signal)).then((rows) => { setAssets(rows); setError(""); })
      .catch((reason: unknown) => {
        if (!controller.signal.aborted) setError(reason instanceof Error ? reason.message : "Could not load fleet inventory.");
      }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [carrierId, getToken, isSignedIn, refreshKey]);

  useEffect(() => {
    if (openAiOnEntry && carrierId) setAiOpen(true);
  }, [carrierId, openAiOnEntry]);

  const carrier = carriers.find((item) => item.id === carrierId);
  const trucks = assets.filter((asset) => asset.asset_type === "TRACTOR");
  const trailers = assets.filter((asset) => asset.asset_type === "TRAILER");
  const available = assets.filter((asset) => asset.status === "AVAILABLE").length;

  return <main id="main-content" className="mx-auto max-w-6xl p-6 md:p-10">
    <WorkspaceHeader environment="Hosted staging" description="Inspect equipment for an authorized carrier." back={onBack} actions={isSignedIn && <>
      {carrierId && <button type="button" className="rounded-lg bg-blue-700 px-4 py-2 font-medium text-white" onClick={() => setAiOpen(true)}>Ask Fleet</button>}
      <UserButton />
    </>} />
    {!isLoaded && <p role="status" className="mt-8">Checking sign-in…</p>}
    {isLoaded && !isSignedIn && <section className="max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 className="text-xl font-semibold">Sign in to FleetOps</h2>
      <p className="mt-2 text-sm text-slate-600">Use your authorized carrier account to explore the hosted staging workspace.</p>
      <SignInButton><button type="button" className="mt-5 w-full rounded-lg bg-blue-700 px-4 py-2 font-semibold text-white">Sign in</button></SignInButton>
    </section>}
    {isSignedIn && <>
      {carriers.length > 0 && <CarrierBar id={carrierId} carriers={carriers} onChange={setCarrierId}
        account="Clerk account" access="Read-only fleet access" />}
      {carrierId && <WorkspaceNav view={view} onChange={setView} />}
      {loading && <p role="status" className="mt-6">Loading fleet…</p>}
      {error && <div role="alert" className="mt-6 rounded-lg border border-red-200 bg-red-50 p-4 text-red-800">
        <p>{error}</p><button type="button" className="mt-2 font-semibold underline" onClick={() => setRefreshKey((key) => key + 1)}>Retry</button>
      </div>}
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
