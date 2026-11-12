BEGIN;

CREATE SCHEMA IF NOT EXISTS maintenance;

CREATE TABLE IF NOT EXISTS maintenance.equipment (
    equipment_id integer PRIMARY KEY CHECK (equipment_id > 0),
    equipment_name text NOT NULL UNIQUE CHECK (btrim(equipment_name) <> ''),
    production_line text NOT NULL CHECK (btrim(production_line) <> ''),
    location text NOT NULL CHECK (btrim(location) <> ''),
    status text NOT NULL CHECK (status IN ('Active', 'Standby'))
);

CREATE TABLE IF NOT EXISTS maintenance.technicians (
    technician_id integer PRIMARY KEY CHECK (technician_id > 0),
    technician_name text NOT NULL CHECK (btrim(technician_name) <> ''),
    specialization text NOT NULL CHECK (specialization IN ('Mechanical', 'Electrical', 'Controls', 'Utilities'))
);

CREATE TABLE IF NOT EXISTS maintenance.maintenance_tickets (
    ticket_id integer PRIMARY KEY CHECK (ticket_id > 0),
    equipment_id integer NOT NULL CONSTRAINT tickets_equipment_fk REFERENCES maintenance.equipment,
    technician_id integer CONSTRAINT tickets_technician_fk REFERENCES maintenance.technicians,
    issue_category text NOT NULL CHECK (
        issue_category IN ('Mechanical', 'Electrical', 'Controls', 'Pneumatics', 'Process Quality')
    ),
    description text NOT NULL CHECK (btrim(description) <> ''),
    priority text NOT NULL CHECK (priority IN ('Critical', 'High', 'Medium', 'Low')),
    status text NOT NULL CHECK (status IN ('Open', 'In Progress', 'Resolved')),
    created_at timestamp(0) without time zone NOT NULL,
    first_response_at timestamp(0) without time zone,
    resolved_at timestamp(0) without time zone,
    sla_target_hours smallint NOT NULL,
    estimated_downtime_hours numeric(6, 2) NOT NULL CHECK (estimated_downtime_hours BETWEEN 0 AND 9999.99),
    CONSTRAINT tickets_sla_target CHECK (
        sla_target_hours = CASE priority
            WHEN 'Critical' THEN 4 WHEN 'High' THEN 12 WHEN 'Medium' THEN 24 WHEN 'Low' THEN 48
        END
    ),
    CONSTRAINT tickets_status_lifecycle CHECK (
        (status = 'Open' AND first_response_at IS NULL AND resolved_at IS NULL)
        OR (status = 'In Progress' AND technician_id IS NOT NULL AND first_response_at IS NOT NULL
            AND resolved_at IS NULL)
        OR (status = 'Resolved' AND technician_id IS NOT NULL AND first_response_at IS NOT NULL
            AND resolved_at IS NOT NULL)
    ),
    CONSTRAINT tickets_timestamp_order CHECK (
        (first_response_at IS NULL OR first_response_at >= created_at)
        AND (resolved_at IS NULL OR resolved_at >= first_response_at)
    )
);

-- Import this one-row view into Power BI so SQL and DAX use the same clock.
CREATE OR REPLACE VIEW maintenance.report_snapshot AS
SELECT TIMESTAMP '2026-01-01 00:00:00' AS period_start_at,
       TIMESTAMP '2026-07-01 00:00:00' AS snapshot_at;

-- One row per ticket in the simulation window for the SQL KPI queries.
CREATE OR REPLACE VIEW maintenance.ticket_reporting AS
SELECT ticket.ticket_id,
       ticket.equipment_id,
       equipment.equipment_name,
       equipment.production_line,
       ticket.priority,
       ticket.status,
       ticket.created_at,
       ticket.first_response_at,
       ticket.resolved_at,
       sla.deadline AS sla_deadline_at,
       ticket.resolved_at IS NULL AS is_open,
       ticket.resolved_at IS NULL AND report.snapshot_at > sla.deadline AS is_overdue,
       ticket.resolved_at <= sla.deadline AS met_sla,
       extract(epoch FROM (ticket.resolved_at - ticket.first_response_at)) / 3600.0 AS repair_hours,
       extract(epoch FROM (ticket.resolved_at - ticket.created_at)) / 3600.0 AS resolution_hours,
       CASE WHEN ticket.resolved_at IS NOT NULL THEN
           extract(epoch FROM (ticket.first_response_at - ticket.created_at)) / 3600.0
       END AS resolved_ticket_response_hours,
       CASE WHEN ticket.resolved_at IS NULL AND report.snapshot_at > sla.deadline THEN
           extract(epoch FROM (report.snapshot_at - sla.deadline)) / 3600.0
       END AS hours_overdue
FROM maintenance.maintenance_tickets AS ticket
JOIN maintenance.equipment AS equipment USING (equipment_id)
CROSS JOIN maintenance.report_snapshot AS report
CROSS JOIN LATERAL (
    SELECT ticket.created_at + make_interval(hours => ticket.sla_target_hours) AS deadline
) AS sla
WHERE ticket.created_at >= report.period_start_at AND ticket.created_at < report.snapshot_at;

COMMIT;
