---
id: "REPLACE_MODULE_ID"
type: module
status: draft
owner_area: "REPLACE_AREA"
source_paths: []
contracts: []
last_verified:
  revision: null
  at: null
  method: not_reviewed
---

# Module responsibility

## Purpose and boundaries

State the user-visible responsibility, what this module owns, and what belongs
to adjacent modules. Describe a domain, not merely a source directory.

## Entry points

| Source path and symbol | Responsibility | Next boundary |
| --- | --- | --- |
| Replace with verified source | Explain why to start here | Link the next module or contract |

## Request or data flow

Describe the shortest useful chain from input to observable result. Link source
symbols. Include asynchronous work, caching, and persistence only when relevant.

## Contracts and invariants

Reference canonical contract IDs. Add module-local rules only when they have no
other canonical owner. Explain observable failure if an invariant is violated.

## Change and validation guide

| Change | Existing tests or check profile | Documentation impact |
| --- | --- | --- |
| Concrete behavior change | Verified cwd and command/profile | Contract/card/human guide |

## Failure localization

| Symptom | First inspection | Evidence that distinguishes causes |
| --- | --- | --- |
| Concrete symptom | Source/log/response boundary | Expected and alternative observations |

## Known gaps

Record unknown or unverified behavior explicitly. Link follow-up work. Do not
present a historical acceptance report as current validation.
