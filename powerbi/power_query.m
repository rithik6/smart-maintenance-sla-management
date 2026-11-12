section Maintenance;

shared #"Maintenance Source" =
let
    Source = PostgreSQL.Database("localhost:5432", "smart_maintenance_demo", [CreateNavigationProperties = false])
in
    Source;

shared Equipment =
let
    Source = #"Maintenance Source"{[Schema = "maintenance", Item = "equipment"]}[Data],
    Typed = Table.TransformColumnTypes(Source, {{"equipment_id", Int64.Type}, {"equipment_name", type text}, {"production_line", type text}, {"location", type text}, {"status", type text}}),
    Renamed = Table.RenameColumns(Typed, {{"equipment_id", "Equipment ID"}, {"equipment_name", "Equipment Name"}, {"production_line", "Production Line"}, {"location", "Location"}, {"status", "Asset Status"}})
in
    Renamed;

shared Technicians =
let
    Source = #"Maintenance Source"{[Schema = "maintenance", Item = "technicians"]}[Data],
    Typed = Table.TransformColumnTypes(Source, {{"technician_id", Int64.Type}, {"technician_name", type text}, {"specialization", type text}}),
    Renamed = Table.RenameColumns(Typed, {{"technician_id", "Technician ID"}, {"technician_name", "Technician Name"}, {"specialization", "Specialization"}})
in
    Renamed;

shared #"Report Snapshot" =
let
    Source = #"Maintenance Source"{[Schema = "maintenance", Item = "report_snapshot"]}[Data],
    Typed = Table.TransformColumnTypes(Source, {{"period_start_at", type datetime}, {"snapshot_at", type datetime}}),
    Renamed = Table.RenameColumns(Typed, {{"period_start_at", "Period Start"}, {"snapshot_at", "Snapshot At"}})
in
    Renamed;

shared Tickets =
let
    Source = #"Maintenance Source",
    Raw = Source{[Schema = "maintenance", Item = "maintenance_tickets"]}[Data],
    Scope = Source{[Schema = "maintenance", Item = "report_snapshot"]}[Data]{0},
    Typed = Table.TransformColumnTypes(Raw, {{"ticket_id", Int64.Type}, {"equipment_id", Int64.Type}, {"technician_id", Int64.Type}, {"issue_category", type text}, {"description", type text}, {"priority", type text}, {"status", type text}, {"created_at", type datetime}, {"first_response_at", type datetime}, {"resolved_at", type datetime}, {"sla_target_hours", Int64.Type}, {"estimated_downtime_hours", Currency.Type}}, "en-US"),
    InPeriod = Table.SelectRows(Typed, each [created_at] >= Scope[period_start_at] and [created_at] < Scope[snapshot_at]),
    Renamed = Table.RenameColumns(InPeriod, {{"ticket_id", "Ticket ID"}, {"equipment_id", "Equipment ID"}, {"technician_id", "Technician ID"}, {"issue_category", "Issue Category"}, {"description", "Description"}, {"priority", "Priority"}, {"status", "Status"}, {"created_at", "Created At"}, {"first_response_at", "First Response At"}, {"resolved_at", "Resolved At"}, {"sla_target_hours", "SLA Target Hours"}, {"estimated_downtime_hours", "Estimated Downtime Hours"}}),
    CreatedDate = Table.AddColumn(Renamed, "Created Date", each Date.From([Created At]), type date),
    Deadline = Table.AddColumn(CreatedDate, "SLA Deadline", each [Created At] + #duration(0, 1, 0, 0) * [SLA Target Hours], type datetime),
    RepairHours = Table.AddColumn(Deadline, "Repair Hours", each if [Resolved At] = null then null else Duration.TotalHours([Resolved At] - [First Response At]), type nullable number),
    PriorityOrder = Table.AddColumn(RepairHours, "Priority Order", each List.PositionOf({"Critical", "High", "Medium", "Low"}, [Priority]) + 1, Int64.Type),
    StatusOrder = Table.AddColumn(PriorityOrder, "Status Order", each List.PositionOf({"Open", "In Progress", "Resolved"}, [Status]) + 1, Int64.Type)
in
    StatusOrder;

shared Calendar =
let
    Scope = #"Report Snapshot"{0},
    StartDate = Date.From(Scope[Period Start]),
    EndDate = Date.From(Scope[Snapshot At]),
    Days = List.Dates(StartDate, Duration.Days(EndDate - StartDate), #duration(1, 0, 0, 0)),
    Dates = Table.FromColumns({Days}, type table [Date = date]),
    MonthStart = Table.AddColumn(Dates, "Month Start", each Date.StartOfMonth([Date]), type date),
    Month = Table.AddColumn(MonthStart, "Month", each Date.ToText([Date], [Format = "MMM yyyy", Culture = "en-US"]), type text)
in
    Month;
