# Maintenance data dictionary

This case study uses synthetic maintenance records for a fictional manufacturer. All identifiers, assets, production lines, and personnel labels are simulated. Timestamps are stored as zone-free values representing UTC. The reporting period is January through June 2026, evaluated at July 1, 2026, 00:00 UTC.

## `maintenance.equipment`

One row per asset. The data includes 24 assets across four production lines.

| Field | PostgreSQL type | Definition |
| --- | --- | --- |
| `equipment_id` | `integer` | Primary key for the asset. |
| `equipment_name` | `text` | Unique asset label with a line and position prefix. |
| `production_line` | `text` | Asset's assigned line, `Line A` through `Line D` in this simulation. |
| `location` | `text` | Manufacturing bay containing the asset. |
| `status` | `text` | Asset register status, either `Active` or `Standby`. |

## `maintenance.technicians`

One row per technician. The data includes 12 fictional technicians.

| Field | PostgreSQL type | Definition |
| --- | --- | --- |
| `technician_id` | `integer` | Primary key for the technician. |
| `technician_name` | `text` | Fictional label, such as `Technician 01`. |
| `specialization` | `text` | `Mechanical`, `Electrical`, `Controls`, or `Utilities`. |

## `maintenance.maintenance_tickets`

One row per ticket, with its latest recorded status at the snapshot. The data includes 540 tickets. Blank CSV fields for nullable columns load as SQL `NULL`.

| Field | PostgreSQL type | Definition |
| --- | --- | --- |
| `ticket_id` | `integer` | Primary key for the ticket. |
| `equipment_id` | `integer` | Required foreign key to `equipment`. An asset can have many tickets. |
| `technician_id` | `integer` | Optional foreign key to `technicians`. A null value means the ticket awaits assignment. |
| `issue_category` | `text` | `Mechanical`, `Electrical`, `Controls`, `Pneumatics`, or `Process Quality`. |
| `description` | `text` | Short synthetic note about the symptom or repair. |
| `priority` | `text` | `Critical`, `High`, `Medium`, or `Low`. |
| `status` | `text` | `Open` before first response, `In Progress` after first response, or `Resolved` after closure. |
| `created_at` | `timestamp(0)` | Time the maintenance request was logged. |
| `first_response_at` | `timestamp(0)` | First technician action. Null for `Open`. |
| `resolved_at` | `timestamp(0)` | Time the technician closed the ticket. Null for unresolved tickets. |
| `sla_target_hours` | `smallint` | Resolution target in elapsed hours, set by ticket priority. |
| `estimated_downtime_hours` | `numeric(6,2)` | Per-ticket estimate of production interruption. Concurrent incidents can overlap, so sums are ticket-level estimates. |

## `maintenance.report_snapshot`

This single-row view supplies a common reporting window and clock to PostgreSQL and Power BI.

| Field | PostgreSQL type | Definition |
| --- | --- | --- |
| `period_start_at` | `timestamp` | Inclusive lower bound for ticket creation, January 1, 2026 at 00:00 UTC. |
| `snapshot_at` | `timestamp` | Evaluation time for backlog and exclusive upper bound for ticket creation, July 1, 2026 at 00:00 UTC. |

## Reporting rules for the simulation

| Priority | Example impact | Resolution target |
| --- | --- | ---: |
| Critical | Line stopped or immediate safety impact | 4 elapsed hours |
| High | Major loss of capacity with limited workaround | 12 elapsed hours |
| Medium | Partial disruption with a workable fallback | 24 elapsed hours |
| Low | Minor degradation or a planned correction | 48 elapsed hours |

- SLA deadline is creation time plus the ticket's resolution target. The clock uses elapsed hours across nights and weekends.
- A resolved ticket meets SLA if its resolution occurs at or before the deadline. An unresolved ticket is overdue if the snapshot is strictly later than the deadline. `Overdue` is a derived reporting condition.
- The open-ticket KPI covers both `Open` and `In Progress`. The SLA compliance denominator includes only resolved tickets. Mean Time to Repair (MTTR) averages elapsed time from first response to resolution for resolved tickets. This is a proxy for repair duration because the case records a first technician action and a closure, with no separate hands-on work log.
- Date filters will select tickets by creation date. The snapshot remains fixed across date selections, so the report can show current backlog for tickets created during a selected period.
- Tickets `535`–`540` are deliberate boundary cases. They cover an on-deadline closure, a closure one minute late, an unresolved ticket exactly due, an unresolved ticket one minute overdue, an unresolved ticket due later, and a closure one minute early, respectively.

The `maintenance.ticket_reporting` view joins each ticket to its asset and derives the SLA deadline, backlog flags, and elapsed durations for the SQL analysis. The three source tables and the snapshot view supply the inputs for the Power BI model. [KPI formulas and benchmark results](kpi_definitions.md)
