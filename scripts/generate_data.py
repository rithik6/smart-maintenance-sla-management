"""Generate the deterministic synthetic maintenance dataset using Python 3.11+."""

import argparse
import csv
import random
from calendar import monthrange
from datetime import datetime, timedelta
from pathlib import Path


DATA_DIR = Path(__file__).resolve().parents[1] / "data"
SNAPSHOT = datetime(2026, 7, 1)
MINUTE = timedelta(minutes=1)
HOUR = timedelta(hours=1)
SLA_HOURS = {"Critical": 4, "High": 12, "Medium": 24, "Low": 48}
MONTHLY_TICKETS = (76, 82, 87, 84, 93, 112)

# Symptoms, technician specializations, and the chance of a high-impact issue.
ISSUES = {
    "Mechanical": ("Mechanical", ("drive vibration above normal", "bearing noise during operation",
                                   "belt tension below specification"), 0.31),
    "Electrical": ("Electrical", ("motor overload relay tripped", "intermittent power at the drive",
                                   "starter contactor failed to engage"), 0.41),
    "Controls": ("Controls", ("position sensor missed a cycle", "drive reported a communication fault",
                               "feedback signal drifted from its setpoint"), 0.34),
    "Pneumatics": ("Utilities", ("air pressure dropped during cycling", "cylinder returned slowly",
                                  "air leak detected at the valve manifold"), 0.24),
    "Process Quality": ("Controls", ("output drifted outside process tolerance",
                                      "recipe change required recalibration",
                                      "verification check flagged inconsistent output"), 0.17),
}

# Asset classes list plausible issue categories in frequency order.
ASSET_ISSUES = {
    "Conveyor": ("Mechanical", "Controls", "Electrical"),
    "Press": ("Mechanical", "Pneumatics", "Electrical"),
    "Robot": ("Controls", "Electrical", "Mechanical"),
    "Tester": ("Process Quality", "Controls", "Electrical"),
    "Sealer": ("Pneumatics", "Process Quality", "Mechanical"),
    "Feeder": ("Mechanical", "Controls", "Pneumatics"),
}

LINES = (
    ("Line A", "Fabrication Bay", ("Press", "Feeder", "Conveyor", "Robot", "Tester", "Press")),
    ("Line B", "Assembly Bay", ("Conveyor", "Robot", "Tester", "Feeder", "Conveyor", "Robot")),
    ("Line C", "Packaging Bay", ("Sealer", "Conveyor", "Feeder", "Tester", "Sealer", "Conveyor")),
    ("Line D", "Finishing Bay", ("Tester", "Press", "Robot", "Conveyor", "Feeder", "Sealer")),
)

EQUIPMENT_COLUMNS = ("equipment_id", "equipment_name", "production_line", "location", "status")
TECHNICIAN_COLUMNS = ("technician_id", "technician_name", "specialization")
TICKET_COLUMNS = (
    "ticket_id", "equipment_id", "technician_id", "issue_category", "description", "priority",
    "status", "created_at", "first_response_at", "resolved_at", "sla_target_hours",
    "estimated_downtime_hours",
)


def catalog():
    equipment = []
    issue_profiles = []
    for line, location, asset_types in LINES:
        for position, asset_type in enumerate(asset_types, start=1):
            equipment_id = len(equipment) + 1
            status = "Standby" if equipment_id in {6, 18, 24} else "Active"
            name = f"{line[-1]}-{position:02d} {asset_type}"
            equipment.append((equipment_id, name, line, location, status))
            issue_profiles.append(ASSET_ISSUES[asset_type])

    technicians = []
    for specialization in ("Mechanical", "Electrical", "Controls", "Utilities"):
        for _ in range(3):
            technician_id = len(technicians) + 1
            technicians.append((technician_id, f"Technician {technician_id:02d}", specialization))
    return equipment, issue_profiles, technicians


def created_time(rng, month, recent):
    last_day = monthrange(2026, month)[1]
    day = rng.randint(last_day - 4 if recent else 1, last_day)
    hour = rng.choices((rng.randint(6, 21), rng.randint(0, 23)), (9, 1))[0]
    return datetime(2026, month, day, hour, rng.randrange(60))


def ticket_history(rng, created, priority, line):
    target = SLA_HOURS[priority] * HOUR
    # Simulate dispatch delays and repair effort separately. One line has more queue pressure.
    long_wait = rng.random() < (0.27 if line == "Line B" else 0.14)
    response_factor = rng.uniform(0.45, 1.65) if long_wait else rng.triangular(0.01, 0.42, 0.07)
    repair_factor = rng.triangular(0.12, 1.45, 0.35)
    response = created + max(1, round(response_factor * target / MINUTE)) * MINUTE
    resolution = response + max(5, round(repair_factor * target / MINUTE)) * MINUTE

    # A small share of late-June requests wait for dispatch or parts beyond the snapshot.
    if created >= SNAPSHOT - 7 * 24 * HOUR:
        remaining = rng.random()
        if remaining < 0.10:
            response = max(response, SNAPSHOT + 6 * HOUR)
        elif remaining < 0.30:
            resolution = max(resolution, SNAPSHOT + 12 * HOUR)

    if response > SNAPSHOT:
        return "Open", None, None
    if resolution > SNAPSHOT:
        return "In Progress", response, None
    return "Resolved", response, resolution


