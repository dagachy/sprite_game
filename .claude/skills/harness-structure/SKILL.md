---
name: harness-structure
description: 하네스 뼈대 구조(CLAUDE.md / .claude/agents / .claude/skills / frontmatter 완비) 진단 진입점. 지정 디렉토리를 harness-structure-auditor 에이전트로 감사하고 리포트를 반환한다. 사용자가 "하네스 구조 점검", "harness structure audit", "뼈대 확인" 등을 요청할 때 사용.
---

# harness-structure

하네스 기본 뼈대 구조 진단 라우터.
단일 디렉토리 / 다중 디렉토리 두 가지를 지원한다.

---

## 모드 결정

- 사용자가 디렉토리 경로 1개를 주면 **단일 모드**. 미지정 시 현재 작업 디렉토리를 사용.
- 디렉토리 경로를 다수 나열하거나 "모든 하위 프로젝트"를 요청하면 **배치 모드** (각 경로를 독립 하네스 루트로 간주).

---

## 단일 모드

입력: 하네스 루트 디렉토리 절대 경로 1개.

1. `harness-structure-auditor` 에이전트를 1회 호출. 프롬프트에 `TARGET=<absolute path>` 를 전달.
2. 에이전트 리포트를 그대로 노출.
3. Verdict가 `INCOMPLETE` 또는 `EMPTY` 이면 Recommendations 블록을 요약 1~2줄로 재강조.

---

## 배치 모드

입력: 디렉토리 경로 다수.

1. 각 경로마다 `harness-structure-auditor` 를 **병렬 호출** (단일 메시지 다수 Agent 툴).
2. 결과를 집계 표로 출력:

```
| Root | CLAUDE.md | agents | skills | FM valid | Verdict |
|------|:---------:|:------:|:------:|:--------:|---------|
```

3. 표 끝에 "INCOMPLETE N건 / 전체 M건" 요약을 1줄로 덧붙인다.

---

## 임계값 override

호출자는 아래 환경변수로 조정 가능.

- `REQUIRE_README` (기본 `0`): `1` 지정 시 README.md 부재도 INCOMPLETE 사유에 포함.
- `MIN_AGENTS` (기본 `1`): 최소 agent 파일 수.
- `MIN_SKILLS` (기본 `1`): 최소 SKILL.md 수.

---

## 자가 검증

다음 샘플 3건이 있으면 각각 실행:

```
<플러그인 루트>/.claude/skills/harness-structure/samples/
├── complete/   # 모두 완비 → COMPLETE
├── partial/    # CLAUDE.md만 있음 → INCOMPLETE
└── empty/      # 전무 → EMPTY
```

3/3 Verdict가 의도대로 나오면 PASS.

---

## 범용 적용 메모

이 스킬은 "condition" 플러그인 번들의 pre-flight 1차 관문이다. 뼈대가 없으면 후속 condition 스킬(agent-frontmatter, agent-tools-contract 등) 실행 자체가 의미 없음.
