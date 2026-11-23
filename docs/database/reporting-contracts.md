# Reporting schema — planned view contracts

`reporting` is the eighteenth schema; no base tables. Views are defined by feature migrations after metric acceptance; this kit deliberately does not emit speculative SQL for aggregate KPIs. Views cannot take parameters; period/interval queries must be implemented through approved service queries or inline TVFs. Always expose tenant_id.

| View | Source tables | Grain and semantics |
|---|---|---|
| `vw_fleet_overview` | fleet.assets, ops.trip_assignments, mnt.maintenance_restrictions | tenant + status; count assets by type, exclude inactive from active denominator |
| `vw_vehicle_availability` | fleet.assets, ops.equipment_reservations, mnt.maintenance_restrictions | tenant + asset; as-of and requested interval via service; not a guarantee |
| `vw_driver_availability` | hr.drivers, hr.driver_availability, ops.driver_reservations | tenant + driver; availability is not HOS eligibility |
| `vw_active_trips` | ops.trips, ops.trip_assignments | tenant + trip; execution states only |
| `vw_dispatch_board` | ops.loads, ops.trip_loads, ops.trips, ops.trip_stops, ops.trip_exceptions | tenant + load/trip; avoid join fanout |
| `vw_delayed_trips` | ops.trip_stops, ops.load_stops, ops.trip_exceptions | tenant + trip; appointment and exception evidence; unknown if unavailable |
| `vw_vehicle_last_location` | gps.latest_vehicle_positions, gps.vehicle_positions | tenant + asset; preserve recorded and received times |
| `vw_maintenance_due` | mnt.maintenance_schedules, mnt.scheduled_services, fleet.odometer_readings | tenant + service; date/mileage/hour trigger |
| `vw_vehicle_downtime` | mnt.downtime_events | tenant + asset + period; avoid overlaps |
| `vw_fuel_efficiency` | fuel.fuel_efficiency_records | tenant + asset + period; aligned miles/gallons; NULL when denominator zero |
| `vw_trip_profitability` | fin.revenue_allocations, fin.revenue_items, fin.expense_allocations, fin.expenses, ops.trip_distances, fin.trip_financial_closures | tenant + trip + currency; separate sums before join; report completeness |
| `vw_vehicle_profitability` | fin.expense_allocations, fin.revenue_allocations, ops.trip_assignments | tenant + asset + currency + period; explicit attribution and denominator |
| `vw_customer_profitability` | crm.customers, ops.loads, ops.trip_loads, fin.revenue_items, fin.expense_allocations | tenant + customer + currency + period; no double counting multi-load costs |
| `vw_driver_performance` | hr.drivers, ops.trip_assignments, ops.trip_stops | tenant + driver + period; restricted; no unverified safety score |
| `vw_document_expirations` | docs.documents, docs.driver_documents, docs.asset_documents | tenant + document/entity; current verified version |
| `vw_missing_pod` | ops.delivery_confirmations, docs.delivery_documents, docs.document_versions, docs.document_verifications | tenant + delivery; evaluate each linked POD at its submitted version and apply the current authorized review decision for that version |
| `vw_compliance_exceptions` | compliance.driver_compliance_records, compliance.asset_compliance_records | tenant + subject + requirement; no conclusive legal determination |
| `vw_ai_usage_summary` | ai.usage_records | tenant + model + period; estimated provider cost by currency |

## Trip contribution and POD acceptance

Pre-aggregate each allocation stream at tenant, trip and source currency. Join each expense allocation to its single parent expense and each revenue allocation to its single parent revenue item to obtain currency and inclusion status. Joining unaggregated revenue and costs multiplies the amounts when a trip has several lines on both sides. Join the single distance record after aggregation. For a finalized view, select the authorized closure revision once and display its stored basis. A live estimate identifies missing inputs. An actual zero and an unknown amount produce different completeness results.

For the pilot fixture, USD 900 + 300 in recognized allocated revenue and USD 100 + 200 in included allocated costs yield USD 900 direct contribution. At 500 total miles, CPM is USD 0.60 and RPM is USD 2.40. At 400 loaded miles, they are USD 0.75 and USD 3.00. A missing or zero denominator yields an unavailable rate. The reporting service provides the same amounts, basis, currency, as-of time and completeness to the UI, export and authorized Copilot tool.

For each required delivery, resolve the submitted POD link and version under the same tenant, confirm its document type, and evaluate its scan and review. A subsequent rejection of that version invalidates a prior approval under the review workflow. Serialize review decisions for a version and specify deterministic ordering before implementing the view. A missing approval or a pending replacement yields an outstanding POD. Keep the physical delivery fact and the finance completeness result independent.
