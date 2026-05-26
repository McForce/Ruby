# Customer 360 View — Solution Design
**BB Ruby Agent MVP1 | Absa Business Banking**

| | |
|---|---|
| **Document Version** | v1.0 |
| **Status** | Draft |
| **Date** | 19 May 2026 |
| **Project** | BB Ruby Agent MVP1 |
| **Component** | c/customerThreeSixtyView |
| **Apex Classes** | BB_C360_Controller \| BB_C360_Helper |
| **Agent Module** | lightning/accApi |
| **Audience** | Business Stakeholders, Product Owners, Salesforce Architecture |

---

## 1  Overview

The Customer 360 View is a consolidated client intelligence interface embedded on the Account record page in Salesforce. It gives Relationship Managers a single view of a client's financial profile, compliance status, and relationship health — removing the need to navigate multiple systems before a client engagement.

The solution is built on three components working together: a Lightning Web Component that renders the interface, an Apex layer that handles data retrieval, and the native `lightning/accApi` module that launches the Ruby Agentforce agent directly from within the LWC. The Apex query logic is shared between the LWC data load and the Agentforce action — written once, used by both.

---

## 2  Architecture

### Approach

A Lightning Web Component is placed on the Account Lightning Record Page via Lightning App Builder. On load, the LWC calls the Apex controller to retrieve all Account data and renders the Customer 360 interface. A Ruby Agent launcher icon sits in the bottom-right of the component.

When the RM clicks the launcher icon, the LWC uses the native `lightning/accApi` module to open the Agentforce panel and pass the current Account Id as an opening utterance. This triggers the Ruby agent's topic, which calls the Apex controller as an Agentforce Action to query live Account data. The agent grounds its response in that data and responds to the RM within the panel.

Because the same Apex helper method is called both by the LWC on load and by the Agentforce action at query time, the data the agent reasons over is always consistent with what the RM sees on screen.

### Architecture Diagram

```
Account Lightning Record Page
        │
        ▼
c/customerThreeSixtyView  (LWC)
        │                               │
   on load                     RM clicks Ruby icon
        │                               │
        ▼                               ▼
BB_C360_Controller            lightning/accApi execute()
   @AuraEnabled                         │
        │                       Ruby Agent panel opens
        ▼                               │
BB_C360_Helper              topic fires → action called
  (shared query)                        │
        │                               ▼
        │                    BB_C360_Controller
  returns data                   @InvocableMethod
   to LWC                              │
        │                              ▼
        ▼                    BB_C360_Helper
Customer 360              (same shared query)
 View rendered                         │
                                       ▼
                         Ruby responds with live Account data
```

> **Architecture Note:** The Apex query logic is written once in `BB_C360_Helper` and shared between the LWC (`@AuraEnabled`) and the Agentforce action (`@InvocableMethod`). No duplication, no synchronisation risk.

---

## 3  Components

### LWC — c/customerThreeSixtyView

Placed on the Account Lightning Record Page via Lightning App Builder. On load the component calls the Apex controller and renders the Customer 360 interface. The Ruby Agent launcher icon in the bottom-right of the component uses the `lightning/accApi` module to open the agent panel when clicked — no custom chat UI is built, no Apex callout is made for the launch itself.

| Region | Content |
|---|---|
| **Header** | Page context label, account name, RM name and role |
| **Account Details Banner** | Account name, segment and industry tags, FICA / Relationship / Client Position KPI tiles |
| **Action Buttons** | Prepare Meeting, Log Interaction, Start Application, Send Summary, Request Support, Escalate Risk |
| **Financial Data Panels** | Four panels: Revenue & Cash Flow, Profitability Metrics, Return & Efficiency, Balance Sheet & Exposure |
| **Ruby Agent Launcher** | Floating icon — calls `lightning/accApi execute()` with Account Id as opening utterance to Ruby |

---

### lightning/accApi — Agent Launcher Module

The `lightning/accApi` module is a native headless LWC module provided by Salesforce as the Agentforce Conversation Client API. It is imported directly into the LWC JavaScript and requires no Apex, no HTTP callouts, and no external client app configuration.

| Method | Usage in Customer 360 View |
|---|---|
| `open()` | Opens the Ruby Agent panel without sending a message. Available for use if needed independently. |
| `close()` | Closes the Ruby Agent panel. Can be wired to a close action within the LWC if required. |
| `execute(utterance, botId)` | Primary method used by the Ruby launcher icon. Opens the agent panel and sends the Account Id as the opening utterance, triggering the agent topic and action. |

> **Bot Id:** Retrieved via SOQL — `SELECT Id, DeveloperName FROM BotDefinition`. This value is stored as a Custom Label or Custom Metadata in the org and referenced in the LWC at runtime.

---

