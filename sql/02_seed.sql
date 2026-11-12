\set ON_ERROR_STOP on

-- Run psql from the project root against the dedicated synthetic database.
BEGIN;

TRUNCATE maintenance.maintenance_tickets, maintenance.technicians, maintenance.equipment;

\copy maintenance.equipment (equipment_id, equipment_name, production_line, location, status) FROM 'data/equipment.csv' WITH (FORMAT csv, HEADER MATCH, ENCODING 'UTF8')
\copy maintenance.technicians (technician_id, technician_name, specialization) FROM 'data/technicians.csv' WITH (FORMAT csv, HEADER MATCH, ENCODING 'UTF8')
\copy maintenance.maintenance_tickets (ticket_id, equipment_id, technician_id, issue_category, description, priority, status, created_at, first_response_at, resolved_at, sla_target_hours, estimated_downtime_hours) FROM 'data/maintenance_tickets.csv' WITH (FORMAT csv, HEADER MATCH, ENCODING 'UTF8')

\ir 03_validate_data.sql

COMMIT;
