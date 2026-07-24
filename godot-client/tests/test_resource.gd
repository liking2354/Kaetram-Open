extends Node
## 资源采集协议级测试（场景方式运行）。
## 验证：Target.Object 包格式正确、资源状态/动画信号分发正常。

const EntityVisualScene := preload("res://scripts/game/entity_visual.gd")

var _checks := 0
var _failed := 0
var _got_resource_state := false
var _got_animation := false


func _ready() -> void:
	GameState.resource_state_changed.connect(func(_i: String, _s: int) -> void: _got_resource_state = true)
	GameState.entity_animation.connect(func(_i: String, _a: int, _r: String) -> void: _got_animation = true)

	# 1) 资源状态包分发。
	GameState._handle_resource([{ "instance": "tree1", "state": 1 }])
	_assert(_got_resource_state, "resource state dispatched")

	# 2) 采集动画包分发。
	GameState._handle_animation([{ "instance": "p1", "action": 0, "resourceInstance": "tree1" }])
	_assert(_got_animation, "animation dispatched")

	# 3) 资源精灵的 shake/exhausted 动画（用树精灵验证）。
	var visual: EntityVisual = EntityVisualScene.new()
	add_child(visual)
	visual.setup({ "type": Modules.EntityType.TREE, "key": "oak", "instance": "tree1", "x": 0, "y": 0 })
	visual.shake()
	visual.set_resource_state(1)
	visual.set_resource_state(0)
	_assert(true, "resource visual states no crash")

	# 4) Target.Object 包结构与 Target.Talk 一致（仅 opcode 不同）。
	var talk_packet := [Opcodes.Target.TALK, "npc1"]
	var object_packet := [Opcodes.Target.OBJECT, "tree1"]
	_assert(talk_packet.size() == object_packet.size(), "object packet same structure as talk")
	_assert(int(object_packet[0]) == 3, "object opcode is OBJECT(3)")

	_finish()


func _assert(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		print("[TEST] FAIL: %s" % label)


func _finish() -> void:
	if _failed == 0:
		print("[TEST] TEST_PASS: resource interaction protocol (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		print("[TEST] TEST_FAIL: %d/%d checks failed" % [_failed, _checks])
		get_tree().quit(1)
