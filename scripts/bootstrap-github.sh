#!/usr/bin/env bash
#
# Bootstraps the GitHub repo, labels, milestones, and Project (v2) for the
# Research Knowledge Graph Platform, per MILESTONES.md.
#
# Run this on a machine where `gh` (GitHub CLI) is installed and authenticated
# as the account that should own the repo, from the directory that contains
# this script's sibling files (README.md, MILESTONES.md, docs/).
#
#   cd research-knowledge-graph
#   ./scripts/bootstrap-github.sh
#
# Safe to re-run: every step checks whether its target already exists before
# creating it.

set -euo pipefail

OWNER="alexanderwiebe"
REPO="research-knowledge-graph"
DESCRIPTION="Open-source, plugin-first platform for a personal semantic graph of academic research."
PROJECT_TITLE="Research Knowledge Graph"

REPO_SLUG="${OWNER}/${REPO}"

echo "== Checking prerequisites =="
if ! command -v gh >/dev/null 2>&1; then
  echo "gh (GitHub CLI) is not installed. Install it first: https://cli.github.com" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

echo "== Repository: ${REPO_SLUG} =="
if gh repo view "${REPO_SLUG}" >/dev/null 2>&1; then
  echo "Repo already exists, skipping creation."
else
  gh repo create "${REPO_SLUG}" \
    --public \
    --description "${DESCRIPTION}" \
    --source=. \
    --remote=origin \
    --push=false
  echo "Created ${REPO_SLUG}."
fi

# Make sure we have a local git repo pointed at it, with the scaffold committed.
if [ ! -d .git ]; then
  git init -b main
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "https://github.com/${REPO_SLUG}.git"
fi

git add README.md MILESTONES.md docs scripts
if ! git diff --cached --quiet; then
  git commit -m "Initial scaffold: high-level plan, milestone decomposition, bootstrap script"
else
  echo "Nothing new to commit."
fi

git push -u origin HEAD:main

echo "== Labels =="
# name|color — bash 3.2 (macOS default) has no associative arrays, so use pipe-delimited entries.
LABELS=(
  "type: milestone|b60205"
  "type: epic|5319e7"
  "type: story|1d76db"
  "type: task|0e8a16"
)
for entry in "${LABELS[@]}"; do
  name="${entry%%|*}"
  color="${entry#*|}"
  if gh label list --repo "${REPO_SLUG}" --search "${name}" --json name --jq '.[].name' | grep -qx "${name}"; then
    echo "Label '${name}' already exists, skipping."
  else
    gh label create "${name}" --repo "${REPO_SLUG}" --color "${color}"
    echo "Created label '${name}'."
  fi
done

echo "== Milestones =="
# title|description — keep in sync with MILESTONES.md
MILESTONES=(
  "M1 — Plugin SDK & Domain Model (Developer Preview)|Stable v1 domain model + plugin capability contracts. Ships when an external developer can build a connector from the docs alone."
  "M2 — MVP Citation Graph (Zotero + OpenAlex)|Zotero connector + OpenAlex metadata + Cytoscape.js graph UI. Ships when a user can explore their own Zotero library as an interactive citation graph."
  "M3 — AI-Assisted Understanding|Research Processor plugin system with summaries, concept extraction, and provenance-tracked relationship suggestions."
  "M4 — Personal Knowledge Synthesis (Human Layer + Obsidian)|UI for accepting/rejecting AI suggestions, user-authored relationships and synthesis, plus an Obsidian Knowledge Store."
  "M5 — Open Ecosystem (v1.0)|At least one alternate implementation per major capability, proving vendor independence. The first 1.0."
)

existing_milestones="$(gh api "repos/${REPO_SLUG}/milestones?state=all" --jq '.[].title')"

for entry in "${MILESTONES[@]}"; do
  title="${entry%%|*}"
  desc="${entry#*|}"
  if grep -qxF "${title}" <<< "${existing_milestones}"; then
    echo "Milestone '${title}' already exists, skipping."
  else
    gh api "repos/${REPO_SLUG}/milestones" -f title="${title}" -f description="${desc}" >/dev/null
    echo "Created milestone '${title}'."
  fi
done

echo "== Project (v2) =="
existing_project_number="$(gh project list --owner "${OWNER}" --format json --jq ".projects[] | select(.title == \"${PROJECT_TITLE}\") | .number" 2>/dev/null | head -n1 || true)"

if [ -n "${existing_project_number}" ]; then
  echo "Project '${PROJECT_TITLE}' already exists (number ${existing_project_number}), skipping creation."
  project_number="${existing_project_number}"
else
  if ! project_json="$(gh project create --owner "${OWNER}" --title "${PROJECT_TITLE}" --format json 2>&1)"; then
    echo "Could not create the Project. This usually means the 'project' scope is missing:" >&2
    echo "  gh auth refresh -h github.com -s project,read:project" >&2
    echo "Then re-run this script." >&2
    exit 1
  fi
  project_number="$(jq -r '.number' <<< "${project_json}")"
  echo "Created Project '${PROJECT_TITLE}' (number ${project_number})."
fi

if gh project link "${project_number}" --owner "${OWNER}" --repo "${REPO_SLUG}" >/dev/null 2>&1; then
  echo "Linked Project to ${REPO_SLUG}."
else
  echo "Project link step skipped or already linked (non-fatal)."
fi

cat <<EOF

== Done ==
Repo:      https://github.com/${REPO_SLUG}
Project:   https://github.com/users/${OWNER}/projects/${project_number}

One manual step left (gh has no CLI command for this yet):
  Open the Project -> "..." menu -> Workflows -> turn on "Auto-add to project"
  for ${REPO_SLUG} so new issues/PRs land on the board automatically.

Next: decompose Milestone 1 into epics (separate conversation, per MILESTONES.md).
EOF
