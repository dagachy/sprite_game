# HANDOFF (2026-11-05, 4)

## Goal
Godot 4 모바일 2D 로그라이트 프로토타입(P0)을 출시 검증 가능한 수준으로 올린다. 한 판이 끝까지 돌고, 3택·로그·디버그 가드·캡처 도구가 들어가 있다. 밸런스는 사람 플레이 기록을 기다리는 중이다.

## Decisions (재논의 금지)
- 엔진 Godot 4.7.2 GDScript, 2D 전용. 루트 `game/`. 논리 해상도 216x384.
- **결정 규칙**: 사용자에게 물을 결정은 technical-director(TD)가 정하고, 실행은 전문가 팀 에이전트가 한다. 메인이 구현 파일을 직접 고치지 않는다. 메모리 `feedback-td-decides-via-teams`. 단, 실제 결제와 비밀 값 취급은 사용자 확인이 남는다.
- 커밋·푸시는 사용자가 요청할 때만, main에 직접 (다른 브랜치 생성 금지).
- 밸런스 값 변경은 사람 플레이 기록 후에만. 봇 0/100은 판정 근거로 쓰지 않는다.
- 디버그 코드는 `scripts/debug/`에 두고 export 제외. 참조는 `OS.is_debug_build()` 가드 안의 `load()`만 (AC-43).
- 새 `class_name` 추가 시 `godot --headless --path game --import` 먼저.
- step 1회 = 월드 시간 t 0.5s.
- 캡처 판정(TD): CAP-03은 보충 방식, 코어 무변경, "화면 내 12마리 이상". CAP-06은 프레임 분산, 도달 후 5초 정지 기준.
- 수익화 판정(TD, `_workspace/td_decision/decision3.md`가 최종): 유상 젬 미도입, 광고 2배 각인 제외, P0 빌드 SDK 없음, 소프트런칭은 수동 로그 수집 먼저, UA 31,000달러 불승인, 0단계 지출 0원 클로즈드 테스트 채택, 1단계 2,000달러는 집행 금지, 세이브 포맷 보류.

## Done (모두 미커밋)
- 직전 커밋 `e2b6f17`. 3택·로그·릴리스 가드 F1~F9·캡처 C1/C2/C5 완료.
- C3 CAP-01~06: 실측·프리셋 완료. CAP-03 보충, CAP-05 진화 강제, CAP-06 `advance_chunk` 프레임 분산(400 step/프레임), CAP-02 오버레이(`scripts/debug/hazard_overlay.gd`) 부착.
- 결정 1~3차 실행: AC 문구 2건 반영(`_workspace/impl_spec/p3_bm_ops/user-acquisition-marketer.md`, `_workspace`는 git 제외), `battle.gd` killer_kind 호출부 2곳, `game/.gitignore` 비밀 파일 패턴 4종.
- 헤드리스 60 tests, 2282 checks, 실패 0. AC-43 가드 grep 확인.
- 봇 100판: 클리어 0/100, 밸런스 보류.

## Next
1. 렌더·기기 확인(사람이 에디터/기기에서): 위험 바닥 오버레이, "준비 중" 표시, F6 PNG 저장, UA-4 PNG 2회 바이트 비교, CAP-06 프레임 시간(400 step 적정성). 헤드리스로는 불가.
2. CAP-06 "도달 후 5초"의 시간 상한은 1번 실측 후 확정(§5.3 AC 2, 131행).
3. 알려진 위험: 도달 중 3택이 열리면 자동 pick(0)으로 offer 버튼이 잠깐 눌릴 수 있다. 미처리.
4. P3 C5 파일명 전체 형식(날짜·res·seed·t·git) 미구현 (`capture_rig.gd`의 `snap()`).
5. 디버그 패널에서 `debug_set_weapon`, `debug_give_passive` 호출 연결.
6. 사람 플레이 기록 수집(사람 행위). 이후 밸런스 판정(AC-20, 23, 25). 기록 수집 직후 2-3b 소프트런칭 수집 분석(live-ops-analyst, bm-expert).
7. 2-4 UA 1단계 재판정 조건: 0단계 통과, 밸런스 판정 완료, 2-3b 수집 경로 가동, AC-43 릴리스 export 검사 통과.
8. 스토어 제출 전 과제: `com.example` 패키지명, `use_gradle_build=false`(AAB 불가), Android 서명 설정. 제출 전 TD 확정.
9. Android SDK·익스포트 템플릿 설치: 사용자가 직접 설치하고 라이선스에 동의. 이후 릴리스 export 검사(AC-43).
10. P5: `docs/specs/` 통합.

## Key files
- `game/scripts/debug/capture_presets.gd`: CAP-01~06 데이터, `advance_chunk`, `advance`, 보충·진화 강제.
- `game/scripts/debug/hazard_overlay.gd`: CAP-02 강조 오버레이, 순수 함수 `hazard_rects`.
- `game/scripts/game/main.gd`: 프리셋 시작, 청크 루프, 오버레이 부착, 가드.
- `game/scripts/core/battle.gd`: 코어 전투와 디버그 API(무변경 원칙), killer_kind 호출부.
- `game/tests/unit/test_capture_presets.gd`, `test_hazard_overlay.gd`: 신규 테스트.
- `game/tools/cap_reach.gd`: 도달 시점 실측 도구(미커밋).
- `game/export_presets.cfg`, `game/.gitignore`: export 제외 설정, 비밀 파일 패턴.
- `_workspace/td_decision/decision3.md`: 최종 결정. 앞 단계는 decision.md, decision2.md.
- `_workspace/impl_spec/p3_bm_ops/user-acquisition-marketer.md` §5: CAP 스펙과 AC.
- `_workspace/impl_spec/p3_bm_ops/_summary.md`: 로그·BM 정본.

## Open questions (사용자 확인이 남는 것만)
- 커밋 여부(CLAUDE.md상 요청 시에만).
- 실제 광고비 결제: 재판정 통과 후에도 결제 직전 사용자 확인 1회.
- 키스토어 등 비밀 값 생성·취급(CLAUDE.md상 사용자 승인).
- (사람 행위, 블로커) 사람 플레이 기록을 누가 언제 줄지.
- (외부 확인) 2-3b SDK 도입 시 Data Safety·ATT·동의 고지·_LICENSES.md, 부활 닫기 지연의 스토어·광고망 정책.
