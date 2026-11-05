class_name Bot extends RefCounted
## 테스트용 단순 봇. skill: 0~1, 낮을수록 회피가 서툴다(반응 거리가 짧아짐).

var rng := RandomNumberGenerator.new()
var skill: float = 0.85

func _init(seed_v: int = 1, skill_v: float = 0.85) -> void:
	rng.seed = seed_v
	skill = skill_v

func drive(b: Battle) -> void:
	if b.awaiting_pick:
		b.pick(rng.randi_range(0, b.current_offer.size() - 1))
		return
	var e: EnemyPool = b.enemies
	var flee := Vector2.ZERO
	var react: float = 16.0 + 14.0 * skill
	var near_d: float = 1e9
	var near := Vector2.ZERO
	for i in e.n:
		if e.hp[i] <= 0.0:
			continue
		var d := Vector2(b.px - e.x[i], b.py - e.y[i])
		var l: float = d.length()
		if l < near_d and e.y[i] > 0.0:
			near_d = l
			near = -d
		if l < react and l > 0.1:
			flee += d / l * (react - l) / react
	for k in b.ebul.n:
		var d2 := Vector2(b.px - b.ebul.x[k], b.py - b.ebul.y[k])
		var l2: float = d2.length()
		if l2 < 40.0 and l2 > 0.1:
			var perp := Vector2(-d2.y, d2.x) / l2
			flee += perp * 1.5
	if near_d > 28.0 and near_d < 200.0 and b.phase != Battle.Phase.PLAZA:
		flee += near / near_d * 0.5
	var home := Vector2(108.0, 300.0)
	if b.phase == Battle.Phase.PLAZA:
		home = Vector2(108.0, 200.0)
		if b.plaza_exit_ready:
			home = Vector2(108.0, 130.0)
	var pull: Vector2 = (home - Vector2(b.px, b.py))
	var dir: Vector2 = flee * 3.0 + pull.limit_length(40.0) / 40.0 * 0.6
	var off: Vector2 = dir.limit_length(1.0) * 40.0
	b.set_input(true, off)
