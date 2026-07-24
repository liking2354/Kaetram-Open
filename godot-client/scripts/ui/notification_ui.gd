class_name NotificationUI
extends VBoxContainer
## 系统通知弹窗：顶部居中堆叠显示，4 秒后自动淡出。

## 同时显示的最大通知数。
const MAX_NOTIFICATIONS := 5
## 显示时长（秒）。
const DISPLAY_TIME := 4.0


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)
	GameState.notification_received.connect(_on_notification)


func _on_notification(message: String, colour: String) -> void:
	var text: String = I18n.parse(message)
	_show_toast(text, _parse_colour(colour))


## 手动推送一条通知（本地事件用）。
func push_text(text: String, color := Color.WHITE) -> void:
	_show_toast(text, color)


func _show_toast(text: String, color: Color) -> void:
	# 超出上限移除最旧。注意 queue_free() 是延迟释放，本帧内 get_child_count()
	# 不会立即减少，若用 while 循环判断会导致死循环卡死游戏；
	# 因此改为立即 remove_child() 使其马上从子节点列表中移除，再 queue_free() 释放内存。
	while get_child_count() >= MAX_NOTIFICATIONS:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.85)
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = Color(0.3, 0.28, 0.25)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	panel.add_child(label)

	add_child(panel)

	# 定时淡出。
	var tween := create_tween()
	tween.tween_interval(DISPLAY_TIME)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)


## 服务端颜色为十六进制字符串（如 "white"、"red" 或 "#ff0000"）。
func _parse_colour(colour: String) -> Color:
	if colour.is_empty():
		return Color.WHITE
	if Color.html_is_valid(colour):
		return Color.html(colour)
	match colour:
		"red": return Color(0.95, 0.4, 0.4)
		"green": return Color(0.5, 0.9, 0.5)
		"yellow": return Color(0.95, 0.85, 0.4)
		_: return Color.WHITE
