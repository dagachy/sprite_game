extends TestCase
## AC-35: 3택 표시 직후 0.5s 동안 카드·리롤 입력을 무시하고, 해제 직후 입력은 처리된다.
## 잠금 타이머는 OfferLock(순수 클래스)로 분리해 검사한다. main.gd 는 이 값으로 탭을 거른다.

func test_offer_lock_window() -> void:
	var lk := OfferLock.new()
	check(not lk.is_locked(), "not locked before any offer")
	lk.arm()
	check_near(lk.left, 0.5, 0.0001, "lock is 0.5s on arm")
	check(lk.is_locked(), "locked right after offer shown")
	lk.tick(0.3)
	check(lk.is_locked(), "still locked at 0.3s")
	lk.tick(0.19)
	check(lk.is_locked(), "still locked at 0.49s")
	lk.tick(0.02)
	check(not lk.is_locked(), "released at 0.51s (tap after release is handled)")
	check_near(lk.left, 0.0, 0.0001, "timer clamps at 0")
	lk.tick(1.0)
	check_near(lk.left, 0.0, 0.0001, "tick after release stays 0")
	note("AC-35: OfferLock 0.5s window")
