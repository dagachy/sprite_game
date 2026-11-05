extends Node
## 헤드리스 UI 스모크: godot --headless --path game res://tools/ui_smoke.tscn (user://meta.json 을 건드리므로 실행 후 삭제됨)
func _ready() -> void:
	var m: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	await get_tree().process_frame
	await get_tree().process_frame
	m.battle.xp = 50
	for i in 10: await get_tree().process_frame
	print("offer visible ", m.offer_box.visible, " awaiting ", m.battle.awaiting_pick, " btn0 ", m.offer_buttons[0].text)
	m._on_reroll()
	m._on_pick(0)
	for i in 5: await get_tree().process_frame
	m.battle.hp = 1.0
	m.battle.god_mode = false
	m.battle.hurt(50.0, &"contact")
	for i in 3: await get_tree().process_frame
	print("result visible ", m.result_box.visible, " :: ", m.result_label.text.replace("\n", " | "))
	m._on_buy(&"n1")
	print("shop0 ", m.shop_buttons[0].text, " points ", RunState.meta.points)
	m.start_run()
	# 터치 합성
	var t := InputEventScreenTouch.new(); t.index = 0; t.pressed = true; t.position = Vector2(100, 300)
	m._unhandled_input(t)
	var d := InputEventScreenDrag.new(); d.index = 0; d.position = Vector2(130, 300)
	m._unhandled_input(d)
	for i in 30: await get_tree().process_frame
	print("player x ", m.battle.px, " touch ", m.touch_idx)
	get_tree().quit()
