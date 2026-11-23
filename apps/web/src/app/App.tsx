import { useEffect, useRef, useState, type FormEvent } from "react";
import { VehicleRegistrationForm } from "../features/vehicles/VehicleRegistrationForm";
import { DemoWorkspace, type DemoView } from "../features/demo/DemoWorkspace";
import { CopilotPanel } from "../features/ai/CopilotPanel";
import { LandingPage } from "../features/landing/LandingPage";
import type { components } from "../../../../packages/api-contracts/vehicle-openapi";

type Vehicle = components["schemas"]["Vehicle"];
type VehicleCreate = components["schemas"]["VehicleCreate"];
type Carrier = { id: string; name: string; permissions: string[] };
type Me = { username: string; carriers: Carrier[] };

async function api<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(`/api/v1${path}`, {
    ...options,
    headers: { "Content-Type": "application/json", "X-Demo-Request": "fleetops-ui", ...options.headers },
  });
  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as { detail?: string };
    throw new Error(typeof body.detail === "string" ? body.detail : `Request failed (${response.status})`);
  }
  return (await response.json()) as T;
}

export function App() {
  const [me, setMe] = useState<Me | null>(null);
  const [checking, setChecking] = useState(true);
  const [username, setUsername] = useState("demo_creator");
  const [carrierId, setCarrierId] = useState("");
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [selected, setSelected] = useState<Vehicle | null>(null);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [formVersion, setFormVersion] = useState(0);
  const [showForm, setShowForm] = useState(false);
  const [view, setView] = useState<DemoView>("Overview");
  const [chatOpen, setChatOpen] = useState(false);
  const [showLogin, setShowLogin] = useState(false);
  const [entryQuestion, setEntryQuestion] = useState<string | null>(null);
  const openCopilotAfterSignIn = useRef(false);
  const pending = useRef<{ key: string; payload: string } | null>(null);
  const scopeVersion = useRef(0);

  useEffect(() => {
    api<Me>("/me").then((session) => {
      setMe(session);
      setCarrierId(session.carriers[0]?.id ?? "");
    }).catch(() => {}).finally(() => setChecking(false));
  }, []);

  const carrier = me?.carriers.find((item) => item.id === carrierId);
  const canCreate = carrier?.permissions.includes("fleet.vehicle.create") ?? false;

  useEffect(() => {
    if (!carrierId) return;
    const controller = new AbortController();
    const version = ++scopeVersion.current;
    setVehicles([]);
    setSelected(null);
    setSearch("");
    setShowForm(false);
    setView("Overview");
    setChatOpen(openCopilotAfterSignIn.current);
    if (!openCopilotAfterSignIn.current) setEntryQuestion(null);
    openCopilotAfterSignIn.current = false;
    setFormVersion((value) => value + 1);
    pending.current = null;
    setError("");
    setNotice("");
    setLoading(true);
    fetch("/api/v1/vehicles", { headers: { "X-Tenant-Id": carrierId }, signal: controller.signal })
      .then(async (response) => {
        if (!response.ok) throw new Error("Could not load vehicles");
        return (await response.json()) as Vehicle[];
      })
      .then((rows) => { if (version === scopeVersion.current) setVehicles(rows); })
      .catch((reason: unknown) => {
        if (!controller.signal.aborted && version === scopeVersion.current)
          setError(reason instanceof Error ? reason.message : "Could not load vehicles");
      })
      .finally(() => { if (version === scopeVersion.current) setLoading(false); });
    return () => { controller.abort(); scopeVersion.current += 1; };
  }, [carrierId]);

  async function signIn(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    try {
      await api("/demo/login", { method: "POST", body: JSON.stringify({ username }) });
      const session = await api<Me>("/me");
      setMe(session);
      setCarrierId(session.carriers[0]?.id ?? "");
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Sign-in failed");
    }
  }

  async function signOut() {
    try {
      await api("/demo/logout", { method: "POST" });
    } catch {
      setError("Could not sign out. Try again.");
      return;
    }
    scopeVersion.current += 1;
    setMe(null);
    setCarrierId("");
    setVehicles([]);
    setSelected(null);
    setShowForm(false);
    setView("Overview");
    setChatOpen(false);
    setShowLogin(false);
    setEntryQuestion(null);
    openCopilotAfterSignIn.current = false;
    pending.current = null;
    setError("");
    setNotice("");
  }

  async function saveVehicle(value: VehicleCreate) {
    if (!carrierId || saving) return;
    const payload = JSON.stringify(value);
    if (!pending.current || pending.current.payload !== payload)
      pending.current = { key: crypto.randomUUID(), payload };
    const version = scopeVersion.current;
    setSaving(true);
    setError("");
    setNotice("");
    try {
      const created = await api<Vehicle>("/vehicles", {
        method: "POST",
        headers: { "X-Tenant-Id": carrierId, "Idempotency-Key": pending.current.key },
        body: payload,
      });
      if (version !== scopeVersion.current) return;
      setVehicles((current) => [created, ...current.filter((item) => item.id !== created.id)]);
      setSelected(created);
      setShowForm(false);
      setFormVersion((number) => number + 1);
      setNotice(`Registered ${created.unit_number}. Saved ${new Date(created.created_at).toLocaleString(undefined, { timeZoneName: "short" })}.`);
      pending.current = null;
    } catch (reason) {
      if (version === scopeVersion.current)
        setError(reason instanceof Error ? reason.message : "Registration failed");
    } finally {
      if (version === scopeVersion.current) setSaving(false);
    }
  }

  const visible = vehicles.filter((vehicle) =>
    vehicle.unit_number.toLocaleLowerCase().includes(search.trim().toLocaleLowerCase())
  );

  if (!checking && !me && !showLogin) return <LandingPage
    onExplore={() => { setEntryQuestion(null); openCopilotAfterSignIn.current = false; setShowLogin(true); }}
    onTryCopilot={(question) => { setEntryQuestion(question); openCopilotAfterSignIn.current = true; setShowLogin(true); }} />;

  return (
    <main id="main-content" className="mx-auto max-w-6xl p-6 md:p-10">
      <header className="mb-8 flex flex-wrap items-start justify-between gap-4 border-b border-slate-200 pb-6">
        <div>
          <p className="text-sm font-bold uppercase tracking-[0.24em] text-blue-700">FleetOps · Local demo</p>
          <h1 className="mt-2 text-4xl font-bold tracking-tight text-slate-900">Fleet vehicles</h1>
          <p className="mt-2 text-slate-600">Register and inspect trucks for an authorized carrier.</p>
        </div>
        {me && <div className="flex gap-2"><button type="button" className="rounded-lg bg-blue-700 px-4 py-2 font-medium text-white hover:bg-blue-800 focus-visible:outline-2 focus-visible:outline-blue-700" onClick={() => setChatOpen(true)}>Ask Fleet</button>
          <button className="rounded-lg border px-4 py-2 font-medium hover:bg-slate-100 focus-visible:outline-2 focus-visible:outline-blue-700" onClick={signOut}>Sign out</button></div>}
      </header>

      {checking ? <p role="status">Checking demo session…</p> : !me ? (
        <section className="max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <button type="button" className="mb-4 text-sm font-semibold text-blue-700 underline" onClick={() => setShowLogin(false)}>Back to FleetOps</button>
          <h2 className="text-xl font-semibold">Sign in to demo</h2>
          <p className="mt-2 text-sm text-slate-600">Choose a demo account to explore the local FleetOps workspace.</p>
          {error && <p role="alert" className="mt-4 rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800">{error}</p>}
          <form onSubmit={signIn} className="mt-5 grid gap-4">
            <div><label htmlFor="username" className="block font-medium">Account</label>
              <select id="username" className="mt-1 w-full rounded-lg border p-2" value={username} onChange={(event) => setUsername(event.target.value)}>
                <option value="demo_creator">Demo creator</option><option value="demo_reader">Demo reader</option>
              </select></div>
            <button className="rounded-lg bg-blue-700 px-4 py-2 font-semibold text-white hover:bg-blue-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-700">Sign in</button>
          </form>
        </section>
      ) : (
        <>
          <section className="mb-6 flex flex-wrap items-end justify-between gap-4 rounded-2xl bg-slate-900 p-5 text-white">
            <div><label htmlFor="carrier" className="block text-sm font-semibold text-slate-300">Carrier</label>
              <select id="carrier" className="mt-1 min-w-64 rounded-lg bg-white p-2 text-slate-900" value={carrierId} onChange={(event) => setCarrierId(event.target.value)}>
                {me.carriers.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
              </select></div>
            <div className="text-sm text-slate-300">Signed in as <strong className="text-white">{me.username}</strong><br />{canCreate ? "Can register trucks" : "Read-only access"}</div>
          </section>
          {error && <p role="alert" className="mb-4 rounded-lg border border-red-200 bg-red-50 p-3 text-red-800">{error}</p>}
          {notice && <p role="status" className="mb-4 rounded-lg border border-green-200 bg-green-50 p-3 text-green-800">{notice}</p>}
          <nav aria-label="Demo sections" className="mb-6 flex flex-wrap gap-2">
            {(["Overview", "Fleet", "Dispatch", "GPS", "Maintenance", "Documents", "Costs", "Reports"] as DemoView[]).map((item) => (
              <button key={item} type="button" aria-current={view === item ? "page" : undefined}
                className={`rounded-lg px-4 py-2 text-sm font-semibold focus-visible:outline-2 focus-visible:outline-blue-700 ${view === item ? "bg-blue-700 text-white" : "border border-slate-200 bg-white text-slate-700 hover:bg-slate-100"}`}
                onClick={() => setView(item)}>{item}</button>
            ))}
          </nav>
          {chatOpen && carrier && <CopilotPanel key={carrierId} carrierId={carrierId} carrierName={carrier.name}
            canFinance={carrier.permissions.includes("demo.finance.read")}
            initialQuestion={entryQuestion}
            onClose={() => { setChatOpen(false); setEntryQuestion(null); }} onNavigate={(nextView) => { setView(nextView); setChatOpen(false); setEntryQuestion(null); }} />}
          <DemoWorkspace key={`${carrierId}:${view}`} view={view} carrierId={carrierId} canCreate={canCreate} canFinance={carrier?.permissions.includes("demo.finance.read") ?? false} />
          {view === "Fleet" &&
          <div className="grid gap-6 lg:grid-cols-[minmax(0,1.5fr)_minmax(20rem,1fr)]">
            <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="mb-4 flex flex-wrap items-center justify-between gap-3"><h2 className="text-xl font-semibold">Trucks</h2>
                {canCreate && <button className="rounded-lg bg-blue-700 px-4 py-2 font-semibold text-white hover:bg-blue-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-700" onClick={() => { setShowForm(true); setSelected(null); setError(""); }}>Register truck</button>}
              </div>
              <label htmlFor="search" className="block text-sm font-medium">Search unit number</label>
              <input id="search" className="mt-1 w-full rounded-lg border p-2" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="e.g. DEMO-101" />
              {loading ? <p role="status" className="mt-5">Loading trucks…</p> : visible.length === 0 ? <p className="mt-5 text-slate-600">No trucks found for this carrier.</p> : (
                <ul className="mt-4 divide-y divide-slate-200">{visible.map((vehicle) => <li key={vehicle.id}>
                  <button className="w-full py-3 text-left hover:text-blue-700 focus-visible:outline-2 focus-visible:outline-blue-700" onClick={() => { setSelected(vehicle); setShowForm(false); }}>
                    <span className="block font-semibold">{vehicle.unit_number}</span><span className="text-sm text-slate-600">{vehicle.model_year} {vehicle.make} {vehicle.model}</span>
                  </button></li>)}</ul>
              )}
            </section>
            <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              {showForm && canCreate ? <><h2 className="mb-4 text-xl font-semibold">Register a truck</h2><VehicleRegistrationForm key={formVersion} onSubmit={(value) => { void saveVehicle(value); }} />{saving && <p role="status" className="mt-3">Saving truck…</p>}</> : selected ? (
                <><h2 className="text-xl font-semibold">Truck details</h2><dl className="mt-5 grid grid-cols-2 gap-4 text-sm">
                  <div><dt className="text-slate-500">Unit number</dt><dd className="font-semibold">{selected.unit_number}</dd></div>
                  <div><dt className="text-slate-500">Model year</dt><dd>{selected.model_year}</dd></div>
                  <div><dt className="text-slate-500">Make</dt><dd>{selected.make}</dd></div>
                  <div><dt className="text-slate-500">Model</dt><dd>{selected.model}</dd></div>
                  <div><dt className="text-slate-500">Ownership</dt><dd>{selected.ownership_type}</dd></div>
                  <div><dt className="text-slate-500">Created</dt><dd>{new Date(selected.created_at).toLocaleString(undefined, { timeZoneName: "short" })}</dd></div>
                </dl></>
              ) : <><h2 className="text-xl font-semibold">Vehicle details</h2><p className="mt-3 text-slate-600">Select a truck to see its registration details.</p></>}
            </section>
          </div>
          }
        </>
      )}
    </main>
  );
}
