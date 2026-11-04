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
  - **왜:** 한 하네스를 깊게 보는 요청과 여러 프로젝트를 나란히 보는 요청을 구분해 결과가 섞이지 않게 한다.
- 디렉토리 경로를 다수 나열하거나 "모든 하위 프로젝트"를 요청하면 **배치 모드** (각 경로를 독립 하네스 루트로 간주).
  - **왜:** 각 경로를 독립 루트로 봐야 한 프로젝트의 결함이 다른 프로젝트의 판정에 섞이지 않는다.

---

## 단일 모드

입력: 하네스 루트 디렉토리 절대 경로 1개.

1. `harness-structure-auditor` 에이전트를 1회 호출. 프롬프트에 `TARGET=<absolute path>` 를 전달.
2. 에이전트 리포트를 그대로 노출.
3. Verdict가 `INCOMPLETE` 또는 `EMPTY` 이면 Recommendations 블록을 요약 1~2줄로 재강조.
   - **왜:** 뼈대가 없으면 후속 condition 스킬 실행 자체가 무의미하므로, 해결 순서를 먼저 드러낸다.

---

## 배치 모드

입력: 디렉토리 경로 다수.

1. 각 경로마다 `harness-structure-auditor` 를 **병렬 호출** (단일 메시지 다수 Agent 툴).
   - **왜:** 경로마다 판정이 독립이라 병렬로 돌려도 서로 간섭하지 않고, 전체 시간이 줄어든다.
2. 결과를 집계 표로 출력:

```
| Root | CLAUDE.md | agents | skills | FM valid | Verdict |
|------|:---------:|:------:|:------:|:--------:|---------|
```

3. 표 끝에 "INCOMPLETE N건 / 전체 M건" 요약을 1줄로 덧붙인다.
   - **왜:** 미완성 하네스가 몇 개인지 한 줄로 보여 정비 범위를 바로 잡게 한다.

---

## 임계값 override

호출자는 아래 환경변수로 조정 가능.

- `REQUIRE_README` (기본 `0`): `1` 지정 시 README.md 부재도 INCOMPLETE 사유에 포함.
  - **왜:** README는 하네스 동작에 필요한 뼈대가 아니라서 기본은 끄고, 문서화를 요구하는 프로젝트만 켠다.
- `MIN_AGENTS` (기본 `1`): 최소 agent 파일 수.
  - **왜:** 에이전트가 하나도 없으면 하네스가 성립하지 않으므로, 1을 하한으로 둔다.
- `MIN_SKILLS` (기본 `1`): 최소 SKILL.md 수.
  - **왜:** 스킬이 최소 하나는 있어야 하네스가 실제 작업 절차를 가진다.

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

**왜:** COMPLETE / INCOMPLETE / EMPTY 세 상태를 모두 구분해야 감사기의 판정을 믿을 수 있다.

---

## 범용 적용 메모

이 스킬은 "condition" 플러그인 번들의 pre-flight 1차 관문이다. 뼈대가 없으면 후속 condition 스킬(agent-frontmatter, agent-tools-contract 등) 실행 자체가 의미 없음.

**왜:** 뼈대가 없는 상태에서 후속 감사를 돌리면 존재하지 않는 파일을 검사하게 되므로, 이 스킬이 항상 먼저 실행되어야 한다.
