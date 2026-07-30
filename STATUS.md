# Status dashboard

High-level view of label/patron-card work staged here for Koha. Auto-updated daily; see [README.koha-wip.md](README.koha-wip.md) for what this repository is. **Bugzilla is the source of truth.**

_Last updated: 2026-07-30 14:50 UTC_

## In flight

| Bug | Internal PR | Bugzilla status | Upstream |
|---|---|---|---|
| [Bug 21052](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=21052) | [#96](https://github.com/cnighswonger/koha-wip/pull/96) (merged) | Needs Signoff | pending |
| [Bug 21052](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=21052) | [#95](https://github.com/cnighswonger/koha-wip/pull/95) (closed) | Needs Signoff | pending |
| [Bug 28806](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=28806) | [#94](https://github.com/cnighswonger/koha-wip/pull/94) (merged) | Needs Signoff | pending |
| [Bug 30819](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=30819) | [#99](https://github.com/cnighswonger/koha-wip/pull/99) (open) | ASSIGNED | pending |
| [Bug 41718](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=41718) | [#93](https://github.com/cnighswonger/koha-wip/pull/93) (merged) | Needs Signoff | pending |
| [Bug 41719](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=41719) | [#1](https://github.com/cnighswonger/koha-wip/pull/1) (merged) | Needs Signoff | pending |

## Landed / resolved

| Bug | Internal PR | Bugzilla status | Upstream |
|---|---|---|---|
| [Bug 43095](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=43095) | [#2](https://github.com/cnighswonger/koha-wip/pull/2) (merged) | RESOLVED DUPLICATE | pending |

## Roadmap

<!-- ROADMAP:BEGIN (human-editable; the dashboard updater preserves this section) -->
### Near term

1. **Await community signoff** — Bugs 28806, 41718, and 41719 are all
   attached and Needs Signoff. Nothing new is submitted while the queue
   is this deep; see Principles below.
2. **Follow-up (after 41718 + 41719 land upstream)** — remove the
   now-redundant `run_allowing_bug_41718_warnings` filter from
   t_Patroncard.t.
3. **Tool location consistency (not yet filed)** — Bug 31162 moved the
   label creator to the Cataloging home page while the patron card
   creator stayed on Tools, though both are still gated by the same
   `tools_label_creator` permission. Patron cards arguably belong in the
   Patrons module by the same workflow-adjacency argument. Deferred
   until the current batch clears.

### Recently completed

- **Bug 41717** — PDF::Reuse 0.43 / PDF::Reuse::Barcode 0.09 version bump
  is **pushed to main** (2026-07-28, for 26.11). The earlier revert was a
  packaging problem, not a code problem: Jenkins could not satisfy the
  dependency because Debian stable ships 0.39/0.07. Resolved by packaging
  the new versions for the community apt repository. Separately,
  `0.43-1~bpo13+1` and `0.09-1~bpo13+1` are in the Debian backports NEW
  queue awaiting review.
- **Bug 28806** — silent label-content loss for items with NULL homebranch.
  `_get_label_item()` INNER-joined on `i.homebranch=br.branchcode`, so such
  items returned no row and BIBBAR labels silently collapsed to
  barcode-only; a die after the CGI header explained the zero-byte
  downloads users reported. Fix is LEFT JOIN + warn. Verified in
  koha-testing-docker (1343 → 22570 bytes; unchanged output for valid
  homebranch; identical on PDF::Reuse 0.39 and 0.43). Attached and Needs
  Signoff.
- **Bug 35976** — signed off (enlarge the barcode width/height fields).
  Someone else's patch; tested here with and without it applied, plus a
  DB round-trip check and koha-qa.pl. Testing-only work like this does not
  go through the internal PR cycle.

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

[89 open bugs](https://github.com/cnighswonger/koha-wip/issues?q=is%3Aissue+is%3Aopen+label%3Abz-mirror) mirrored from the Bugzilla *Label/patron card printing* component (36 defects, 53 enhancements), synced daily. Mirror issues close only when a bug's fix is pushed to official Koha.
