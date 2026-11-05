class_name AutoAim extends RefCounted
## 자동 조준(mechanics §3): 최근접 적. 현재 타깃보다 새 후보가 margin(16px) 넘게 가깝지 않으면 hold(0.5s) 동안 유지.

var target_uid: int = -1
var hold_left: float = 0.0
var margin: float = 16.0
var hold_time: float = 0.5

## 타깃 인덱스(없으면 -1). uids/xs/ys/hp 는 적 배열, n 은 개수.
func update(dt: float, px: float, py: float, xs: PackedFloat32Array, ys: PackedFloat32Array,
		hp: PackedFloat32Array, uids: PackedInt32Array, n: int, max_range: float, min_y: float) -> int:
	hold_left = maxf(hold_left - dt, 0.0)
	var best: int = -1
	var best_d: float = max_range * max_range
	var cur: int = -1
	var cur_d: float = 0.0
	for i in n:
		if hp[i] <= 0.0 or ys[i] < min_y:
			continue
		var dx: float = xs[i] - px
		var dy: float = ys[i] - py
		var d: float = dx * dx + dy * dy
		if uids[i] == target_uid:
			cur = i
			cur_d = d
		if d < best_d:
			best_d = d
			best = i
	if cur >= 0 and cur_d <= max_range * max_range:
		if best == cur or hold_left > 0.0:
			return cur
		var dc: float = sqrt(cur_d)
		var db: float = sqrt(best_d)
		if dc - db <= margin:
			return cur
	if best >= 0:
		if uids[best] != target_uid:
			target_uid = uids[best]
			hold_left = hold_time
		return best
	target_uid = -1
	return -1
