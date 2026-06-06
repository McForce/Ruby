# Salesforce Data Cloud Architect

**Composite skill** drawing from: `sf-datacloud` · `sf-datacloud-connect` · `sf-datacloud-prepare` · `sf-datacloud-harmonize` · `sf-datacloud-segment` · `sf-datacloud-act` · `sf-datacloud-retrieve` · `sf-connected-apps` · `sf-integration`

Use this skill when work spans multiple Data Cloud phases, or when the root cause isn't yet isolated to a single phase. For narrow single-phase work, the focused source skills are more efficient.

---

## When This Skill Owns the Task

TRIGGER on:
- End-to-end Data Cloud pipeline design or cross-phase troubleshooting
- Data Cloud API authentication (JWT bearer → Data Cloud token exchange)
- Data Graph setup and querying
- Data space and data kit management
- Health checks where the broken phase is unknown
- CRM-to-Unified-Profile architecture decisions
- Named Credential wiring to a Data Cloud tenant URL

DELEGATE narrow work to the phase skill:
| Phase | Skill |
|---|---|
| Connector setup, source discovery | `sf-datacloud-connect` |
| Data streams, DLOs, transforms, DocAI | `sf-datacloud-prepare` |
| DMOs, field mappings, identity resolution, data graphs | `sf-datacloud-harmonize` |
| Segments, calculated insights, member counts | `sf-datacloud-segment` |
| Activations, activation targets, data actions | `sf-datacloud-act` |
| SQL queries, vector/hybrid search, table metadata | `sf-datacloud-retrieve` |
| Apex callout implementation | `sf-apex` |
| Session tracing / STDM parquet analysis | `sf-ai-agentforce-observability` |

---

## Data Cloud API Authentication (Single-Org Setup)

For a single Salesforce org directly connected to Data Cloud (`*.c360a.salesforce.com`), authentication is a **two-step token exchange**:

```
Step 1 — JWT Bearer → Core SF Token
  POST {org_domain}/services/oauth2/token
  grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer
  assertion={signed_JWT}
  → returns: core Salesforce access_token

Step 2 — Core Token → Data Cloud Token
  POST {org_domain}/services/a360/token
  grant_type=urn:salesforce:grant-type:external:cdp
  subject_token={core_access_token}
  subject_token_type=urn:ietf:params:oauth:token-type:access_token
  → returns: Data Cloud access_token + instance_url
```

### Connected App Requirements for Data Cloud Auth

| Setting | Required value | Why |
|---|---|---|
| `isNamedUserJwtEnabled` | `false` (or unchecked) | JWT-format access tokens CANNOT be used as `subject_token` in the a360 exchange — they are REST-API-only. Leave this unchecked. |
| "Use digital signatures" | enabled + certificate uploaded | Required for JWT bearer assertion signing |
| Scopes | `api`, `cdp_profile_api`, `cdp_query_api` | Minimum for Data Cloud access |
| `refresh_token` scope | Include — JWT bearer requires it for pre-authorized flows | Remove only if stale approval bloat causes `too many scopes requested` errors |
| `isAdminApproved` | `true` + integration user's profile listed | Pre-authorization for JWT bearer |
| Access Token Format | **Opaque** (do NOT enable "Issue JWT-based access tokens") | Required for a360 token exchange |

### Managed Package Auth Provider (lwt__DataCloudAuthProvider)

If using the `lwt__DataCloudAuthProvider` managed package, configure the `lwt__DataCloudAuthProvider__mdt` CMT record:

| CMT Field | Value |
|---|---|
| `lwt__Auth_Provider_Name__c` | Must match the Auth Provider's URL suffix exactly |
| `lwt__Connected_App_Id__c` | Consumer Key of the Connected App |
| `lwt__Integration_Username__c` | Integration user's username |
| `lwt__JWT_Signing_Certificate_Name__c` | Certificate API Name (case-sensitive) |
| `lwt__My_Domain_URL__c` | Org's My Domain URL (single-org: same as Hub Org) |
| `lwt__Data_Space_Name__c` | Leave blank for default data space |
| `lwt__Is_Sandbox__c` | `false` for production/developer orgs |

### External Credential Setup for Data Cloud

```
External Credential
  ├── Authentication Protocol: OAuth 2.0
  ├── Auth Provider: <DataCloud auth provider>
  ├── Principal (Named Principal)
  │     └── Scope: leave BLANK (do not set to "1" or any value)
  └── No External Auth Identity Provider needed

Named Credential
  ├── URL: https://<tenant-id>.c360a.salesforce.com
  ├── External Credential: <above>
  └── Generate Authorization Header: true

Permission Set (REQUIRED to authenticate principal)
  └── External Credential Principal Access → <principal name>
      Assign to: the user clicking "Authenticate" on the principal
```

### Common Auth Errors

