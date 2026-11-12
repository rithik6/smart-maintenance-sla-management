# Business findings and recommendations

All observations come from 540 synthetic tickets created from January through June 2026. Backlog was evaluated at July 1, 2026, 00:00 UTC. The actions below are proposed pilots. Benefits are hypothetical and require validation with operational data.

## 1. Triage the overdue queue by urgency and age

**Observation.** Thirteen of 22 unresolved tickets were overdue at the snapshot. Line A had six overdue tickets, including both Critical cases. The oldest overdue ticket was 86.80 hours past its deadline.

**Action.** Have the maintenance manager run a shift-start review with production supervisors. Confirm owners and next actions for Critical cases first, then review other overdue tickets by deadline age. Assign an owner to tickets still awaiting dispatch.

**Expected benefit and measurement.** Earlier ownership and escalation could shorten the time unresolved work stays overdue. Record weekly overdue count, Critical overdue count, and age of the oldest overdue ticket at a consistent cutoff. Compare weekly snapshots against the initial 13, two, and 86.80 hours.

## 2. Review first-action delays on Line B

**Observation.** Line B had the lowest SLA compliance of the four lines, at 52.73% (87 of 165 resolved tickets). In 24 of its 78 late closures, the SLA deadline had already passed before the first recorded technician action. Average first-response time was 10.03 hours for its resolved tickets.

**Action.** Pilot a named dispatch owner for Line B and a pre-deadline review of unassigned and untouched tickets. Inspect the 24 cases with an initial action after the deadline to distinguish assignment delays, timestamp entry gaps, and capacity issues.

**Expected benefit and measurement.** Earlier review could move more first actions inside the resolution window. Compare the share of resolved tickets whose first action occurred after the deadline, the time to first action, and resolution SLA compliance over equal-length periods. Break results down by priority to account for different SLA targets.

## 3. Investigate recurring mechanical reports for B-01 Conveyor

**Observation.** B-01 Conveyor generated 64 of Line B's 169 tickets (37.9%). Of the 64, 38 were categorized as Mechanical, 17 as Controls, and nine as Electrical.

**Action.** Ask maintenance engineering to review the Mechanical work orders and inspection history. Check whether the same assemblies or components recur, then agree on an inspection or preventive maintenance change if the evidence supports it.

**Expected benefit and measurement.** A confirmed corrective action could reduce repeat mechanical requests and disruption. Monitor Mechanical tickets per 1,000 asset operating hours before and after the pilot. Collect operating hours alongside ticket counts so changes in equipment use can be accounted for.

## 4. Test capacity planning against changes in incoming workload

**Observation.** June recorded 118 new tickets, 39.81% above the January–May average of 84.40 tickets per month. The dataset covers a single six-month simulation.

**Action.** Have the production supervisor and maintenance manager review weekly arrivals, upcoming production plans, and technician coverage together. Confirm whether the increase persists in comparable production weeks before changing staffing or shift coverage.

**Expected benefit and measurement.** A more timely workload review could help align available technician coverage with demand. Compare weekly tickets per production shift, median time to first action, and overdue backlog at the weekly cutoff. Track priority mix and production volume alongside those measures.

## Reproduce the evidence

Run the following command after loading the demo database. Use your configured PostgreSQL connection values.

```powershell
psql -X -h localhost -U postgres -d smart_maintenance_demo -v ON_ERROR_STOP=1 -f sql/06_business_findings.sql
```

[Findings queries](../sql/06_business_findings.sql) · [KPI definitions](kpi_definitions.md) · [Report screenshots](../README.md#power-bi-desktop-report)
