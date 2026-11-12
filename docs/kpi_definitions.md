# Maintenance KPIs and reporting metrics

## Data behind the report

The case uses 540 synthetic maintenance tickets created from January through June 2026. Each ticket represents one logged maintenance request and records its asset, issue category, priority, status, timestamps, SLA target, and estimated downtime. The equipment table supplies the production line for each asset. The technician table supplies the assigned technician's specialization where an assignment exists. The reporting clock is fixed at **July 1, 2026, 00:00 UTC**. The generated records describe a fictional manufacturer. [Data dictionary](data_dictionary.md)

## Headline measures

A **metric** is any quantity we measure. A **KPI** is a metric selected to track a business objective. This report uses five headline measures. Total tickets gives workload context, open and overdue tickets track backlog, and SLA compliance and MTTR track service performance. The values below use all 540 tickets.

| Headline measure | Business question | Formula | Result |
| --- | --- | --- | ---: |
| Total tickets | How much work came in? | Count ticket IDs in the selected scope. | 540 |
| Open tickets | How much work is still outstanding? | Count tickets in `Open` or `In Progress` at the snapshot. | 22 |
| Overdue tickets | How much unresolved work has breached its deadline? | Count open tickets whose SLA deadline is strictly before the snapshot. | 13 |
| SLA compliance % | How often do we resolve work on time? | Resolved at or before the SLA deadline ÷ all resolved tickets × 100. | 61.78% |
| Mean Time to Repair (MTTR) | How long does work take after the first technician action? | Sum of hours from first response to resolution ÷ resolved tickets. | 16.95 h |

Each SLA deadline is the ticket's creation timestamp plus its resolution target. Targets are 4 hours for Critical, 12 for High, 24 for Medium, and 48 for Low. The clock runs continuously. A closure exactly on its deadline meets SLA. An unresolved ticket due exactly at the snapshot becomes overdue once the clock passes the deadline. MTTR uses elapsed hours as a proxy for repair time, including any waits between the first action and closure.

## Supporting metrics

| Metric | How it is calculated and used | Baseline or example |
| --- | --- | --- |
| Resolved within and after SLA | Counts of resolved tickets split at the deadline. They explain the SLA percentage. | 320 within, 198 after, 518 resolved |
| Average time to first response | Average of first response minus creation for the resolved cohort. It shows time to the first technician action for the same tickets used in MTTR. | 8.32 h |
| Average request-to-resolution time | Average of resolution minus creation for the resolved cohort. It shows the full elapsed time production waited for closure. | 25.27 h |
| Tickets by status and priority | Counts of tickets in each status and priority. They show how work and backlog are distributed. | 10 `Open`, 12 `In Progress`, 518 `Resolved` |
| Monthly ticket volume | Count by creation month. It shows changes in incoming workload. | 76 in January, 118 in June |
| Tickets and SLA by line | Group volume, backlog, SLA and MTTR by the asset's production line. | Line B had 169 tickets and 52.73% SLA compliance (87 of 165 resolved). |
| Equipment with repeated incidents | Count tickets per asset in scope. Keep assets with at least two tickets, sort by count descending and equipment ID ascending, and return ten. | B-01 Conveyor had 64 tickets. |
| Hours overdue | Snapshot timestamp minus SLA deadline, in hours, for open tickets with a breached deadline. | The longest overdue ticket was 86.80 h past its deadline. |

The benchmark includes hours in decimal form. Average time to first response plus MTTR equals average request-to-resolution time before rounding, because all three averages use the same resolved cohort. Incident counts guide equipment investigation. Estimating total line downtime requires accounting for overlapping interruptions. Comparing incident rates requires operating hours or another measure of asset exposure.

## PostgreSQL benchmarks for Power BI reconciliation

Use ticket creation date for date filters. Status filters select the exact status at the reporting snapshot. Selecting `Open` in the status slicer shows the 10 tickets with status `Open`. With all statuses selected, the open-tickets measure also includes 12 `In Progress` tickets. A filter with no matching rows yields zero for counts. SLA compliance and average durations are blank whenever the selection has no resolved tickets.

| Creation date | Production line | Priority | Status | Total | Open | Overdue | SLA compliance % | MTTR (h) |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| All | All | All | All | 540 | 22 | 13 | 61.7761% | 16.9542 |
| June 2026 | All | All | All | 118 | 22 | 13 | 61.4583% | 14.8115 |
| All | Line B | High | All | 42 | 0 | 0 | 47.6190% | 9.5103 |
| June 2026 | Line B | High | Resolved | 11 | 0 | 0 | 63.6364% | 8.3894 |
| All | All | All | Open | 10 | 10 | 6 | Blank | Blank |
| January 2026 | All | All | Open | 0 | 0 | 0 | Blank | Blank |

Compare displayed counts exactly and rates and durations at the same displayed precision. PostgreSQL returns percentage points (for example, `61.7761`), and Power BI's percentage format displays the corresponding fraction as `61.7761%` at four decimal places. The SQL benchmarks matched independent CSV calculations and all six DAX results in Power BI Desktop using both the bundled snapshot and an authenticated PostgreSQL Import refresh. [SQL benchmarks](../sql/05_kpi_benchmarks.sql) · [DAX benchmarks](../powerbi/validate_kpis.dax)
