# Change record

Create one JSON record in `docs/ai/changes/active/<task>.json` using
`schemas/change-v1.schema.json` relative to `docs/ai/`.

```json
{
  "schema_version": 1,
  "id": "task-name",
  "base_revision": "<full base commit>",
  "work_status": "in_progress",
  "docs_impact": "affected",
  "dispositions": {},
  "validation": {
    "objective": "<problem and expected behavior>",
    "acceptance": ["<observable result>"],
    "scope": ["<affected paths>"],
    "required_reads": ["<policy and contract paths>"],
    "checks": {}
  },
  "next_action": "<next concrete step>"
}
```

Each affected contract needs a disposition containing `status`, `reason` and an
`evidence` array. Use `updated`, `reviewed_unchanged` or `not_applicable`. Record
commands and actual results under validation; mark completed when acceptance checks pass.
