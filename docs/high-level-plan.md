# Research Knowledge Graph Platform

## High-Level Plan

## 1. Vision

Build an open-source, plugin-first **Research Knowledge Graph Platform** for exploring, processing, and understanding academic research.

The platform should provide a semantic graph view of a research corpus while remaining independent of any particular reference manager, note-taking system, metadata source, AI provider, or storage backend.

The system should support three primary dimensions simultaneously:

1. **Documented scholarly relationships**
   - Paper A cites Paper B.
   - Paper C is cited by Paper D.
   - Relationships may come from the documents themselves or external scholarly metadata providers.

2. **Semantic and user-defined relationships**
   - Paper A extends Paper B.
   - Paper A contradicts Paper C.
   - Paper A and Paper D use the same ontology or methodology.
   - Relationships may be created by the user, inferred by AI, or supplied by plugins.

3. **Personal processing state**
   - Has the paper been discovered?
   - Has the full text been acquired?
   - Has AI preprocessing occurred?
   - Has the user read it?
   - Has the user synthesized it into their own understanding?

The platform should ultimately function as a **personal semantic research environment**, not merely a citation visualizer.

---

## 2. Core Architectural Principle

> **The core talks to capabilities, never products.**

No third-party product should be a hard dependency of the platform.

For example, the core should never contain APIs such as:

```typescript
getPapersFromZotero()
saveNotesToObsidian()
getCitationsFromOpenAlex()
processWithClaude()
```

Instead, the core defines stable capability contracts such as:

```text
Research Library Connector
Knowledge Store
Scholarly Metadata Provider
Document Acquisition Provider
Research Processor
Relationship Provider
Publishing Provider
Discovery Source Provider
Notification/Digest Provider
```

Specific integrations then implement those contracts:

```text
Research Library Connector
├── Zotero
├── BibTeX
├── Mendeley
└── Future integrations

Knowledge Store
├── Obsidian
├── Markdown filesystem
├── Logseq
└── Future integrations

Scholarly Metadata Provider
├── OpenAlex
├── Crossref
├── Semantic Scholar
└── OpenCitations

Research Processor
├── Claude
├── Codex / OpenAI
├── Gemini
├── Local models
└── Custom agents

Publishing Provider
├── Quarto (learning-from-data)
├── Static site generators (Hugo, Jekyll, ...)
└── Future integrations

Discovery Source Provider
├── Twitter/X lists via RSSHub (ai-briefing)
├── RSS/Atom feeds
└── Future integrations

Notification/Digest Provider
├── Telegram (ai-briefing)
├── Email
├── Slack
└── Future integrations
```

