# Maintenance business rules

The rules below define the simulation. Priority examples describe proposed triage criteria for a future ticket intake process.

## Priority and SLA

| Priority | Triage criteria | Resolution target |
| --- | --- | ---: |
| Critical | Production line stopped or an immediate safety impact is reported. | 4 elapsed hours |
| High | Major capacity loss with a limited workaround. | 12 elapsed hours |
| Medium | Partial disruption with a workable fallback. | 24 elapsed hours |
| Low | Minor degradation or a planned correction. | 48 elapsed hours |

- **BR-01** — Use one priority per ticket. The schema checks that the stored SLA target matches the priority. In the proposed workflow, the maintenance manager confirms priority at triage.
- **BR-02** — SLA deadline equals `created_at` plus `sla_target_hours`. Elapsed time includes nights and weekends. Resolution exactly at the deadline meets SLA.
- **BR-03** — An unresolved ticket becomes overdue only after its deadline passes. Use the shared UTC snapshot to evaluate the backlog. `Overdue` is a calculated flag and can apply to `Open` or `In Progress`.

## Ticket lifecycle

| Status | Assignment and timestamp rules |
| --- | --- |
| `Open` | First response and resolution are null. A technician may be assigned while work is queued. |
| `In Progress` | Technician and first response are required. Resolution is null. |
| `Resolved` | Technician, first response, and resolution are required. |

- **BR-04** — One ticket references one equipment record and at most one technician. The first response cannot precede creation. The resolution cannot precede the first response.
- **BR-05** — The report stores a single status per ticket at the fixed snapshot. Dates select tickets by creation time, so changing the date slicer changes the ticket cohort while the reporting clock stays fixed.

## Reporting calculations

- **BR-06** — Open-ticket count includes both unresolved statuses. SLA compliance uses resolved tickets as its denominator. MTTR averages elapsed first-response-to-closure hours for resolved tickets. SLA compliance and MTTR return blank when the selected cohort has no resolutions.
- **BR-07** — Repeat-incident ranking counts tickets per asset in the selected scope. Assets qualify with two or more tickets. Rank by count descending and equipment ID ascending, and show up to ten assets.
- **BR-08** — Estimated downtime is recorded per ticket. Overlapping incidents and missing operating-hour exposure limit its use in estimating total line downtime or comparing failure rates.

[Data dictionary](data_dictionary.md) · [KPI formulas and reconciliation benchmarks](kpi_definitions.md)
