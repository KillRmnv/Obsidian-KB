# Obsidian-KB

## What this is

Personal Obsidian knowledge base — markdown notes, not a code project. Content is in **Russian**.

## Structure

- `Java/` — main workspace root (contains `.obsidian/` config)
- Notes are organized by topic under `Java/` (Программирование, Тестирование, Databases, etc.)
- Images stored as `.png`/`.jpg` alongside notes

## Key constraints

- **Git LFS** is required for binary files (images, PDFs, Office docs, etc.) — see `.gitattributes`
- Do not commit `.obsidian/workspace.json` or other local Obsidian state
- Do not commit `.smart_env/`
- No build system, no tests, no linter — this is a documentation vault

## Conventions

- Commit messages are in Russian
- Prefer editing existing notes over creating new ones
- Follow existing Obsidian note format (YAML frontmatter when present, `[[wikilinks]]` for internal links)
