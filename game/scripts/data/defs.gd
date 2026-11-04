class_name Defs extends RefCounted
## 상수 테이블: 무기(W01~W04 Lv1~5 + 진화), 패시브(P01~P04), 적, 직업. 출처: mechanics §4~§5, §8, economy §2.1.
## 알파에서 Resource(.tres)로 옮길 후보. 키 문자열은 storyteller 키(w.w01, p.p01, e.w01).

const K_SWARM := 0
const K_EXPLODER := 1
const K_SHOOTER := 2
const K_HEAVY := 3
const K_BOSS := 4

const MAX_LEVEL := 5

const WEAPONS := {
	&"W01": {
		"key": "w.w01", "kind": &"arc", "tags": [&"area"],
		"levels": [
			{"dmg": 8.0, "cd": 1.20, "arc": 120.0, "range": 40.0, "swings": 1, "kb": 20.0},
			{"dmg": 10.0, "cd": 1.15, "arc": 120.0, "range": 44.0, "swings": 1, "kb": 20.0},
			{"dmg": 12.0, "cd": 1.00, "arc": 180.0, "range": 48.0, "swings": 2, "kb": 20.0},
			{"dmg": 15.0, "cd": 1.00, "arc": 180.0, "range": 52.0, "swings": 2, "kb": 20.0},
			{"dmg": 18.0, "cd": 0.85, "arc": 180.0, "range": 60.0, "swings": 2, "kb": 30.0},
		],
	},
	&"W02": {
		"key": "w.w02", "kind": &"bolt", "tags": [&"pierce", &"rate"],
		"levels": [
			{"dmg": 6.0, "cd": 0.90, "count": 1, "pierce": 0, "fan": 0.0, "speed": 220.0, "range": 160.0},
			{"dmg": 7.0, "cd": 0.85, "count": 1, "pierce": 0, "fan": 0.0, "speed": 220.0, "range": 160.0},
			{"dmg": 8.0, "cd": 0.80, "count": 2, "pierce": 1, "fan": 0.0, "speed": 220.0, "range": 160.0},
			{"dmg": 10.0, "cd": 0.75, "count": 2, "pierce": 1, "fan": 0.0, "speed": 220.0, "range": 160.0},
			{"dmg": 12.0, "cd": 0.70, "count": 3, "pierce": 2, "fan": 8.0, "speed": 220.0, "range": 160.0},
		],
	},
	&"W03": {
		"key": "w.w03", "kind": &"orbit", "tags": [&"orbit", &"area"],
		"levels": [
			{"dmg": 4.0, "count": 1, "radius": 36.0, "period": 2.4, "rehit": 0.4, "block": false},
			{"dmg": 5.0, "count": 1, "radius": 38.0, "period": 2.4, "rehit": 0.4, "block": false},
			{"dmg": 6.0, "count": 2, "radius": 40.0, "period": 2.4, "rehit": 0.4, "block": false},
			{"dmg": 7.0, "count": 2, "radius": 44.0, "period": 2.4, "rehit": 0.4, "block": false},
			{"dmg": 8.0, "count": 3, "radius": 48.0, "period": 2.4, "rehit": 0.4, "block": true},
		],
	},
	&"W04": {
		"key": "w.w04", "kind": &"mine", "tags": [&"area"],
		"levels": [
			{"dmg": 14.0, "cd": 3.0, "blast": 28.0, "trigger": 14.0, "max": 3, "residual": false, "double": false},
			{"dmg": 17.0, "cd": 2.8, "blast": 30.0, "trigger": 14.0, "max": 3, "residual": false, "double": false},
			{"dmg": 20.0, "cd": 2.6, "blast": 36.0, "trigger": 14.0, "max": 3, "residual": true, "double": false},
			{"dmg": 24.0, "cd": 2.4, "blast": 38.0, "trigger": 14.0, "max": 3, "residual": true, "double": false},
			{"dmg": 28.0, "cd": 2.0, "blast": 44.0, "trigger": 14.0, "max": 3, "residual": true, "double": true},
		],
	},
	# 진화형 [가정: 피해/쿨은 문서에 없는 값]
	&"E01": {
		"key": "e.w01", "kind": &"arc", "tags": [&"area"], "evolved": true,
		"levels": [{"dmg": 22.0, "cd": 0.85, "arc": 360.0, "range": 70.0, "swings": 1, "kb": 30.0}],
	},
	&"E02": {
		"key": "e.w02", "kind": &"bolt", "tags": [&"pierce", &"rate"], "evolved": true,
		"levels": [{"dmg": 8.0, "cd": 0.35, "count": 5, "pierce": 2, "fan": 12.0, "speed": 240.0, "range": 170.0, "ignore_walls": true}],
	},
}

