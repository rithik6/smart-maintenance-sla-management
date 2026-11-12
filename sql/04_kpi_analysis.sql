-- Status and priority breakdown. Open and In Progress both contribute to open tickets.
SELECT status, priority, count(*) AS total_tickets
FROM maintenance.ticket_reporting
GROUP BY status, priority
ORDER BY CASE status WHEN 'Open' THEN 1 WHEN 'In Progress' THEN 2 ELSE 3 END,
         CASE priority WHEN 'Critical' THEN 1 WHEN 'High' THEN 2 WHEN 'Medium' THEN 3 ELSE 4 END;

-- Incoming monthly workload. The month is based on ticket creation.
SELECT date_trunc('month', created_at)::date AS created_month, count(*) AS total_tickets
FROM maintenance.ticket_reporting
GROUP BY created_month
ORDER BY created_month;

-- Line comparison. Workload gives context for the SLA percentage and backlog.
SELECT production_line,
       count(*) AS total_tickets,
       count(*) FILTER (WHERE is_open) AS open_tickets,
       count(*) FILTER (WHERE is_overdue) AS overdue_tickets,
       count(resolved_at) AS resolved_tickets,
       count(*) FILTER (WHERE met_sla) AS resolved_within_sla,
       round(100.0 * count(*) FILTER (WHERE met_sla) / nullif(count(resolved_at), 0), 2) AS sla_compliance_pct,
       round(avg(repair_hours), 2) AS mttr_hours
FROM maintenance.ticket_reporting
GROUP BY production_line
ORDER BY production_line;

-- Top 10 assets with repeated incidents. An asset qualifies after two tickets in the period.
SELECT equipment_id, equipment_name, production_line,
       count(*) AS total_tickets,
       count(*) FILTER (WHERE is_overdue) AS overdue_tickets
FROM maintenance.ticket_reporting
GROUP BY equipment_id, equipment_name, production_line
HAVING count(*) >= 2
ORDER BY total_tickets DESC, equipment_id
LIMIT 10;

-- Oldest breached deadlines first. Hours are displayed to two decimal places.
SELECT ticket_id, equipment_name, production_line, priority, status,
       created_at, sla_deadline_at, round(hours_overdue, 2) AS hours_overdue
FROM maintenance.ticket_reporting
WHERE is_overdue
ORDER BY sla_deadline_at, ticket_id;
