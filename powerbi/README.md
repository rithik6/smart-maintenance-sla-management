# Build and validate the Power BI report

This report uses synthetic data for a fictional manufacturer. Both pages show tickets created from January through June 2026, with backlog evaluated at **July 1, 2026, 00:00 UTC**.

Open the verified [maintenance_dashboard.pbix](maintenance_dashboard.pbix) to review both pages with the bundled data already loaded. The PBIP project is available for edits. The PostgreSQL Import steps below are for connecting your own seeded database.

## Open the supplied Power BI project

1. Open `maintenance_dashboard.pbip` in current Power BI Desktop. Keep the `.Report` and `.SemanticModel` folders beside it.
2. On a fresh clone, select **Home → Refresh**. If Desktop shows pending query changes, select **Apply changes**. The project's initial `Data Source` parameter is **Bundled Snapshot**, which contains the committed synthetic CSVs for a portable preview.
3. To use PostgreSQL, first create and seed the demo database using the [repository setup](../README.md#load-the-postgresql-demo-database). In **Home → Transform data → Edit parameters**, set `Data Source` to `PostgreSQL`, and enter your server and database in `PostgreSQL Server` and `PostgreSQL Database`. The defaults are `localhost:5432` and `smart_maintenance_demo`. Apply the changes, choose **Database** authentication when prompted, and supply a PostgreSQL login that can read the three tables and the snapshot view. Refresh the report. Keep credentials in the Desktop credential store.
4. Run the validation steps below. Use **File → Save as**, select **Power BI Desktop files (*.pbix)**, and save `maintenance_dashboard.pbix`. Open the saved file in Power BI Desktop and check the two page tabs and the baseline KPIs.

[Power BI projects](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview) · [PostgreSQL connector](https://learn.microsoft.com/en-us/power-query/connectors/postgresql)

## Assemble manually from a blank PBIX

### 1. Connect to PostgreSQL using Import mode

1. In Power BI Desktop, choose **Home → Get data → More → Database → PostgreSQL database**.
2. Enter your host and port in **Server** (for example, `localhost:5432`), enter `smart_maintenance_demo` in **Database**, and choose **Import**. Authenticate with your PostgreSQL login.
3. In Navigator, select `maintenance.equipment`, `maintenance.technicians`, `maintenance.maintenance_tickets`, and `maintenance.report_snapshot`, then choose **Transform Data**. Rename these four queries and replace their definitions in the next step. The `maintenance.ticket_reporting` view supplies the SQL benchmark.

### 2. Transform in Power Query

Use the expressions in [power_query.m](power_query.m). Create `Maintenance Source` first using **New Source → Blank Query**. For each named query below, create or rename a query, open **Advanced Editor**, and paste only its `let … in …` expression, excluding the final semicolon. Update the server and database in `Maintenance Source` if needed.

| Query | What the expression does |
| --- | --- |
| `Maintenance Source` | Connects to PostgreSQL and exposes the Navigator tables. Disable **Enable load** for this query. |
| `Equipment` | Keeps one row per asset, sets its ID to Whole Number, and gives the reporting fields readable names. |
| `Technicians` | Keeps one row per technician and sets its ID to Whole Number. |
| `Report Snapshot` | Keeps the single UTC row for the reporting start and snapshot. |
| `Tickets` | Assigns types, preserves nullable assignments and timestamps, filters to the reporting period, and adds creation date, SLA deadline, elapsed repair hours, and sort order fields. |
| `Calendar` | Creates one row per date in the simulation and adds a month label and month start. |

Leave **Enable load** checked for the five model tables. Use **Close & Apply** and confirm 540 tickets, 24 assets, 12 technicians, one snapshot, and 181 calendar dates.

### 3. Set the model relationships

In **Model view → Manage relationships**, add or verify the three active, single-direction relationships. Filters flow from the one side to the ticket table.

| One side | Many side |
| --- | --- |
| `Equipment[Equipment ID]` | `Tickets[Equipment ID]` |
| `Technicians[Technician ID]` | `Tickets[Technician ID]` |
| `Calendar[Date]` | `Tickets[Created Date]` |

Leave `Report Snapshot` disconnected so date, line, priority, and status selections share the same reporting clock. Preserve blank technician IDs for unassigned work. Set `Calendar[Month]` to **Sort by column → Month Start**, `Tickets[Priority]` to **Priority Order**, and `Tickets[Status]` to **Status Order**. Set key fields to **Don't summarize**.

[Microsoft's relationship guide](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-create-and-manage-relationships)

### 4. Add the DAX measures

Select `Tickets`, choose **New measure**, and paste one definition at a time from [measures.dax](measures.dax). Format `SLA Compliance %` as Percentage with two decimal places, `MTTR Hours` and `Hours Overdue` with two decimal places, and the counts as whole numbers. `Open Tickets` includes `Open` and `In Progress`. `KEEPFILTERS` makes the open and resolved calculations respect the selected ticket status.

### 5. Assemble the two report pages

Use a 1440 × 900 canvas. Add a heading and a small **Simulated case study** label to both pages. Place four slicers across the top. Use `Calendar[Date]` as a **Between** slicer, and use dropdowns for `Equipment[Production Line]`, `Tickets[Priority]`, and `Tickets[Status]`. Use **View → Sync slicers** to show and synchronize each slicer on both pages.

| Page | Visual | Field or measure |
| --- | --- | --- |
| Maintenance Operations Overview | Five cards | Total tickets, open tickets, overdue tickets, SLA compliance, and MTTR. |
| Maintenance Operations Overview | Line chart | `Calendar[Month]` by `[Total Tickets]`, chronological order. |
| Maintenance Operations Overview | Column chart | `Tickets[Priority]` by `[Total Tickets]`. |
| Maintenance Operations Overview | Overdue worklist | Ticket ID, Equipment Name, Production Line, Priority, Status, SLA Deadline, and `[Hours Overdue]`. Filter the visual to `[Hours Overdue] > 0` and sort by deadline ascending. |
| Equipment Performance & SLA Analysis | Horizontal bar chart | `Equipment[Equipment Name]` by `[Repeat Incident Tickets]`, descending. The measure selects up to ten assets with at least two tickets in scope and breaks ties by equipment ID. |
| Equipment Performance & SLA Analysis | Column chart | `Equipment[Production Line]` by `[SLA Compliance %]`. |
| Equipment Performance & SLA Analysis | Comparison table | Production Line, Total Tickets, Open Tickets, Overdue Tickets, Resolved Tickets, Resolved Within SLA, SLA Compliance %, and MTTR Hours. |

## Validate and save

1. Clear all slicer selections. The five cards should show **540**, **22**, **13**, **61.78%**, and **16.95 h**.
2. Open **DAX Query View**, paste [validate_kpis.dax](validate_kpis.dax), and select **Run**. Compare the six rows with [the SQL benchmarks](../docs/kpi_definitions.md#postgresql-benchmarks-for-power-bi-reconciliation). Counts must match exactly. The query returns rates and durations rounded to four decimal places. Confirm blank SLA and MTTR for the two scenarios without resolved tickets.
3. Select June, Line B, High, and Resolved using the slicers. Confirm 11 total, zero open and overdue, 63.64% SLA compliance, and 8.39 h MTTR. Switch pages and check that the slicer selections follow. Clear them before saving the default report view.
4. Save using **File → Save as → Power BI Desktop files (*.pbix)**. Name the file `maintenance_dashboard.pbix`, reopen it, and verify the default cards and two pages again.

[DAX Query View](https://learn.microsoft.com/en-us/power-bi/transform-model/dax-query-view)

## Finish the two Desktop acceptance checks

Use a local copy of the PBIX for these checks so the portfolio copy stays ready to open with the bundled snapshot.

Both checks passed in Power BI Desktop. The PostgreSQL test used a local read-only login and reconciled all six benchmark scenarios after refresh.

1. **Check slicer synchronization.** On the Operations Overview, leave the date and status slicers at their defaults and select **Line B** and **High**. Confirm 42 tickets and 47.62% SLA compliance. Switch to the Equipment page and check that both slicers retain their selections and the line chart shows 47.62% for Line B. Clear both slicers and confirm the Overview returns to 540 tickets.
2. **Check PostgreSQL refresh.** Seed the local demo database, set `Data Source` to `PostgreSQL` in the copy, enter your server and database, and authenticate in Desktop. Apply the changes and refresh. Check the unfiltered 540-ticket baseline and run the six [DAX benchmark scenarios](validate_kpis.dax) against the [PostgreSQL results](../docs/kpi_definitions.md#postgresql-benchmarks-for-power-bi-reconciliation).
