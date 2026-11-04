---
name: harness
description: "프로젝트에 맞는 하네스를 설계하고, 전문 에이전트와 각 에이전트가 사용할 스킬을 만든다. 사용자가 '하네스 구성해줘', '하네스 구축해줘', '하네스 설계', '하네스 엔지니어링', '에이전트 팀 만들어줘'라고 요청할 때 사용한다. 새로운 분야나 프로젝트의 자동화 체계를 구축하거나 기존 하네스를 재구성·확장할 때도 사용한다. '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화'처럼 기존 하네스를 운영하거나 유지 보수하는 요청에도 사용한다. 실행 결과를 회고하고 피드백을 반영하는 작업에는 harness:evolve 스킬을 사용한다."
---

# Harness v2 라우터

## 단계 (필요한 단계 파일만 읽는다)

- 0단계 현재 상태 점검: 기존 `.claude/` 구성을 먼저 확인할 때 [0단계 상세](references/stage-0-current-state.md)
- 1단계 분야와 작업 분석: 새로 구축하거나 작업 종류와 흐름을 나눌 때 [1단계 상세](references/stage-1-analysis.md)
- 2단계 실행 모드와 팀 구조: 실행 모드와 팀 구성을 정할 때 [2단계 상세](references/stage-2-team-design.md), [실행 모드 상세](references/execution-modes.md), [팀 구성 패턴](references/team-patterns.md)
- 3단계 에이전트 정의: `.claude/agents/{name}.md`를 만들거나 고칠 때 [3단계 상세](references/stage-3-agent-definition.md), [모델 선택 가이드](references/model-selection-guide.md), [QA 에이전트 가이드](references/qa-agent-guide.md)
- 4단계 스킬 작성: `.claude/skills/{name}/SKILL.md`를 만들거나 고칠 때 [4단계 상세](references/stage-4-skill-writing.md), [스킬 작성 가이드](references/skill-writing-guide.md)
- 5단계 통합과 실행 순서: 오케스트레이터와 데이터 전달·오류 처리를 정할 때 [5단계 상세](references/stage-5-integration.md), [오케스트레이터 템플릿](references/orchestrator-template.md), [워크플로 예시](references/workflow-recipes.md), [실전 팀 구성 예시](references/team-examples.md), [CLAUDE.md 기록 템플릿](references/claude-md-template.md)
- 6단계 검증과 테스트: 구성을 마치고 검증할 때 [6단계 상세](references/stage-6-testing.md), [스킬 테스트 가이드](references/skill-testing-guide.md)
- 7단계 운영·유지 보수: 기존 하네스를 점검·수정·동기화할 때 [7단계 상세](references/stage-7-maintenance.md)

## 공통 참고

- 설계를 시작하거나 판단이 애매할 때 [핵심 원칙](references/core-principles.md)
- 완료 보고 전에 [산출물 점검표](references/deliverables-checklist.md)
