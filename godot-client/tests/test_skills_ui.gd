extends Node
## 技能/经验数据流测试（场景方式运行）。
## 验证：Skill BATCH/UPDATE 同步、Experience 等级同步与飘字、中文名映射。

var _checks := 0
var _failed := 0
var _skill_updates := 0
var _exp_floats := 0


func _ready() -> void:
	GameState.skills_updated.connect(func() -> void: _skill_updates += 1)
	GameState.experience_float.connect(func(_i: String, _a: int, _s: int) -> void: _exp_floats += 1)

	GameState.player_instance = "p1"
	GameState.player_data = { "level": 1, "experience": 0 }

	# 1) Skill BATCH 批量同步。
	GameState._handle_skill([Opcodes.Skill.BATCH, {
		"skills": [
			{ "type": Modules.Skills.HEALTH, "level": 5, "experience": 1000, "percentage": 45.0 },
			{ "type": Modules.Skills.LUMBERJACKING, "level": 2, "experience": 300, "percentage": 10.0 },
		],
	}])
	_assert(GameState.skills.size() == 2, "BATCH populated 2 skills")
	_assert(GameState.skills[Modules.Skills.HEALTH]["level"] == 5, "health skill level")

	# 2) Skill UPDATE 单条更新。
	GameState._handle_skill([Opcodes.Skill.UPDATE, {
		"type": Modules.Skills.MINING, "level": 3, "experience": 500, "percentage": 60.0,
	}])
	_assert(GameState.skills.size() == 3, "UPDATE added skill")
	_assert(_skill_updates == 2, "skills_updated fired twice")

	# 3) Experience 等级同步（Sync）。
	GameState._handle_experience([Opcodes.Experience.SYNC, {
		"instance": "p1", "level": 6,
	}])
	_assert(GameState.player_data["level"] == 6, "level synced to 6")

	# 4) 经验飘字（仅本地玩家）。
	GameState._handle_experience([Opcodes.Experience.SKILL, {
		"instance": "p1", "amount": 25, "skill": Modules.Skills.LUMBERJACKING,
	}])
	GameState._handle_experience([Opcodes.Experience.SKILL, {
		"instance": "other", "amount": 25, "skill": Modules.Skills.LUMBERJACKING,
	}])
	_assert(_exp_floats == 1, "experience float only for local player")

	# 5) 技能中文名映射。
	_assert(Modules.SKILL_NAMES[Modules.Skills.LUMBERJACKING] == "伐木", "skill name mapping")
	_assert(Modules.SKILL_NAMES[Modules.Skills.HEALTH] == "生命", "health name")

	_finish()


func _assert(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		print("[TEST] FAIL: %s" % label)


func _finish() -> void:
	if _failed == 0:
		print("[TEST] TEST_PASS: skills/experience data flow (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		print("[TEST] TEST_FAIL: %d/%d checks failed" % [_failed, _checks])
		get_tree().quit(1)
