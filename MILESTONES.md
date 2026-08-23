# Milestones

This document decomposes the [high-level plan](docs/high-level-plan.md) into milestones — the top level of the project's work-breakdown hierarchy.

## Hierarchy convention

This project tracks work in GitHub using the following structure. Everything below "Milestone" is decomposed separately, milestone by milestone, as work is about to start on it — not all at once up front.

| Level | Definition | GitHub representation |
|---|---|---|
| **Milestone** | An incremental, marketable release. | Native GitHub Milestone, plus a tracking issue (labeled `type: milestone`, assigned to that same Milestone, added to the Project) — see below |
| **Epic** | A group of related functionality. | Issue, labeled `type: epic`, assigned to a Milestone, linked as a sub-issue of that Milestone's tracking issue |
| **Story** | Something explainable to a user. | Issue, labeled `type: story`, linked as a sub-issue of its parent Epic |
| **Task** | Something accomplishable and testable. | Issue, labeled `type: task`, linked as a sub-issue of its parent Story |
| **Pull Request** | Implements one or more Tasks. | PR, references the Task issue(s) it closes (`Closes #123`) |

Rule of containment: a Milestone contains 1+ Epics, an Epic contains 1+ Stories, a Story contains 1+ Tasks, a Task is closed by 1+ PRs.

### Milestones as Project artifacts

A native GitHub Milestone has no presence on a Project (v2) board and no checklist — it's invisible until issues are filed against it. So each Milestone also gets a **tracking issue** (created by `scripts/create-milestone-issues.sh`): body has a `Delivers` checklist (mirrors this doc's bullets, checked off as the corresponding Epics close) and a `Ships when` section stating the definition of done. It's labeled `type: milestone`, assigned to its own native Milestone, and added to the Project so it shows up as a real, trackable item. As Epics are filed under a Milestone, link them as sub-issues of that Milestone's tracking issue so the Project's built-in "Sub-issues progress" field rolls up automatically.

A Task should be independently accomplishable and independently testable (it has a clear, verifiable "done"). A Story should be describable to a user in terms of what they can now do, not how it's built. An Epic groups Stories that all serve the same piece of related functionality. A Milestone is the point at which the accumulated Epics add up to something you'd actually tag, release, and tell someone about.

---

## M1 — Plugin SDK & Domain Model (Developer Preview)

**Marketable to:** plugin authors, integrators, and coding agents extending the platform — not yet end users.

**Why this counts as a release:** it's the point where an external developer (human or agent) can be handed a contract — e.g. "implement a Paperpile Research Library Connector conforming to `ResearchLibraryConnector` v1" — and build against it without reading core source. That's a real, usable deliverable even though there's no UI yet.