| Error | Root cause | Fix |
|---|---|---|
| `too many scopes requested` | Accumulated stale OAuth approvals for integration user (JWT bearer combines scopes across ALL prior approvals) | Revoke all OAuth tokens for integration user via Setup > Users > OAuth Connected Apps |
| `invalid subject token` on a360 exchange | Core access token is JWT-format (not opaque) | Uncheck "Issue JSON Web Token (JWT)-based access tokens for named users" on Connected App |
| `refresh_token scope is required` | Scope trimmed too aggressively | Restore `refresh_token` scope on Connected App |
| `Data not available` | Certificate API Name wrong (case-sensitive) | Verify exact name in Setup > Certificate and Key Management |

---

## Data Cloud Pipeline — Phase Overview

### Phase 1: Connect
Set up source connectors to bring data into Data Cloud.

- CLI: `sf data360 connection *`
- Key gotcha: connector catalog name ≠ connection connector type label
- Ingestion API setup is incomplete until schema is uploaded via `connection schema-upsert`
- Snowflake and SharePoint have distinct credential shapes

### Phase 2: Prepare
Create Data Streams and Data Lake Objects (DLOs) from connected sources.

- Classify datasets as **Profile**, **Engagement**, or **Other** before creating streams
- DLO field naming: `__c` suffix becomes `_c` (differs from CRM convention)
- Stream refresh and connection-level reruns are not interchangeable
- Some connectors require UI for initial stream creation

### Phase 3: Harmonize
Map DLOs to Data Model Objects (DMOs), configure identity resolution, build data graphs.

- Inspect DMO schemas before mapping — never assume field names
- Identity resolution runs are **asynchronous** — always verify after completion
- Data Graphs are built on top of harmonized DMOs — requires healthy IR

### Phase 4: Segment
Build audiences and calculated insights on unified profiles.

- Data Cloud SQL is **not SOQL** — table names require double-quotes
- Always verify outcomes via counts/queries, not just publish success
- Use `--api-version 64.0` if segment creation is unstable on newer defaults

### Phase 5: Act
Push audiences into external systems via activations and activation targets.

- Create activation **targets first**, then activations
- Activations require a **healthy published upstream segment**
- Verify downstream connectivity before assuming delivery success

### Phase 6: Retrieve
Query Data Cloud data directly via SQL or vector/hybrid search.

- Query selection: count → `sqlv2` → async (use smallest shape that fits)
- Vector/hybrid search requires healthy search indexes — run `describe` first
- Hybrid queries support prefilters only on fields configured at index creation

---

## Data Graph API (Query)

After obtaining a Data Cloud access token, query the Data Graph:

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:BB_C360_DataCloud/api/v2/dataGraph/<graphName>/query');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setBody('{"sql": "SELECT 1"}');
HttpResponse res = new Http().send(req);
```

Or direct REST:
```
POST https://<tenant>.c360a.salesforce.com/api/v2/dataGraph/<graphName>/query
Authorization: Bearer <data_cloud_access_token>
Content-Type: application/json
{"sql": "SELECT \"fieldName\" FROM \"ObjectName\" LIMIT 10"}
```

Note: Data Cloud SQL requires double-quoted identifiers. Standard SOQL syntax does not apply.

---

## Required Prerequisites

- [ ] `sf data360` CLI plugin installed: `sf plugins install @salesforce/plugin-data360`
- [ ] Org authenticated with `sf org login web`
- [ ] Integration user has: `Data Cloud User`, `Data Cloud Architect`, and relevant feature permission sets assigned
- [ ] Remote Site Settings active for: org's My Domain URL + Data Cloud tenant URL (`*.c360a.salesforce.com`)
- [ ] Certificate exists in org's Certificate and Key Management

---

## Readiness Check (run before mutations)

```bash
node ~/.claude/skills/sf-datacloud/scripts/diagnose-org.mjs -o <org-alias> --json
```

Note: `sf data360 doctor` can fail on partially-provisioned orgs even when read-only commands work. Use targeted smoke-test commands instead of treating doctor output as final proof.

---

## Key Metadata Locations

```
force-app/main/default/
  connectedApps/              → .connectedApp-meta.xml (Data Cloud Connected App)
  authproviders/              → .authprovider-meta.xml (lwt__DataCloudAuthProvider)
  externalCredentials/        → .externalCredential-meta.xml
  namedCredentials/           → .namedCredential-meta.xml (URL: *.c360a.salesforce.com)
  customMetadata/             → lwt__DataCloudAuthProvider__mdt CMT records
```

---

## Quality Score (Data Cloud)

| Area | Max |
|---|---|
| Auth setup correctness (JWT → token exchange) | 25 |
| Pipeline phase coverage (connect → act) | 25 |
| Data model design (DMOs, identity resolution) | 25 |
| Operational readiness (logging, error handling, readiness checks) | 25 |
| **Total** | **100** · 90+ ship · 70–89 review · <70 block |

*Sources: sf-datacloud, sf-datacloud-connect, sf-datacloud-prepare, sf-datacloud-harmonize, sf-datacloud-segment, sf-datacloud-act, sf-datacloud-retrieve, sf-connected-apps, sf-integration — Jaganpro/sf-skills (archived Apr 2026)*
