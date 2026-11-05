class_name TestCase extends RefCounted
## 테스트 베이스. test_ 로 시작하는 메서드를 러너가 호출한다. check() 실패는 모아서 보고한다.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []

func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)

func check_eq(actual: Variant, expected: Variant, msg: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s (기대 %s, 실제 %s)" % [msg, str(expected), str(actual)])

func check_near(actual: float, expected: float, tol: float, msg: String) -> void:
	checks += 1
	if absf(actual - expected) > tol:
		failures.append("%s (기대 %s ±%s, 실제 %s)" % [msg, str(expected), str(tol), str(actual)])

func note(s: String) -> void:
	notes.append(s)

## 고정 델타 시뮬 보조: seconds 만큼 1/60 로 step
func run_for(b: Battle, seconds: float, dt: float = 1.0 / 60.0) -> void:
	var n: int = int(round(seconds / dt))
	for i in n:
		b.step(dt)
