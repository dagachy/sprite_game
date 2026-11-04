class_name Imprint extends RefCounted
## 각인 지급식 (economy §4.1): P = 3 + (4+F) + 10*보스 + (첫 도달 15). 실패(보스 미격파)는 floor(P*0.6).

## floor_idx: F, boss_cleared: 보스 격파, first_reach: 이번 판이 보스 첫 도달이며 지금까지 도달 기록 없음
static func points(floor_idx: int, boss_cleared: bool, first_reach: bool,
		participation: int = 3, floor_coef: int = 4, boss_bonus: int = 10,
		first_bonus: int = 15, fail_ratio: float = 0.6) -> int:
	var p := participation + (floor_coef + floor_idx)
	if boss_cleared:
		p += boss_bonus
	if first_reach:
		p += first_bonus
	if not boss_cleared:
		return int(floorf(p * fail_ratio))
	return p

## 노드 비용. 앞 3개는 5, 이후 k번째(1부터)는 10+6k.
static func node_cost_k(k: int, base: int = 10, step: int = 6) -> int:
	return base + step * k

static func node_cost_total(count: int) -> int:
	var s := 0
	for k in range(1, count + 1):
		s += node_cost_k(k)
	return s

## 일일 판 수 구간별 비율 [[5,1.0],[15,0.5],[INF,0.2]] (n 은 오늘 N번째 판, 1부터)
static func daily_ratio(n: int) -> float:
	if n <= 5:
		return 1.0
	if n <= 15:
		return 0.5
	return 0.2
