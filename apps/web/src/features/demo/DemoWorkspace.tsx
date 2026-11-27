import { useEffect, useState, type FormEvent, type ReactNode } from "react";

export type DemoView = "Overview" | "Fleet" | "Dispatch" | "GPS" | "Maintenance" | "Documents" | "Costs" | "Reports";

type Asset = {
  id: string; unit_number: string; asset_type: "TRACTOR" | "TRAILER";
  make: string; model: string; model_year: number; ownership_type: string;
  status: string; terminal: string | null; odometer_miles: number | null;
  service_due_date: string | null; service_due_miles: number | null;
  service_note: string | null; gps_latitude: number | null;
  gps_longitude: number | null; gps_source: string | null;
  gps_observed_at: string | null; gps_received_at: string | null;
};
type Assignment = {
  id: string; trip_reference: string; truck_asset_id: string; trailer_asset_id: string | null;
  truck_unit: string; trailer_unit: string | null; starts_at: string; ends_at: string;
};
type Document = { id: string; asset_id: string; unit_number: string; kind: string; expires_on: string | null; file_name: string; uploaded_at: string };
type Cost = { id: string; asset_id: string; unit_number: string; trip_reference: string | null; category: string; amount_usd: string; occurred_on: string };
type Report = { equipment: { asset_type: "TRACTOR" | "TRAILER"; status: string; asset_count: number }[];
  currency: "USD"; mileage_basis: string; cost_completeness: string; recorded_cost_total: string | null };

const inputClass = "mt-1 w-full rounded-lg border border-slate-300 bg-white p-2 text-slate-900 focus-visible:outline-2 focus-visible:outline-blue-700";
const buttonClass = "rounded-lg bg-blue-700 px-4 py-2 font-semibold text-white hover:bg-blue-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-700 disabled:opacity-50";

type TokenGetter = () => Promise<string | null>;

async function request<T>(path: string, carrierId: string, options: RequestInit = {}, getToken?: TokenGetter): Promise<T> {
  const token = getToken ? await getToken() : null;
  const response = await fetch(`/api/v1/${getToken ? "pilot" : "demo"}${path}`, {
    ...options,
    headers: { "Content-Type": "application/json", ...(getToken ? { Authorization: `Bearer ${token ?? ""}` } : { "X-Demo-Request": "fleetops-ui" }), "X-Tenant-Id": carrierId, ...options.headers },
  });
  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as { detail?: string | { msg: string }[] };
    const detail = Array.isArray(body.detail) ? body.detail.map((item) => item.msg).join("; ") : body.detail;
    throw new Error(detail || `Request failed (${response.status})`);
  }
  return (await response.json()) as T;
}

function timestamp(value: string): Date {
  return new Date(/(?:Z|[+-]\d{2}:?\d{2})$/i.test(value) ? value : `${value}Z`);
}

function utc(value: string | null): string {
  if (!value) return "Unknown";
  return timestamp(value).toLocaleString(undefined, { timeZone: "UTC", timeZoneName: "short" });
}

function freshness(value: string | null): string {
  if (!value) return "No position";
  const age = Date.now() - timestamp(value).getTime();
  return age > 60 * 60 * 1000 ? "Stale" : "Recent";
}

function cents(amount: string): number {
  const [whole, fraction = ""] = amount.split(".");
  return Number(whole) * 100 + Number(fraction.padEnd(2, "0").slice(0, 2));
}

function csvCell(value: string | number | null): string {
  const raw = String(value ?? "");
  const safe = /^[\s]*[=+\-@]/.test(raw) ? `'${raw}` : raw;
  return `"${safe.replaceAll('"', '""')}"`;
}

function downloadCsv(name: string, rows: (string | number | null)[][]) {
  const csv = rows.map((row) => row.map(csvCell).join(",")).join("\r\n") + "\r\n";
  const url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
  const link = document.createElement("a");
  link.href = url; link.download = name; link.click();
  window.setTimeout(() => URL.revokeObjectURL(url), 60_000);
}

