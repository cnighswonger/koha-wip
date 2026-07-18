# Status dashboard

High-level view of label/patron-card work staged here for Koha. Auto-updated daily; see [README.koha-wip.md](README.koha-wip.md) for what this repository is. **Bugzilla is the source of truth.**

_Last updated: 2026-07-18 12:11 UTC_

## In flight

| Bug | Internal PR | Bugzilla status | Upstream |
|---|---|---|---|
| [Bug 41718](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=41718) | [#93](https://github.com/cnighswonger/koha-wip/pull/93) (merged) | Needs Signoff | pending |
| [Bug 41719](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=41719) | [#1](https://github.com/cnighswonger/koha-wip/pull/1) (merged) | Needs Signoff | pending |

## Landed / resolved

| Bug | Internal PR | Bugzilla status | Upstream |
|---|---|---|---|
| [Bug 43095](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=43095) | [#2](https://github.com/cnighswonger/koha-wip/pull/2) (merged) | RESOLVED DUPLICATE | pending |

## Roadmap

<!-- ROADMAP:BEGIN (human-editable; the dashboard updater preserves this section) -->
### Near term

1. **Bug 28806** — fix silent label-content loss for items with NULL
   homebranch. Re-testing (2026-07-18, koha-testing-docker) found the
   mechanism: `_get_label_item()` INNER-joins on
   `i.homebranch=br.branchcode`, so such items return no row and BIBBAR
   labels silently collapse to barcode-only; a die after the CGI header
   explains the zero-byte downloads users reported. Fix: LEFT JOIN +
   warn. PDF::Reuse version was ruled out (renders fine on 0.39 and
   0.43). Patch staged internally; Bugzilla attachment held until the
   in-flight queue clears.
2. **Follow-up (after 41718 + 41719 land upstream)** — remove the
   now-redundant `run_allowing_bug_41718_warnings` filter from
   t_Patroncard.t.

### Recently verified (no patches needed)

- **Bug 31241** — exports work on current main; Error-500 symptom was
  Bug 34157 (RESOLVED FIXED), zero-byte symptom tracks Bug 28806.
  Closure candidate absent new reports on supported releases.

### Principles

Submissions are paced deliberately — in-flight bugs move through the
community's signoff/QA queue before new ones are added. Bugzilla is always
the source of truth; nothing here confers status in the Koha project.
<!-- ROADMAP:END -->

## Triage board

[88 open bugs](https://github.com/cnighswonger/koha-wip/issues?q=is%3Aissue+is%3Aopen+label%3Abz-mirror) mirrored from the Bugzilla *Label/patron card printing* component (34 defects, 54 enhancements), synced daily. Mirror issues close only when a bug's fix is pushed to official Koha.
