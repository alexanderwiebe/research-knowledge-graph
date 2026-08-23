#!/usr/bin/env bash
#
# Creates one "tracking issue" per native GitHub Milestone and adds it to the
# Project, so each Milestone has a visible artifact on the board: a Delivers
# checklist (progress) and a Ships-when section (definition of done).
#
# Native GitHub Milestones aren't Project items and carry no checklist, so
# they're invisible on the board until issues are filed against them. This
# script gives each Milestone a standing issue, labeled `type: milestone`,
# assigned to its own native milestone, added to the Project.
#
# Run from the repo root, after scripts/bootstrap-github.sh:
#   ./scripts/create-milestone-issues.sh
#
# Safe to re-run: skips any milestone that already has a tracking issue.

set -euo pipefail

OWNER="alexanderwiebe"
REPO="research-knowledge-graph"
PROJECT_TITLE="Research Knowledge Graph"
LABEL="type: milestone"

REPO_SLUG="${OWNER}/${REPO}"

echo "== Checking prerequisites =="
if ! command -v gh >/dev/null 2>&1; then
  echo "gh (GitHub CLI) is not installed. Install it first: https://cli.github.com" >&2
  exit 1
fi

if ! gh label list --repo "${REPO_SLUG}" --search "${LABEL}" --json name --jq '.[].name' | grep -qx "${LABEL}"; then
  echo "Label '${LABEL}' does not exist yet. Run scripts/bootstrap-github.sh first." >&2
  exit 1
fi

project_number="$(gh project list --owner "${OWNER}" --format json --jq ".projects[] | select(.title == \"${PROJECT_TITLE}\") | .number" 2>/dev/null | head -n1 || true)"
if [ -z "${project_number}" ]; then
  echo "Project '${PROJECT_TITLE}' not found. Run scripts/bootstrap-github.sh first." >&2
  exit 1
fi

# Title must exactly match the milestone titles created by bootstrap-github.sh / MILESTONES.md.
titles=(
  "M1 — Plugin SDK & Domain Model (Developer Preview)"
  "M2 — MVP Citation Graph (Zotero + OpenAlex)"
  "M3 — AI-Assisted Understanding"
  "M4 — Personal Knowledge Synthesis (Human Layer + Obsidian)"
  "M5 — Open Ecosystem (v1.0)"
  "M6 — Public Publishing (Quarto/Notebook Vessel)"
)

body_for() {
  case "$1" in
  "M1 — Plugin SDK & Domain Model (Developer Preview)")
    cat <<'EOF'
**Marketable to:** plugin authors, integrators, and coding agents extending the platform — not yet end users.

**Why this counts as a release:** it's the point where an external developer (human or agent) can be handed a contract — e.g. "implement a Paperpile Research Library Connector conforming to `ResearchLibraryConnector` v1" — and build against it without reading core source.

### Delivers
- [ ] Core domain model: `Document`, `Relationship`, `Assertion`, `Provenance`, `ProcessingEvent`, `ExternalIdentifier`, `Artifact`, `Concept` — with storage schema, serialization format, and unit tests.
- [ ] Identity-resolution strategy (DOI, title+authors, OpenAlex ID, Zotero key, ISBN, arXiv ID, PMID).
- [ ] Resolution of the plan's other cross-cutting decisions: relationship ontology extensibility, human-vs-AI assertion authority (default: coexist, no destructive overwrite), sync model (pull/push/subscription), initial storage choice, plugin execution model (in-process vs. child process vs. RPC).
- [ ] Plugin SDK v1: versioned capability contracts for Research Library Connector, Scholarly Metadata Provider, Knowledge Store, Research Processor, Relationship Provider, Document Acquisition Provider.
- [ ] Plugin manifest format and capability discovery.
- [ ] Contract tests + example mock plugins for each capability.
- [ ] Developer documentation generated from the contracts.

### Ships when (definition of done)
A developer unfamiliar with the internals can read the plugin-sdk docs and produce a working mock connector against the contract tests.
EOF
    ;;
  "M2 — MVP Citation Graph (Zotero + OpenAlex)")
    cat <<'EOF'
**Marketable to:** individual researchers who already use Zotero.

**Why this counts as a release:** it's the first version a real researcher can point at their own library and get value from — an explorable, enriched citation graph of papers they already have.

### Delivers
- [ ] Zotero Research Library Connector (read-only): list papers, read metadata, read collections, read attachments, map Zotero item keys to internal IDs, detect changes.
- [ ] OpenAlex Scholarly Metadata Provider: document identity resolution, metadata enrichment, references, cited-by relationships — all retaining OpenAlex provenance.
- [ ] Cytoscape.js graph UI: render papers and citation edges, node selection, persistent document inspector (not modal), search, filter, zoom/pan, focus-neighborhood, processing-state styling, relationship-provenance styling.

### Ships when (definition of done)
A user can connect their Zotero library and browse it as an interactive citation graph, with no AI or manual-curation features yet required.
EOF
    ;;
  "M3 — AI-Assisted Understanding")
    cat <<'EOF'
**Marketable to:** researchers who want help triaging and understanding a large paper backlog.

**Why this counts as a release:** it's the first point where the platform actively helps the user understand their corpus, not just visualize documented citations.

