class_name DeathUI
extends ColorRect
## 死亡界面：全屏暗化 + 复活按钮。

var _respawn_button: Button


func _ready() -> void:
	visible = false
	color = Color(0, 0, 0, 0.65)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var label := Label.new()
	label.text = "你已死亡……"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	vbox.add_child(label)

	_respawn_button = Button.new()
	_respawn_button.text = "复活"
	_respawn_button.custom_minimum_size = Vector2(160, 44)
	_respawn_button.pressed.connect(_on_respawn)
	vbox.add_child(_respawn_button)

	GameState.player_died.connect(_show)
	GameState.player_respawned.connect(_hide)


func _show() -> void:
	visible = true


func _hide() -> void:
	visible = false


func _on_respawn() -> void:
	Network.send_packet(Packets.RESPAWN, [])
	_respawn_button.disabled = true
	_respawn_button.text = "复活中……"
	await get_tree().create_timer(1.0).timeout
	_respawn_button.disabled = false
	_respawn_button.text = "复活"
