import { ClerkProvider, SignInButton, UserButton, useAuth } from "@clerk/react";
import { useEffect, useState } from "react";
import { DemoWorkspace } from "../features/demo/DemoWorkspace";
import { LandingPage } from "../features/landing/LandingPage";
import { ProductionAiPanel } from "./ProductionAiPanel";
import { hostedJson } from "./hostedApi";
import { CarrierBar, WorkspaceHeader, WorkspaceNav, type WorkspaceView } from "./WorkspaceChrome";

type Carrier = { id: string; name: string; permissions: string[] };

function FleetWorkspace({ openAiOnEntry, initialQuestion, onBack }: {
  openAiOnEntry: boolean; initialQuestion: string; onBack: () => void;
}) {
  const { getToken, isLoaded, isSignedIn } = useAuth();
  const [carriers, setCarriers] = useState<Carrier[]>([]);
  const [carrierId, setCarrierId] = useState("");
  const [view, setView] = useState<WorkspaceView>("Overview");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [aiOpen, setAiOpen] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    if (!isLoaded || !isSignedIn) {
      setCarriers([]); setCarrierId(""); setAiOpen(false);
      return;
    }
    const controller = new AbortController();
    setLoading(true);
    getToken().then((token) => hostedJson<{ carriers: Carrier[] }>("/api/v1/me", token,
      undefined, controller.signal)).then((result) => {
      setCarriers(result.carriers); setCarrierId(result.carriers[0]?.id ?? ""); setError("");
    }).catch((reason: unknown) => {
      if (!controller.signal.aborted) {
        setCarriers([]); setCarrierId("");
        setError(reason instanceof Error ? reason.message : "Sign-in failed");
      }
    }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [getToken, isLoaded, isSignedIn, refreshKey]);

  useEffect(() => { setView("Overview"); setAiOpen(false); }, [carrierId]);
  useEffect(() => { if (openAiOnEntry && carrierId) setAiOpen(true); }, [carrierId, openAiOnEntry]);

  const carrier = carriers.find((item) => item.id === carrierId);
  const permissions = carrier?.permissions ?? [];
  const canCreate = permissions.includes("fleet.vehicle.create");
  const canReadDocuments = permissions.includes("pilot.documents.read");
  const canWriteDocuments = permissions.includes("pilot.documents.write");
  const canReadFinance = permissions.includes("pilot.finance.read");
  const canWriteFinance = permissions.includes("pilot.finance.write");

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
        account="Clerk account" access={canCreate ? "Can manage equipment" : "Read-only fleet access"} />}
      {carrierId && <WorkspaceNav view={view} onChange={setView} />}
      {loading && <p role="status" className="mt-6">Loading carrier access…</p>}
      {error && <div role="alert" className="mt-6 rounded-lg border border-red-200 bg-red-50 p-4 text-red-800">
        <p>{error}</p><button type="button" className="mt-2 font-semibold underline" onClick={() => setRefreshKey((key) => key + 1)}>Retry</button>
      </div>}
      {!loading && !error && carrierId && <DemoWorkspace key={carrierId} view={view} carrierId={carrierId}
        canCreate={canCreate} canFinance={canWriteFinance} canReadDocuments={canReadDocuments}
        canWriteDocuments={canWriteDocuments} canReadFinance={canReadFinance}
        canWriteFinance={canWriteFinance} getToken={getToken} />}
    </>}
    {aiOpen && carrierId && <ProductionAiPanel key={carrierId} carrierId={carrierId}
      initialQuestion={initialQuestion} onClose={() => setAiOpen(false)} />}
  </main>;
}

function ProductionHome() {
  const [entered, setEntered] = useState(false);
  const [openAiOnEntry, setOpenAiOnEntry] = useState(false);
  const [initialQuestion, setInitialQuestion] = useState("");
  if (!entered) return <LandingPage mode="production"
    onExplore={() => { setInitialQuestion(""); setOpenAiOnEntry(false); setEntered(true); }}
    onTryCopilot={(question) => { setInitialQuestion(question); setOpenAiOnEntry(true); setEntered(true); }} />;
  return <FleetWorkspace openAiOnEntry={openAiOnEntry} initialQuestion={initialQuestion}
    onBack={() => { setEntered(false); setOpenAiOnEntry(false); }} />;
}

export function ProductionApp() {
  const publishableKey = window.__FLEETOPS_CONFIG__?.publishableKey?.startsWith("pk_")
    ? window.__FLEETOPS_CONFIG__.publishableKey : import.meta.env.VITE_CLERK_PUBLISHABLE_KEY;
  if (!publishableKey) return <main role="alert">FleetOps sign-in is not configured.</main>;
  return <ClerkProvider publishableKey={publishableKey}><ProductionHome /></ClerkProvider>;
}
