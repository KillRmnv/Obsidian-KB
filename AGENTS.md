# Obsidian-KB

## What this is

Personal Obsidian knowledge base — markdown notes, not a code project. Content is in **Russian**.

## Structure

- `Java/` — main workspace root (contains `.obsidian/` config)
- Notes are organized by topic under `Java/` (Программирование, Тестирование, Databases, etc.)
- Images stored as `.png`/`.jpg` alongside notes

## Key constraints

- **Git LFS** is required for: `*.pdf *.docx *.pptx *.xlsx *.zip *.psd *.ai *.mp4 *.mov *.png *.jpg *.jpeg` — see `.gitattributes`
- Do not commit `.obsidian/workspace.json` or other local Obsidian state
- Do not commit `.smart_env/`
- No build system, no tests, no linter — this is a documentation vault

## Gotchas

- Root `.gitignore` is broken — it contains a shell script (`cat > .gitignore << 'EOF'`), not actual patterns. The real `.smart_env/` ignore lives in `Java/.gitignore`. If you need to add global ignores, fix the root `.gitignore` first.
- `Java/.obsidian/workspace.json` is tracked in git and shows as modified locally. The AGENTS.md instruction to not commit it still holds — treat it as local state.

## Conventions

- Commit messages are in Russian
- Prefer editing existing notes over creating new ones
- Notes use Obsidian wikilinks (`[[note]]`) and embeds (`![[image.png]]`) for internal references
- No YAML frontmatter observed in existing notes — do not add it unless the note already has it