const BASE_WEAPONS: Array[StringName] = [&"W01", &"W02", &"W03", &"W04"]
const BASE_PASSIVES: Array[StringName] = [&"P01", &"P02", &"P03", &"P04"]

## 무기 id -> {passive, result}
const EVOLUTIONS := {
	&"W01": {"passive": &"P01", "result": &"E01"},
	&"W02": {"passive": &"P02", "result": &"E02"},
}

const PASSIVES := {
	&"P01": {"key": "p.p01", "tags": [&"defense"], "stat": &"dmg_reduce", "levels": [0.08, 0.14, 0.20, 0.25, 0.30]},
	&"P02": {"key": "p.p02", "tags": [&"rate"], "stat": &"haste", "levels": [0.08, 0.16, 0.24, 0.32, 0.40]},
	&"P03": {"key": "p.p03", "tags": [&"utility"], "stat": &"magnet", "levels": [16.0, 32.0, 48.0, 64.0, 96.0]},
	&"P04": {"key": "p.p04", "tags": [&"defense"], "stat": &"max_hp", "levels": [0.10, 0.20, 0.30, 0.40, 0.50]},
}

const FALLBACKS: Array[StringName] = [&"heal", &"coin", &"xp"]

const CLASSES := {
	&"sword": {"start": &"W01", "invuln_bonus": 0.2, "cover_haste": 1.0, "bias": {&"area": 1.5, &"defense": 1.5}},
	&"archer": {"start": &"W02", "invuln_bonus": 0.0, "cover_haste": 1.15, "bias": {&"pierce": 1.5, &"rate": 1.5}},
}

## 적 정의. hp/contact/speed/xp 는 economy §2.1(자폭형 속도는 mechanics 70), r 은 art §A.3 캔버스의 절반.
const ENEMIES := {
	&"A1": {"kind": K_SWARM, "family": 0, "hp": 12.0, "atk": 8.0, "speed": 28.0, "xp": 1, "r": 6.0, "death": "death.a1"},
	&"A2": {"kind": K_EXPLODER, "family": 0, "hp": 10.0, "atk": 12.0, "speed": 70.0, "xp": 2, "r": 6.0, "death": "death.a2",
		"blast_radius": 36.0, "telegraph": 0.6, "trigger": 48.0},
	&"B1": {"kind": K_SHOOTER, "family": 1, "hp": 18.0, "atk": 6.0, "speed": 22.0, "xp": 2, "r": 6.0, "death": "death.b1",
		"bullet_speed": 80.0, "hold_dist": 140.0, "aim": 0.4, "cooldown": 1.6},
	&"B2": {"kind": K_SWARM, "family": 1, "hp": 30.0, "atk": 8.0, "speed": 20.0, "xp": 3, "r": 7.0, "death": "death.b2"},
	&"EL": {"kind": K_HEAVY, "family": 2, "hp": 350.0, "atk": 6.0, "speed": 18.0, "xp": 25, "r": 12.0, "death": "death.elite",
		"slam_dmg": 15.0, "slam_radius": 48.0, "slam_trigger": 56.0, "telegraph": 0.8, "recover": 1.0, "kb_resist": 0.75},
	&"BOSS": {"kind": K_BOSS, "family": 2, "hp": 2000.0, "atk": 20.0, "speed": 14.0, "xp": 0, "r": 22.0, "death": "death.boss_b1"},
}

static func item_tags(id: StringName) -> Array:
	if WEAPONS.has(id):
		return WEAPONS[id]["tags"]
	if PASSIVES.has(id):
		return PASSIVES[id]["tags"]
	return []

static func item_key(id: StringName) -> String:
	if WEAPONS.has(id):
		return WEAPONS[id]["key"]
	if PASSIVES.has(id):
		return PASSIVES[id]["key"]
	return "ui.fallback.%s" % String(id)

static func is_weapon(id: StringName) -> bool:
	return WEAPONS.has(id)

static func is_passive(id: StringName) -> bool:
	return PASSIVES.has(id)

static func weapon_level_def(id: StringName, level: int) -> Dictionary:
	var lv: Array = WEAPONS[id]["levels"]
	return lv[clampi(level - 1, 0, lv.size() - 1)]

static func passive_value(id: StringName, level: int) -> float:
	if level <= 0:
		return 0.0
	var lv: Array = PASSIVES[id]["levels"]
	return float(lv[clampi(level - 1, 0, lv.size() - 1)])
