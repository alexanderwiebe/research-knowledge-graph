# Research Knowledge Graph Platform

An open-source, plugin-first platform for building a personal semantic graph of academic research. It combines documented scholarly relationships, AI-derived understanding, human-created knowledge, and personal research workflow state — while remaining independent of any specific reference manager, AI provider, metadata source, note-taking application, or storage backend.

See [`docs/high-level-plan.md`](docs/high-level-plan.md) for the full architecture and vision, and [`MILESTONES.md`](MILESTONES.md) for how that plan is being decomposed into shippable releases.

## Status

Early planning stage. No code yet — see Milestone 1 in [`MILESTONES.md`](MILESTONES.md).

## Core principle

> The core talks to capabilities, never products.

No third-party product (Zotero, Obsidian, OpenAlex, Claude, ...) is a hard dependency. The core defines stable capability contracts — Research Library Connector, Knowledge Store, Scholarly Metadata Provider, Document Acquisition Provider, Research Processor, Relationship Provider — and specific integrations implement them as plugins.

## Work breakdown

Work is tracked as: **Milestone** (incremental, marketable release) → **Epic** (group of related functionality) → **Story** (explainable to a user) → **Task** (accomplishable and testable) → **Pull Request**. See [`MILESTONES.md`](MILESTONES.md) for the convention and the current milestone list.

## Contributing

Not yet open for external contribution — the domain model and plugin contracts (Milestone 1) need to stabilize first. Once that lands, the explicit goal is to make it straightforward for both human and AI coding agents to build new plugins against documented contracts without reading the core source.