### Apex — BB_C360_Controller & BB_C360_Helper

Two Apex classes handle all data retrieval. The helper contains the shared query logic — a single SOQL against the Account object with a cross-object Owner lookup for Segment, and a second query against FinancialAccount for Utilisation. The controller exposes this in two ways without duplicating any query logic.

| Class / Method | Purpose |
|---|---|
| **BB_C360_Helper** | Shared private query method. Executes SOQL against Account (including `Owner.RBB_Super_Region__c`) and FinancialAccount. Returns a typed result object. All query logic lives here only. |
| **BB_C360_Controller `@AuraEnabled`** | Called by the LWC on component load. Invokes `BB_C360_Helper` and returns Account data for the Customer 360 View to render. |
| **BB_C360_Controller `@InvocableMethod`** | Registered as a custom Agentforce Action. Called by the Ruby agent topic when the RM asks a question. Invokes `BB_C360_Helper` with the Account Id from the session context and returns live data for the agent to reason over. |

---

### Agentforce — Ruby Agent Topic & Action

| Component | Configuration |
|---|---|
| **Agent** | Ruby — existing Agentforce agent deployed for BB Relationship Managers |
| **Topic** | Customer 360 Queries — fires when the RM asks a question about the client currently in context. The Account Id passed via `execute()` at session open is available to the topic. |
| **Action** | `BB_C360_Controller @InvocableMethod` — registered as a custom Agentforce Action. Receives the Account Id as input, invokes `BB_C360_Helper`, and returns structured Account data as the agent's grounding context. |

---

## 4  Data Sources

Fields are sourced across three platforms. Salesforce fields are retrieved by `BB_C360_Helper` as part of the shared Apex query. Data Cloud and External fields are separate concerns — their retrieval mechanism and how they are surfaced in both the LWC and the agent context is a separate design item to be confirmed.

### Salesforce Fields — retrieved by BB_C360_Helper

| Status | Field | Object \| API Name |
|---|---|---|
| ✅ Confirmed | Account Legal Name | Account \| `Name` |
| ✅ Confirmed | Segment | User \| `RBB_Super_Region__c` (via `Account.Owner`) |
| ✅ Confirmed | Industry | Account \| `Industry` |
| ✅ Confirmed | FICA Status | Account \| `FICA_CIF_Flag__c` |
| ✅ Confirmed | Relationship Tenure | Account \| `FinServ__LengthOfRelationship__c` |
| ✅ Confirmed | VAPM | Account \| `VAPM__c` |
| 🟡 Likely | Sub-Industry | Account \| `Business_Sub_segment__c` — confirm with business |
| 🟡 Likely | FICA Progress | Account \| `FICA_CIF_Flag_Indicator__c` — confirm which field holds the % |
| 🟡 Likely | Client Opportunity | Account \| `LLC_BI__CustomerPriority__c` — confirm with business |
| 🟡 Likely | Total Revenue | Account \| `FinServ__TotalRevenue__c` — confirm vs Data Cloud writeback |
| 🟡 Likely | Total Exposure | Account \| `LLC_BI__Total_Direct_Exposure__c` — confirm with Mandla |
| 🟡 Likely | Utilisation | FinancialAccount \| `Balance__c ÷ CreditLimit` (derived) |
| 🟠 Possible | Relationship Strength | Account \| `Risk_Status__c` — no direct match, confirm with business |
| 🟠 Possible | Client Health | Account \| `Customer_Status__c` — no direct match, confirm with business |
| 🟠 Possible | Client Turnover | Account \| `AnnualRevenue` — awaiting Mandla Mhlongo confirmation |

---

### Fields Pending Source Confirmation

| Field | Status |
|---|---|
| Cash Flow Movement | Not found in package.xml — awaiting Mandla Mhlongo (Credit Ops) |
| Deposit Growth | Not found in package.xml — awaiting Mandla Mhlongo |
| Lending Growth | Not found in package.xml — awaiting Mandla Mhlongo |
| Client Profitability | No source identified in source model or package.xml |
| Profitability Ranking | Not on Customer Profitability model — source TBD |
| Margin Trend | Not on Customer Profitability model — source TBD |
| Risk Adjusted Return | No source identified |
| Return on Exposure | Not on Customer Profitability model — source TBD |
| Cost to Serve | Pending confirmation — check with Anuj against Customer Prof Model |

---

### Data Cloud & External Fields

PBT, PAT, RORC, Average Advances, and Average Deposits are confirmed as sourced from the Profitability Data DMO in Data Cloud. FICA fields originate from an external FICA system via integration. How these fields are retrieved and passed into both the LWC render and the Agentforce action context is a separate design item to be confirmed prior to data integration development.

---

*This document is intended for internal use only — Absa Business Banking | Salesforce Implementation Team*