def boundary_tickets(first_id):
    """Stable ticket IDs for verifying on-time and overdue deadline comparisons."""
    june = datetime(2026, 6, 17, 8)
    rows = (
        (1, 1, "Mechanical", "Press guide realigned after excessive play", "High", "Resolved",
         june, june + HOUR, june + 12 * HOUR, "3.25"),
        (2, 4, "Electrical", "Feeder motor starter replaced after repeated trips", "High", "Resolved",
         june, june + HOUR, june + 12 * HOUR + MINUTE, "4.00"),
        (3, None, "Controls", "Conveyor encoder fault awaiting dispatch", "Critical", "Open",
         SNAPSHOT - 4 * HOUR, None, None, "2.50"),
        (4, 7, "Controls", "Robot axis position fault under diagnosis", "Critical", "In Progress",
         SNAPSHOT - 4 * HOUR - MINUTE, SNAPSHOT - 3 * HOUR, None, "2.75"),
        (5, None, "Process Quality", "Tester calibration check queued for the next shift", "Low", "Open",
         SNAPSHOT - 6 * HOUR, None, None, "0.00"),
        (6, 10, "Pneumatics", "Standby press cylinder seal replaced after an air leak", "High", "Resolved",
         june, june + HOUR, june + 12 * HOUR - MINUTE, "2.00"),
    )
    for ticket_id, row in enumerate(rows, start=first_id):
        equipment_id, technician_id, category, description, priority, status, created, response, resolved, downtime = row
        yield (ticket_id, equipment_id, technician_id, category, description, priority, status,
               created, response, resolved, SLA_HOURS[priority], downtime)


def generate_tickets(equipment, issue_profiles, technicians):
    rng = random.Random(20260701)
    assets_by_id = {row[0]: row for row in equipment}
    weights = [0.45 if row[4] == "Standby" else 1.0 for row in equipment]
    weights[6] = 2.6  # Higher utilization for the main assembly conveyor.
    weights[12] = 1.9  # Higher utilization for the first packaging sealer.
    tickets = []

    for month, count in enumerate(MONTHLY_TICKETS, start=1):
        for position in range(count):
            equipment_id = rng.choices(tuple(assets_by_id), weights=weights)[0]
            _, name, line, _, _ = assets_by_id[equipment_id]
            category = rng.choices(issue_profiles[equipment_id - 1], (6, 3, 2))[0]
            specialization, symptoms, high_impact = ISSUES[category]
            priority = rng.choices(tuple(SLA_HOURS), (high_impact * 20, high_impact * 80,
                                                      (1 - high_impact) * 67, (1 - high_impact) * 33))[0]
            created = created_time(rng, month, month == 6 and position < 16)
            status, response, resolved = ticket_history(rng, created, priority, line)

            technician_id = rng.choice([row[0] for row in technicians if row[2] == specialization])
            if status == "Open" and rng.random() < 0.72:
                technician_id = None
            impact = {"Critical": (0.50, 1.00), "High": (0.20, 0.70),
                      "Medium": (0.00, 0.35), "Low": (0.00, 0.12)}[priority]
            duration = (resolved - created) / HOUR if resolved else SLA_HOURS[priority]
            downtime = 0.0 if priority in {"Low", "Medium"} and rng.random() < 0.25 else duration * rng.uniform(*impact)
            description = f"{name}: {rng.choice(symptoms)}"
            tickets.append((equipment_id, technician_id, category, description, priority, status,
                            created, response, resolved, SLA_HOURS[priority], f"{downtime:.2f}"))

    tickets.sort(key=lambda row: row[6])
    yield from ((ticket_id, *row) for ticket_id, row in enumerate(tickets, start=1))
    yield from boundary_tickets(len(tickets) + 1)


def datasets():
    equipment, profiles, technicians = catalog()
    return (
        ("equipment.csv", EQUIPMENT_COLUMNS, equipment),
        ("technicians.csv", TECHNICIAN_COLUMNS, technicians),
        ("maintenance_tickets.csv", TICKET_COLUMNS, generate_tickets(equipment, profiles, technicians)),
    )


def write_csv(output, columns, rows):
    writer = csv.writer(output, lineterminator="\n")
    writer.writerow(columns)
    writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=DATA_DIR)
    output = parser.parse_args().output_dir
    output.mkdir(parents=True, exist_ok=True)
    for filename, columns, rows in datasets():
        with (output / filename).open("w", encoding="utf-8", newline="") as stream:
            write_csv(stream, columns, rows)


if __name__ == "__main__":
    main()
