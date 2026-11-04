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
   - **왜:** 기억이 아니라 실제 변경 상태에서 기록해야, 다음 세션이 틀린 전제로 시작하지 않는다.
2. Write `HANDOFF.md` with exactly the sections defined in [섹션 정의](references/sections.md), in Korean if the user works in Korean.
   - **왜:** 섹션을 고정해 두면 다음 세션이 목표·결정·다음 할 일을 매번 같은 자리에서 찾는다. 언어를 사용자에 맞추는 것도 사용자가 바로 읽고 이어갈 문서이기 때문이다.
3. Keep the whole file under about 6 KB. The hook truncates anything longer.
   - **왜:** SessionStart 훅이 6KB를 넘는 부분을 잘라 내므로, 잘리기 전에 줄여 핵심이 살아남게 한다.
4. Do not copy code or long logs into it. Point to file paths instead.
   - **왜:** 긴 로그는 6KB 한도를 빨리 채우고 다음 세션 컨텍스트를 다시 무겁게 만들므로, 경로로 대신한다.
5. Tell the user the file is saved and suggest `/clear` next.
   - **왜:** 저장이 끝난 뒤에야 /clear를 해야 컨텍스트를 비워도 정보가 남는다.

## Notes

- Overwrite the previous `HANDOFF.md`. Only the latest handoff matters.
  - **왜:** 훅은 최신 파일만 읽으므로, 이전 내용을 쌓아 두면 오래된 결정이 되살아날 위험이 있다.
- If the project should not track this file, add `HANDOFF.md` to `.gitignore`.
  - **왜:** 핸드오프는 일회성 세션 상태라, 저장소 이력에 남길 필요가 없는 프로젝트가 많다.
