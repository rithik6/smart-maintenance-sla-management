"""Compare an exported PostgreSQL benchmark CSV with the source data."""

import argparse
import csv
from datetime import datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from unittest import TestCase


DATA = Path(__file__).resolve().parents[1] / "data"
SNAPSHOT = datetime(2026, 7, 1)


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as source:
        return list(csv.DictReader(source))


def ratio(numerator, denominator):
    if denominator == 0:
        return ""
    result = Decimal(numerator) / denominator
    return str(result.quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP))


def summarize(scenario, rows):
    opened = overdue = resolved = on_time = 0
    repair_seconds = resolution_seconds = response_seconds = 0
    for row in rows:
        created = datetime.fromisoformat(row["created_at"])
        deadline = created + timedelta(hours=int(row["sla_target_hours"]))
        if row["status"] == "Resolved":
            response = datetime.fromisoformat(row["first_response_at"])
            closure = datetime.fromisoformat(row["resolved_at"])
            resolved += 1
            on_time += closure <= deadline
            repair_seconds += int((closure - response).total_seconds())
            resolution_seconds += int((closure - created).total_seconds())
            response_seconds += int((response - created).total_seconds())
        else:
            opened += 1
            overdue += SNAPSHOT > deadline

    return {
        "scenario": scenario,
        "total_tickets": str(len(rows)),
        "open_tickets": str(opened),
        "overdue_tickets": str(overdue),
        "resolved_tickets": str(resolved),
        "resolved_within_sla": str(on_time),
        "resolved_after_sla": str(resolved - on_time),
        "sla_compliance_pct": ratio(100 * on_time, resolved),
        "mttr_hours": ratio(repair_seconds, resolved * 3600),
        "avg_request_to_resolution_hours": ratio(resolution_seconds, resolved * 3600),
        "avg_first_response_hours": ratio(response_seconds, resolved * 3600),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("benchmark_csv", type=Path, help="psql --csv output from sql/05_kpi_benchmarks.sql")
    args = parser.parse_args()
    lines = {row["equipment_id"]: row["production_line"] for row in read_csv(DATA / "equipment.csv")}
    tickets = read_csv(DATA / "maintenance_tickets.csv")
    june = [ticket for ticket in tickets if ticket["created_at"].startswith("2026-06-")]
    line_b_high = [ticket for ticket in tickets
                   if lines[ticket["equipment_id"]] == "Line B" and ticket["priority"] == "High"]
    open_status = [ticket for ticket in tickets if ticket["status"] == "Open"]
    expected = [
        summarize("All tickets", tickets),
        summarize("June 2026", june),
        summarize("Line B | High", line_b_high),
        summarize("June 2026 | Line B | High | Resolved", [
            ticket for ticket in line_b_high
            if ticket["created_at"].startswith("2026-06-") and ticket["status"] == "Resolved"
        ]),
        summarize("Open status", open_status),
        summarize("January 2026 | Open", [
            ticket for ticket in open_status if ticket["created_at"].startswith("2026-01-")
        ]),
    ]
    checks = TestCase()
    checks.maxDiff = None
    checks.assertEqual(read_csv(args.benchmark_csv), expected)
    print(f"All {len(expected)} SQL benchmark rows match independent calculations from the source CSVs.")


if __name__ == "__main__":
    main()
