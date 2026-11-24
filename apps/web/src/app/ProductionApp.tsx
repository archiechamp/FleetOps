import { ClerkProvider, SignInButton, UserButton, useAuth } from "@clerk/react";
import { useEffect, useState } from "react";

import type { components } from "../../../../packages/api-contracts/vehicle-openapi";
import { LandingPage } from "../features/landing/LandingPage";
import { ProductionAiPanel } from "./ProductionAiPanel";

type Vehicle = components["schemas"]["Vehicle"];
type Carrier = { id: string; permissions: string[] };

function FleetWorkspace({ openAiOnEntry, initialQuestion, onBack }: { openAiOnEntry: boolean; initialQuestion: string; onBack: () => void }) {
  const { getToken, isLoaded, isSignedIn } = useAuth();
  const [carriers, setCarriers] = useState<Carrier[]>([]);
  const [carrierId, setCarrierId] = useState("");
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [aiOpen, setAiOpen] = useState(false);

  useEffect(() => {
    if (!isLoaded || !isSignedIn) {
      setCarriers([]);
      setCarrierId("");
      setVehicles([]);
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
    setVehicles([]);
    setAiOpen(false);
    if (!carrierId || !isSignedIn) return;
    const controller = new AbortController();
    setLoading(true);
    getToken().then((token) => fetch("/api/v1/vehicles", {
      headers: { Authorization: `Bearer ${token ?? ""}`, "X-Tenant-Id": carrierId },
      signal: controller.signal,
    })).then(async (response) => {
      if (!response.ok) throw new Error("Could not load fleet inventory.");
      return (await response.json()) as Vehicle[];
    }).then((rows) => { setVehicles(rows); setError(""); })
      .catch((reason: unknown) => {
        if (!controller.signal.aborted) setError(reason instanceof Error ? reason.message : "Could not load fleet inventory.");
      }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [carrierId, getToken, isSignedIn]);

  useEffect(() => {
    if (openAiOnEntry && carrierId) setAiOpen(true);
  }, [carrierId, openAiOnEntry]);

  return <main className="mx-auto max-w-5xl p-6">
    <button type="button" className="mb-5 text-sm text-blue-700 underline" onClick={onBack}>Back to FleetOps</button>
    <header className="flex items-center justify-between border-b pb-5">
      <div><p className="text-xs font-bold uppercase tracking-widest text-blue-700">FleetOps</p>
        <h1 className="text-3xl font-bold">OOOFleet inventory</h1></div>
      {isSignedIn && <div className="flex items-center gap-3">
        {carrierId && <button type="button" className="rounded bg-blue-700 px-4 py-2 text-white" onClick={() => setAiOpen(true)}>Ask Fleet</button>}
        <UserButton />
      </div>}
    </header>
    {!isLoaded && <p role="status" className="mt-8">Checking sign-in…</p>}
    {isLoaded && !isSignedIn && <section className="mt-8 rounded-lg border p-6">
      <h2 className="text-xl font-semibold">Sign in to FleetOps</h2>
      <p className="my-4">Use your authorized carrier account.</p>
      <SignInButton><button className="rounded bg-blue-700 px-4 py-2 text-white">Sign in</button></SignInButton>
    </section>}
    {isSignedIn && <>
      {carriers.length > 0 && <label className="mt-8 block">Carrier
        <select className="mt-2 block rounded border p-2" value={carrierId}
          onChange={(event) => setCarrierId(event.target.value)}>
          {carriers.map((carrier) => <option key={carrier.id} value={carrier.id}>{carrier.id}</option>)}
        </select>
      </label>}
      {loading && <p role="status" className="mt-6">Loading fleet…</p>}
      {error && <p role="alert" className="mt-6 text-red-700">{error}</p>}
      {!loading && !error && carrierId && <section className="mt-8">
        <h2 className="text-xl font-semibold">Vehicles</h2>
        {vehicles.length === 0 ? <p className="mt-4">No vehicles in this carrier.</p> :
          <ul className="mt-4 space-y-3">{vehicles.map((vehicle) =>
            <li className="rounded-lg border p-4" key={vehicle.id}>
              <strong>{vehicle.unit_number}</strong> · {vehicle.make} {vehicle.model} · {vehicle.model_year}
            </li>)}</ul>}
      </section>}
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
