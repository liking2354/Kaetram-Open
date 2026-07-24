extends SceneTree
## 精灵库冒烟测试（无头运行）。
## 用法：Godot --headless --path . -s tests/test_sprites.gd
## 校验：关键精灵的 SpriteFrames 构建、动画数量、帧数、默认动画表。

const GVER := "0.5.5-beta"


func _init() -> void:
	var failed := 0

	# 1) 怪物精灵（显式 animations 或默认 mobs 表）
	failed += _check_sprite("mobs/rat", ["idle_down", "walk_down", "atk_down"])
	# 2) 玩家基础精灵（默认玩家动画表）
	failed += _check_sprite("player/base", ["idle_down", "idle_right", "walk_down", "walk_right", "walk_up", "atk_down"])
	# 3) NPC（默认 npcs 表：idle_down 2帧）
	failed += _check_sprite("npcs/guard", ["idle_down"])
	# 4) 物品（默认 idle 1帧）
	failed += _check_sprite("items/bronzeaxe", ["idle"])
	# 5) 装备图层精灵
	failed += _check_sprite("player/chestplate/bronzechestplate", ["idle_down", "walk_down"])

	if failed == 0:
		print("[TEST] TEST_PASS: all sprites built correctly")
		quit(0)
	else:
		print("[TEST] TEST_FAIL: %d sprite checks failed" % failed)
		quit(1)


func _check_sprite(key: String, expected_anims: Array) -> int:
	var frames: SpriteFrames = SpriteLibrary.get_sprite_frames(key)
	if not frames:
		print("[TEST] FAIL %s: SpriteFrames is null" % key)
		return 1

	for anim: String in expected_anims:
		if not frames.has_animation(anim):
			print("[TEST] FAIL %s: missing animation %s" % [key, anim])
			return 1
		if frames.get_frame_count(anim) < 1:
			print("[TEST] FAIL %s: animation %s has no frames" % [key, anim])
			return 1

	var anims := frames.get_animation_names()
	print("[TEST] OK %s: %d animations (%s)" % [key, anims.size(), ", ".join(anims.slice(0, 4))])
	return 0
