import csv
import unittest
from collections import Counter
from datetime import datetime, timedelta
from decimal import Decimal
from io import StringIO
from pathlib import Path

from scripts.generate_data import datasets, write_csv


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
SLA_HOURS = {"Critical": 4, "High": 12, "Medium": 24, "Low": 48}
SNAPSHOT = datetime(2026, 7, 1)
FILES = ("equipment.csv", "technicians.csv", "maintenance_tickets.csv")


def read_rows(filename, key):
    with (DATA / filename).open(encoding="utf-8", newline="") as source:
        rows = list(csv.DictReader(source))
    indexed = {int(row[key]): row for row in rows}
    if len(indexed) != len(rows):
        raise AssertionError(f"Duplicate {key} in {filename}")
    return indexed


class SyntheticDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.equipment = read_rows(FILES[0], "equipment_id")
        cls.technicians = read_rows(FILES[1], "technician_id")
        cls.tickets = read_rows(FILES[2], "ticket_id")

    def test_generator_reproduces_committed_files(self):
        for filename, columns, rows in datasets():
            with self.subTest(filename=filename):
                output = StringIO()
                write_csv(output, columns, rows)
                self.assertEqual(output.getvalue().encode("utf-8"), (DATA / filename).read_bytes())

    def test_unique_keys_coverage_and_relationships(self):
        self.assertEqual((len(self.equipment), len(self.technicians), len(self.tickets)), (24, 12, 540))
        self.assertEqual({row["production_line"] for row in self.equipment.values()},
                         {"Line A", "Line B", "Line C", "Line D"})
        self.assertEqual({row["created_at"][:7] for row in self.tickets.values()},
                         {f"2026-{month:02d}" for month in range(1, 7)})
        self.assertEqual(Counter(row["status"] for row in self.tickets.values()),
                         {"Resolved": 518, "In Progress": 12, "Open": 10})
        self.assertEqual({row["priority"] for row in self.tickets.values()}, set(SLA_HOURS))

        specialization = {"Mechanical": "Mechanical", "Electrical": "Electrical", "Controls": "Controls",
                          "Pneumatics": "Utilities", "Process Quality": "Controls"}
        for ticket_id, row in self.tickets.items():
            with self.subTest(ticket_id=ticket_id):
                self.assertIn(int(row["equipment_id"]), self.equipment)
                if row["technician_id"]:
                    technician = self.technicians[int(row["technician_id"])]
                    self.assertEqual(technician["specialization"], specialization[row["issue_category"]])

    def test_lifecycle_sla_targets_and_downtime(self):
        for ticket_id, row in self.tickets.items():
            with self.subTest(ticket_id=ticket_id):
                created = datetime.fromisoformat(row["created_at"])
                self.assertLess(created, SNAPSHOT)
                self.assertEqual(int(row["sla_target_hours"]), SLA_HOURS[row["priority"]])
                self.assertGreaterEqual(Decimal(row["estimated_downtime_hours"]), 0)
                self.assertTrue(row["description"].strip())

                if row["status"] == "Open":
                    self.assertFalse(row["first_response_at"])
                else:
                    self.assertTrue(row["technician_id"])
                    response = datetime.fromisoformat(row["first_response_at"])
                    self.assertLessEqual(created, response)
                    self.assertLessEqual(response, SNAPSHOT)

                if row["status"] == "Resolved":
                    resolved = datetime.fromisoformat(row["resolved_at"])
                    self.assertLessEqual(response, resolved)
                    self.assertLessEqual(resolved, SNAPSHOT)
                else:
                    self.assertFalse(row["resolved_at"])

    def test_deadline_boundary_tickets(self):
        expected = {
            535: (0, True, False), 536: (60, False, False), 537: (0, None, False),
            538: (60, None, True), 539: (-151200, None, False), 540: (-60, True, False),
        }
        for ticket_id, (seconds_from_deadline, met_sla, overdue) in expected.items():
            with self.subTest(ticket_id=ticket_id):
                row = self.tickets[ticket_id]
                deadline = datetime.fromisoformat(row["created_at"]) + timedelta(hours=int(row["sla_target_hours"]))
                resolved = datetime.fromisoformat(row["resolved_at"]) if row["resolved_at"] else None
                self.assertEqual(((resolved or SNAPSHOT) - deadline).total_seconds(), seconds_from_deadline)
                self.assertEqual(resolved <= deadline if resolved else None, met_sla)
                self.assertEqual(resolved is None and SNAPSHOT > deadline, overdue)


if __name__ == "__main__":
    unittest.main()
