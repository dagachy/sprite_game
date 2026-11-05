class_name HazardOverlay extends Node2D
## 디버그 전용 BIT_HAZARD 셀 강조 오버레이 (CAP-02 hazard_highlight). 디버그 빌드에서만 main.gd 가 load() 로 붙인다.
## battle_view 와 같은 좌표계(view 의 자식, 화면 좌표)에 그린다. 게임 로직·battle_view 는 건드리지 않는다.
## 색: DANGER(FF2D55) 채움 alpha 0.35 + 테두리 alpha 0.9. 보라 HAZ 지형(HAZ_D/HAZ_B) 위에서 보색에 가까워 구분되고,
## 채움을 옅게 해 아래 지형 줄무늬가 비친다. 신호색이라 지형 팔레트와 겹치지 않는다.

const FILL_ALPHA := 0.35
const LINE_ALPHA := 0.9
const COLS := 12            # (WIDTH_PX - 2*BORDER) / TILE
const Y_MIN := -16.0
const Y_MAX := 400.0

var battle: Battle
var enabled: bool = true

## 강조할 셀의 화면 Rect2 목록. bits_at(x, screen_y) -> int 로 셀 중심을 조회한다(WorldStrip.bits_screen 과 같은 시그니처).
## scroll 은 WorldStrip.scroll. 행은 월드 기준 16px 정렬이라 화면 y = row*16 + scroll.
static func hazard_rects(bits_at: Callable, scroll: float, y_min: float = Y_MIN, y_max: float = Y_MAX) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var t: float = WorldStrip.TILE
	var r0: int = floori((y_min - scroll) / t)
	var r1: int = floori((y_max - scroll) / t)
	for r in range(r0, r1 + 1):
		var y: float = r * t + scroll
		for c in COLS:
			var x: float = WorldStrip.BORDER + c * t
			if int(bits_at.call(x + t * 0.5, y + t * 0.5)) & ChunkDef.BIT_HAZARD:
				out.append(Rect2(x, y, t, t))
	return out

func _process(_dt: float) -> void:
	if enabled:
		queue_redraw()

func _draw() -> void:
	if not enabled or battle == null:
		return
	var fill: Color = Palette.DANGER
	fill.a = FILL_ALPHA
	var line: Color = Palette.DANGER
	line.a = LINE_ALPHA
	var s: WorldStrip = battle.strip
	for rc in hazard_rects(s.bits_screen, s.scroll):
		draw_rect(rc, fill)
		draw_rect(rc.grow(-0.5), line, false, 1.0)
