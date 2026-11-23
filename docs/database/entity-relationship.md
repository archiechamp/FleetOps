# Physical ERD atlas

Each domain diagram contains all local physical tables and columns, plus external parent stubs. FK edges point child → parent. `0..1` on parent side means nullable FK, otherwise `1`; child side `0..1` for unique FK and `0..*` otherwise. All relationships are derived from actual generated keys. Links are SVG plus editable DOT source. Polymorphic references are deliberately not drawn as foreign keys.

- **ai** (13 tables): [SVG](erd/ai.svg) · [DOT](erd/ai.dot)
- **audit** (5 tables): [SVG](erd/audit.svg) · [DOT](erd/audit.dot)
- **compliance** (14 tables): [SVG](erd/compliance.svg) · [DOT](erd/compliance.dot)
- **core** (6 tables): [SVG](erd/core.svg) · [DOT](erd/core.dot)
- **crm** (6 tables): [SVG](erd/crm.svg) · [DOT](erd/crm.dot)
- **docs** (11 tables): [SVG](erd/docs.svg) · [DOT](erd/docs.dot)
- **fin** (16 tables): [SVG](erd/fin.svg) · [DOT](erd/fin.dot)
- **fleet** (9 tables): [SVG](erd/fleet.svg) · [DOT](erd/fleet.dot)
- **fuel** (7 tables): [SVG](erd/fuel.svg) · [DOT](erd/fuel.dot)
- **gps** (9 tables): [SVG](erd/gps.svg) · [DOT](erd/gps.dot)
- **hr** (9 tables): [SVG](erd/hr.svg) · [DOT](erd/hr.dot)
- **iam** (9 tables): [SVG](erd/iam.svg) · [DOT](erd/iam.dot)
- **integration** (11 tables): [SVG](erd/integration.svg) · [DOT](erd/integration.dot)
- **mnt** (13 tables): [SVG](erd/mnt.svg) · [DOT](erd/mnt.dot)
- **notify** (8 tables): [SVG](erd/notify.svg) · [DOT](erd/notify.dot)
- **ops** (15 tables): [SVG](erd/ops.svg) · [DOT](erd/ops.dot)
- **ref** (13 tables): [SVG](erd/ref.svg) · [DOT](erd/ref.dot)

## Foundation overview

[SVG diagram](erd/foundation-overview.svg) · [DOT source](erd/foundation-overview.dot). This overview omits common actor FK edges; individual domain diagrams contain the complete relationship detail.
