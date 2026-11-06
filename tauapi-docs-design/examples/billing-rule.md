---
paths:
  - "tauapi-be/pkg/billingexpr/**"
  - "tauapi-be/setting/billing_setting/**"
  - "tauapi-be/common/quota_math.go"
  - "tauapi-be/relay/**"
  - "tauapi-be/plugins/tasks/**"
  - "tauapi-be/service/*billing*.go"
  - "tauapi-be/service/*quota*.go"
  - "tauapi-fe/src/features/pricing/**"
  - "tauapi-fe/testdata/contracts/**"
---

# Billing contract reminder

Example target: `.claude/rules/billing.md`. Install after the linked contract
exists and expand these seed patterns using the complete migration ledger.

Before changing billable quantities, pricing, pre-consume, settlement, refunds,
or usage reporting, read `docs/ai/contracts/billing-and-quota.md` in full.

Trace validation, estimation, reservation, usage, settlement/refund, and audit.
Include passthrough, multipart, plugin, stream, and cancellation paths where used.
Preserve existing bounds, quota helpers, saturation auditing, and response-count
semantics. Extend existing behavioral regression tables where suitable.

These patterns are reminders, not complete semantic coverage. Any change that
affects billing must follow the contract even when no file pattern matches.
