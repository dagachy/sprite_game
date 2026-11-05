class_name Balance extends Resource
## 밸런스 스칼라 값 묶음. data/balance.tres 로 저장해 인스펙터에서 조정한다. 근거는 각 그룹 주석.
## 표 형태 데이터(무기/패시브/적)는 defs.gd 상수 테이블.

@export_group("Player (economy §1.1)")
@export var max_hp: float = 100.0
@export var hit_invuln: float = 0.8
@export var sword_invuln_bonus: float = 0.2
@export var plaza_heal_ratio: float = 0.40
@export var elite_heal_drop: float = 0.08
@export var base_magnet: float = 24.0
@export var player_radius: float = 5.0
@export var player_start: Vector2 = Vector2(108, 296)
@export var bottom_damage: float = 5.0
@export var bottom_invuln: float = 0.5
@export var damage_mult: float = 1.0

@export_group("Move (mechanics §2.2 + P1 보정 110px/s)")
@export var max_speed: float = 110.0
@export var accel_time: float = 0.06
@export var decel_time: float = 0.05
@export var deadzone_px: float = 3.0
@export var arrive_radius: float = 2.0
@export var reanchor_radius: float = 48.0
@export var sensitivity: float = 1.0
@export var follow_time: float = 0.05
@export var kb_player_hit: Vector2 = Vector2(8.0, 0.08)

@export_group("Slow (mechanics §2.5)")
@export var slow_world_scale: float = 0.5
@export var slow_player_comp: float = 0.8
@export var blend_in: float = 0.08
@export var blend_out: float = 0.05
@export var boss_gauge_max: float = 3.0
@export var boss_gauge_regen: float = 0.5
@export var boss_gauge_resume: float = 0.75
@export var boss_gauge_enabled: bool = true

@export_group("Scroll (level §4.3)")
@export var scroll_base: float = 16.0
@export var scroll_min_ratio: float = 0.6
@export var crowd_start: int = 24
@export var crowd_end: int = 36
@export var elite_ratio: float = 0.6
@export var ratio_lerp_time: float = 0.5
@export var plaza_decel_time: float = 6.0
@export var plaza_hold_time: float = 20.0   # p4 결정 4: 40s -> 20s
@export var plaza_accel_time: float = 1.0
@export var plaza_decel_top_y: float = 96.0
@export var entry_speed_mult: float = 3.0
@export var arena_slide_speed: float = 96.0
@export var arena_top_y: float = 48.0
@export var player_top_limit: float = 96.0
@export var player_bottom_limit: float = 370.0

@export_group("Hazard (mechanics §7 + P1 절충)")
@export var hazard_tick: float = 0.5
@export var hazard_player_tick: float = 2.5
@export var hazard_enemy_tick: float = 5.0
@export var hazard_elite_tick: float = 2.0

@export_group("Spawn (economy §2.3, level §5)")
@export var max_alive: int = 36
@export var defer_alive: int = 32
@export var spawn_grace_zone: float = 2.0
@export var spawn_grace_start: float = 3.0   # p4 결정 1: 5s -> 3s
@export var pressure_early: float = 2.0
@export var pressure_late: float = 3.0
@export var pressure_split_t: float = 75.0
@export var pressure_end_t: float = 150.0
@export var t_life: float = 10.0
@export var ring_share: float = 0.4
@export var ring_top_ratio: float = 0.8
@export var player_safe_radius: float = 96.0
@export var spawn_ids: PackedStringArray = ["A1", "B1", "A2", "B2"]
@export var spawn_weights: PackedFloat32Array = [6.0, 3.0, 1.0, 0.0]
@export var group_jitter: float = 24.0
@export var shooter_group_size: int = 3
@export var enemy_bullet_cap: int = 80
@export var ally_bullet_cap: int = 140
@export var stress_alive: int = 150

@export_group("Scaling (economy §2.2)")
@export var hp_growth: float = 0.00265
@export var atk_growth: float = 0.0015
@export var speed_growth: float = 0.0007
@export var speed_cap: float = 1.25
@export var elite_hp_mult: float = 1.2

@export_group("Boss (mechanics §8.3, level §3.5) [가정]")
@export var boss_hp: float = 2000.0
@export var boss_intro: float = 1.5
@export var boss_idle_gap: float = 1.5
@export var boss_phase2_ratio: float = 0.5
@export var boss_phase2_speed: float = 1.25
@export var boss_phase2_gap: float = 0.8
@export var boss_phase2_pause: float = 1.5
@export var b1_telegraph: float = 1.0
@export var b1_speed: float = 220.0
@export var b1_shock: float = 0.2
@export var b1_rest: float = 1.2
@export var b1_stun_pillar: float = 1.5
@export var b1_stun_wall: float = 0.8
@export var b1_contact_dmg: float = 20.0
@export var b1_shock_dmg: float = 10.0
@export var b1_shock_radius: float = 40.0
@export var b2_telegraph: float = 0.8
@export var b2_volleys: int = 3
@export var b2_interval: float = 0.4
@export var b2_rest: float = 1.0
@export var b2_bullet_speed: float = 80.0
@export var b2_bullet_dmg: float = 10.0
@export var b2_fan_deg: float = 15.0
@export var minion_interval: float = 4.0
@export var minion_max: int = 8

@export_group("Feel (mechanics §9)")
@export var hs_elite_hit: float = 0.04
@export var hs_elite_kill: float = 0.06
@export var hs_player_hit: float = 0.05
@export var hs_boss_kill: float = 0.10
@export var shake_player_hit: Vector2 = Vector2(2.0, 0.15)
@export var shake_elite_kill: Vector2 = Vector2(2.0, 0.12)
@export var shake_boss_hit: Vector2 = Vector2(3.0, 0.25)
@export var shake_boss_kill: Vector2 = Vector2(3.0, 0.4)
@export var shake_enabled: bool = true

@export_group("XP (economy §1.2)")
@export var xp_a: float = 8.0
@export var xp_b: float = 5.0
@export var xp_c: float = 0.4
@export var xp_first_mult: float = 1.0
@export var xp_first_need_early: int = 8     # p4 결정 2: 판 1~3 xp_need(1)=8
@export var early_run_count: int = 3

@export_group("Offer (mechanics §6.1)")
@export var offer_base_weight: float = 100.0
@export var material_boost: float = 3.0
@export var material_pity: int = 3
@export var free_rerolls: int = 2
@export var evolve_min_level: int = 4      # p4 결정 3: 단축판은 Lv4 + 짝 패시브
@export var evolve_delay: float = 1.5

@export_group("Imprint (economy §4.1)")
@export var imprint_participation: int = 3
@export var imprint_floor_coef: int = 4
@export var imprint_boss_bonus: int = 10
@export var imprint_first_reach: int = 15
@export var imprint_fail_ratio: float = 0.6
@export var floor_index: int = 1

static func load_default() -> Balance:
	if ResourceLoader.exists("res://data/balance.tres"):
		var r := load("res://data/balance.tres") as Balance
		if r != null:
			return r
	return Balance.new()
