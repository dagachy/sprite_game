class_name CutPlayer extends RefCounted
## 컷 재생 로직(UI 없음). 각 컷은 MIN_SECONDS 이상 표시, 1탭 넘김, 스킵.
## UI 계약: 매 프레임 update(delta), 화면 탭 -> tap(), 스킵 버튼 -> skip().
## 시그널: cut_shown(key, text, index, total), finished(skipped)

signal cut_shown(key: StringName, text: String, index: int, total: int)
signal finished(skipped: bool)

const MIN_SECONDS: float = 1.2

var keys: Array[StringName] = []
var index: int = -1
var elapsed: float = 0.0
var playing: bool = false

func start(cut_keys: Array[StringName]) -> void:
	keys = cut_keys.duplicate()
	if keys.is_empty():
		finished.emit(false)
		return
	playing = true
	index = -1
	_show_next()

func update(delta: float) -> void:
	if playing:
		elapsed += delta

## 최소 표시 시간이 지났을 때만 넘긴다. 반환: 입력이 받아들여졌는지
func tap() -> bool:
	if not playing or elapsed < MIN_SECONDS:
		return false
	_show_next()
	return true

func skip() -> void:
	if not playing:
		return
	playing = false
	finished.emit(true)

func can_advance() -> bool:
	return playing and elapsed >= MIN_SECONDS

func current_text() -> String:
	return GameStrings.get_text(keys[index]) if playing and index >= 0 else ""

func _show_next() -> void:
	index += 1
	elapsed = 0.0
	if index >= keys.size():
		playing = false
		finished.emit(false)
		return
	cut_shown.emit(keys[index], GameStrings.get_text(keys[index]), index, keys.size())
