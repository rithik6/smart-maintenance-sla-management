-- These checks expect the committed synthetic dataset. A failure raises an error.
DO $$
DECLARE
    violated_constraint text;
BEGIN
    IF (SELECT count(*) FROM maintenance.equipment) <> 24
       OR (SELECT count(*) FROM maintenance.technicians) <> 12
       OR (SELECT count(*) FROM maintenance.maintenance_tickets) <> 540 THEN
        RAISE EXCEPTION 'Unexpected synthetic dataset row counts';
    END IF;

    IF (SELECT count(DISTINCT date_trunc('month', created_at))
        FROM maintenance.maintenance_tickets) <> 6
       OR EXISTS (
           SELECT 1
           FROM maintenance.maintenance_tickets AS ticket
           CROSS JOIN maintenance.report_snapshot AS report
           WHERE ticket.created_at < report.period_start_at
              OR ticket.created_at >= report.snapshot_at
              OR ticket.first_response_at > report.snapshot_at
              OR ticket.resolved_at > report.snapshot_at
       ) THEN
        RAISE EXCEPTION 'Ticket dates fall outside the expected six-month simulation';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM (VALUES
            (535, 'Resolved', 0, true, false),
            (536, 'Resolved', 60, false, false),
            (537, 'Open', 0, NULL, false),
            (538, 'In Progress', 60, NULL, true),
            (539, 'Open', -151200, NULL, false),
            (540, 'Resolved', -60, true, false)
        ) AS expected(ticket_id, status, deadline_offset_seconds, met_sla, overdue)
        LEFT JOIN maintenance.maintenance_tickets AS ticket USING (ticket_id)
        CROSS JOIN maintenance.report_snapshot AS report
        CROSS JOIN LATERAL (
            SELECT ticket.created_at + make_interval(hours => ticket.sla_target_hours) AS deadline
        ) AS sla
        WHERE ticket.status IS DISTINCT FROM expected.status
           OR extract(epoch FROM (coalesce(ticket.resolved_at, report.snapshot_at) - sla.deadline))
              IS DISTINCT FROM expected.deadline_offset_seconds
           OR (ticket.resolved_at <= sla.deadline) IS DISTINCT FROM expected.met_sla
           OR (ticket.resolved_at IS NULL AND report.snapshot_at > sla.deadline)
              IS DISTINCT FROM expected.overdue
    ) THEN
        RAISE EXCEPTION 'An SLA deadline boundary case is missing or misclassified';
    END IF;

    BEGIN
        UPDATE maintenance.maintenance_tickets SET equipment_id = 999999 WHERE ticket_id = 535;
        RAISE EXCEPTION 'An orphaned ticket was accepted';
    EXCEPTION WHEN foreign_key_violation THEN
        GET STACKED DIAGNOSTICS violated_constraint = CONSTRAINT_NAME;
        IF violated_constraint <> 'tickets_equipment_fk' THEN RAISE; END IF;
    END;

    BEGIN
        UPDATE maintenance.maintenance_tickets SET resolved_at = NULL WHERE ticket_id = 535;
        RAISE EXCEPTION 'A resolved ticket without a resolution timestamp was accepted';
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS violated_constraint = CONSTRAINT_NAME;
        IF violated_constraint <> 'tickets_status_lifecycle' THEN RAISE; END IF;
    END;

    BEGIN
        UPDATE maintenance.maintenance_tickets SET first_response_at = created_at - interval '1 minute'
        WHERE ticket_id = 535;
        RAISE EXCEPTION 'A response before ticket creation was accepted';
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS violated_constraint = CONSTRAINT_NAME;
        IF violated_constraint <> 'tickets_timestamp_order' THEN RAISE; END IF;
    END;

    BEGIN
        UPDATE maintenance.maintenance_tickets SET sla_target_hours = 24 WHERE ticket_id = 535;
        RAISE EXCEPTION 'An incorrect priority SLA target was accepted';
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS violated_constraint = CONSTRAINT_NAME;
        IF violated_constraint <> 'tickets_sla_target' THEN RAISE; END IF;
    END;
END
$$;

SELECT status, count(*) AS ticket_count
FROM maintenance.maintenance_tickets
GROUP BY status
ORDER BY status;
