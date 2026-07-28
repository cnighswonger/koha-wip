# Bug clusters — shared solutions

Open bugs in the *Label/patron card printing* component grouped by **shared
solution**, not by symptom. Each cluster is a set of bugs one piece of work would
plausibly close, or which share a root cause such that fixing them separately means
touching the same code repeatedly.

Bugzilla remains the source of truth and these groupings are local triage only —
upstream, **one bug = one scope**, and each still gets its own patch. The point is to
sequence our work so the shared part is done once.

| Label | Bugs | Shared solution |
|---|---|---|
| `cluster:barcode-formats` | 37356, 23510, 39113, 42478 | A shared barcode-drawing helper. Bug 37356 records that barcode generation is **duplicated between `C4::Labels::Label` and `C4::Patroncards::Patroncard`** — EAN13 works on labels but not patron cards purely because of that duplication. De-duplicating is the prerequisite; adding Code128, QR, and DataMatrix then happens once instead of twice. |
| `cluster:barcode-render` | 30819, 40478, 19325 | Geometry and appearance of the drawn barcode. 30819 (text font size) needs `textsize` in PDF::Reuse::Barcode; 40478 (justification) and 19325 (padding) are both about placing the barcode within its usable width. All three touch the same `x_scale_factor` / `$length` maths at `C4/Labels/Label.pm:529-560`. |
| `cluster:text-wrapping` | 2499, 7062, 18092, 14859, 42943 | One text-fitting routine. 2499 asks for a better wrapping algorithm outright; 7062 (titles not truncating), 18092 (enumchron truncated to 2 chars), 14859 (bounding-box/font-metrics truncation) and 42943 (call number fields should wrap like others) are all symptoms of the same measure-and-fit code. |
| `cluster:callnumber-split` | 2500, 28691 | The call number splitting algorithm. 2500 is the standing request to add/update splitting rules; 28691 asks that the quick spine label creator use the same splitting as the label creator. Same code, two consumers. |
| `cluster:printer-profile` | 15739, 21052 | Printer profile save validation. Both are the same defect surfacing differently: empty Printer Name or Paper Bin either 500s (15739) or silently fails to save (21052). |
| `cluster:export-modal` | 40366, 40412 | Replacing the Greybox modal in the export flow — label side and patron card side of one change. |
| `cluster:csv-encoding` | 39327, 21806, 10400 | CSV output encoding and error handling. Missing UTF-8 BOM (39327), unicode support in patron card batch export (21806), and standardising `Text::CSV_XS` error checking (10400). |

## Notes

- **`cluster:barcode-formats` is the highest-leverage group** but also the largest: the
  de-duplication is a refactor across two modules, and per the project's own
  standards a refactor of that size needs explicit sign-off rather than being folded
  into a feature patch. Worth its own bug.
- **`cluster:barcode-render` is partly in flight** — 30819 is assigned and blocked on
  PDF::Reuse::Barcode 0.10 (see
  [issue #3](https://github.com/cnighswonger/PDF-Reuse-Barcode/issues/3)). 40478 and
  19325 are unblocked and could be done independently.
- **`cluster:printer-profile` and `cluster:export-modal` are the cheap ones** — two
  bugs each, tightly scoped, likely a single small patch per pair.
- Bug 39167 (`creator_layouts.scale_height`/`scale_width` should be DECIMAL) is not
  clustered here but touches the same table as the barcode-render work; worth
  checking before any schema change in that area.

Not every open bug is clustered — most are genuinely standalone. Absence of a
cluster label means no shared solution was identified, not that the bug is unimportant.
