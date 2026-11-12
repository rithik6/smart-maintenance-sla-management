# Maintenance process flows

These workflows describe a fictional factory. The AS-IS map shows the scenario's manual process. The TO-BE map proposes changes for a future operating process. The portfolio demonstrates the data and reporting steps with a fixed synthetic snapshot.

## AS-IS — Requests tracked across channels

```mermaid
flowchart LR
    A["Operator observes equipment issue"] --> B{"Report through available channel"}
    B --> C["Spreadsheet"]
    B --> D["Email"]
    B --> E["Phone call"]
    C --> F["Supervisor reconciles incoming requests"]
    D --> F
    E --> F
    F --> G["Supervisor assigns technician and interprets urgency"]
    G --> H["Technician repairs equipment and sends an update"]
    H --> I["Supervisor follows up and updates the tracker"]
    I --> J["Manager compiles a periodic spreadsheet summary"]
```

Different channels can omit an asset ID, timestamp, or status update. Supervisors have to check several places to learn whether work was assigned, started, or closed. Managers have no shared definition of an SLA breach.

## TO-BE — Standard ticket workflow with SLA reporting

```mermaid
flowchart LR
    A["Production logs a ticket with asset and impact"] --> B["Maintenance validates details and assigns priority"]
    B --> C["Record the creation time and SLA deadline"]
    C --> D["Assign a technician"]
    D --> E["Record first action and set status to In Progress"]
    E --> F["Complete work and record closure and repair notes"]
    C --> G["Monitor the open and in-progress queue"]
    G --> H{"Unresolved ticket past its deadline?"}
    H -- "Yes" --> I["Manager confirms owner and communicates escalation"]
    H -- "No" --> G
    I --> G
    C --> J["Standardized ticket records"]
    D --> J
    E --> J
    F --> J
    J --> K["Power BI reports backlog, SLA, and repeat incidents"]
    K --> L["Manager reviews worklist and improvement actions"]
```

Proposed escalation requires a maintenance owner and a communication step. In the portfolio, PostgreSQL holds the standardized records, and Power BI reads them for reporting. In a deployment, a ticketing system would capture and update those records.

[Business requirements](business_requirements.md) · [Rules and SLA thresholds](business_rules.md)