### Delivers
- [ ] Research Processor plugin system + a reference Claude/OpenAI processor.
- [ ] Summarization, concept extraction, and relationship-suggestion capabilities, each producing assertions with full provenance and confidence scores.
- [ ] Processing-event pipeline exposed as a simplified status in the UI (Discovered → Acquired → AI Processed → …).

### Ships when (definition of done)
Newly-acquired papers are automatically summarized, concept-tagged, and given AI-suggested relationships that are visibly distinct (styling/provenance) from documented citations.
EOF
    ;;
  "M4 — Personal Knowledge Synthesis (Human Layer + Obsidian)")
    cat <<'EOF'
**Marketable to:** researchers who want the platform to hold their own understanding, not just AI output.

**Why this counts as a release:** this is where the platform becomes what the vision describes as a "personal semantic research environment" rather than a citation/AI tool — the user's own synthesis becomes first-class data.

### Delivers
- [ ] UI to accept/reject AI-suggested relationships.
- [ ] Create and edit user-authored relationships with explanations.
- [ ] Mark reading progress, write synthesis, edit concepts — kept as assertions distinct from AI/external ones.
- [ ] Obsidian Knowledge Store reference implementation: one Markdown file per paper, round-tripping internal ID, Zotero key, DOI, AI summary, user synthesis, concepts, relationships, and processing metadata — without leaking the Obsidian file format into the core domain model.

### Ships when (definition of done)
A user can disagree with an AI suggestion, write their own understanding of a paper, and have that synthesis show up both in the graph and in their Obsidian vault.
EOF
    ;;
  "M5 — Open Ecosystem (v1.0)")
    cat <<'EOF'
**Marketable to:** the broader open-source community — this is the milestone that proves the core architectural claim of the whole project.

**Why this counts as a release:** every prior milestone could, in principle, have been built with hidden assumptions that only work for Zotero/OpenAlex/Claude/Obsidian. This milestone forces and proves vendor independence, and is the natural 1.0.

### Delivers
- [ ] At least one alternate implementation per major capability: BibTeX Research Library Connector, Crossref Metadata Provider, Markdown-filesystem Knowledge Store, local/mock Research Processor.
- [ ] Any contract revisions surfaced by building those alternates.
- [ ] Polished plugin-authoring documentation, examples, and a first pass at the plugin isolation/permissions model (read/write library, read/write local files, network access, invoke AI provider, write knowledge store, modify graph).

### Ships when (definition of done)
A plugin author can swap out any single capability (library, metadata, processor, or knowledge store) for an alternate implementation with zero core changes, and this has actually been demonstrated for each capability at least once.
EOF
    ;;
  "M6 — Public Publishing (Quarto/Notebook Vessel)")
    cat <<'EOF'
**Marketable to:** researchers who want to share curated synthesis publicly, and readers/collaborators who want to consume it without needing the platform itself.

**Why this counts as a release:** every prior milestone is about building and enriching the *personal* graph; this is the first milestone where output reaches an audience outside the tool — personal synthesis becoming a public, shareable artifact.

### Delivers
- [ ] Publishing Provider capability contract (new, alongside the plan's other six capabilities): takes curated, opt-in-only Documents/Concepts/Relationships/synthesis out of the graph and renders publishable content, with provenance (documented vs. AI-suggested vs. user-authored) preserved in the output.
- [ ] Quarto/Jupyter Publishing Provider reference implementation, built on [`learning-from-data`](https://github.com/alexanderwiebe/learning-from-data)'s devcontainer + `_quarto.yml` conventions: one rendered page per published paper/concept, cross-linked, deployed via Quarto Pub or GitHub Pages.
- [ ] Per-item public/private opt-in flag — nothing is published by default; a user explicitly marks a paper, concept, or synthesis as public first.

### Ships when (definition of done)
A user can flag a paper's synthesis as "public," run a publish command, and get a live, readable page at a public URL, with the platform's provenance distinctions (documented / AI-suggested / user-authored) visible on it.
EOF
    ;;
  *)
    echo "No body template for milestone: $1" >&2
    exit 1
    ;;
  esac
}

echo "== Milestone tracking issues =="
existing_issue_titles="$(gh issue list --repo "${REPO_SLUG}" --label "${LABEL}" --state all --json title --jq '.[].title')"

for title in "${titles[@]}"; do
  if grep -qxF "${title}" <<< "${existing_issue_titles}"; then
    echo "Tracking issue for '${title}' already exists, skipping."
    continue
  fi

  issue_url="$(gh issue create \
    --repo "${REPO_SLUG}" \
    --title "${title}" \
    --body "$(body_for "${title}")" \
    --label "${LABEL}" \
    --milestone "${title}")"

  echo "Created tracking issue for '${title}': ${issue_url}"

  gh project item-add "${project_number}" --owner "${OWNER}" --url "${issue_url}" >/dev/null
  echo "Added to project."
done

cat <<EOF

== Done ==
Each milestone now has a tracking issue: on the board (Group by "Milestone" in
a table view, or add a board view grouped by Milestone) and on its native
milestone page (https://github.com/${REPO_SLUG}/milestones), where the
Delivers checklist shows progress and the issue body states what "done" means.

As epics are filed under a milestone (labeled type: epic, assigned to that
milestone), link them as sub-issues of the milestone's tracking issue so its
"Sub-issues progress" field on the board also rolls up automatically.
EOF
