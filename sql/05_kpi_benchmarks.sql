-- Reference for the five Power BI measures and supporting metrics.
-- Add a scenario here to benchmark a specific set of slicer selections.
WITH scenarios (id, scenario, from_date, to_date_exclusive, production_line, priority, status) AS (
    VALUES
        (1, 'All tickets', NULL::date, NULL::date, NULL::text, NULL::text, NULL::text),
        (2, 'June 2026', DATE '2026-06-01', DATE '2026-07-01', NULL, NULL, NULL),
        (3, 'Line B | High', NULL, NULL, 'Line B', 'High', NULL),
        (4, 'June 2026 | Line B | High | Resolved', DATE '2026-06-01', DATE '2026-07-01', 'Line B', 'High', 'Resolved'),
        (5, 'Open status', NULL, NULL, NULL, NULL, 'Open'),
        (6, 'January 2026 | Open', DATE '2026-01-01', DATE '2026-02-01', NULL, NULL, 'Open')
)
SELECT scenario.scenario,
       count(ticket.ticket_id) AS total_tickets,
       count(*) FILTER (WHERE ticket.is_open) AS open_tickets,
       count(*) FILTER (WHERE ticket.is_overdue) AS overdue_tickets,
       count(ticket.resolved_at) AS resolved_tickets,
       count(*) FILTER (WHERE ticket.met_sla) AS resolved_within_sla,
       count(*) FILTER (WHERE NOT ticket.met_sla) AS resolved_after_sla,
       round(100.0 * count(*) FILTER (WHERE ticket.met_sla) / nullif(count(ticket.resolved_at), 0), 4) AS sla_compliance_pct,
       round(avg(ticket.repair_hours), 4) AS mttr_hours,
       round(avg(ticket.resolution_hours), 4) AS avg_request_to_resolution_hours,
       round(avg(ticket.resolved_ticket_response_hours), 4) AS avg_first_response_hours
FROM scenarios AS scenario
LEFT JOIN maintenance.ticket_reporting AS ticket
    ON (scenario.from_date IS NULL OR ticket.created_at >= scenario.from_date)
   AND (scenario.to_date_exclusive IS NULL OR ticket.created_at < scenario.to_date_exclusive)
   AND (scenario.production_line IS NULL OR ticket.production_line = scenario.production_line)
   AND (scenario.priority IS NULL OR ticket.priority = scenario.priority)
   AND (scenario.status IS NULL OR ticket.status = scenario.status)
GROUP BY scenario.id, scenario.scenario
ORDER BY scenario.id;
