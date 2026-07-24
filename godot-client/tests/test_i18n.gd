extends Node
## i18n + 通知弹窗测试（场景方式运行）。

var _checks := 0
var _failed := 0


func _ready() -> void:
	# 1) 简单 key 解析。
	var t1: String = I18n.parse("misc:UI_LOGIN")
	_assert(t1 == "登录", "simple key: %s" % t1)

	# 2) 带参数插值。
	var t2: String = I18n.parse("misc:NOT_ONLINE;username=testplayer")
	_assert(t2.contains("testplayer"), "param interpolation: %s" % t2)

	# 3) 多参数插值。
	var t3: String = I18n.parse("misc:NO_SKILL_DOOR;skill=伐木;level=10")
	_assert(t3.contains("伐木") and t3.contains("10"), "multi params: %s" % t3)

	# 4) 非 i18n 键原样返回。
	var t4: String = I18n.parse("hello world")
	_assert(t4 == "hello world", "plain text passthrough")

	# 5) 未知 key 返回 key 本身。
	var t5: String = I18n.parse("misc:NONEXISTENT_KEY_XYZ")
	_assert(t5.contains("NONEXISTENT"), "unknown key fallback")

	# 6) 通知弹窗不崩溃。
	var notif := NotificationUI.new()
	add_child(notif)
	GameState.notification_received.emit("misc:UI_WELCOME_TITLE", "white")
	await get_tree().process_frame
	_assert(notif.get_child_count() == 1, "notification shown")

	_finish()


func _assert(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		print("[TEST] FAIL: %s" % label)


func _finish() -> void:
	if _failed == 0:
		print("[TEST] TEST_PASS: i18n/notification (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		print("[TEST] TEST_FAIL: %d/%d checks failed" % [_failed, _checks])
		get_tree().quit(1)
