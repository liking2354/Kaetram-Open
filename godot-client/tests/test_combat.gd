extends Node
## 战斗机制合成测试（场景方式运行，无需真实怪物）。
## 验证：Combat/Points 包分发、受击表现、血条、死亡动画、伤害数字。

const EntityVisualScene := preload("res://scripts/game/entity_visual.gd")

var _checks := 0
var _failed := 0


func _ready() -> void:
	# 1) Combat.Hit 包分发为 combat_hit 信号。
	GameState.combat_hit.connect(_on_combat_hit)
	GameState.points_updated.connect(_on_points_updated)

	GameState._handle_combat([Opcodes.Combat.HIT, {
		"instance": "attacker1",
		"target": "target1",
		"hit": { "type": 0, "damage": 15 },
	}])

	GameState._handle_points([{
		"instance": "target1",
		"hitPoints": 40,
		"maxHitPoints": 69,
	}])

	# 2) EntityVisual 战斗表现。
	var visual: EntityVisual = EntityVisualScene.new()
	add_child(visual)
	visual.setup({
		"type": Modules.EntityType.MOB,
		"key": "rat",
		"name": "Rat",
		"instance": "target1",
		"x": 0, "y": 0,
	})
	_assert(visual != null, "visual created")

	visual.play_attack()
	visual.show_hit({ "type": 0, "damage": 15 })
	visual.set_health(40, 69)
	visual.set_health(0, 69)
	visual.play_death()
	_assert(visual.died, "visual died flag")

	# 3) 玩家多图层 + 战斗表现不崩溃。
	var player_visual: EntityVisual = EntityVisualScene.new()
	add_child(player_visual)
	player_visual.setup({
		"type": Modules.EntityType.PLAYER,
		"key": "player",
		"name": "TestPlayer",
		"instance": "p1",
		"x": 0, "y": 0,
		"equipments": [
			{ "type": 3, "key": "bronzechestplate" },
			{ "type": 4, "key": "bronzesword" },
		],
	})
	player_visual.play_attack()
	player_visual.show_hit({ "type": 6, "damage": 30 })

	# 等一帧让信号处理完。
	await get_tree().process_frame

	_finish()


func _on_combat_hit(attacker: String, target: String, hit: Dictionary) -> void:
	_assert(attacker == "attacker1", "combat attacker")
	_assert(target == "target1", "combat target")
	_assert(int(hit.get("damage", 0)) == 15, "combat damage")


func _on_points_updated(instance: String, hp: int, max_hp: int, _mana: int, _max_mana: int) -> void:
	_assert(instance == "target1", "points instance")
	_assert(hp == 40 and max_hp == 69, "points values")


func _assert(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		print("[TEST] FAIL: %s" % label)


func _finish() -> void:
	if _failed == 0:
		print("[TEST] TEST_PASS: combat mechanics (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		print("[TEST] TEST_FAIL: %d/%d checks failed" % [_failed, _checks])
		get_tree().quit(1)