function Panel({ title, children }: { title: string; children: ReactNode }) {
  return <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><h2 className="text-xl font-semibold">{title}</h2><div className="mt-4">{children}</div></section>;
}

function BarChart({ title, rows }: { title: string; rows: { label: string; value: number }[] }) {
  const max = Math.max(1, ...rows.map((row) => row.value));
  return <figure className="rounded-xl border border-slate-200 p-4" aria-label={title}>
    <figcaption className="mb-4 font-semibold">{title}</figcaption>
    <div className="space-y-3">{rows.map((row) => <div key={row.label}>
      <div className="mb-1 flex justify-between text-sm"><span>{row.label}</span><strong>{row.value}</strong></div>
      <div className="h-3 rounded-full bg-slate-100"><div className="h-3 rounded-full bg-blue-600" style={{ width: `${(row.value / max) * 100}%` }} /></div>
    </div>)}</div>
  </figure>;
}

async function fileBase64(file: File): Promise<string> {
  const bytes = new Uint8Array(await file.arrayBuffer());
  let binary = "";
  for (let index = 0; index < bytes.length; index += 8192)
    binary += String.fromCharCode(...bytes.slice(index, index + 8192));
  return btoa(binary);
}

export function DemoWorkspace({ view, carrierId, canCreate, canFinance, getToken,
  canReadDocuments = canCreate, canWriteDocuments = canCreate,
  canReadFinance = canFinance, canWriteFinance = canFinance }: {
  view: DemoView; carrierId: string; canCreate: boolean; canFinance: boolean;
  getToken?: TokenGetter; canReadDocuments?: boolean; canWriteDocuments?: boolean;
  canReadFinance?: boolean; canWriteFinance?: boolean;
}) {
  const [assets, setAssets] = useState<Asset[]>([]);
  const [assignments, setAssignments] = useState<Assignment[]>([]);
  const [documents, setDocuments] = useState<Document[]>([]);
  const [costs, setCosts] = useState<Cost[]>([]);
  const [report, setReport] = useState<Report | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [assetId, setAssetId] = useState("");
  const [status, setStatus] = useState("MAINTENANCE");
  const [kind, setKind] = useState("REGISTRATION");
  const [category, setCategory] = useState("FUEL");
  const [reportStatus, setReportStatus] = useState("ALL");
  const [reportFrom, setReportFrom] = useState("");
  const [reportTo, setReportTo] = useState("");
  const [file, setFile] = useState<File | null>(null);

  async function load(signal?: AbortSignal) {
    const data = await Promise.all([
      request<Asset[]>("/assets", carrierId, { signal }, getToken),
      request<Assignment[]>("/assignments", carrierId, { signal }, getToken),
      canReadDocuments ? request<Document[]>("/documents", carrierId, { signal }, getToken) : Promise.resolve([]),
      canReadFinance ? request<Cost[]>("/costs", carrierId, { signal }, getToken) : Promise.resolve([]),
      getToken ? request<Report>("/reports", carrierId, { signal }, getToken) : Promise.resolve(null),
    ]);
    if (signal?.aborted) return;
    setAssets(data[0]); setAssignments(data[1]); setDocuments(data[2]); setCosts(data[3]); setReport(data[4]);
    setAssetId((current) => current && data[0].some((asset) => asset.id === current) ? current : data[0][0]?.id ?? "");
  }

  useEffect(() => {
    const controller = new AbortController();
    load(controller.signal).catch((reason: unknown) => {
      if (!controller.signal.aborted) setError(reason instanceof Error ? reason.message : "Could not load demo data");
    }).finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [carrierId, canCreate, canReadDocuments, canReadFinance, getToken]);

  async function submit(path: string, body: object, method = "POST") {
    setBusy(true); setError(""); setNotice("");
    try {
      await request(path, carrierId, { method, body: JSON.stringify(body) }, getToken);
      await load();
      setNotice("Saved to this demo carrier.");
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Save failed");
    } finally { setBusy(false); }
  }

  async function downloadDocument(id: string, fileName: string) {
    setError("");
    try {
      const token = getToken ? await getToken() : null;
      const response = await fetch(`/api/v1/${getToken ? "pilot" : "demo"}/documents/${id}/file`, {
        headers: { "X-Tenant-Id": carrierId, ...(getToken ? { Authorization: `Bearer ${token ?? ""}` } : {}) },
      });
      if (!response.ok) throw new Error(`Could not open document (${response.status})`);
      const url = URL.createObjectURL(await response.blob());
      const link = document.createElement("a");
      link.href = url; link.download = fileName; link.click();
      window.setTimeout(() => URL.revokeObjectURL(url), 60_000);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Could not open document");
    }
  }

  const trucks = assets.filter((asset) => asset.asset_type === "TRACTOR");
  const trailers = assets.filter((asset) => asset.asset_type === "TRAILER");
  const selected = assets.find((asset) => asset.id === assetId);
  const activeAssignments = assignments.filter((item) => timestamp(item.ends_at).getTime() > Date.now());
  const currentAssignments = activeAssignments.filter((item) => timestamp(item.starts_at).getTime() <= Date.now());
  const available = assets.filter((asset) => asset.status === "AVAILABLE" && !currentAssignments.some((item) => item.truck_asset_id === asset.id || item.trailer_asset_id === asset.id)).length;
  const serviceDue = trucks.filter((asset) => asset.service_due_date && asset.service_due_date <= new Date().toISOString().slice(0, 10)
    || asset.service_due_miles != null && asset.odometer_miles != null && asset.odometer_miles >= asset.service_due_miles).length;
  const totalCostCents = report?.recorded_cost_total != null ? cents(report.recorded_cost_total) : costs.reduce((sum, cost) => sum + cents(cost.amount_usd), 0);
  const money = (value: number) => value.toLocaleString("en-US", { style: "currency", currency: "USD" });
  const statuses = ["AVAILABLE", "ASSIGNED", "IN_TRANSIT", "MAINTENANCE", "OUT_OF_SERVICE", "INACTIVE"].map((label) => ({ label,
    value: report ? report.equipment.filter((row) => row.status === label).reduce((sum, row) => sum + row.asset_count, 0)
      : assets.filter((asset) => asset.status === label).length }));
  const costBars = ["FUEL", "MAINTENANCE", "TOLLS", "OTHER"].map((label) => ({ label, value: costs.filter((cost) => cost.category === label).reduce((sum, cost) => sum + cents(cost.amount_usd), 0) / 100 }));
  const reportAssets = assets.filter((asset) => reportStatus === "ALL" || asset.status === reportStatus);
  const reportCosts = costs.filter((cost) => (!reportFrom || cost.occurred_on >= reportFrom) && (!reportTo || cost.occurred_on <= reportTo));
  const reportTotalCents = !reportFrom && !reportTo ? totalCostCents : reportCosts.reduce((sum, cost) => sum + cents(cost.amount_usd), 0);
  const reportEquipment = report ? report.equipment.filter((row) => reportStatus === "ALL" || row.status === reportStatus) : null;
  const reportCostBars = costBars.map((row) => ({ label: row.label, value: reportCosts.filter((cost) => cost.category === row.label).reduce((sum, cost) => sum + cents(cost.amount_usd), 0) / 100 }));

  if (loading) return <p role="status">Loading demo {view.toLowerCase()}…</p>;

  return <div className="space-y-6">
    {error && <p role="alert" className="rounded-lg border border-red-200 bg-red-50 p-3 text-red-800">{error}</p>}
    {notice && <p role="status" className="rounded-lg border border-green-200 bg-green-50 p-3 text-green-800">{notice}</p>}

    {view === "Fleet" && <div className="grid gap-6 lg:grid-cols-2">
      <Panel title="Fleet inventory">
        {assets.length === 0 ? <p>No equipment registered.</p> : <ul className="divide-y divide-slate-200">{assets.map((asset) =>
          <li key={asset.id} className="py-3"><strong>{asset.unit_number}</strong> · {asset.asset_type === "TRACTOR" ? "Truck" : "Trailer"} · {asset.status}<br />
            <span className="text-sm text-slate-600">{asset.model_year} {asset.make} {asset.model} · {asset.ownership_type} · {asset.terminal ?? "No terminal"} · {asset.odometer_miles == null ? "Odometer unknown" : `${asset.odometer_miles} mi`}</span></li>)}</ul>}
      </Panel>
      <Panel title="Register a trailer">
        {canCreate ? <form className="grid gap-3" onSubmit={(event) => {
          event.preventDefault(); const data = new FormData(event.currentTarget);
          void submit("/trailers", { unit_number: data.get("unit"), make: data.get("make"), model: data.get("model"),
            model_year: Number(data.get("year")), ownership_type: data.get("ownership") });
        }}>
          <label>Unit number<input className={inputClass} name="unit" maxLength={30} required /></label>
          <label>Make<input className={inputClass} name="make" maxLength={80} required /></label>
          <label>Model<input className={inputClass} name="model" maxLength={80} required /></label>
          <label>Model year<input className={inputClass} name="year" type="number" min="1900" max="2100" required /></label>
          <label>Ownership<select className={inputClass} name="ownership"><option value="OWNED">Owned</option><option value="LEASED">Leased</option><option value="CONTRACTED">Contracted</option></select></label>
          <button className={buttonClass} disabled={busy}>Register trailer</button>
        </form> : <p>Read-only account. Trailer registration requires creator access.</p>}
      </Panel>
    </div>}

    {view === "Overview" && <>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[ ["Trucks", report ? report.equipment.filter((row) => row.asset_type === "TRACTOR").reduce((sum, row) => sum + row.asset_count, 0) : trucks.length],
          ["Trailers", report ? report.equipment.filter((row) => row.asset_type === "TRAILER").reduce((sum, row) => sum + row.asset_count, 0) : trailers.length],
          ["Available equipment in view", available], ["Service due in view", serviceDue] ].map(([label, value]) =>
          <div key={label} className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"><p className="text-sm text-slate-600">{label}</p><strong className="mt-2 block text-3xl">{value}</strong></div>)}
      </div>
      <div className="grid gap-6 lg:grid-cols-2"><Panel title="Fleet status"><BarChart title="Equipment by operating status" rows={statuses} /></Panel>
        <Panel title="Dispatch and GPS"><p>{activeAssignments.length} assignment(s) with an end time in the future.</p>
          <p className="mt-2">{trucks.filter((asset) => freshness(asset.gps_observed_at) === "Stale").length} truck(s) have stale last known positions.</p>
          <p className="mt-4 text-sm text-slate-600">GPS records here are fictional or manually entered observations, not live tracking.</p></Panel></div>
    </>}

    {view === "Dispatch" && <div className="grid gap-6 lg:grid-cols-2">
      <Panel title="Equipment assignments">
        {assignments.length === 0 ? <p>No trips assigned for this carrier.</p> : <ul className="divide-y divide-slate-200">{assignments.map((item) =>
          <li key={item.id} className="py-3"><strong>{item.trip_reference}</strong> · {item.truck_unit}{item.trailer_unit ? ` + ${item.trailer_unit}` : ""}<br />
            <span className="text-sm text-slate-600">{utc(item.starts_at)} to {utc(item.ends_at)}</span></li>)}</ul>}
      </Panel>
      <Panel title={getToken ? "Assign equipment to a fictional trip" : "Assign equipment to a demo trip"}>
        {canCreate ? <form className="grid gap-3" onSubmit={(event: FormEvent<HTMLFormElement>) => {
          event.preventDefault(); const data = new FormData(event.currentTarget);
          void submit("/assignments", { trip_reference: String(data.get("trip_reference")), truck_asset_id: data.get("truck"),
            trailer_asset_id: data.get("trailer") || null, starts_at: new Date(String(data.get("starts_at"))).toISOString(),
            ends_at: new Date(String(data.get("ends_at"))).toISOString() });
        }}>
          <label>Trip reference<input className={inputClass} name="trip_reference" maxLength={40} required placeholder="DEMO-TRIP-1" /></label>
          <label>Truck<select className={inputClass} name="truck" required>{trucks.map((asset) => <option key={asset.id} value={asset.id}>{asset.unit_number} · {asset.status}</option>)}</select></label>
          <label>Trailer (optional)<select className={inputClass} name="trailer"><option value="">None</option>{trailers.map((asset) => <option key={asset.id} value={asset.id}>{asset.unit_number} · {asset.status}</option>)}</select></label>
          <label>Start (your local time)<input className={inputClass} name="starts_at" type="datetime-local" required /></label>
          <label>End (your local time)<input className={inputClass} name="ends_at" type="datetime-local" required /></label>
          <button className={buttonClass} disabled={busy || trucks.length === 0}>Assign equipment</button>
          <p className="text-sm text-slate-600">Time windows are stored in UTC. This demo assigns equipment to a reference, without driver or HOS validation.</p>
        </form> : <p>Read-only account. Assignment requires creator access.</p>}
      </Panel>
    </div>}

    {view === "GPS" && <div className="grid gap-6 lg:grid-cols-2">
      <Panel title="Last known truck positions">
        {trucks.length === 0 ? <p>No trucks registered.</p> : <ul className="divide-y divide-slate-200">{trucks.map((asset) =>
          <li key={asset.id} className="py-3"><strong>{asset.unit_number}</strong> · <span className={freshness(asset.gps_observed_at) === "Stale" ? "font-semibold text-amber-700" : "font-semibold"}>{freshness(asset.gps_observed_at)}</span>
            <br /><span className="text-sm">Observed {utc(asset.gps_observed_at)} · Received {utc(asset.gps_received_at)}</span>
            {asset.gps_latitude != null && <p className="text-sm text-slate-600">{asset.gps_latitude}, {asset.gps_longitude} · {asset.gps_source}</p>}</li>)}</ul>}
      </Panel>
      <Panel title="Record a demo position">
        {canCreate ? <form className="grid gap-3" onSubmit={(event) => {
          event.preventDefault(); const data = new FormData(event.currentTarget);
          void submit(`/assets/${data.get("asset")}/position`, { latitude: Number(data.get("latitude")), longitude: Number(data.get("longitude")),
            observed_at: new Date(String(data.get("observed_at"))).toISOString(), source: "Manual demo entry" });
        }}>
          <label>Truck<select className={inputClass} name="asset">{trucks.map((asset) => <option key={asset.id} value={asset.id}>{asset.unit_number}</option>)}</select></label>
          <label>Latitude<input className={inputClass} name="latitude" type="number" min="-90" max="90" step="0.000001" required /></label>
          <label>Longitude<input className={inputClass} name="longitude" type="number" min="-180" max="180" step="0.000001" required /></label>
          <label>Observed (your local time)<input className={inputClass} name="observed_at" type="datetime-local" required /></label>
          <button className={buttonClass} disabled={busy || trucks.length === 0}>Save position</button>
          <p className="text-sm text-slate-600">Older observations leave the latest known position unchanged. No live telematics provider is connected.</p>
        </form> : <p>Read-only account.</p>}
      </Panel>
    </div>}

    {view === "Maintenance" && <div className="grid gap-6 lg:grid-cols-2">
      <Panel title="Service schedule and status">
        {assets.length === 0 ? <p>No equipment registered.</p> : <ul className="divide-y divide-slate-200">{assets.map((asset) =>
          <li key={asset.id} className="py-3"><strong>{asset.unit_number}</strong> · {asset.status}<br />
            <span className="text-sm text-slate-600">Odometer: {asset.odometer_miles == null ? "Unknown" : `${asset.odometer_miles} mi`} · Due: {asset.service_due_date ?? "No date"} / {asset.service_due_miles == null ? "No mileage" : `${asset.service_due_miles} mi`}</span>
            {asset.service_note && <p className="text-sm">{asset.service_note}</p>}</li>)}</ul>}
      </Panel>
      <Panel title="Update equipment service">
        {canCreate ? <form className="grid gap-3" onSubmit={(event) => {
          event.preventDefault(); const data = new FormData(event.currentTarget);
          const body: Record<string, string | number | null> = {
            odometer_miles: data.get("odometer") ? Number(data.get("odometer")) : null,
            service_due_date: data.get("due_date") ? String(data.get("due_date")) : null,
            service_due_miles: data.get("due_miles") ? Number(data.get("due_miles")) : null,
            service_note: String(data.get("note") || ""), status,
          };
          void submit(`/assets/${assetId}`, body, "PATCH");
        }}>
          <label>Equipment<select className={inputClass} value={assetId} onChange={(event) => setAssetId(event.target.value)}>{assets.map((asset) => <option key={asset.id} value={asset.id}>{asset.unit_number}</option>)}</select></label>
          <label>Odometer (miles)<input className={inputClass} name="odometer" type="number" min="0" step="0.1" defaultValue={selected?.odometer_miles ?? ""} key={`${assetId}:odo`} /></label>
          <label>Service due date<input className={inputClass} name="due_date" type="date" defaultValue={selected?.service_due_date ?? ""} key={`${assetId}:date`} /></label>
          <label>Service due odometer (miles)<input className={inputClass} name="due_miles" type="number" min="0" step="0.1" defaultValue={selected?.service_due_miles ?? ""} key={`${assetId}:miles`} /></label>
          <label>Operating status<select className={inputClass} value={status} onChange={(event) => setStatus(event.target.value)}><option value="MAINTENANCE">Maintenance</option><option value="OUT_OF_SERVICE">Out of service</option><option value="AVAILABLE">Available / release</option><option value="INACTIVE">Inactive</option></select></label>
          <label>Service or release note<textarea className={inputClass} name="note" maxLength={300} required /></label>
          <button className={buttonClass} disabled={busy || !assetId}>Save service update</button>
          <p className="text-sm text-slate-600">An active assignment blocks a restriction. Release requires a note; this demo does not certify inspection or compliance.</p>
        </form> : <p>Read-only account.</p>}
      </Panel>
    </div>}

    {view === "Documents" && <div className="grid gap-6 lg:grid-cols-2">
      <Panel title="Registration and insurance records">
        {!canReadDocuments ? <p>Document access is restricted.</p> : documents.length === 0 ? <p>No documents uploaded for this carrier.</p> :
          <ul className="divide-y divide-slate-200">{documents.map((item) => <li key={item.id} className="py-3">
            <strong>{item.unit_number}</strong> · {item.kind}<br /><span className="text-sm">Expires {item.expires_on ?? "not recorded"} · {item.file_name}</span><br />
            <button type="button" className="font-semibold text-blue-700 underline" onClick={() => { void downloadDocument(item.id, item.file_name); }}>Download private file</button>
          </li>)}</ul>}
      </Panel>
      <Panel title="Upload a demo document">
        {canWriteDocuments ? <form className="grid gap-3" onSubmit={async (event) => {
          event.preventDefault(); if (!file) return;
          const data = new FormData(event.currentTarget);
          if (file.size > 1024 * 1024) { setError("File must be 1 MB or smaller"); return; }
          await submit("/documents", { asset_id: data.get("asset"), kind, expires_on: data.get("expires") || null,
            file_name: file.name, content_type: file.type, content_base64: await fileBase64(file) });
          setFile(null);
        }}>
          <label>Equipment<select className={inputClass} name="asset">{assets.map((asset) => <option key={asset.id} value={asset.id}>{asset.unit_number}</option>)}</select></label>
          <label>Document type<select className={inputClass} value={kind} onChange={(event) => setKind(event.target.value)}><option value="REGISTRATION">Registration</option><option value="INSURANCE">Insurance</option></select></label>
          <label>Expiration date<input className={inputClass} name="expires" type="date" /></label>
          <label>Private file (PDF, PNG or JPEG; 1 MB maximum)<input className={inputClass} type="file" accept=".pdf,.png,.jpg,.jpeg" required onChange={(event) => setFile(event.target.files?.[0] ?? null)} /></label>
          <button className={buttonClass} disabled={busy || !file || assets.length === 0}>Upload document</button>
          <p className="text-sm text-slate-600">Files are restricted to authorized carrier members. No malware scan or production document review is provided.</p>
        </form> : <p>Read-only account.</p>}
      </Panel>
    </div>}

    {view === "Costs" && <div className="grid gap-6 lg:grid-cols-2">
      <Panel title="Recorded operating costs">
        {!canReadFinance ? <p>Finance access is restricted.</p> : <><p className="mb-3 text-2xl font-bold">{money(totalCostCents / 100)} <span className="text-sm font-normal text-slate-600">recorded USD costs{report ? " for this carrier" : " in view"}</span></p>
          {costs.length === 0 ? <p>No costs recorded.</p> : <ul className="divide-y divide-slate-200">{costs.map((item) => <li key={item.id} className="py-2">
            <strong>{money(cents(item.amount_usd) / 100)}</strong> · {item.category} · {item.unit_number}<br /><span className="text-sm text-slate-600">{item.occurred_on}{item.trip_reference ? ` · ${item.trip_reference}` : ""}</span>
          </li>)}</ul>}
          <p className="mt-4 text-sm text-slate-600">Coverage is unknown; missing expenses are not zero. These costs are not net profit.</p></>}
      </Panel>
      <Panel title={getToken ? "Add a fictional staging expense" : "Add a demo expense"}>
        {canWriteFinance ? <form className="grid gap-3" onSubmit={(event) => {
          event.preventDefault(); const data = new FormData(event.currentTarget);
          void submit("/costs", { asset_id: data.get("asset"), trip_reference: data.get("trip") || null,
            category, amount_usd: String(data.get("amount")), occurred_on: data.get("date") });
        }}>
          <label>Equipment<select className={inputClass} name="asset">{assets.map((asset) => <option key={asset.id} value={asset.id}>{asset.unit_number}</option>)}</select></label>
          <label>Trip (optional)<select className={inputClass} name="trip"><option value="">No trip</option>{assignments.map((item) => <option key={item.id} value={item.trip_reference}>{item.trip_reference}</option>)}</select></label>
          <label>Category<select className={inputClass} value={category} onChange={(event) => setCategory(event.target.value)}>{["FUEL", "MAINTENANCE", "TOLLS", "OTHER"].map((item) => <option key={item}>{item}</option>)}</select></label>
          <label>Amount (USD)<input className={inputClass} name="amount" type="number" min="0.01" step="0.01" required /></label>
          <label>Occurred on<input className={inputClass} name="date" type="date" required /></label>
          <button className={buttonClass} disabled={busy || assets.length === 0}>Record expense</button>
        </form> : <p>Finance access is restricted.</p>}
      </Panel>
    </div>}

    {view === "Reports" && <>
      <Panel title="Fleet report"><div className="mb-4 flex flex-wrap items-end gap-3">
        <label>Status filter<select className={inputClass} value={reportStatus} onChange={(event) => setReportStatus(event.target.value)}><option value="ALL">All statuses</option>{statuses.map((item) => <option key={item.label}>{item.label}</option>)}</select></label>
        <button className={buttonClass} onClick={() => downloadCsv(getToken ? "fleet-staging-inventory.csv" : "fleet-demo-inventory.csv", [
          ["Carrier ID", "Unit", "Type", "Status", "Ownership", "Terminal", "Odometer miles"],
          ...reportAssets.map((asset) => [carrierId, asset.unit_number, asset.asset_type, asset.status, asset.ownership_type, asset.terminal, asset.odometer_miles]),
        ])}>Export filtered fleet CSV</button>
      </div><div className="grid gap-6 lg:grid-cols-2">
        <BarChart title="Equipment by type" rows={[{ label: "Trucks", value: reportEquipment ? reportEquipment.filter((row) => row.asset_type === "TRACTOR").reduce((sum, row) => sum + row.asset_count, 0) : reportAssets.filter((asset) => asset.asset_type === "TRACTOR").length }, { label: "Trailers", value: reportEquipment ? reportEquipment.filter((row) => row.asset_type === "TRAILER").reduce((sum, row) => sum + row.asset_count, 0) : reportAssets.filter((asset) => asset.asset_type === "TRAILER").length }]} />
        <BarChart title="Equipment by status" rows={statuses.map((row) => ({ label: row.label, value: reportEquipment ? reportEquipment.filter((item) => item.status === row.label).reduce((sum, item) => sum + item.asset_count, 0) : reportAssets.filter((asset) => asset.status === row.label).length }))} />
      </div><p className="mt-4 text-sm text-slate-600">Current carrier only. Charts use {report ? "server totals" : "saved demo records"}; CSV exports the displayed equipment list, up to 100 rows.</p></Panel>
      {canReadFinance ? <Panel title="Operating cost report"><div className="grid gap-6 lg:grid-cols-2">
        <div className="lg:col-span-2 flex flex-wrap items-end gap-3">
          <label>From date<input className={inputClass} type="date" value={reportFrom} onChange={(event) => setReportFrom(event.target.value)} /></label>
          <label>To date<input className={inputClass} type="date" value={reportTo} onChange={(event) => setReportTo(event.target.value)} /></label>
          <button className={buttonClass} onClick={() => downloadCsv(getToken ? "fleet-staging-costs.csv" : "fleet-demo-costs.csv", [
            ["Carrier ID", "Date", "Unit", "Trip reference", "Category", "Amount USD", "Completeness"],
            ...reportCosts.map((cost) => [carrierId, cost.occurred_on, cost.unit_number, cost.trip_reference, cost.category, cost.amount_usd, "Unknown"]),
          ])}>Export filtered costs CSV</button>
        </div>
        <BarChart title="Recorded USD by category" rows={reportCostBars} />
        <div><p className="text-3xl font-bold">{money(reportTotalCents / 100)}</p><p>{report && !reportFrom && !reportTo ? "Recorded costs for this carrier" : "Recorded costs in displayed date range"}</p>
          {getToken && (reportFrom || reportTo) && <p className="text-sm text-slate-600">Date filtered rows are limited to the latest 200 entries; this is not a full period total.</p>}
          <dl className="mt-4 space-y-2 text-sm"><div><dt className="font-semibold">Mileage basis</dt><dd>Unavailable — no period distance records</dd></div>
            <div><dt className="font-semibold">Cost per mile</dt><dd>Unavailable</dd></div>
            <div><dt className="font-semibold">Data completeness</dt><dd>Unknown — required cost categories are not reconciled</dd></div></dl></div>
      </div></Panel> : <Panel title="Operating cost report"><p>Finance report requires carrier finance access.</p></Panel>}
    </>}
  </div>;
}
