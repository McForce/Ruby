# Salesforce Integration Architect

**Composite skill** drawing from: `sf-integration` (v1.2.0) · `sf-connected-apps` (v1.1.0) · `sf-permissions`

Use this skill when the task spans multiple integration concerns at once: OAuth app configuration AND Named Credentials AND permission auditing. For narrow single-phase work, prefer the focused source skills directly.

---

## When This Skill Owns the Task

TRIGGER on any combination of:
- Designing or troubleshooting an end-to-end integration (auth → callout → error handling)
- JWT bearer flow, client credentials, or auth-code Connected App / ECA setup **alongside** Named Credential wiring
- External Credential + Auth Provider configuration (including custom `Auth.AuthProviderPlugin` classes)
- Platform Events, Change Data Capture, or event-driven integration architecture
- Integration user access auditing — "does this user have what they need to call out?"
- Named Credential callout patterns (REST/SOAP, `callout:` syntax, merge fields)

DELEGATE narrowly-scoped work:
| If the task is only… | Use instead |
|---|---|
| Apex callout implementation / token handling code | `sf-apex` |
| Deploying integration metadata to an org | `sf-deploy` |
| Data Cloud API connectivity specifically | `sf-datacloud-architect` (this project) |
| SOQL-only data queries | `sf-soql` |

---

## Decision Framework

### 1 — Choose the App Model
| Situation | Prefer |
|---|---|
| New development, packaging, stronger secret handling | External Client App (ECA) |
| Legacy compatibility, simple single-org | Connected App |
| Spring '26+ org (new Connected Apps disabled by default) | ECA unless legacy required |

### 2 — Choose the OAuth Flow
| Use case | Flow |
|---|---|
| Server-to-server / CI/CD / integration user | JWT Bearer |
| Backend web app | Authorization Code |
| SPA / mobile / public client | Authorization Code + PKCE |
| Service account (headless) | Client Credentials (ECA) |
| CLI / device | Device Flow |

### 3 — Choose the Callout Pattern
| Pattern | When to use |
|---|---|
| Named Credential (legacy) | Simple endpoint + auth, single org |
| External Credential + Named Credential (per-user) | Per-user OAuth identity |
| External Credential + Named Credential (named principal) | Service-account / org-wide identity |
| Custom Auth Provider (`Auth.AuthProviderPlugin`) | Non-standard OAuth flows (e.g. Data Cloud two-step) |

### 4 — Choose Sync vs Async
- **Synchronous**: simple queries, <10s response, low volume
- **Asynchronous** (Queueable/Batch): high volume, retries needed, fire-and-forget
- **Platform Events / CDC**: event-driven, decoupled systems, audit trail required
- Never do synchronous callouts from triggers

---

## JWT Bearer Flow Checklist

For server-to-server integrations using JWT bearer (the most common pattern for Data Cloud and external system integration):

- [ ] Certificate created in **Setup > Certificate and Key Management** — note the **exact** API Name (case-sensitive)
- [ ] Certificate public key uploaded to the Connected App / ECA
- [ ] `isNamedUserJwtEnabled = true` on Connected App **OR** JWT flow enabled on ECA
- [ ] `isAdminApproved = true` + integration user's profile listed under permitted profiles
- [ ] Scopes: minimum required — typically `api` + feature-specific scopes; **exclude** `refresh_token` unless explicitly needed (JWT bearer does not use refresh tokens)
- [ ] **"Issue JWT-based access tokens"** (`isNamedUserJwtEnabled`) — understand what this controls: it changes the *format* of the returned access token to JWT. JWT-format access tokens **cannot be used as subject_tokens** in token exchange flows (e.g. Data Cloud `/services/a360/token`). Leave unchecked unless downstream systems explicitly require JWT-format tokens.
- [ ] Stale OAuth approvals cleared for integration user (JWT bearer combines scopes across all prior approvals — excess accumulated approvals cause `too many scopes requested`)
- [ ] Remote Site Setting for all callout endpoints (including self-referencing org endpoints)
- [ ] External Credential Principal has a Permission Set granting **External Credential Principal Access** — assigned to any user who must authenticate

---

## External Credential Setup (OAuth 2.0 + Custom Auth Provider)

```
External Credential
  ├── Authentication Protocol: OAuth 2.0
  ├── Auth Provider: <your Auth.AuthProviderPlugin class>
  ├── Principal (Named Principal for org-wide / Per-User for user-specific)
  │     └── Scope: leave blank unless the auth provider requires it
  └── No External Auth Identity Provider needed for custom plugin flows

Named Credential
  ├── URL: the target API base URL
  ├── External Credential: <above>
  └── Generate Authorization Header: true (default)

Permission Set (REQUIRED)
  └── External Credential Principal Access → <principal name>
      Assign to: every user who will authenticate or use the credential
```

---

## Security Rules (Non-Negotiable)

| Anti-pattern | Risk | Fix |
|---|---|---|
| Hardcoded credentials in Apex or metadata | Secret exposure | Named/External Credentials |
| Synchronous callout from trigger | Governor limit exception | Queueable or Platform Event |
| Missing timeout on `HttpRequest` | Thread starvation | Always `req.setTimeout(30000)` |
| Wildcard callback URL | Token interception | Explicit domain callback |
| `Full` scope on Connected App | Excess privilege | Minimum required scopes only |
| Consumer secret in source control | Credential exposure | Custom Metadata or Named Credential secret field |
| JWT-format access tokens used as subject_token | Exchange fails | Uncheck "Issue JWT-based access tokens" |

---

## Quality Score (120 points)

| Area | Max | Production-ready threshold |
|---|---|---|
| Auth model selection | 30 | — |
| Callout pattern and error handling | 30 | — |
| Security (creds, scopes, callbacks) | 30 | — |
| Async/retry/logging strategy | 30 | — |
| **Total** | **120** | **108+ ship · 72–107 review · <72 block** |

---

## Key Metadata Locations

```
force-app/main/default/
  connectedApps/          → .connectedApp-meta.xml
  externalClientApps/     → .eca-meta.xml
  authproviders/          → .authprovider-meta.xml
  externalCredentials/    → .externalCredential-meta.xml
  namedCredentials/       → .namedCredential-meta.xml
  customMetadata/         → CMT records for auth config
  remoteSiteSettings/     → .remoteSite-meta.xml
```

---

## Cross-Skill Handoff Map

| Next task | Skill |
|---|---|
| Apex callout implementation | `sf-apex` |
| Deploying this metadata | `sf-deploy` |
| Permission set creation | `sf-metadata` |
| Permission audit ("who has access?") | `sf-permissions` |
| Data Cloud API integration | `sf-datacloud-architect` |

*Sources: sf-integration v1.2.0, sf-connected-apps v1.1.0, sf-permissions — Jaganpro/sf-skills*
