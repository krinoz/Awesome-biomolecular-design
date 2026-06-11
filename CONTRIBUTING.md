# Contributing to Awesome Biomolecular Design

Thank you for helping improve this curated reference for computational biomolecular design. The goal is to keep the repository useful for researchers and practitioners who need to choose, install, and combine tools across binder discovery workflows.

## What Belongs Here

Contributions should fit at least one of these categories:

- Computational tools, models, databases, APIs, or workflows for biomolecular binder discovery.
- Practical resources for small molecules, peptides, protein binders, nanobodies, antibodies, RNA aptamers, docking, molecular dynamics, screening, optimization, or agentic discovery.
- Corrections to broken links, outdated installation instructions, publication metadata, descriptions, or section placement.
- Documentation that makes the repository easier to use, verify, or maintain.

Avoid adding resources that are primarily promotional, unrelated to biomolecular design, impossible to access, or missing enough public information for readers to evaluate.

## Tool Addition Criteria

New tool entries should include:

- **Name:** Official project or tool name.
- **Category:** The most specific section and subsection where it belongs.
- **Description:** One concise sentence describing what the tool does and where it fits in the pipeline.
- **URL or repository:** A stable project page, paper page, hosted service, or code repository.
- **Publication:** Peer-reviewed paper, preprint, technical report, or documentation link when available.
- **Install path:** A realistic install option such as `pip`, `conda`, Docker, source build, web API, or hosted service.
- **Minimal usage:** A short command or code snippet that demonstrates the main workflow.
- **Maintenance signal:** Recent release, active repository, maintained service, or clear note if the project is archival.

Prefer entries that are reproducible, documented, and useful to more than one lab or project. If a tool is closed-source or hosted only, make that clear.

## Entry Style

Keep entries consistent with the surrounding README section:

- Use the existing heading level and ordering.
- Keep descriptions factual and specific.
- Include GitHub star badges for GitHub-hosted tools when the surrounding section uses them.
- Put longer installation and usage examples inside a `<details>` block when appropriate.
- Do not overstate benchmark performance or clinical readiness.
- Mention important limitations when they affect practical use, such as required licenses, unavailable weights, restricted APIs, or abandoned code.

## Pull Request Checklist

Before opening a pull request:

- Confirm links resolve in a browser.
- Confirm install commands are plausible and copied from official documentation when possible.
- Check that the tool is not already listed under another name.
- Place the entry in the most specific matching subsection.
- Keep unrelated changes out of the pull request.
- Run any available repository checks before requesting review.

## Corrections and Updates

Corrections are welcome even when they are small. Useful updates include:

- Broken or redirected links.
- Renamed repositories or moved documentation.
- New papers, releases, or model versions.
- Deprecated install instructions.
- Incorrect modality, pipeline stage, or description.
- Duplicate entries.

When changing an existing entry, briefly explain the source of truth in the pull request description.

## Curation Principles

This repository values practical usefulness over completeness. A good entry helps readers understand what the resource does, why it matters, how to access it, and where it fits in a design pipeline.

Maintainers may decline entries that are too speculative, not sufficiently documented, out of scope, or difficult to verify.
