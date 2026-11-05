# core - UI 연결 기준 (ui-implementer 인수용)

`scripts/core/` 는 Node·물리 엔진 없는 RefCounted 코어다. UI 는 `Battle` 의 시그널과 공개 필드만 읽고, 게임 규칙은 코어에 넣는다.
`scripts/game/main.gd` 는 최소 구동기 + 텍스트 UI 이며 교체 대상이다(Battle 구동, 터치 입력, 3택/결과/노드 구매 버튼).

## 구동 방법

```gdscript
var battle := Battle.new(Balance.load_default(), seed, &"sword", RunState.meta, RunState.is_early_run(), ChunkDb.load_all())
# 고정 델타로 호출(권장 1/60). _process 에서 누적기로 돌린다.
battle.step(1.0 / 60.0)
```

- 일시정지: 메뉴가 열려 있으면 step 을 호출하지 않는다. 3택 대기(`awaiting_pick`) 중에는 step 이 아무것도 하지 않는다.
- 배속(디버그): 같은 프레임에 step 을 여러 번 호출한다. `Engine.time_scale` 은 쓰지 않는다.
- 감속: 손을 떼면(`set_input(false, ...)`) 월드가 0.5배가 된다. `battle.slow_on`, `battle.clock.world_scale` 로 표시한다.

## 입력 API

| 호출 | 설명 |
|---|---|
| `set_input(active: bool, offset: Vector2)` | 상대 드래그. offset = 현재 터치 위치 - 터치 시작 위치(논리 px, 216x384 좌표). 터치 뗌 = `set_input(false, Vector2.ZERO)` |
| `pick(index: int) -> bool` | 3택 카드 선택(0~2) |
| `reroll() -> bool` | 무료 리롤. 남은 횟수가 0 이면 false |
| `god_mode: bool` | 디버그 무적 |

터치 입력은 반드시 논리 좌표(`InputEventScreenTouch.position`, canvas_items 스트레치 적용 후)를 넘긴다. 물리 px 를 넘기지 않는다(AC-03).

## 시그널 (Battle)

| 시그널 | 인자 | 용도 |
|---|---|---|
| `offer_ready` | `cards: Array[Dictionary], rerolls_left: int, source: StringName` | 3택 표시. source = `&"levelup"` / `&"plaza"`. 리롤해도 같은 시그널이 다시 온다 |
| `banner` | `key: String` | 구역 자막(`ui.zone.a` / `ui.zone.plaza` / `ui.zone.boss`). 1.5s, y=96 띠(ux §2.3) |
| `hint` | `key: String` | 온보딩 힌트 키(`hint.slow`, `hint.cover`, `hint.hazard`, `hint.exit`, `hint.pillar`). 문구는 storyteller 테이블로 매핑 |
| `player_hurt` | `amount: float, cause: StringName` | cause = `contact` / `projectile` / `hazard` / `crush`. 사망 아이콘 3종 매핑 |
| `evolved` | `weapon_id, result_id` | 진화 연출 |
| `run_ended` | `result: Dictionary` | 판 종료(클리어/쓰러짐) |
| `log_event` | `name: String, data: Dictionary` | 로그 이벤트. `Log.event()` 로 전달 |

카드 Dictionary: `{kind: &"weapon"/&"passive"/&"fallback", id: StringName, is_new: bool, level: int, key: String}`.
`key` 는 storyteller 문자열 키(`w.w01`, `p.p01`, `ui.fallback.heal` 등). 입력 잠금 0.5s 는 UI 가 처리한다(코어는 즉시 받는다).

`result` 키: `cleared, boss_reached, duration, world_time, death_cause, death_zone(&"A"/&"plaza"/&"boss"), level, levelups, kills, seed, class, pick_log, top_items([{key, value}] 상위 3)`.
각인 계산은 `RunState.meta.settle(result, bal)` 가 지급량을 돌려준다(저장은 `RunState.save_meta()`).

## HUD 가 읽는 필드 (Battle)

`hp, max_hp, level, xp, xp_need, kills, run_time(실시간 초), t(월드 시간), phase(Battle.Phase), awaiting_pick, boss_gauge(0~3), enemies(EnemyPool), invuln_left, plaza_exit_ready`
보스 HP: `enemies.index_of_uid(boss_uid)` 로 인덱스를 찾아 `enemies.hp[i] / enemies.maxhp[i]`. 보스 예고: `boss_tele_kind(0/1/2)`, `boss_tele_x`, `boss_tele_t`.

## 렌더

`scripts/game/battle_view.gd` 가 배열을 직접 `_draw` 한다. 탄·적·보석은 노드가 없다. 팔레트는 `Palette` 오토로드.
화면 흔들림은 `battle.shake_left > 0` 일 때 `battle.shake_amp` 크기로 뷰 오프셋을 흔든다(`bal.shake_enabled` 가 false 면 코어가 요청 자체를 만들지 않는다).

## 오토로드

`GameClock`(코어 래퍼, 현재 미사용), `RunState`(메타 저장: `meta: MetaState`), `Palette`, `Log`(JSONL). 테스트(`--script`) 에서는 오토로드 이름이 안 보이므로 코어는 오토로드를 참조하지 않는다.

## 테스트

`godot --headless --path game --script res://tests/run_tests.gd [-- --suite=<파일명 일부>]` 종료 코드 0/1/2.
`godot --headless --path game --script res://tools/run_chunk_lint.gd` 청크 린터.
`godot --headless --path game res://tools/ui_smoke.tscn` 씬 UI 스모크(오토로드 필요하므로 --script 아님).
새 `class_name` 을 추가한 직후에는 `godot --headless --path game --import` 로 클래스 캐시를 갱신해야 `--script` 실행이 타입을 찾는다.
