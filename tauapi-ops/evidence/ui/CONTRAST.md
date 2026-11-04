# Minimalist Flat token contrast (WCAG 2.2 relative luminance)

Computed from the semantic tokens in tauapi-fe src/styles/theme.css. Text targets 4.5:1 (S16), non-text control/state indicators 3:1 (S17). Automated computation; complements, does not replace, visual review.

| theme | pair | ratio | target | result |
| --- | --- | --- | --- | --- |
| light | body text #171717 on page #FAFAFA | 17.18:1 | 4.5:1 | pass |
| light | body text #171717 on surface #FFFFFF | 17.93:1 | 4.5:1 | pass |
| light | secondary text #525252 on page #FAFAFA | 7.49:1 | 4.5:1 | pass |
| light | secondary text #525252 on muted #F5F5F5 | 7.17:1 | 4.5:1 | pass |
| light | primary button text #FFFFFF on #1D4ED8 | 6.70:1 | 4.5:1 | pass |
| light | link/primary #1D4ED8 on surface #FFFFFF | 6.70:1 | 4.5:1 | pass |
| light | input border #737373 on surface #FFFFFF (non-text) | 4.74:1 | 3.0:1 | pass |
| light | focus ring #2563EB on page #FAFAFA (non-text) | 4.95:1 | 3.0:1 | pass |
| light | decorative divider #E5E5E5 on #FFFFFF (decorative, no requirement) | 1.26:1 | - | n/a (decorative) |
| dark | body text #F5F5F5 on page #111111 | 17.32:1 | 4.5:1 | pass |
| dark | body text #F5F5F5 on surface #1B1B1B | 15.80:1 | 4.5:1 | pass |
| dark | secondary text #A3A3A3 on page #111111 | 7.49:1 | 4.5:1 | pass |
| dark | secondary text #A3A3A3 on muted #262626 | 6.00:1 | 4.5:1 | pass |
| dark | primary button text #111827 on #93C5FD | 9.84:1 | 4.5:1 | pass |
| dark | link/primary #93C5FD on surface #1B1B1B | 9.55:1 | 4.5:1 | pass |
| dark | input border #737373 on surface #1B1B1B (non-text) | 3.63:1 | 3.0:1 | pass |
| dark | focus ring #93C5FD on page #111111 (non-text) | 10.47:1 | 3.0:1 | pass |
| dark | decorative divider #333333 on #1B1B1B (decorative, no requirement) | 1.36:1 | - | n/a (decorative) |
