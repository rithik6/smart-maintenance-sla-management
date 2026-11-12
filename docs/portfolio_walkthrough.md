# Portfolio walkthrough

## A 60-second explanation

> This is a simulated Business Analyst case study for a manufacturer that tracked maintenance requests across spreadsheets, email, and phone calls. I mapped the current workflow and proposed a standard ticket process with clearer ownership, priorities, and SLA deadlines. I created 540 synthetic tickets in PostgreSQL and built a two-page Power BI Desktop report. The first page helps a maintenance supervisor manage overdue work. The second helps an operations manager compare lines and decide which equipment to investigate. I checked five DAX measures against PostgreSQL across six filter scenarios. In the simulation, 320 of 518 resolved tickets met SLA, and 13 of 22 unresolved tickets were already overdue. I used those results to propose a daily backlog review, a Line B dispatch pilot, and an investigation of B-01 Conveyor.

## How to show the work

1. **Start with the business problem.** Explain how multiple intake channels made ownership and priorities hard to reconcile. Use the AS-IS and TO-BE process maps to show where standard ticket fields and a shared SLA deadline enter the proposed workflow. [Process maps](process_flows.md)
2. **Explain the data.** One row represents one request. The equipment record supplies the production line. The technician record adds assignment context. The fixed July 1 snapshot lets SQL and DAX classify overdue tickets against the same clock. [Data dictionary](data_dictionary.md)
3. **Use the first page for daily decisions.** Point to the 22 open and 13 overdue tickets, then use the worklist to show where a supervisor would follow up. Total tickets gives workload context. Overdue tickets and SLA compliance track backlog risk and service performance. [Operations Overview](../powerbi/screenshots/maintenance_operations_overview.png)
4. **Use the second page to explain a recommendation.** Show Line B's 52.73% SLA compliance and the 64 tickets tied to B-01 Conveyor. Explain that incident counts identify where to investigate. The dispatch pilot and equipment investigation have different owners and success measures. [Equipment & SLA Analysis](../powerbi/screenshots/equipment_performance_sla.png) · [Business findings](business_findings.md)
5. **Show one validation example.** Select June, Line B, High, and Resolved. Explain why the result is 11 tickets, zero open, and 63.64% SLA compliance. Compare that selection with the matching SQL benchmark. Clear slicers at the end. [Validation query](../powerbi/validate_kpis.dax)

## Questions a reviewer may ask

| Question | How to explain it |
| --- | --- |
| Why use PostgreSQL and Power BI? | PostgreSQL enforces the ticket relationships and supplies an independent way to calculate the KPIs. Power BI Desktop gives supervisors interactive views of the same measures and worklist. |
| How are KPIs different from metrics? | A metric is any measured quantity, such as 518 resolved tickets. A KPI is selected to monitor a business objective. SLA compliance uses 320 on-time closures and 518 resolved tickets to measure deadline performance. |
| Why is MTTR shorter than request-to-resolution time? | MTTR in this case starts at the first recorded technician action. Request-to-resolution starts when production logs the request. On the same resolved cohort, the averages were 16.95 h and 25.27 h, with 8.32 h before the first action. |
| How did you check synthetic data quality? | I used a reproducible generator, validated keys and lifecycle rules, and deliberately included tickets at the exact deadline and one minute either side. Then I checked that SQL and DAX classified them consistently. |
| What would you do before a real rollout? | Validate priority rules with the maintenance manager and production supervisors. Collect reliable assignment, operating-hour, and status-history data. Pilot the recommendations and compare outcomes over equivalent periods. |

[Verified Power BI report](../powerbi/maintenance_dashboard.pbix) · [Requirements and stakeholders](business_requirements.md) · [UAT scenarios](uat_test_cases.md)
