# 에이전트 목록

`.claude/agents/`에 정의된 에이전트 37명이다. 모델은 전부 `sonnet`이고, `token-auditor`만 `haiku`다.
구분은 권한(tools) 기준이다. 게임 개발 전문가 중 구현 에이전트 6명만 Edit·Write·Bash를 가진다.

## 구현 (Edit·Write·Bash)

| 이름 | 역할 |
|---|---|
| `gameplay-programmer` | 플레이어 조작, 2D 이동·충돌, 상태 머신, 게임 필 구현 |
| `level-pipeline-engineer` | Sprite Fusion 등 맵 임포터, 콜라이더 변환, 레벨 로딩 |
| `technical-artist` | 아틀라스, 텍스처 압축, URP 2D, 셰이더, 픽셀아트 렌더링 설정 |
| `ui-implementer` | uGUI·UI Toolkit 화면, 세이프 영역, 해상도 대응 |
| `backend-engineer` | 세이브 동기화, 계정, 결제 영수증 검증, 원격 설정 |
| `build-release-engineer` | 안드로이드·iOS 빌드, 서명, 빌드 자동화, 스토어 업로드 |

## 기획·분석 (읽기 전용)

| 이름 | 역할 |
|---|---|
| `game-reviewer` | 기획서·제안서·빌드를 플레이어 관점에서 평가 |
| `storyteller` | 세계관, 인물, 분기 서사, 반복 플레이의 서사 정당화 |
| `level-designer` | 레벨 구조, 난이도 곡선, 체크포인트, 타일맵 레이어 설계 |
| `bm-expert` | 가격 전략, 과금 설계, 재화 경제, LTV·ARPDAU |
| `economy-balance-analyst` | 재화 흐름, 성장 곡선, 밸런스 수치 분석 |
| `commercial-game-analyst` | 상용 게임의 루프, 메카닉, 수익 모델 분석 |
| `mechanics-analyst` | 핵심 조작, 게임 필, 학습·숙련 곡선 분석 |
| `ux-onboarding-analyst` | 첫 실행 경험, 튜토리얼, HUD, 접근성 옵션 |
| `art-audio-analyst` | 시각 언어, 색 팔레트, 사운드 설계 분석 |
| `market-data-analyst` | 매출·순위·DAU 등 정량 시장 데이터 수집과 교차 검증 |
| `market-review-analyst` | 스토어·커뮤니티 리뷰 흐름, 경쟁작 포지셔닝 |
| `user-acquisition-marketer` | ASO, 광고 캠페인, 소프트 런칭, 사전 등록 |
| `live-ops-analytics` | 이벤트 트래킹 명세, 대시보드, 라이브 옵스 운영 |
| `mobile-producer` | 범위(MVP) 정의, 일정, 리스크, 우선순위 |
| `mobile-qa-lead` | 테스트 매트릭스, 인터럽트 테스트, 출시 품질 게이트 |
| `mobile-performance-engineer` | 프레임, GC, 발열, 빌드 크기, 프로파일링 진단 |
| `store-compliance-specialist` | 스토어 심사 정책, 연령 등급, 개인정보·ATT·아동 규정 |
| `spritefusion-expert` | Sprite Fusion 에디터, 내보내기, MCP 연동 |
| `technical-director` | 아키텍처·계약·결정성·성능 예산 검토, 구현 작업 분배 |

## 하네스 메타 (감사·실행)

| 이름 | 역할 | 권한 |
|---|---|---|
| `harness-structure-auditor` | 하네스 뼈대(CLAUDE.md, agents, skills, frontmatter) 진단 | 읽기 + Bash |
| `agent-frontmatter-auditor` | 에이전트 frontmatter 필수 필드 진단 | 읽기 + Bash |
| `agent-tools-contract-auditor` | 에이전트 tools 필드의 역할 적합성 판정 | 읽기 + Bash |
| `antipattern-detector-auditor` | SKILL.md 안티패턴 3종 판정 | 읽기 + Bash |
| `skill-size-auditor` | SKILL.md 분리 신호 진단 | 읽기 + Bash |
| `menu-pattern-auditor` | 메뉴판 라우터 원칙 준수 진단 | 읽기 + Bash |
| `dag-validator-auditor` | tasks.json의 depends_on DAG 검증 | 읽기 + Bash |
| `team-size-governor-auditor` | 팀 규모 상한(전체·Phase별) 위반 진단 | 읽기 + Bash |
| `prose-pruner` | SKILL.md 본문 가지치기(컨텍스트 절약) | 읽기 + Write + Bash |
| `retry-safety-executor` | generator·verifier 재시도 루프 실행 | 읽기 + Write + Bash |
| `with-without-runner` | With/Without 환경 동시 실행과 메트릭 기록 | 읽기 + Write + Bash |
| `with-without-grader` | 단언 기반 pass_rate 채점과 comparison.md 작성 | 읽기 + Write + Bash |
| `token-auditor` | 세션 토큰 사용량 점검과 절감안 제시 (haiku) | 읽기 + Bash |

## 요약

- 전체 37명: 구현 6, 기획·분석 18, 하네스 메타 13.
- 구현 6명 외에도 `prose-pruner`, `retry-safety-executor`, `with-without-*`는 파일을 쓸 수 있다. 게임 산출물을 직접 바꾸지는 않는다.
- 팀 구성 규칙과 phase 후보는 `.claude/phases.json`, 승인 기준은 `CLAUDE.md`를 따른다.
