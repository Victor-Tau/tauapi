# Shared engineering rules

## Code quality

Use early returns, clear branches and domain names. Keep functions focused. Extract a
helper for reusable behavior, framework callbacks, exported APIs, test fixtures or complex
business logic that needs direct tests. Keep simple single-use logic at its call site.
Use nested functions when the callback API or local closure benefits from them.

## Authentication

Authentication work follows the [authentication contract](contracts/authentication.md),
the latest stable [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
and relevant [OWASP cheat sheets](https://cheatsheetseries.owasp.org/).
Read the guidance for each affected mechanism before implementation: authentication,
sessions, password storage/recovery, MFA, OAuth and CSRF.

Enforce credential protection, enumeration and brute-force controls, CSRF/replay protection,
expiry, single use, session rotation/revocation and reauthentication on the server. Apply
these controls to recovery and alternative login paths as well. Audit events record useful
context and exclude passwords, codes, private keys and usable tokens.

Test affected success, failure, expiry, replay and bypass cases. Record OWASP references,
ASVS version/IDs when used, results and remaining work in the change record.

## Attribution

Preserve New API / QuantumNous identity, copyrights, licenses, upstream README files,
module paths, metadata and attribution in source, UI, packages and deployment artifacts.

## Issues

Use `tauapi-be/.agents/github/ISSUE.md` for issue scope and the complete issue body.
Requests about Coding Plan, reverse-engineered channels, third-party wrappers/hosts,
Codex reverse-proxy compatibility and pass-through-only forwarding are outside its scope.
For usage, configuration and integration questions, consult upstream documentation, README
and source and answer directly. Search existing documentation before reporting a defect.

For a defect report, establish actual behavior, impact, frequency, evidence that the defect
is in new-api, and relevant relay/billing/frontend/deployment details. Ask for missing facts.
Quote the user's request faithfully in the template and keep answers factual. File an issue
once the required facts are available; use the template body rather than GitHub issue forms.

## Pull requests

Compare the current Git author with recurring core authors in Git history. Keep Git config
unchanged. State AI assistance in the PR body when the author is not a core developer.

For an owner request, use `tauapi-be/.github/PULL_REQUEST_TEMPLATE.md` for Chinese requests
or `tauapi-be/.github/PULL_REQUEST_TEMPLATE/en.md` for English requests. Use
`tauapi-be/.agents/github/PR.md` for other agent-created PRs. An explicit owner template
choice takes precedence.

Fill the chosen template completely, quote the request faithfully, and list commands and
observed results. Resolve missing required facts before opening the PR. Keep descriptions
and comments short and factual.
