-- Backlog at the reporting snapshot. The overall row is the portfolio baseline.
SELECT coalesce(production_line, 'All lines') AS scope,
       count(*) FILTER (WHERE is_open) AS open_tickets,
       count(*) FILTER (WHERE is_overdue) AS overdue_tickets,
       count(*) FILTER (WHERE is_overdue AND priority = 'Critical') AS critical_overdue,
       round(max(hours_overdue), 2) AS oldest_overdue_hours
FROM maintenance.ticket_reporting
GROUP BY GROUPING SETS ((production_line), ())
ORDER BY grouping(production_line) DESC, production_line;

-- Check whether the deadline had already passed by the first technician action.
SELECT production_line,
       count(resolved_at) AS resolved_tickets,
       count(*) FILTER (WHERE met_sla) AS resolved_within_sla,
       count(*) FILTER (WHERE NOT met_sla) AS resolved_after_sla,
       count(*) FILTER (WHERE NOT met_sla AND first_response_at > sla_deadline_at) AS late_first_actions,
       round(avg(resolved_ticket_response_hours), 2) AS avg_first_response_hours
FROM maintenance.ticket_reporting
GROUP BY production_line
ORDER BY production_line;

-- Profile reported symptoms for the asset with the most tickets in the period.
WITH leading_asset AS (
    SELECT equipment_id, equipment_name, production_line, count(*) AS asset_tickets
    FROM maintenance.ticket_reporting
    GROUP BY equipment_id, equipment_name, production_line
    ORDER BY asset_tickets DESC, equipment_id
    LIMIT 1
)
SELECT asset.equipment_name, asset.production_line, asset.asset_tickets,
       ticket.issue_category, count(*) AS category_tickets
FROM leading_asset AS asset
JOIN maintenance.ticket_reporting AS report USING (equipment_id)
JOIN maintenance.maintenance_tickets AS ticket USING (ticket_id)
GROUP BY asset.equipment_name, asset.production_line, asset.asset_tickets, ticket.issue_category
ORDER BY category_tickets DESC, ticket.issue_category;

-- Compare each month's incoming volume with the average of earlier months in scope.
WITH monthly AS (
    SELECT date_trunc('month', created_at)::date AS created_month, count(*) AS tickets
    FROM maintenance.ticket_reporting
    GROUP BY created_month
), comparisons AS (
    SELECT created_month, tickets,
           avg(tickets) OVER (ORDER BY created_month ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)
               AS prior_months_avg
    FROM monthly
)
SELECT created_month, tickets, round(prior_months_avg, 2) AS prior_months_avg,
       round(100.0 * (tickets - prior_months_avg) / nullif(prior_months_avg, 0), 2) AS pct_above_prior_avg
FROM comparisons
ORDER BY created_month;
