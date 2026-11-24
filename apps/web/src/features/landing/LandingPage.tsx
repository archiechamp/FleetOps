type LandingPageProps = {
  onExplore: () => void;
  onTryCopilot: (question: string) => void;
};

const prompts = [
  "Which trucks need service?",
  "What equipment is available?",
  "Where was DEMO-101 last seen?",
];

const features = [
  { number: "01", title: "xFleet inventory", detail: "Keep trucks and trailers, ownership, mileage, and operating status in one view." },
  { number: "02", title: "Dispatch availability", detail: "Reserve equipment for a trip window and see conflicts before assigning it." },
  { number: "03", title: "Maintenance & GPS", detail: "Track service due dates and clearly labeled last-known vehicle positions." },
  { number: "04", title: "Costs & reports", detail: "Review recorded expenses and fleet trends with explicit data limits." },
];

export function LandingPage({ onExplore, onTryCopilot }: LandingPageProps) {
  return <main id="main-content" className="min-h-screen bg-[#f5f7fb] text-slate-900">
    <div className="bg-[#0a1630] text-white">
      <div className="mx-auto max-w-7xl px-6 lg:px-10">
        <header className="flex items-center justify-between gap-4 border-b border-white/15 py-6">
          <a href="#main-content" className="flex items-center gap-3 text-lg font-black tracking-tight" aria-label="FleetOps home">
            <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-500 text-xl">F</span>
            FleetOps
          </a>
          <nav aria-label="Landing navigation" className="flex items-center gap-3 sm:gap-6">
            <a href="#features" className="hidden text-sm text-slate-200 hover:text-white sm:inline">Features</a>
            <a href="#copilot" className="hidden text-sm text-slate-200 hover:text-white sm:inline">AI Fleet</a>
            <button type="button" onClick={onExplore} className="rounded-lg border border-white/30 px-4 py-2 text-sm font-semibold hover:bg-white/10">Enter demo</button>
          </nav>
        </header>

        <section className="grid items-center gap-12 py-16 lg:grid-cols-[1.05fr_0.95fr] lg:py-24">
          <div>
            <p className="mb-5 inline-flex rounded-full border border-blue-300/30 bg-blue-400/10 px-3 py-1 text-xs font-bold uppercase tracking-[0.2em] text-blue-200">Local operations demo</p>
            <h1 className="max-w-3xl text-5xl font-black leading-[1.08] tracking-tight sm:text-6xl">Know your fleet.<br /><span className="text-blue-400">Move with clarity.</span></h1>
            <p className="mt-6 max-w-xl text-lg leading-8 text-slate-300">Explore fleet inventory, dispatch availability, maintenance, last-known GPS, operating costs, and source-linked AI answers in one workspace.</p>
            <div className="mt-9 flex flex-wrap gap-3">
              <button type="button" onClick={onExplore} className="rounded-xl bg-blue-500 px-6 py-3 font-bold text-white shadow-lg shadow-blue-950/40 hover:bg-blue-400">Explore the demo <span aria-hidden="true">→</span></button>
              <button type="button" onClick={() => onTryCopilot("")} className="rounded-xl border border-white/30 px-6 py-3 font-bold hover:bg-white/10">Try AI Fleet</button>
            </div>
            <p className="mt-5 text-sm text-slate-400">Fictional demo records · Sign-in required · Not a live carrier system</p>
          </div>

          <div id="copilot" className="rounded-[2rem] border border-white/15 bg-white/10 p-3 shadow-2xl shadow-black/30 backdrop-blur-sm">
            <div className="rounded-[1.5rem] bg-white p-6 text-slate-900 sm:p-7">
              <div className="flex items-start justify-between gap-4">
                <div><p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-700">AI Fleet</p><h2 className="mt-2 text-2xl font-bold">Ask about your operation.</h2></div>
                <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-800">Read only</span>
              </div>
              <p className="mt-3 text-sm leading-6 text-slate-600">Choose a question to carry into the authenticated demo. Answers use permitted database records and show source references.</p>
              <div className="mt-6 space-y-2" aria-label="Example AI Fleet questions">
                {prompts.map((prompt) => <button key={prompt} type="button" onClick={() => onTryCopilot(prompt)} className="flex w-full items-center justify-between gap-4 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-left text-sm font-medium text-slate-800 hover:border-blue-300 hover:bg-blue-50 focus-visible:outline-2 focus-visible:outline-blue-700">
                  <span>{prompt}</span><span aria-hidden="true" className="text-blue-700">↗</span>
                </button>)}
              </div>
              <div className="mt-6 flex items-center gap-3 border-t border-slate-200 pt-5 text-xs text-slate-500"><span className="h-2 w-2 rounded-full bg-blue-500" />The AI cannot assign, pay, or change records.</div>
            </div>
          </div>
        </section>
      </div>
    </div>

    <section id="features" className="mx-auto max-w-7xl px-6 py-20 lg:px-10">
      <div className="max-w-2xl"><p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-700">Built around daily decisions</p><h2 className="mt-3 text-3xl font-black tracking-tight sm:text-4xl">A connected view of your operation</h2><p className="mt-4 text-slate-600">The demo brings essential equipment, activity, and recorded cost information together without presenting stale positions or incomplete financials as final answers.</p></div>
      <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {features.map((feature) => <article key={feature.number} className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"><span className="text-sm font-black text-blue-600">{feature.number}</span><h3 className="mt-6 text-lg font-bold">{feature.title}</h3><p className="mt-3 text-sm leading-6 text-slate-600">{feature.detail}</p></article>)}
      </div>
    </section>

    <section className="mx-auto max-w-7xl px-6 pb-20 lg:px-10">
      <div className="flex flex-col items-start justify-between gap-6 rounded-3xl bg-blue-700 p-8 text-white sm:p-10 lg:flex-row lg:items-center">
        <div><h2 className="text-3xl font-black">Take the demo for a drive.</h2><p className="mt-2 max-w-xl text-blue-100">Sign in with a local demo account to explore workflows and ask AI Fleet about fictional carrier records.</p></div>
        <button type="button" onClick={onExplore} className="shrink-0 rounded-xl bg-white px-6 py-3 font-bold text-blue-800 hover:bg-blue-50">Enter the demo <span aria-hidden="true">→</span></button>
      </div>
    </section>
    <footer className="border-t border-slate-200 px-6 py-7 text-center text-sm text-slate-500">FleetOps · Local evaluation demo · No live carrier data</footer>
  </main>;
}
