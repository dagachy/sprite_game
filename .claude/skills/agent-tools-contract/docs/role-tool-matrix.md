# 역할-도구 적합성 매트릭스 (ex-04-01 + ex-11-04 원칙)

## 역할 분류

| 역할 | 신호 키워드 | 허용 도구 | 금지 도구 |
|------|------------|----------|----------|
| READ_ONLY | auditor, analyzer, reviewer, reader, inspector, scanner, 감사, 검토, 분석 | Read, Grep, Glob, Bash(read-only commands) | **Write, Edit, NotebookEdit** |
| WRITE_OK | writer, editor, refactorer, builder, generator, 작성, 편집, 리팩토러 | Read + Write + Edit + Bash | — |
| ORCHESTRATOR | orchestrator, coordinator, router, 조율, 라우터, 오케스트레이터 | **Task, SendMessage 필수** + 기타 | — |

## 왜 물리적으로 강제하는가

책 ex-04-01 원칙: **"안전은 지침이 아니라 권한으로 강제한다".**
- READ_ONLY 에이전트가 지침으로만 "Write 하지 마라" 선언 → 사고로 Write 호출 가능.
- `tools` 필드에서 Write 제외 → 호출 자체가 블록.

## 자동 커밋 리스크

Bash 보유 에이전트는 `git commit` / `git push` 호출이 가능. 명시적으로 **금지/안전 조항**이 본문에 선언되어야 함.

예:
```markdown
- git commit / git push 금지. 커밋은 유저가 수행.
```

이게 없으면 Verdict `RISK`.

## 비범위

- `tools` 필드가 YAML 리스트 다중 라인 형태인 경우 현 로직은 부분 지원.
- 역할 분류는 heuristic이라 override 필요한 프로젝트는 환경변수로 사전 교체.