**Delivers:**
- Core domain model: `Document`, `Relationship`, `Assertion`, `Provenance`, `ProcessingEvent`, `ExternalIdentifier`, `Artifact`, `Concept` — with storage schema, serialization format, and unit tests.
- Identity-resolution strategy (how duplicate papers are recognized across DOI, title+authors, OpenAlex ID, Zotero key, ISBN, arXiv ID, PMID).
- Resolution of the other cross-cutting decisions in the plan's "Key Architecture Decisions" section: relationship ontology extensibility, human-vs-AI assertion authority (default: coexist, no destructive overwrite), sync model (pull/push/subscription), initial storage choice, and plugin execution model (in-process vs. child process vs. RPC).
- Plugin SDK v1: versioned capability contracts for Research Library Connector, Scholarly Metadata Provider, Knowledge Store, Research Processor, Relationship Provider, and Document Acquisition Provider.
- Plugin manifest format and capability discovery (plugins declare what they support, per the plan's example).
- Contract tests + example mock plugins for each capability.
- Developer documentation generated from the contracts.

**Maps to plan sections:** Phase 0 (research existing tools), Phase 1 (core domain model), Phase 2 (plugin SDK), Section 27 (key architecture decisions).

**Ships when:** a developer unfamiliar with the internals can read the plugin-sdk docs and produce a working mock connector against the contract tests.

---

## M2 — MVP Citation Graph (Zotero + OpenAlex)

**Marketable to:** individual researchers who already use Zotero.

**Why this counts as a release:** it's the first version a real researcher can point at their own library and get value from — an explorable, enriched citation graph of papers they already have.

**Delivers:**
- Zotero Research Library Connector (read-only): list papers, read metadata, read collections, read attachments, map Zotero item keys to internal IDs, detect changes.
- OpenAlex Scholarly Metadata Provider: document identity resolution, metadata enrichment, references, cited-by relationships — all retaining OpenAlex provenance.
- Cytoscape.js graph UI: render papers and citation edges, node selection, persistent document inspector (not modal), search, filter, zoom/pan, focus-neighborhood, processing-state styling, relationship-provenance styling.

**Maps to plan sections:** Phase 3 (Zotero connector), Phase 4 (OpenAlex provider), Phase 5 (initial graph UI).

**Ships when:** a user can connect their Zotero library and browse it as an interactive citation graph, with no AI or manual-curation features yet required.

---

## M3 — AI-Assisted Understanding

**Marketable to:** researchers who want help triaging and understanding a large paper backlog.

**Why this counts as a release:** it's the first point where the platform actively helps the user understand their corpus, not just visualize documented citations.

**Delivers:**
- Research Processor plugin system + a reference Claude/OpenAI processor.
- Summarization, concept extraction, and relationship-suggestion capabilities, each producing assertions with full provenance and confidence scores.
- Processing-event pipeline exposed as a simplified status in the UI (Discovered → Acquired → AI Processed → …).

**Maps to plan sections:** Phase 6 (processing pipeline).

**Ships when:** newly-acquired papers are automatically summarized, concept-tagged, and given AI-suggested relationships that are visibly distinct (styling/provenance) from documented citations.

---

## M4 — Personal Knowledge Synthesis (Human Layer + Obsidian)

**Marketable to:** researchers who want the platform to hold their own understanding, not just AI output.

**Why this counts as a release:** this is where the platform becomes what the vision describes as a "personal semantic research environment" rather than a citation/AI tool — the user's own synthesis becomes first-class data.

**Delivers:**
- UI to accept/reject AI-suggested relationships, create and edit user-authored relationships with explanations, mark reading progress, write synthesis, and edit concepts — kept as assertions distinct from AI/external ones.
- Obsidian Knowledge Store reference implementation: one Markdown file per paper, round-tripping internal ID, Zotero key, DOI, AI summary, user synthesis, concepts, relationships, and processing metadata — without leaking the Obsidian file format into the core domain model.

**Maps to plan sections:** Phase 7 (Obsidian knowledge store), Phase 8 (human knowledge layer).

**Ships when:** a user can disagree with an AI suggestion, write their own understanding of a paper, and have that synthesis show up both in the graph and in their Obsidian vault.

---

## M5 — Open Ecosystem (v1.0)

**Marketable to:** the broader open-source community — this is the milestone that proves the core architectural claim of the whole project.

**Why this counts as a release:** every prior milestone could, in principle, have been built with hidden assumptions that only work for Zotero/OpenAlex/Claude/Obsidian. This milestone forces and proves vendor independence, and is the natural 1.0.

**Delivers:**
- At least one alternate implementation per major capability, per the plan's extensibility-validation phase: BibTeX Research Library Connector, Crossref Metadata Provider, Markdown-filesystem Knowledge Store, local/mock Research Processor.
- Any contract revisions surfaced by building those alternates (the plan explicitly expects this: "if alternate implementations require core changes, revise the contract").
- Polished plugin-authoring documentation, examples, and a first pass at the plugin isolation/permissions model (read/write library, read/write local files, network access, invoke AI provider, write knowledge store, modify graph).

**Maps to plan sections:** Phase 9 (extensibility validation), Section 22 (plugin isolation and permissions).

**Ships when:** a plugin author can swap out any single capability (library, metadata, processor, or knowledge store) for an alternate implementation with zero core changes, and this has actually been demonstrated for each capability at least once.

---

## M6 — Public Publishing (Quarto/Notebook Vessel)

**Marketable to:** researchers who want to share curated synthesis publicly, and readers/collaborators who want to consume it without needing the platform itself.

**Why this counts as a release:** every prior milestone is about building and enriching the *personal* graph; this is the first milestone where output reaches an audience outside the tool — personal synthesis becoming a public, shareable artifact.

**Delivers:**
- Publishing Provider capability contract (new, alongside the plan's other six capabilities): takes curated, opt-in-only Documents/Concepts/Relationships/synthesis out of the graph and renders publishable content, with provenance (documented vs. AI-suggested vs. user-authored) preserved in the output.
- Quarto/Jupyter Publishing Provider reference implementation, built on [`learning-from-data`](https://github.com/alexanderwiebe/learning-from-data)'s devcontainer + `_quarto.yml` conventions: one rendered page per published paper/concept, cross-linked, deployed via Quarto Pub or GitHub Pages.
- Per-item public/private opt-in flag — nothing is published by default; a user explicitly marks a paper, concept, or synthesis as public first.

**Maps to plan sections:** Phase 10 (public publishing).

**Ships when:** a user can flag a paper's synthesis as "public," run a publish command, and get a live, readable page at a public URL, with the platform's provenance distinctions (documented / AI-suggested / user-authored) visible on it.

---

## Not yet milestoned

The plan's "Long-Term Direction" (timeline view, additional graph views beyond citation/semantic/neighborhood/processing, deeper permissioning/sandboxing, additional metadata/library/store integrations) is intentionally left unscheduled. These become candidate M7+ milestones once M1–M6 are delivered and real usage clarifies what's actually valuable next — decomposing them now would be planning ahead of the evidence. (M6 — Public Publishing — was pulled forward as an exception because a concrete external integration, `learning-from-data`, already exists and was ready to plan against.)
