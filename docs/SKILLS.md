# Building Hermes skills

Skills are how Hermes specializes. A skill is a self-contained folder with a charter (what it does, when to invoke), supporting reference docs, and executable scripts. Hermes' Curator grades, prunes, and consolidates skills on a 7-day cycle.

This repo includes [`skills/alpha-desk/`](../skills/alpha-desk/) as a full worked example — an equity research workflow.

## Required structure

```
skills/<your-skill-name>/
├── SKILL.md           # the charter — required
├── references/        # markdown docs the skill can pull into context
│   └── *.md
└── scripts/           # executable helpers — Python recommended
    └── *.py
```

## SKILL.md anatomy (read alpha-desk's for the full pattern)

A SKILL.md typically has:

- **Purpose** — one paragraph, what problem this solves
- **When to invoke** — triggers, keywords, user intents that should route here
- **Inputs** — what the skill needs from the conversation
- **Process** — the standard operating procedure
- **References** — pointers into `references/`
- **Tools** — what `scripts/` are available and what they do
- **Output format** — what the skill produces

## Deploying a skill to a running Hermes

```bash
# From the repo on your laptop
scp -r skills/<name> user@<vm>:/opt/hermes-anywhere/hermes-data/skills/

# Hermes picks it up on next conversation. The Curator grades it within 7 days.
```

For a fresh deploy (no existing VM): the cloud-init bootstrap clones this repo to `/opt/hermes-anywhere`. Skills in the repo's `skills/` directory are not auto-copied into `hermes-data/skills/` because skill installation is per-deployment intentional. Either copy manually after first boot or extend the cloud-init `runcmd` block to do it.

## Iterating on a skill

Hermes' value comes from the agent **modifying** skills based on experience. Don't over-specify — give it room to learn. The Curator will:

- Promote skills that get good outcomes
- Prune skills that go unused
- Consolidate overlapping skills
- Write reports to `hermes-data/logs/curator/`

Read those reports periodically to understand what Hermes has learned about your usage patterns.

## Sharing skills publicly

If you build a skill worth sharing, open a PR against this repo's `skills/` directory. We'll review for safety (no hardcoded secrets, no destructive scripts without confirmations) and merge.
