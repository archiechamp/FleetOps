import type { ReactNode } from "react";

export type WorkspaceView = "Overview" | "Fleet" | "Dispatch" | "GPS" | "Maintenance" | "Documents" | "Costs" | "Reports";

const views: WorkspaceView[] = ["Overview", "Fleet", "Dispatch", "GPS", "Maintenance", "Documents", "Costs", "Reports"];

export function WorkspaceHeader({ back, actions, environment, description = "Register and inspect trucks for an authorized carrier." }: {
  back?: () => void; actions?: ReactNode; environment: string; description?: string;
}) {
  return <header className="mb-8 flex flex-wrap items-start justify-between gap-4 border-b border-slate-200 pb-6">
    <div>
      {back && <button type="button" className="mb-3 text-sm font-semibold text-blue-700 underline" onClick={back}>Back to FleetOps</button>}
      <p className="text-sm font-bold uppercase tracking-[0.24em] text-blue-700">FleetOps · {environment}</p>
      <h1 className="mt-2 text-4xl font-bold tracking-tight text-slate-900">Fleet vehicles</h1>
      <p className="mt-2 text-slate-600">{description}</p>
    </div>
    {actions && <div className="flex gap-2">{actions}</div>}
  </header>;
}

export function CarrierBar({ id, carriers, onChange, account, access }: {
  id: string; carriers: { id: string; name: string }[]; onChange: (id: string) => void;
  account: string; access: string;
}) {
  return <section className="mb-6 flex flex-wrap items-end justify-between gap-4 rounded-2xl bg-slate-900 p-5 text-white">
    <div><label htmlFor="carrier" className="block text-sm font-semibold text-slate-300">Carrier</label>
      <select id="carrier" className="mt-1 min-w-64 rounded-lg bg-white p-2 text-slate-900" value={id}
        onChange={(event) => onChange(event.target.value)}>
        {carriers.map((carrier) => <option key={carrier.id} value={carrier.id}>{carrier.name}</option>)}
      </select>
    </div>
    <div className="text-sm text-slate-300">Signed in as <strong className="text-white">{account}</strong><br />{access}</div>
  </section>;
}

export function WorkspaceNav({ view, onChange }: {
  view: WorkspaceView; onChange: (view: WorkspaceView) => void;
}) {
  return <nav aria-label="Fleet workspace sections" className="mb-6 flex flex-wrap gap-2">
    {views.map((item) => <button key={item} type="button" aria-current={view === item ? "page" : undefined}
      className={`rounded-lg px-4 py-2 text-sm font-semibold focus-visible:outline-2 focus-visible:outline-blue-700 ${view === item ? "bg-blue-700 text-white" : "border border-slate-200 bg-white text-slate-700 hover:bg-slate-100"}`}
      onClick={() => onChange(item)}>{item}</button>)}
  </nav>;
}
