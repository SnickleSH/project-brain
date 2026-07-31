# project-brain

A markdown knowledge graph and execution pipeline that lives **inside** a repo,
next to the work it plans. Claude Code is the engine; Obsidian or VSCode is
just the viewer. No state files, no progress JSON — progress is checkbox state
plus git history.

Raw input goes in one door and gets routed: durable facts to a reference topic,
shallow work to a dated standing backlog, observations to an append-only log
stream, and only the material that genuinely needs a decision to a design doc.
Designs become checklists, checklists become code, and the whole graph is
committed alongside it.

It is not software-specific. The same stages carry investing, health,
coursework, or client work — see [`brain/README.md`](brain/README.md).

## Install

```
/plugin marketplace add SnickleSH/project-brain
/plugin install brain@project-brain
```

Then, in any repo you want a brain in:

```
/brain:init
```

`/brain:init` creates only the content tree, the lint script, a pre-commit
hook, and the operating contract inside marked fences in that repo's
`CLAUDE.md`. The commands stay in the plugin and are never copied in — which
is what keeps every repo on the same framework instead of drifting into its
own. When the plugin updates, `/brain:sync` refreshes the framework layer and
touches nothing you wrote.

## Commands

| | |
|---|---|
| `/brain:capture <text>` | append a raw note to the inbox |
| `/brain:triage` | dispatch the inbox without synthesizing |
| `/brain:plan <topic>` | synthesize the residue into a design doc |
| `/brain:analyze <doc>` | stress-test a design, or a policy against its log |
| `/brain:breakdown <doc>` | derive a checklist from a design |
| `/brain:execute <list>` | implement checklist items as code |
| `/brain:tidy` | audit the graph for drift, duplicates, bloat |
| `/brain:distill` | mint a skill from a thrice-repeated procedure |
| `/brain:init` `/brain:sync` | scaffold, and refresh the framework |

## Repo layout

This repository is three things at once: the marketplace
(`.claude-plugin/marketplace.json`), the plugin (`plugins/brain/`), and a
consumer of its own plugin (`brain/`, planning its own development).

Full documentation: [`brain/README.md`](brain/README.md).
Operating contract: [`plugins/brain/contract/brain-contract.md`](plugins/brain/contract/brain-contract.md).
