class_name MetaState extends RefCounted
## 환생 메타 상태(각인 포인트, 노드, 판 수). 세이브 직렬화 가능한 순수 데이터.
## P0 디버그 노드 4개(p4 결정 8). 비용: 앞 3개는 4/5/5, 4번째는 16(economy 5판 표, p4 결정 6).

const NODES := [
	{"id": &"n1", "name": "전생 기억 1: 최대 체력 +10%", "cost": 4, "stat": &"max_hp_mult", "value": 0.10},
	{"id": &"n2", "name": "전생 기억 2: 자석 +16", "cost": 5, "stat": &"magnet", "value": 16.0},
	{"id": &"n3", "name": "전생 기억 3: 3택 리롤 +1", "cost": 5, "stat": &"reroll", "value": 1.0},
	{"id": &"n4", "name": "각인: 피해 +5%", "cost": 16, "stat": &"damage_mult", "value": 0.05},
]

var points: int = 0
var owned: Array[StringName] = []
var runs_played: int = 0
var boss_reached_before: bool = false
var best_clear: bool = false

func can_buy(id: StringName) -> bool:
	if owned.has(id):
		return false
	var nd: Dictionary = node_def(id)
	return not nd.is_empty() and points >= int(nd["cost"])

func buy(id: StringName) -> bool:
	if not can_buy(id):
		return false
	points -= int(node_def(id)["cost"])
	owned.append(id)
	return true

static func node_def(id: StringName) -> Dictionary:
	for nd in NODES:
		if nd["id"] == id:
			return nd
	return {}

func stat(stat_name: StringName) -> float:
	var s: float = 0.0
	for id in owned:
		var nd: Dictionary = node_def(id)
		if nd["stat"] == stat_name:
			s += float(nd["value"])
	return s

## 판 결과를 정산해 points 에 더하고 지급량을 돌려준다.
func settle(result: Dictionary, bal: Balance) -> int:
	var reached: bool = bool(result.get("boss_reached", false))
	var first: bool = reached and not boss_reached_before
	var cleared: bool = bool(result.get("cleared", false))
	var p: int = Imprint.points(bal.floor_index, cleared, first, bal.imprint_participation,
			bal.imprint_floor_coef, bal.imprint_boss_bonus, bal.imprint_first_reach, bal.imprint_fail_ratio)
	points += p
	runs_played += 1
	if reached:
		boss_reached_before = true
	if cleared:
		best_clear = true
	return p

func to_dict() -> Dictionary:
	var o: Array = []
	for id in owned:
		o.append(String(id))
	return {"points": points, "owned": o, "runs": runs_played, "boss_reached": boss_reached_before, "clear": best_clear}

static func from_dict(d: Dictionary) -> MetaState:
	var m := MetaState.new()
	m.points = int(d.get("points", 0))
	m.runs_played = int(d.get("runs", 0))
	m.boss_reached_before = bool(d.get("boss_reached", false))
	m.best_clear = bool(d.get("clear", false))
	for s in d.get("owned", []):
		m.owned.append(StringName(s))
	return m
