extends Node
## 背包/装备合成测试（场景方式运行）。
## 验证：Container BATCH/ADD/REMOVE 同步、Equipment 装备更新、物品图标加载。

var _checks := 0
var _failed := 0


func _ready() -> void:
	GameState.inventory_updated.connect(func() -> void: _log("inventory_updated: %d items" % GameState.inventory.size()))
	GameState.equipment_updated.connect(func() -> void: _log("equipment_updated"))

	# 1) BATCH 批量同步。
	GameState._handle_container([Opcodes.Containers.BATCH, {
		"type": 1,
		"data": {
			"slots": [
				{ "index": 0, "key": "bronzeaxe", "count": 1, "enchantments": {}, "name": "Bronze Axe", "equippable": true },
				{ "index": 1, "key": "shrimp", "count": 5, "enchantments": {}, "name": "Shrimp", "edible": true },
			],
		},
	}])
	_assert(GameState.inventory.size() == 2, "BATCH populated 2 items")
	_assert(GameState.inventory[0]["key"] == "bronzeaxe", "slot 0 key")
	_assert(GameState.inventory[1]["count"] == 5, "slot 1 count")

	# 2) ADD。
	GameState._handle_container([Opcodes.Containers.ADD, {
		"type": 1,
		"slot": { "index": 2, "key": "stick", "count": 3, "enchantments": {}, "name": "Stick" },
	}])
	_assert(GameState.inventory.size() == 3, "ADD added item")

	# 3) REMOVE。
	GameState._handle_container([Opcodes.Containers.REMOVE, {
		"type": 1,
		"slot": { "index": 2 },
	}])
	_assert(GameState.inventory.size() == 2, "REMOVE removed item")

	# 4) 非背包容器（Bank=0）应被忽略。
	GameState._handle_container([Opcodes.Containers.ADD, {
		"type": 0,
		"slot": { "index": 0, "key": "gold", "count": 100, "enchantments": {} },
	}])
	_assert(GameState.inventory.size() == 2, "Bank container ignored")

	# 5) Equipment 装备更新。
	GameState.player_data = {
		"name": "TestPlayer",
		"equipments": [],
	}
	GameState._handle_equipment([Opcodes.Equipment.EQUIP, {
		"data": { "type": 4, "key": "bronzeaxe", "count": 1, "enchantments": {} },
	}])
	_assert(GameState.player_data["equipments"].size() == 1, "EQUIP added equipment")
	_assert(GameState.player_data["equipments"][0]["key"] == "bronzeaxe", "equipment key")

	# 6) Unequip。
	GameState._handle_equipment([Opcodes.Equipment.UNEQUIP, { "type": 4 }])
	_assert(GameState.player_data["equipments"].is_empty(), "UNEQUIP removed equipment")

	# 7) 物品图标加载。
	var texture := SpriteLibrary.get_item_texture("items/bronzeaxe")
	_assert(texture != null, "item icon texture loaded")

	_finish()


func _assert(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		print("[TEST] FAIL: %s" % label)


func _log(msg: String) -> void:
	print("[TEST] %s" % msg)


func _finish() -> void:
	if _failed == 0:
		print("[TEST] TEST_PASS: inventory mechanics (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		print("[TEST] TEST_FAIL: %d/%d checks failed" % [_failed, _checks])
		get_tree().quit(1)
