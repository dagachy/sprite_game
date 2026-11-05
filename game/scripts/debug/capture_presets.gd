class_name CapturePresets extends RefCounted
## 시드 프리셋 CAP-01~06 (P3 C3, user-acquisition-marketer §5). 디버그 빌드 전용.
## 호출부는 OS.is_debug_build() 가드 안에서 load() 로만 만든다. 이 폴더는 릴리스 export 에서 제외된다(AC-43).
## 결정성: Battle 을 프리셋 시드로 새로 만들고, 시간은 battle.step(STEP) 직접 호출로만 진행한다(D1·D2).
## 주의: forward_steps 와 slots 값은 [추정] 기본값이다. 청크 도달 시점은 실측 전까지 확정하지 않는다.

const STEP: float = 1.0 / 60.0
const MAX_STEPS: int = 600   # 10초 분량 (§5.2 수용 기준 2)
const MATCH_WEAPON := &"W01"
const MATCH_PASSIVE := &"P01"

## 프리셋 데이터. 키는 §5.1 스키마를 따른다.
const PRESETS: Dictionary = {
	&"CAP-01": {"label": "엄폐 방어", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": 0, "god": true, "weapon": {}, "passives": {}, "pause_after": true,
		"note": "cover_01 도달 조건 미구현 [추정]"},
	&"CAP-02": {"label": "지형 3종", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": 0, "god": false, "weapon": {}, "passives": {}, "pause_after": true,
		"overrides": {"hazard_highlight": true},
		"note": "위험 바닥 강조는 렌더 오버라이드 미구현 [추정]"},
	&"CAP-03": {"label": "병목 처치", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": 0, "god": false, "weapon": {}, "passives": {}, "pause_after": true,
		"overrides": {"spawn_count": 12},
		"note": "choke_01 도달·스폰 수 12 미구현 [추정]"},
	&"CAP-04": {"label": "3택 직전", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": MAX_STEPS, "god": false,
		"weapon": {MATCH_WEAPON: 4}, "passives": {MATCH_PASSIVE: 1}, "pause_after": true,
		"stop_on": "offer"},
	&"CAP-05": {"label": "진화", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": 0, "god": false, "weapon": {MATCH_WEAPON: 4}, "passives": {MATCH_PASSIVE: 1},
		"pause_after": true, "overrides": {"force_evolve": true},
		"note": "정예 상자 개방 직후 진화 상태 강제 [추정]"},
	&"CAP-06": {"label": "보스 예고 직전", "seed": 12345, "class_id": &"sword", "early_run": true,
		"forward_steps": 0, "god": true, "weapon": {}, "passives": {}, "pause_after": true,
		"note": "알파 이월 가능. 보스 예고 도달 조건 미구현 [추정]"},
}

## 프리셋 ID 목록(정렬). 메뉴 버튼 순서에 쓴다.
static func ids() -> Array[StringName]:
	var keys: Array[String] = []
	for k in PRESETS.keys():
		keys.append(String(k))
	keys.sort()   # StringName 은 사전순 정렬이 아니므로 String 으로 정렬한다
	var out: Array[StringName] = []
	for k in keys:
		out.append(StringName(k))
	return out

## 프리셋으로 Battle 을 만든다. 무기·패시브 오버라이드를 적용한다(D1·D5).
## meta 는 프리셋 고정 값을 넣는다(D5). 저장 파일을 읽지 않는다.
static func make_battle(id: StringName, bal: Balance, db: Dictionary, meta: MetaState) -> Battle:
	var p: Dictionary = PRESETS[id]
	var b := Battle.new(bal, int(p["seed"]), p["class_id"], meta, bool(p["early_run"]), db)
	b.god_mode = bool(p.get("god", false))
	var weapons: Dictionary = p.get("weapon", {})
	for wid in weapons:
		b.debug_set_weapon(wid, int(weapons[wid]))
	var passives: Dictionary = p.get("passives", {})
	for pid in passives:
		b.debug_give_passive(pid, int(passives[pid]))
	return b

## 프리셋의 정지 조건까지 시간을 진행한다. 실제로 진행한 STEP 수를 돌려준다(D2).
## stop_on == "offer" 면 3택이 열리는 순간에 멈춘다. 그 밖에는 forward_steps 만큼 진행한다.
static func advance(b: Battle, id: StringName) -> int:
	var p: Dictionary = PRESETS[id]
	var limit: int = mini(int(p.get("forward_steps", 0)), MAX_STEPS)
	var stop_offer: bool = p.get("stop_on", "") == "offer"
	var n: int = 0
	while n < limit:
		if stop_offer and b.awaiting_pick:
			break
		if b.ended:
			break
		b.step(STEP)
		n += 1
	# [추정] 상한까지 3택이 자연히 열리지 않으면 레벨업 3택을 강제로 연다.
	# 무기 Lv4 를 시드 전투로 만들려면 XP 가 필요해 10초 안에 열리지 않는다.
	if stop_offer and not b.awaiting_pick and not b.ended:
		b.debug_force_offer()
	return n

## 결정성 확인용 요약. 같은 프리셋이면 같은 값이어야 한다(수용 기준 1, 로그 대체).
static func state_digest(b: Battle) -> Dictionary:
	return {
		"t": snappedf(b.t, 0.0001),
		"enemies": b.enemies.n,
		"px": snappedf(b.px, 0.0001),
		"py": snappedf(b.py, 0.0001),
		"level": b.level,
		"awaiting_pick": b.awaiting_pick,
	}
