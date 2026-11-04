class_name XpCurve extends RefCounted
## xp_need(n) = round(8 + 5n + 0.4n^2). n = 현재 레벨 (economy §1.2).

static func need(n: int, a: float = 8.0, b: float = 5.0, c: float = 0.4, first_mult: float = 1.0) -> int:
	var v := roundi(a + b * n + c * n * n)
	if n == 1 and first_mult != 1.0:
		v = roundi(v * first_mult)
	return v

## 누적 XP total 로 도달하는 레벨업 횟수
static func levelups_for(total_xp: float, a: float = 8.0, b: float = 5.0, c: float = 0.4) -> int:
	var acc := 0.0
	var n := 1
	while true:
		acc += need(n, a, b, c)
		if total_xp < acc:
			return n - 1
		n += 1
	return 0
