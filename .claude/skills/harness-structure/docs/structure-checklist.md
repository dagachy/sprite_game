# 하네스 뼈대 구조 체크리스트 (ex-02-02 원칙)

프로젝트 kickoff 전 pre-flight 1차 관문.

| 항목 | 필수? | 사유 |
|------|:-----:|------|
| `CLAUDE.md` | ✅ | 프로젝트 지침·룰·현재 단계 선언. Claude Code가 최우선 참조. |
| `.claude/agents/` | ✅ | 전문 에이전트 정의 디렉토리. 1개 이상 필수. |
| `.claude/skills/` | ✅ | 스킬 정의 디렉토리. 1개 이상 SKILL.md 필수. |
| `README.md` | 선택 | 유저용 안내. `REQUIRE_README=1` override 시 필수화. |
| agent/skill frontmatter | ✅ | `name` + `description` 2필드 최소 완비. 상세 스키마는 `agent-frontmatter` 스킬 책임. |

## 왜 이 순서인가

- `CLAUDE.md` 가 없으면 하네스 전체가 "지침 없는 에이전트 묶음"이 된다.
- `.claude/` 두 디렉토리가 없으면 Claude Code가 agent/skill을 발견하지 못한다.
- frontmatter 결함은 해당 agent/skill이 **로드 자체가 실패**한다.

## 범용 적용 범위

- 단일 저장소 프로젝트: 루트를 TARGET으로.
- 모노레포: 하위 프로젝트별로 배치 모드 호출.
- 글로벌 하네스(`~/.claude/`): 홈 디렉토리를 TARGET으로.

## 비범위

- 각 agent/skill의 **품질** (단일 책임, 역할 분리, 라우터 패턴 등)은 별도 condition 스킬 책임.
- 이 스킬은 "뼈대가 있는가"만 본다.
