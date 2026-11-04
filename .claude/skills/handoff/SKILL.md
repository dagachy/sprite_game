---
name: handoff
description: Save the current work state to HANDOFF.md so the session can be cleared (/clear) and resumed cheaply. Use when a unit of work finishes, before a long break, or when the context is getting large.
---

# handoff

Write `HANDOFF.md` in the project root (the current working directory). A SessionStart hook
loads this file automatically after `/clear`, so the next session starts from a small, accurate
summary instead of the full history.

## Steps

1. Check the current state of the work. Use `git status` and `git diff --stat` if the project is a repo.
2. Write `HANDOFF.md` with exactly these sections, in Korean if the user works in Korean:
   - **Goal**: what the user wants, in 1–3 sentences
   - **Decisions**: choices already made and why (do not reopen these)
   - **Done**: completed steps with file paths
   - **Next**: the concrete next actions, in order
   - **Key files**: paths the next session must read, with one line each on why
   - **Open questions**: anything blocked on the user
3. Keep the whole file under about 6 KB. The hook truncates anything longer.
4. Do not copy code or long logs into it. Point to file paths instead.
5. Tell the user the file is saved and suggest `/clear` next.

## Notes

- Overwrite the previous `HANDOFF.md`. Only the latest handoff matters.
- If the project should not track this file, add `HANDOFF.md` to `.gitignore`.
