class_name OfferLock extends RefCounted
## 3택 입력 잠금 타이머 (ux §2.2, AC-35). 3택이 표시되면 arm() 으로 0.5s 를 건다.
## tick() 은 실시간(게임 시간 배속과 무관) 델타로 줄인다. 잠금 중 카드 탭·리롤은 무시한다.

const LOCK_S: float = 0.5

var left: float = 0.0

## 카드·리롤 입력 허용 여부. 잠금 중이거나 박스가 숨겨진 상태(hide_offer 프리셋)면 무시한다.
static func accepts(locked: bool, hidden: bool) -> bool:
	return not locked and not hidden

func arm() -> void:
	left = LOCK_S

func tick(delta: float) -> void:
	if left > 0.0:
		left = maxf(0.0, left - delta)

func is_locked() -> bool:
	return left > 0.0
