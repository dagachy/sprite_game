class_name TH extends RefCounted
## 테스트 보조: 고정 월드 구성, 셀 찾기.

## 스폰·스크롤을 멈춘 전투(지형/무기 단위 테스트용). 입력은 활성(감속 없음).
static func frozen_battle(seed_v: int = 1, cls: StringName = &"sword", early: bool = true) -> Battle:
	var b := Battle.new(Balance.new(), seed_v, cls, null, early)
	b.spawner.grace_until = 1e9
	b.scroll_model.state = ScrollModel.S.ARENA
	b.set_input(true, Vector2.ZERO)
	return b

## 비트가 bit 인 셀들의 (청크, 행, 열) 목록
static func cells_with(b: Battle, bit: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for pi in b.strip.placed.size():
		var p: WorldStrip.Placed = b.strip.placed[pi]
		for r in p.def.height:
			for c in p.def.width:
				if p.bits[r * p.def.width + c] & bit:
					out.append(Vector3i(pi, r, c))
	return out

## 해당 셀이 화면 y=target_sy 에 오도록 scroll 을 맞추고 셀 중심(화면 좌표)을 돌려준다.
static func focus(b: Battle, cell: Vector3i, target_sy: float = 200.0) -> Vector2:
	var p: WorldStrip.Placed = b.strip.placed[cell.x]
	var wy: float = p.origin_y + cell.y * 16.0 + 8.0
	b.strip.scroll = target_sy - wy
	return Vector2(12.0 + cell.z * 16.0 + 8.0, target_sy)

static func bits_at(b: Battle, x: float, y: float) -> int:
	return b.strip.bits_screen(x, y)