A **Publishing Provider** takes curated, opt-in-only content out of the graph — selected Documents, Concepts, Relationships, and synthesis, always with their provenance (documented vs. AI-suggested vs. user-authored) intact — and renders it for a public audience outside the platform. Nothing is public by default; a user explicitly marks a paper, concept, or synthesis as public before a Publishing Provider can render or publish it. The reference implementation renders notebook-shaped content via [Quarto](https://quarto.org), using the [`learning-from-data`](https://github.com/alexanderwiebe/learning-from-data) devcontainer + `_quarto.yml` conventions as the publishing vessel, deployed to Quarto Pub or GitHub Pages.

A **Discovery Source Provider** is distinct from a Research Library Connector: a connector reads a library the user already curates (Zotero, BibTeX), while a discovery source surfaces *candidate* items from a noisy external stream (a Twitter/X list, an RSS feed) that may or may not become real Documents in the graph. It answers "what's new out there worth looking at?" rather than "what's already in my library?" — candidates enter the graph in a `Discovered` processing state, deduplicated against each other, before any Research Processor or Relationship Provider touches them. The reference implementation adapts the existing [`ai-briefing`](https://github.com/alexanderwiebe/learning-from-data) Twitter-list pipeline: RSSHub feed fetch, semantic (embedding-similarity) deduplication, and link enrichment (arXiv abstracts, blog previews, t.co resolution).

A **Notification/Digest Provider** pushes a personalized, private summary of graph activity to an external channel on a schedule — the inverse of a Publishing Provider (private and push-based vs. public and opt-in/pull-based). The reference implementation adapts `ai-briefing`'s Telegram bot: a twice-daily scheduled digest with interactive callbacks (re-fetch a section, view item detail, save an item into the graph).

Every interaction between the platform and an external system should occur through a documented plugin API.

---

## 3. Project Goals

### Primary goals

- Open source.
- Local-first where practical.
- Plugin-first architecture.
- Agent-friendly extension model.
- Vendor-independent core.
- Strong provenance for generated/imported knowledge.
- Graph-native representation of research.
- Support both machine and human understanding.
- Preserve user ownership of research data.
- Allow multiple interchangeable providers for the same capability.
- Make it straightforward for coding agents to create new plugins.

### Non-goals for the initial version

- Replacing Zotero as a complete reference manager.
- Replacing Obsidian as a general-purpose note-taking application.
- Building a new academic search index.
- Building a PDF reader from scratch.
- Building an AI model provider.
- Solving every bibliographic metadata problem internally.

The platform should orchestrate and connect those systems rather than recreate all of them.

---

# 4. Core Domain Model

The core data model should remain independent of integrations.

At a high level:

```text
Research Graph
│
├── Documents
├── Relationships
├── Concepts
├── Assertions
├── Provenance
├── Processing Events
└── Artifacts
```

---

## 4.1 Documents

A `Document` represents a scholarly object.

Initially this will primarily mean papers, but the abstraction should permit additional research objects later:

- journal articles
- conference papers
- books
- book chapters
- dissertations
- standards
- reports
- datasets
- web resources
- notes or other research artifacts

Example conceptual model:

```typescript
interface Document {
  id: DocumentId;

  title?: string;
  authors?: Author[];
  publicationDate?: Date;
  doi?: string;

  externalIdentifiers: ExternalIdentifier[];

  metadata: Assertion[];
}
```

The internal document ID belongs to the Research Knowledge Graph Platform.

External identifiers such as Zotero keys, DOIs, OpenAlex IDs, Semantic Scholar IDs, etc. are mappings to that internal identity.

---

# 5. Relationships

Relationships are first-class graph objects rather than simple links.

A relationship should contain at minimum:

```typescript
interface Relationship {
  id: RelationshipId;

  source: EntityId;
  target: EntityId;

  type: RelationshipType;

  assertions: Assertion[];
}
```

Examples of relationship types:

### Formal scholarly relationships

```text
CITES
CITED_BY
```

### Semantic relationships

```text
RELATED_TO
EXTENDS
CONTRADICTS
SUPPORTS
USES_METHOD_FROM
USES_SAME_METHOD
BUILDS_ON
REPLICATES
APPLIES
COMPARES_WITH
```

The exact ontology should remain extensible.

Plugins should be able to introduce additional relationship types without modifying the core.

---

# 6. Assertions and Provenance

One of the most important architectural concepts should be the distinction between:

> **A fact**

and

> **An assertion that a fact is true**

The system should retain where information came from.

For example:

```text
Paper A → CITES → Paper B

asserted by:
OpenAlex
```

or:

```text
Paper A → EXTENDS → Paper B

asserted by:
Claude Research Processor

confidence:
0.78
```

or:

```text
Paper A → EXTENDS → Paper B

asserted by:
User
```

Conceptual model:

```typescript
interface Assertion<T> {
  value: T;

  provenance: {
    actor: string;
    plugin?: string;
    source?: string;
    timestamp: Date;
  };

  confidence?: number;
}
```

This should apply broadly to:

- metadata
- citations
- semantic relationships
- concepts
- summaries
- classifications
- processing results
- generated annotations

This allows contradictory assertions to coexist without destroying information.

---

# 7. Processing Model

The platform should represent research processing as **events**, rather than storing only a single status enum.

For example:

```text
Paper discovered
       ↓
Paper acquired
       ↓
Metadata enriched
       ↓
AI preprocessing completed
       ↓
Concepts extracted
       ↓
Relationships suggested
       ↓
User started reading
       ↓
User completed reading
       ↓
User synthesized understanding
```

Example event history:

```text
✓ discovered
  source: Zotero Connector

✓ acquired
  source: Local Document Acquisition Provider

✓ metadata-enriched
  source: OpenAlex Provider

✓ summarized
  source: Claude Processor

✓ concepts-extracted
  source: Claude Processor

✓ reading-started
  source: user

✓ reading-completed
  source: user

✓ synthesized
  source: user
```

The UI can derive a simplified processing state from those events.

For example:

```text
Discovered
Acquired
AI Processed
Reading
Human Processed
Synthesized
```

The detailed event history remains intact.

---

# 8. Plugin Architecture

Plugins should implement well-defined capability contracts.

Plugins should not receive unrestricted access to internal implementation details by default.

Where possible:

- contracts should be versioned;
- capabilities should be discoverable;
- plugins should declare supported features;
- optional functionality should be represented explicitly;
- plugins should be independently testable;
- reference plugins should demonstrate recommended implementation patterns.

---

# 9. Research Library Connector

This replaces the concept of **"Zotero ingestion."**

Preferred capability name:

> **Research Library Connector**

Its responsibility is interacting with an external research/reference library.

Possible capabilities include:

```text
read documents
search documents
read collections
read attachments
read annotations
write metadata
subscribe to changes
```

A connector declares which capabilities it supports.

Example:

```typescript
interface ResearchLibraryConnector {
  capabilities(): LibraryCapabilities;

  listDocuments(query?: DocumentQuery): Promise<Document[]>;

  getDocument(
    externalId: string
  ): Promise<Document>;

  getAttachments(
    externalId: string
  ): Promise<Attachment[]>;

  getAnnotations?(
    externalId: string
  ): Promise<Annotation[]>;

  updateMetadata?(
    externalId: string,
    patch: MetadataPatch
  ): Promise<void>;

  subscribe?(
    events: LibraryEventHandler
  ): Promise<Subscription>;
}
```

### Initial reference implementation

```text
Research Library Connector API
└── Zotero Connector
```

Potential future implementations:

```text
BibTeX
Mendeley
Paperpile
EndNote
Local PDF directory
Custom research databases
```

---

# 10. Document Acquisition Provider

Document discovery and document acquisition should be separate concerns.

A Research Library Connector may know that a paper exists without possessing its full text.

A Document Acquisition Provider answers:

> How can the platform obtain the actual research artifact?

Conceptual contract:

```typescript
interface DocumentAcquisitionProvider {
  locate(
    document: Document
  ): Promise<AcquisitionCandidate[]>;

  acquire(
    candidate: AcquisitionCandidate
  ): Promise<Artifact>;
}
```

Potential providers:

```text
Local filesystem
Existing reference-manager attachments
Open-access providers
Publisher APIs
Institutional access integrations
User-supplied files
```

---

# 11. Scholarly Metadata Provider

Scholarly metadata should come through a dedicated contract.

Responsibilities may include:

- document identification
- DOI resolution
- metadata enrichment
- citation lookup
- reference lookup
- author metadata
- venue metadata

Conceptual contract:

```typescript
interface ScholarlyMetadataProvider {
  identify(
    document: Partial<Document>
  ): Promise<DocumentIdentity[]>;

  enrich(
    document: Document
  ): Promise<Metadata>;

  citations(
    document: Document
  ): Promise<Citation[]>;

  references(
    document: Document
  ): Promise<Citation[]>;
}
```

### Initial reference implementation

```text
OpenAlex Provider
```

Potential additional providers:

```text
Crossref
Semantic Scholar
OpenCitations
```

Multiple providers should be able to assert information about the same paper.

---

# 12. Relationship Provider

Relationship providers discover or create graph edges.

Possible relationship sources include:

```text
bibliographic citation data
AI semantic analysis
embedding similarity
ontology extraction
user-created relationships
external knowledge graphs
```

Example:

```text
OpenAlex
   │
   └── Paper A CITES Paper B

Claude
   │
   └── Paper A EXTENDS Paper B

User
   │
   └── Paper A USES_SAME_ONTOLOGY_AS Paper C
```

Relationships retain provenance and confidence.

---

# 13. Research Processor

AI and automated document processing should occur through a generic processing contract.

The core should not know what Claude, OpenAI, Gemini, or any other model is.

Conceptual capability:

```typescript
interface ResearchProcessor {
  capabilities(): ProcessorCapabilities;

  process(
    document: ResearchDocument,
    context: ProcessingContext
  ): Promise<ProcessingResult>;
}
```

Possible processor capabilities:

```text
summarization
highlighting
annotation generation
concept extraction
relationship discovery
keyword extraction
methodology extraction
ontology extraction
claim extraction
citation analysis
question generation
```

### Initial reference processors

Potentially:

```text
Claude Processor
OpenAI/Codex Processor
```

The architecture should also permit:

```text
Gemini
Ollama
local inference
specialized research agents
custom workflows
```

---

# 14. Knowledge Store

The abstraction for Obsidian integration should be broader than "notes."

Preferred capability name:

> **Knowledge Store**

A Knowledge Store persists user or generated research knowledge outside the graph database when desired.

Possible content:

- notes
- summaries
- synthesis
- annotations
- relationship explanations
- concept notes
- reading notes
- generated Markdown

Conceptual contract:

```typescript
interface KnowledgeStore {
  getDocumentKnowledge(
    documentId: DocumentId
  ): Promise<DocumentKnowledge>;

  saveDocumentKnowledge(
    documentId: DocumentId,
    knowledge: DocumentKnowledge
  ): Promise<void>;

  getRelationshipKnowledge?(
    relationshipId: RelationshipId
  ): Promise<RelationshipKnowledge>;

  saveRelationshipKnowledge?(
    relationshipId: RelationshipId,
    knowledge: RelationshipKnowledge
  ): Promise<void>;
}
```

### Initial reference implementation

```text
Obsidian Knowledge Store
```

Potential alternatives:

```text
Markdown filesystem
Logseq
Notion
Git repository
Internal database
Custom knowledge system
```

---

# 15. Core Graph Storage

The internal graph should be authoritative for:

```text
internal document identity
relationships
assertions
provenance
processing events
concepts
plugin-generated knowledge
integration mappings
```

The persistence implementation should itself ideally be abstractable.

Potential implementations could eventually include:

```text
SQLite
PostgreSQL
graph databases
embedded graph stores
```

The initial implementation should optimize for simplicity and portability rather than adopting a graph database solely because the UI is graph-based.

---

# 16. Visualization

The primary interface should present research as an interactive graph.

Core visual model:

```text
Papers / research objects = nodes
Relationships            = edges
Processing state         = node styling
Relationship provenance  = edge styling
Relationship type        = edge styling / labels
```

Examples:

```text
Paper A ─────CITES─────→ Paper B

Paper A - - -EXTENDS- -→ Paper C
          AI assertion

Paper A ═══RELATED_TO══→ Paper D
          user assertion
```

Processing state can be represented through node appearance.

For example:

```text
Discovered
Acquired
AI processed
Reading
Human processed
Synthesized
```

The exact colors and visual language should be configurable.

---

# 17. Graph Interaction Model

Clicking a node should display a persistent document inspector rather than requiring modal dialogs for common navigation.

Possible inspector contents:

```text
Title
Authors
Publication information
Identifiers
Processing status
Processing history
AI summary
User synthesis
Concepts
Relationships
Citations
Cited-by papers
Annotations
External-library links
Open PDF
Open in connected knowledge store
```

The interface should permit rapid traversal from paper to paper.

---

# 18. Multiple Graph Views

The same graph data should support multiple visualization strategies.

### Citation View

Emphasize documented scholarly lineage.

```text
newer papers
     ↓
citation relationships
     ↓
foundational papers
```

### Semantic View

Emphasize conceptual relationships.

```text
Ontology
Knowledge Graphs
OWL
LLMs
Semantic Web
Reasoning
```

### Neighborhood View

Focus on one paper and its immediate relationships.

```text
             cited by
                ↑
related ← [ PAPER ] → cites
                ↓
              extends
```

### Processing View

Emphasize workflow status.

Example questions:

```text
What papers have I acquired but not AI processed?
What papers are AI processed but unread?
What papers have I read but not synthesized?
```

### Timeline View

Potential future view:

```text
publication chronology
research development
personal reading chronology
```

---

# 19. Visualization Technology

Initial recommendation:

> **Cytoscape.js**

Reasons:

- graph-native library;
- directed and typed edges;
- arbitrary node/edge metadata;
- event handling;
- data-driven styling;
- strong layout ecosystem;
- graph algorithms;
- suitable for interactive research graphs.

The architecture should avoid coupling graph data structures directly to Cytoscape.js so the renderer can eventually be replaced.

Potential high-scale renderer:

```text
Sigma.js + Graphology
```

This may become useful if graphs grow toward very large node/edge counts.

---

# 20. Agent-Friendly Plugin Development

A major project goal is enabling AI coding agents to extend the platform.

Plugin APIs should therefore prioritize:

- small interfaces;
- strong TypeScript types;
- JSON schemas where useful;
- generated API documentation;
- reference implementations;
- contract tests;
- minimal hidden conventions;
- examples of common integration patterns;
- isolated plugin repositories/packages where practical.

An agent should be able to receive a request such as:

> Implement a Paperpile Research Library Connector conforming to ResearchLibraryConnector v1.

and produce a plugin without needing to modify the core.

---

# 21. Plugin Capability Discovery

Plugins should declare what they can do.

Example:

```json
{
  "plugin": "zotero-connector",
  "implements": "research-library-connector",
  "apiVersion": "1",
  "capabilities": {
    "documents": true,
    "collections": true,
    "attachments": true,
    "annotations": true,
    "writeMetadata": true,
    "subscriptions": true
  }
}
```

This avoids forcing all connectors to implement every possible feature.

The UI and workflows can adapt to available capabilities.

---

# 22. Plugin Isolation and Permissions

As the ecosystem grows, plugins may access sensitive resources.

The architecture should eventually support explicit permissions such as:

```text
read research library
write research library
read local files
write local files
network access
invoke AI provider
write knowledge store
modify graph
```

This does not need to be fully sandboxed in the first prototype, but the plugin model should avoid making future isolation impossible.

---

# 23. Suggested Initial Reference Stack

The first usable system can be built around a deliberately small number of reference plugins:

```text
Research Knowledge Graph Core
│
├── Zotero Research Library Connector
├── OpenAlex Scholarly Metadata Provider
├── Claude/OpenAI Research Processor
├── Obsidian Knowledge Store
└── Cytoscape.js Graph UI
```

Important:

None of these should be required by the core.

They are reference implementations demonstrating the plugin contracts.

---

# 24. Example End-to-End Workflow

```text
1. Zotero Connector discovers a new paper
                 │
                 ▼
2. Core creates / resolves Document identity
                 │
                 ▼
3. OpenAlex enriches metadata
                 │
                 ├── references
                 ├── cited-by relationships
                 └── external identifiers
                 │
                 ▼
4. Document Acquisition Provider finds full text
                 │
                 ▼
5. Research Processor analyzes the paper
                 │
                 ├── summary
                 ├── highlights
                 ├── concepts
                 ├── claims
                 └── suggested relationships
                 │
                 ▼
6. Graph adds AI assertions with provenance
                 │
                 ▼
7. Knowledge Store receives generated notes
                 │
                 ▼
8. User reads paper
                 │
                 ├── accepts/rejects AI relationships
                 ├── creates relationships
                 ├── writes notes
                 └── synthesizes understanding
                 │
                 ▼
9. Processing events record the user's progress
                 │
                 ▼
10. Graph UI reflects the evolving research model
```

---

# 25. Suggested Development Phases

## Phase 0 — Research Existing Tools

Before implementing the platform, examine existing systems for useful interaction patterns and architecture ideas.

Primary systems to evaluate:

```text
ResearchRabbit
Litmaps
Zotero Citation Graph
Inciteful
Connected Papers
Obsidian graph ecosystem
```

The goal is not to copy their product model, but to identify:

- useful graph interactions;
- citation-navigation patterns;
- layout approaches;
- Zotero synchronization patterns;
- paper discovery workflows;
- useful filtering techniques;
- common UX failures.

---

## Phase 1 — Core Domain Model

Build and test:

```text
Document
Relationship
Assertion
Provenance
ProcessingEvent
ExternalIdentifier
Artifact
Concept
```

Avoid third-party integration logic during this phase.

Deliverables:

- TypeScript domain model;
- storage schema;
- serialization format;
- unit tests;
- identity-resolution strategy.

---

## Phase 2 — Plugin SDK

Define version 1 contracts for:

```text
Research Library Connector
Scholarly Metadata Provider
Knowledge Store
Research Processor
Relationship Provider
Document Acquisition Provider
```

Deliverables:

- TypeScript interfaces;
- plugin manifest;
- capability discovery;
- plugin lifecycle;
- contract tests;
- example mock plugins;
- developer documentation.

---

## Phase 3 — Zotero Reference Connector

Implement Zotero as the first Research Library Connector.

Initial capabilities:

```text
list papers
read metadata
read collections
read attachments
map Zotero item keys to internal IDs
detect changes
```

Bidirectional writes can be added after the read path is stable.

---

## Phase 4 — OpenAlex Provider

Implement:

```text
document identity resolution
metadata enrichment
references
cited-by relationships
```

Ensure every imported relationship retains OpenAlex provenance.

---

## Phase 5 — Initial Graph UI

Implement Cytoscape.js visualization.

Minimum features:

```text
render papers
render citation edges
node selection
persistent inspector
search
filter
zoom/pan
focus neighborhood
processing-state styling
relationship provenance styling
```

---

## Phase 6 — Processing Pipeline

Implement the Research Processor plugin system.

First processor should demonstrate:

```text
summary
concept extraction
relationship suggestions
processing events
```

All generated information must retain processor/model provenance.

---

## Phase 7 — Obsidian Reference Knowledge Store

Create an Obsidian-oriented Knowledge Store implementation.

Potential representation:

```text
one Markdown file per paper
stable internal document ID
Zotero key
DOI
AI summary
user synthesis
concepts
relationships
processing metadata
```

Avoid making the Obsidian file format part of the core domain model.

---

## Phase 8 — Human Knowledge Layer

Add UI for:

```text
creating relationships
editing relationships
accepting AI suggestions
rejecting AI suggestions
adding relationship explanations
marking reading progress
writing synthesis
editing concepts
```

Human assertions should remain distinct from AI and external assertions.

---

## Phase 9 — Extensibility Validation

Before expanding the feature set, prove the plugin architecture by implementing at least one alternate plugin for several capabilities.

Examples:

```text
BibTeX Research Library Connector
Markdown Knowledge Store
Crossref Metadata Provider
Local/mock Research Processor
```

If alternate implementations require core changes, revise the contract.

---

## Phase 10 — Public Publishing

Give the platform a public-facing output path: a Publishing Provider capability contract, plus a reference implementation that renders curated, opt-in content to the web via Quarto.

Delivers:

```text
Publishing Provider capability contract
Quarto/Jupyter Publishing Provider (learning-from-data)
Per-item public/private opt-in flag
Provenance preserved in published output (documented vs. AI-suggested vs. user-authored)
```

Nothing is published without explicit per-item opt-in. Depends on there being synthesized content worth publishing (Phase 6 processing pipeline, Phase 8 human knowledge layer).

---

## Phase 11 — Ambient Discovery & Briefing

Give the platform a way to proactively surface new candidate material instead of only reacting to what a user's library already contains: a Discovery Source Provider capability contract, an actionability/importance Research Processor, and a Notification/Digest Provider capability contract — reference implementations adapted from the existing `ai-briefing` Twitter → Telegram system.

Delivers:

```text
Discovery Source Provider capability contract
Twitter/X-via-RSSHub Discovery Source (ai-briefing)
Semantic dedup + link enrichment on discovered candidates
Actionability/importance classification as a Research Processor (Claude, four-quadrant, trend + credibility context)
Notification/Digest Provider capability contract
Telegram Notification/Digest Provider (ai-briefing), scheduled, with interactive save/detail callbacks
```

Depends on the Research Processor plugin system (Phase 6) for classification, and the core domain model (Phase 1) for candidate documents to land in a `Discovered` state.

---

## Phase 12 — Ambient Relationship Discovery

Prove the Relationship Provider contract for background, corpus-wide relationship discovery — not just per-paper AI suggestions — via a reference implementation adapted from `ai-briefing`'s `connections.py` vault agent.

Delivers:

```text
Embedding-based Relationship Provider reference implementation
Scheduled (weekly) vault-wide scan for semantic neighbors above a similarity threshold
Automatic population of a note's Related section with backlinks, tagged with this provider's provenance
Dry-run/preview mode before writing
```

Depends on the Obsidian Knowledge Store (Phase 7) and the Relationship Provider contract (Section 12).

---

# 26. Repository Strategy

A possible project structure:

```text
research-knowledge-graph/
│
├── packages/
│   ├── core/
│   ├── domain/
│   ├── plugin-sdk/
│   ├── graph-ui/
│   └── app/
│
├── plugins/
│   ├── zotero-connector/
│   ├── openalex-provider/
│   ├── obsidian-knowledge-store/
│   └── ai-research-processor/
│
├── examples/
│   ├── minimal-library-connector/
│   ├── minimal-knowledge-store/
│   └── minimal-relationship-provider/
│
├── docs/
│   ├── architecture/
│   ├── plugin-api/
│   └── development/
│
└── tests/
    └── plugin-contracts/
```

This is only an initial organizational direction and should not be treated as a fixed monorepo decision until the plugin loading/distribution model is designed.

---

# 27. Key Architecture Decisions to Resolve

Before significant implementation, explicitly decide:

### Identity

How are duplicate papers identified across providers?

Potential identifiers:

```text
DOI
title + authors
OpenAlex ID
Zotero item key
ISBN
arXiv ID
PMID
```

The platform needs an identity-resolution layer rather than relying on one provider's ID.

### Relationship ontology

Determine how relationship types are defined and extended.

Questions include:

- Are relation types free-form?
- Are they URI-based?
- Can plugins register schemas?
- Are inverse relationships explicit?
- Can relationships target concepts as well as documents?

### Human vs AI authority

Decide whether user assertions can:

```text
override
reject
supersede
or coexist with
```

machine-generated assertions.

Default preference should be coexistence plus explicit user decisions rather than destructive overwrite.

### Synchronization

Define whether integrations use:

```text
pull
push
event subscription
periodic synchronization
```

and how conflicts are handled.

### Storage

Choose an initial persistence layer that is simple but does not restrict the semantic model.

### Plugin execution

Determine whether plugins initially run:

```text
in-process
as local child processes
through HTTP
through an RPC protocol
```

The long-term architecture should allow stronger isolation.

---

# 28. Guiding Principles

The following principles should guide design decisions.

### The core owns meaning

External products supply data and capabilities.

They do not define the platform's internal ontology.

### Preserve provenance

Never silently collapse:

```text
external scholarly data
AI inference
user understanding
```

into a single indistinguishable fact.

### Prefer events over mutable workflow flags

Keep the history.

Derive convenient status labels from it.

### Plugins describe capabilities

Do not assume every provider supports the same feature set.

### Human understanding is first-class

The system is not complete when AI has summarized a paper.

The user's own synthesis, relationships, and conceptual model are core data.

### Make extension easy for agents

A plugin interface should be understandable without reading the entire platform source.

### Avoid vendor-specific abstractions

Use:

```text
Research Library Connector
```

not:

```text
Zotero Adapter API
```

Use:

```text
Knowledge Store
```

not:

```text
Obsidian Notes API
```

Use:

```text
Research Processor
```

not:

```text
Claude Integration
```

---

# 29. Long-Term Direction

The platform should ultimately allow a researcher to look at a body of literature and see several overlapping knowledge systems at once:

```text
                     RESEARCH KNOWLEDGE GRAPH

              documented scholarly knowledge
                         citation graph
                              │
                              ▼
              ┌─────────────────────────┐
              │                         │
              │     research papers     │
              │                         │
              └─────────────────────────┘
                   ▲               ▲
                   │               │
         AI understanding      human understanding
                   │               │
          inferred concepts    personal concepts
          inferred relations   personal relations
          generated notes      synthesis
                   │               │
                   └───────┬───────┘
                           │
                    processing history
```

The result should be more than a literature-discovery tool.

It should become an extensible environment for building and navigating a researcher's evolving model of knowledge.

---

# 30. Working Project Description

> **Research Knowledge Graph Platform** is an open-source, plugin-first system for building a personal semantic graph of academic research. It combines documented scholarly relationships, AI-derived understanding, human-created knowledge, and personal research workflow state while remaining independent of any specific reference manager, AI provider, metadata source, note-taking application, or storage backend.

