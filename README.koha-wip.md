# About this repository (koha-wip)

This is a **personal working repository** belonging to Chris Nighswonger, a
long-time Koha contributor. It is a clone of the
[Koha](https://git.koha-community.org/Koha-community/Koha) integrated library
system used as a staging and review area for patches **before** they are
submitted to the Koha community through the normal channel.

**This repository is not part of the Koha project's infrastructure.**

## If you are looking for Koha itself

- Project home: <https://koha-community.org>
- Official repository: <https://git.koha-community.org/Koha-community/Koha>
- Bug tracker and patch submission: <https://bugs.koha-community.org>
- Patch submission guidelines: <https://wiki.koha-community.org/wiki/Submitting_A_Patch>

Koha does not accept pull requests on git hosting sites — all patches go
through Bugzilla, and that is exactly where the work staged here ends up.
Please do not open issues or pull requests in this repository expecting Koha
project support; they will not reach the Koha community.

## What the branches and pull requests here are

Bug branches (`bug/...`) hold patches in preparation for specific Koha
Bugzilla bugs. Pull requests in this repository are an **internal review
step only**: each patch is reviewed here — including by AI review tooling —
and receives final human review and approval before it is attached to the
corresponding Bugzilla bug. Merging a PR here confers no status whatsoever
in the Koha project; the community's signoff and QA process on Bugzilla is
the only review that counts, and patches staged here enter that process
like any other submission.

## AI assistance disclosure

Some patches staged here are developed and reviewed with AI assistance.
In line with the Koha community's draft guideline on AI- and LLM-assisted
contributions, every such patch:

- carries an `Assisted-by:` trailer and a description of the tools' role in
  the commit message;
- is reviewed, verified, and approved by the human author, who takes full
  responsibility for the contribution;
- is tested in koha-testing-docker before submission.

AI tooling here drafts and reviews; it does not decide. The human author is
accountable for everything submitted to the community, and submissions are
paced deliberately with respect for the community QA team's queue.

## Housekeeping

The default branch tracks upstream Koha `main` plus any staged-but-not-yet-
upstream patches, and is periodically reset onto upstream once staged
patches have been attached to Bugzilla. Branch history here is working
history — the patch of record is always the Bugzilla attachment.
