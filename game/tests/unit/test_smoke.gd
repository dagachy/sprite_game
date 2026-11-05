extends TestCase

func test_battle_runs_10s() -> void:
	var b := Battle.new(Balance.new(), 1)
	b.set_input(true, Vector2.ZERO)
	run_for(b, 10.0)
	check(b.t > 9.9, "world time advanced %s" % b.t)
	check(not b.ended, "not ended")
	check(b.enemies.n > 0, "enemies spawned: %d" % b.enemies.n)
