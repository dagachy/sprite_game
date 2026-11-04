---
name: agent-frontmatter
description: 에이전트 정의 파일의 frontmatter 완비성(필수 4필드 + 본문 프롬프트) 진단 진입점. 단일 agent .md 또는 디렉토리를 agent-frontmatter-auditor 에이전트로 감사하고 집계 리포트를 반환한다. 사용자가 "에이전트 frontmatter 점검", "agent frontmatter audit", "에이전트 메타 검증" 등을 요청할 때 사용.
---

# agent-frontmatter

에이전트 정의 frontmatter 완비성 진단 라우터.
단일 모드 / 배치 모드 두 가지를 지원한다.

---

## 모드 결정

- 사용자가 `.md` 파일 경로를 주면 **단일 모드**.
- 디렉토리 경로를 주거나 "모든 에이전트"/"전체 감사"를 요청하면 **배치 모드** (기본 `.claude/agents/`).

---

## 단일 모드

입력: agent `.md` 절대 경로 1개.

1. `agent-frontmatter-auditor` 에이전트 1회 호출. 프롬프트에 `TARGET=<absolute path>`.
2. 리포트 그대로 노출.
3. Verdict가 `BROKEN` 이면 "로드 실패 위험" 1줄로 재강조.

---

## 배치 모드

입력: 디렉토리 경로.

1. `*.md` glob으로 대상 파일 수집 (하위 디렉토리 포함 안 함, maxdepth=1).
2. 각 파일마다 `agent-frontmatter-auditor` 를 **병렬 호출**. 10개 단위 배치.
3. 집계 표:

```
| Agent | Required | Recommended | Body | Verdict |
|-------|:--------:|:-----------:|:----:|---------|
```

4. 끝에 "BROKEN N건 / INCOMPLETE M건 / 전체 K건" 요약.

---

## 임계값 override

- `REQUIRED_FIELDS` (기본 `name,description,model,tools`): 쉼표 구분 필수 필드 목록.
- `RECOMMENDED_FIELDS` (기본 `color`): 권장 필드. 누락 시 INCOMPLETE 사유에만 포함, BROKEN은 아님.
- `MIN_BODY_LINES` (기본 `3`): frontmatter 뒤 본문 최소 라인 수. 그 미만이면 "본문 부재"로 판정.

---

## 자가 검증

```
<플러그인 루트>/.claude/skills/agent-frontmatter/samples/
├── complete/sample-agent.md       # 필수 4 + 권장 + 본문 → COMPLETE
├── missing-tools/sample-agent.md  # tools 누락 → BROKEN
└── no-body/sample-agent.md        # frontmatter만, 본문 없음 → BROKEN
```

3/3 Verdict 일치 → PASS.

---

## 범용 적용 메모

이 스킬은 `harness-structure` 가 뼈대를 확인한 뒤 각 agent 품질을 보장한다.
반대로 `agent-tools-contract` 는 `tools:` 필드의 **역할 적합성**을 본다 (권한 과소/과잉).
세 스킬 역할 분리:
- harness-structure: 뼈대 존재 여부
- agent-frontmatter: 메타 필드 완비성
- agent-tools-contract: 권한 적합성
