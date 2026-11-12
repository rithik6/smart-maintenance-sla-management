# Business Requirements Document

## Case and objectives

A fictional manufacturer receives maintenance requests by spreadsheet, email, and phone. The channels capture different details, and maintenance supervisors must reconcile requests manually to identify owners, priorities, and delayed work. Operations leaders lack a consistent view of backlog, repair time, and repeated equipment incidents. The case uses synthetic data. Stakeholder needs were inferred from the scenario and would require confirmation during a real discovery phase.

- Give supervisors one view of ticket volume, ownership, and backlog at a shared reporting cutoff.
- Define priority and SLA rules so operations and maintenance teams interpret deadlines consistently.
- Help managers identify overdue work, compare production lines, and select equipment for investigation.
- Provide reproducible SQL and Power BI checks so reviewers can trace each KPI to the source data.

## Stakeholders

| Hypothetical role | Decision or need | Influence and proposed engagement |
| --- | --- | --- |
| Operations director | Compare service performance across lines and decide where to sponsor improvements. | Sponsor. Review the KPI definitions and proposed pilot measures. |
| Maintenance manager | Own prioritization, dispatch, overdue follow-up, and repeat-failure review. | Process owner. Confirm the SLA matrix, worklist order, and acceptance scenarios. |
| Production supervisor | Report equipment disruption with enough detail and monitor outstanding tickets for their line. | Daily report user. Review intake fields and test the production-line and status views. |
| Maintenance technician | Receive clear assignments and record the first action, repair notes, and closure. | Workflow contributor. Validate timestamp meanings and assignment exceptions. |
| IT or BI support | Manage source access, data refresh, and troubleshooting. | Technical owner. Verify the database setup, credentials, Import mode, and refresh procedure. |
| Business analyst | Translate the scenario into requirements, process maps, measures, and acceptance tests. | Case study author. Maintain links between requirements, KPI rules, and test evidence. |

## Scope, assumptions, and constraints

| Topic | Definition |
| --- | --- |
| In scope | AS-IS and proposed TO-BE workflows, a relational PostgreSQL source, synthetic data, SQL checks, and a two-page Power BI Desktop report. |
| Future operating process | Central ticket intake, triage, technician updates, and escalation are proposed workflow steps. The portfolio implements the data and reporting layer. |
| Deferred capabilities | Ticket entry, editing and dispatch in an application, automatic alerts, production integration, and deployment to Power BI Service. |
| Data and clock | 540 synthetic tickets, four production lines, 24 assets, and 12 technicians. Tickets are created January through June 2026. Backlog is evaluated at July 1, 2026, 00:00 UTC. |
| Reporting limits | Each ticket has one current status. SLA uses continuous hours, and MTTR uses elapsed time from first technician action to closure. Production exposure, actual labor time, and status-transition history would need additional source fields. |
| Environment | Power BI Desktop on Windows. The saved PBIX contains the synthetic snapshot. Refresh from PostgreSQL requires a running server and authorized database access. |

## Functional requirements and success criteria

| ID | Requirement | Acceptance evidence |
| --- | --- | --- |
| FR-01 | Keep a unique ticket record tied to equipment and, once work begins, an assigned technician. | The seed loads 540 tickets, 24 assets, and 12 technicians. PostgreSQL enforces valid keys and lifecycle fields. UAT-01. |
| FR-02 | Calculate the priority deadline and distinguish overdue backlog from late closures. | Tickets at and one minute either side of the SLA boundary are classified as specified. UAT-06. |
| FR-03 | Show ticket volume, open backlog, overdue backlog, SLA compliance, and MTTR. | Unfiltered cards show 540, 22, 13, 61.78%, and 16.95 h. All six DAX scenarios reconcile with SQL. UAT-02 through UAT-05. |
| FR-04 | Help supervisors find overdue work by production line and deadline. | The worklist includes all 13 overdue tickets and sorts by oldest deadline first. UAT-08. |
| FR-05 | Compare line performance and rank recurring equipment incidents. | The report shows four line results and up to ten assets. B-01 Conveyor leads with 64 tickets. UAT-07. |
| FR-06 | Let users filter by ticket creation date, line, priority, and status across both report pages. | The combined filter returns 11 tickets and 63.64% SLA compliance. Both pages use the same slicer groups. UAT-03 and UAT-09. |
| FR-07 | Provide a portable report and a repeatable path to PostgreSQL Import mode. | The saved PBIX reopens with the bundled model. The PostgreSQL refresh has its own manual acceptance test. UAT-10 and UAT-11. |

## Non-functional requirements

| ID | Requirement | Acceptance evidence |
| --- | --- | --- |
| NFR-01 | Reproducibility | A fixed generator seed reproduces the committed CSVs byte for byte. The database seed and checks run in a single transaction. |
| NFR-02 | Usability | Each page has a clear decision purpose, descriptive labels, and the four consistent slicers. Counts, percentages, and hours display in their stated units. |
| NFR-03 | Data protection | Use fictional records and keep database credentials outside GitHub. The bundled report opens using only synthetic data. |
| NFR-04 | Traceability | Document source columns, rules, formulas, SQL benchmarks, test outcomes, and the steps to rebuild the report. |

[Process maps](process_flows.md) · [User stories](user_stories.md) · [Business rules](business_rules.md) · [UAT scenarios](uat_test_cases.md)
