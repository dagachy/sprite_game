class_name OfferState extends RefCounted
## 3택 생성에 필요한 보유 상태(노드 비의존).

var weapons: Dictionary = {}    # id(StringName) -> level
var passives: Dictionary = {}
var evolved: Dictionary = {}    # 기본 무기 id -> true
var weapon_slots: int = 4
var passive_slots: int = 4
var since_material: int = 0     # 재료 패시브가 안 나온 연속 3택 수
var tag_bias: Dictionary = {}   # 판 시작 태그 가중
var material_boost: float = 3.0
var material_pity: int = 3
var base_weight: float = 100.0
var last_fallback: StringName = &""
var evolve_min_level: int = 4   # 진화 재료 판정 무기 레벨(p4 결정 3. AC-05 원안은 5)

func weapon_count() -> int:
	return weapons.size()

func passive_count() -> int:
	return passives.size()

func level_of(id: StringName) -> int:
	if weapons.has(id):
		return int(weapons[id])
	return int(passives.get(id, 0))

func owns(id: StringName) -> bool:
	return weapons.has(id) or passives.has(id)

func duplicate_state() -> OfferState:
	var s := OfferState.new()
	s.weapons = weapons.duplicate()
	s.passives = passives.duplicate()
	s.evolved = evolved.duplicate()
	s.weapon_slots = weapon_slots
	s.passive_slots = passive_slots
	s.since_material = since_material
	s.tag_bias = tag_bias.duplicate()
	s.material_boost = material_boost
	s.material_pity = material_pity
	s.base_weight = base_weight
	s.last_fallback = last_fallback
	s.evolve_min_level = evolve_min_level
	return s
