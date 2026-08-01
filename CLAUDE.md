# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is not a software project — it's an R/Quarto pipeline that produces Spur Afrika's periodic (twice-yearly and annual) program reports as PDFs. Each report is a pair of Quarto documents (a title-page "cover" and a "body") rendered separately and then merged into one PDF with corrected page numbering. There is no application code, no tests, and no build/lint tooling — "correctness" here means the rendered PDF reads and paginates correctly.

## Report naming convention

Every report consists of a triplet of files sharing a common `{file_name}` stem:

```
{file_name}.R              # render + merge script
{file_name}_cover.qmd      # title page (titlepage-pdf format)
{file_name}_body.qmd       # report content (PrettyPDF-pdf format)
```

`{file_name}` follows `{Year}{H1|H2}_{Program}[_Kisumu].R`, e.g. `2025H2_Mentorship`, `2024H2_Special_Kisumu`, or for the one-off annual report `2025_SpurAfrikaAustralia_Annual`. Programs seen historically: `Elimisha`, `Mentorship`, `Special`, `Bingwa`, each optionally with a `_Kisumu` variant for the Kisumu regional program. Not every program runs every half — check existing files for the closest prior period before starting a new one.

**To create a new period's report**: copy the most recent `.R`, `_cover.qmd`, and `_body.qmd` for that program, update the `file_name` in the `.R` script and the title/subtitle/dates/images in the `.qmd` files. The `.R` script is boilerplate and essentially identical across all reports — do not hand-write it from scratch.

## Rendering a report

Rendering requires a full R + Quarto + LaTeX + `pdftk` toolchain; do not assume it's runnable in every environment. To render a given report, `source()` its `.R` script (e.g. from an R console with the working directory set to the repo root):

```r
source("2025H2_Mentorship.R")
```

This does, in order:
1. `quarto_render()` the `_cover.qmd` with format `titlepage-pdf` and the `_body.qmd` with format `PrettyPDF-pdf` (both custom formats from `_extensions/`).
2. Combine cover + body PDFs via `pdftools::pdf_combine()`.
3. Dump the body PDF's metadata/bookmarks with `pdftk ... dump_data`, shift all `BookmarkPageNumber` values up by one (because the cover PDF is inserted before it), and append page-label rules from `pagerenumbering_metadata.txt` (cover pages are lowercase roman numerals starting at `i`, body pages restart at arabic `1`).
4. Re-apply that corrected metadata to the combined PDF with `pdftk ... update_info`, producing the final `{file_name}.pdf`.

Required R packages: `quarto`, `pdftools`, `fs`, `stringr`. Required external binary: `pdftk`.

## Custom Quarto formats

- `_extensions/nrennie/PrettyPDF/` — defines the `PrettyPDF-pdf` format used for body documents (page style, fonts, `pagestyle.tex`).
- `_extensions/nmfs-opensci/titlepage/` — defines the `titlepage-pdf` format used for cover documents (background image, logo, title block layout).

Per-report page-numbering footer text (e.g. cover photo captions in the fancy footer) is set per `_body.qmd` in a raw LaTeX block near the top (`\fancypagestyle{myCoverStyle}{...}`) — copy and edit this from the prior period's body file rather than the format defaults.

## Content conventions in `_body.qmd` files

Reports follow a consistent section structure: `## Introduction`, `## Activities and Outputs` (with per-activity `###`/`####` subsections), `## Outcomes`, `## Impacts`, `## Challenges faced in the last six months`, `## Plans for {next period}`, `## Editor`, `## Contact`. Match this structure when drafting new report content so formatting (bullet styles, image placement) stays consistent with prior reports.

Images are referenced from `images/` with a naming convention of `{Year}{H1/H2 or Annual} {Program} {description}.{ext}` and inserted as `![caption](images/...){fig-align="center"}`.

## Repo hygiene notes

- `.gitignore` excludes `.quarto/`, `*.pdf`, `*.tex`, and `*_body_files/` — rendered/intermediate output is not normally committed. A few final `.pdf`/`.tex` outputs are currently committed for specific reports (e.g. `2024H2_Special`, `2025_SpurAfrikaAustralia_Annual`); follow existing precedent rather than committing render output by default.
- `Temp/` holds scratch/incoming source material (e.g. drafts of report text) — not part of the report pipeline itself.
- `images/*.jpg:Zone.Identifier` files are Windows metadata sidecar files, not real images — safe to ignore.
