# HANDOFF

## Goal
사용자 지시는 3단계다. (1) 구현팀 엔진을 Godot 4로 전환한다. (2) 제안서 v5(`docs/proposals/game_proposal_v5.md`)를 바탕으로 기획·분석 18명이 phase별로 구현팀에 넘길 수준의 상세 기획을 쓴다. phase 간 결과는 파일로 공유한다. (3) 그 결과로 Godot 프로토타입 1차 구현을 시작한다. 사용자는 "끝나면 이어서 진행"하라고 했다.

## Decisions
- 엔진: Godot 4.7.2(`/opt/homebrew/bin/godot`), GDScript, Compatibility 렌더러. 프로젝트는 `game/`이다.
- 논리 해상도 216x384(×5 = 1080x1920). 청크 12x24(192px) + 좌우 12px 경계. 이동 110px/s, 스크롤 16px/s.
- 메인 결정(그리드 문자, 적 4종 매핑, z 순서, 문자열 마스터는 storyteller, 리뷰 개선 8건 채택, 불일치 정리)은 `_workspace/detail_spec/p{1..4}*/_summary.md`에 있다. 개별 문서와 충돌하면 요약이 우선한다(뒤 phase 요약이 앞 phase보다 우선).
- 성능 방침: 물리 엔진을 쓰지 않는다. 셀 비트마스크와 공간 해시로 처리하고, 탄은 배열 + 단일 노드로 렌더한다. 탄·적에 Area2D는 금지한다(p4 요약).
- 읽기 전용 에이전트 결과는 `python3 _workspace/detail_spec/extract.py <agent_id> <out>`로 transcript에서 추출한다. 스크립트 안의 TASKS 경로는 이 세션(d3431280…) 기준이다.
- 커밋·푸시는 사용자가 요청할 때만, main에 직접 한다.

## Done
- 구현 에이전트 6명을 Godot 기준으로 재작성했다. `CLAUDE.md`, `docs/SETUP.md`, `.gitignore`도 고쳤다(미커밋).
- 기획 P1~P4 18명 완료: `_workspace/detail_spec/{p1_analysis,p2_design,p3_bm_ops,p4_quality}/`(문서 18개 + 각 `_summary.md`), `brief.md`.
- 구현(gameplay-programmer, ID ad1fca7e5be86ed5d)은 **5시간 사용 한도(05:00 KST 리셋)에 걸려 중단됐다.** 지금까지 만든 것은 `game/scripts/core/{game_clock,log,palette}.gd`, `world/{chunk_def,chunk_db,chunk_lint}.gd`, `data/{imprint,offer_generator,offer_state,xp_curve,balance,defs}.gd`(약 830줄), `game/data/{chunks,recipes}/`다. 씬·전투·테스트는 아직 없다.

## Next
1. 한도가 리셋된 뒤 gameplay-programmer를 SendMessage(ad1fca7e5be86ed5d)로 이어서 진행시킨다. 새로 띄우지 않는다. 전달할 내용: `p4_quality/_summary.md`의 리뷰 개선 8건·불일치 정리·성능 방침을 반영하고, 테스트 러너 규약(종료 코드 0/1/2)을 지킬 것. 이어서 받지 못하면 같은 역할로 새로 띄우고 기존 파일을 읽고 이어 가게 한다.
2. 구현 보고를 받으면 `godot --headless --path game --script res://tests/run_tests.gd`와 `--quit-after`로 직접 검증한다.
3. P5: `docs/specs/`에 인계 문서를 통합한다. README에는 목차·확정값(요약 4개를 합친 것)·P0 범위·AC 목록 위치를 두고, 영역별 문서는 `_workspace` 문서를 복사한다(`_workspace/`는 gitignore 대상이라 저장소에 남기려면 필요하다).
4. ui-implementer에게 P0 UI를 맡긴다(ux §2, storyteller 문자열, 디버그·캡처 C1~C5, 최소 노드 구매 화면). 연결 기준은 `game/scripts/core/README.md`(gameplay가 작성).
5. 필요하면 technical-artist(플래시 셰이더, 위험 바닥 애니)를 맡긴다. 이후 사용자에게 실행 방법(`godot --path game`)과 결정 항목을 보고한다.

## Key files
- `_workspace/detail_spec/brief.md`: 범위·규칙·phase 표
- `_workspace/detail_spec/p4_quality/_summary.md`: 최신 메인 결정(리뷰 반영, 성능, 테스트 규약)
- `_workspace/detail_spec/p1_analysis/_summary.md`, `p2_design/_summary.md`, `p3_bm_ops/_summary.md`: 확정값
- `_workspace/detail_spec/p2_design/level-designer.md`: 청크 그리드 원본
- `_workspace/detail_spec/p4_quality/mobile-qa-lead.md`: AC-01~49, T-01~T-20
- `_workspace/detail_spec/p4_quality/mobile-producer.md` §5: 사용자 결정 D-01~D-26

## Open questions
- W1 마감 결정: D-14 P0 Core/Plus 분할, D-15 Godot 확정 + SDK 스파이크, D-09 SF 샘플 크레딧 승인.
- D-16 각인 노드 비용 6k, D-19 유상 젬 미도입, D-20 UA는 검증용으로만(LTV30 0.19달러 대비 CPI 2.2~2.5달러). §17.2의 13개.
- 이번 변경 커밋 여부.
