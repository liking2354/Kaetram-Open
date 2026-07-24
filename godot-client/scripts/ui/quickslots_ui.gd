class_name QuickslotsUI
extends HBoxContainer
## 底部主动技能快捷栏：左键释放，右键配置或清空。

const SLOT_COUNT := 4

## 槽位控件 [{panel, label, style}]。
var _slots: Array[Dictionary] = []


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	for index: int in SLOT_COUNT:
		_slots.append(_create_slot(index))
	GameState.abilities_updated.connect(refresh)
	GameState.ability_toggled.connect(_on_ability_toggled)
	refresh()


## 按键释放技能（由 game.gd 转发）。
func activate(index: int) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	var ability := _ability_at_slot(index)
	if ability.is_empty():
		return
	_use(ability)


func _use(ability: Dictionary) -> void:
	var key := str(ability.get("key", ""))
	if key.is_empty():
		return
	Network.send_packet(Packets.ABILITY, {
		"opcode": Opcodes.Ability.USE,
		"key": key,
	})


func refresh() -> void:
	for index: int in SLOT_COUNT:
		var ability := _ability_at_slot(index)
		var widgets: Dictionary = _slots[index]
		var label: Label = widgets["label"]
		var panel: PanelContainer = widgets["panel"]
		var style: StyleBoxFlat = widgets["style"]

		if ability.is_empty():
			label.text = ""
			panel.tooltip_text = "%d 号快捷栏\n左键：释放技能\n右键：配置技能" % (index + 1)
			style.bg_color = Color(0.1, 0.1, 0.15, 0.75)
			style.border_color = Color(0.35, 0.3, 0.25)
			continue

		var key := str(ability.get("key", ""))
		label.text = _short_name(key)
		panel.tooltip_text = "%s（Lv %d）\n左键：释放技能\n右键：更换或清空" % [
			key,
			int(ability.get("level", 1)),
		]
		var active := bool(ability.get("active", false))
		style.bg_color = Color(0.2, 0.45, 0.25, 0.9) if active else Color(0.16, 0.22, 0.36, 0.9)
		style.border_color = Color(0.45, 1.0, 0.5) if active else Color(0.45, 0.7, 1.0)


func _ability_at_slot(slot: int) -> Dictionary:
	for key: String in GameState.abilities:
		var ability: Dictionary = GameState.abilities[key]
		if int(ability.get("quickSlot", -1)) == slot:
			return ability
	return {}


func _on_slot_input(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			activate(index)
		MOUSE_BUTTON_RIGHT:
			_show_config_dialog(index)


func _show_config_dialog(slot_index: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "配置 %d 号快捷栏" % (slot_index + 1)
	dialog.ok_button_text = "保存"
	dialog.add_cancel_button("取消")

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(280, 0)
	content.add_theme_constant_override("separation", 6)
	dialog.add_child(content)

	var hint := Label.new()
	hint.text = "选择一个主动技能；“清空”会解除当前技能的绑定。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	content.add_child(hint)

	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.add_item("清空此快捷栏")
	option.set_item_metadata(0, "")
	content.add_child(option)

	var current: Dictionary = _ability_at_slot(slot_index)
	var current_key := str(current.get("key", ""))
	var selected_item := 0
	for ability: Dictionary in _active_abilities():
		var key := str(ability.get("key", ""))
		option.add_item("%s（Lv %d）" % [key, int(ability.get("level", 1))])
		option.set_item_metadata(option.item_count - 1, key)
		if key == current_key:
			selected_item = option.item_count - 1
	option.select(selected_item)

	dialog.confirmed.connect(_on_config_confirmed.bind(dialog, option, slot_index, current_key))
	dialog.canceled.connect(_on_config_canceled.bind(dialog))
	add_child(dialog)
	dialog.popup_centered(Vector2i(330, 150))


func _on_config_confirmed(
	dialog: ConfirmationDialog,
	option: OptionButton,
	slot_index: int,
	current_key: String
) -> void:
	var selected_key := str(option.get_item_metadata(option.selected))
	if selected_key == current_key:
		dialog.queue_free()
		return

	if selected_key.is_empty():
		if not current_key.is_empty():
			_set_quick_slot(current_key, -1)
	else:
		_set_quick_slot(selected_key, slot_index)
	dialog.queue_free()


func _on_config_canceled(dialog: ConfirmationDialog) -> void:
	dialog.queue_free()


func _set_quick_slot(key: String, index: int) -> void:
	Network.send_packet(Packets.ABILITY, {
		"opcode": Opcodes.Ability.QUICK_SLOT,
		"key": key,
		"index": index,
	})


func _active_abilities() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key: String in GameState.abilities:
		var ability: Dictionary = GameState.abilities[key]
		if int(ability.get("type", Modules.AbilityType.PASSIVE)) == Modules.AbilityType.ACTIVE:
			result.append(ability)
	return result


func _on_ability_toggled(_key: String, _active: bool) -> void:
	refresh()


func _short_name(key: String) -> String:
	if key.length() <= 3:
		return key.to_upper()
	return key.left(3).to_upper()


func _create_slot(index: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(46, 46)
	panel.gui_input.connect(_on_slot_input.bind(index))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.75)
	style.border_color = Color(0.35, 0.3, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(center)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(label)

	var hotkey := Label.new()
	hotkey.text = str(index + 1)
	hotkey.add_theme_font_size_override("font_size", 8)
	hotkey.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	hotkey.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hotkey.position = Vector2(3, 2)
	panel.add_child(hotkey)

	add_child(panel)
	return { "panel": panel, "label": label, "style": style }
