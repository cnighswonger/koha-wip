# Status dashboard

High-level view of label/patron-card work staged here for Koha. Auto-updated daily; see [README.koha-wip.md](README.koha-wip.md) for what this repository is. **Bugzilla is the source of truth.**

_Last updated: 2026-07-18 11:14 UTC_

## In flight

| Bug | Internal PR | Bugzilla status | Upstream |
|---|---|---|---|
| [Bug 41719](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=41719) | [#1](https://github.com/cnighswonger/koha-wip/pull/1) (merged) | Needs Signoff | pending |

## Landed / resolved

| Bug | Internal PR | Bugzilla status | Upstream |
|---|---|---|---|
| [Bug 43095](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=43095) | [#2](https://github.com/cnighswonger/koha-wip/pull/2) (merged) | RESOLVED DUPLICATE | pending |

## Roadmap

<!-- ROADMAP:BEGIN (human-editable; the dashboard updater preserves this section) -->
### Near term

1. **Bug 41718** — fix `draw_guide_grid()` argument handling (removes the known
   warnings the Bug 41719 tests currently filter around; follow-up will drop
   those filters).
2. **Bugs 28806 / 31241** — re-test the broken-PDF-export reports against
   PDF::Reuse 0.43 (Bug 41717) in koha-testing-docker; report findings on
   Bugzilla. Verification only, no new patches expected.

### Principles

Submissions are paced deliberately — in-flight bugs move through the
community's signoff/QA queue before new ones are added. Bugzilla is always
the source of truth; nothing here confers status in the Koha project.
<!-- ROADMAP:END -->

## Triage board

[88 open bugs](https://github.com/cnighswonger/koha-wip/issues?q=is%3Aissue+is%3Aopen+label%3Abz-mirror) mirrored from the Bugzilla *Label/patron card printing* component (34 defects, 54 enhancements), synced daily. Mirror issues close only when a bug's fix is pushed to official Koha.
