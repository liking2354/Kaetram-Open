class_name CraftingUI
extends DraggablePanel
## 制作界面：可制作物品、配方详情、材料校验及 1/5/10 次制作。

var _title_label: Label
var _result_label: Label
var _item_list: VBoxContainer
var _req_list: VBoxContainer
var _craft_button: Button
var _amount_buttons: Dictionary = {}

var _selected_key := ""
var _selected_details: Dictionary = {}
var _skill_type := -1
var _craft_amount := 1


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(520, 340)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_title_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(columns)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(220, 0)
	columns.add_child(scroll)
	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_item_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_result_label)

	var req_title := Label.new()
	req_title.text = "材料需求"
	req_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(req_title)

	_req_list = VBoxContainer.new()
	_req_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_req_list)

	var amounts := HBoxContainer.new()
	amounts.alignment = BoxContainer.ALIGNMENT_CENTER
	amounts.add_theme_constant_override("separation", 4)
	right.add_child(amounts)
	for amount: int in [1, 5, 10]:
		var amount_button := Button.new()
		amount_button.text = "x%d" % amount
		amount_button.custom_minimum_size = Vector2(44, 0)
		amount_button.pressed.connect(_on_amount_pressed.bind(amount))
		amounts.add_child(amount_button)
		_amount_buttons[amount] = amount_button

	_craft_button = Button.new()
	_craft_button.disabled = true
	_craft_button.pressed.connect(_on_craft_pressed)
	right.add_child(_craft_button)

	GameState.crafting_opened.connect(_on_crafting_opened)
	GameState.crafting_selected.connect(_on_crafting_selected)
	GameState.inventory_updated.connect(_refresh_selected_details)
	GameState.skills_updated.connect(_refresh_selected_details)


func _on_crafting_opened(skill_type: int, previews: Array) -> void:
	_skill_type = skill_type
	_title_label.text = "%s 制作" % Modules.SKILL_NAMES.get(skill_type, "制作")
	visible = true
	_selected_key = ""
	_selected_details = {}
	_craft_amount = 1
	_clear_requirements()

	for child: Node in _item_list.get_children():
		child.queue_free()

	for preview: Dictionary in previews:
		_item_list.add_child(_make_preview_row(preview))

	if not previews.is_empty():
		_select_item(str(previews[0].get("key", "")))
	else:
		_result_label.text = "当前没有可制作物品"
	_update_amount_buttons()


func _make_preview_row(preview: Dictionary) -> PanelContainer:
	var key := str(preview.get("key", ""))
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 34)
	row.gui_input.connect(_on_preview_input.bind(key))

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	row.add_child(content)

	var icon := TextureRect.new()
	icon.texture = SpriteLibrary.get_item_texture("items/%s" % key)
	icon.custom_minimum_size = Vector2(28, 28)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)

	var label := Label.new()
	label.text = "%s（Lv %d）" % [key, int(preview.get("level", 1))]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)
	return row


func _on_preview_input(event: InputEvent, key: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_item(key)


func _select_item(key: String) -> void:
	if key.is_empty():
		return
	_selected_key = key
	_selected_details = {}
	_clear_requirements()
	_result_label.text = "正在读取配方……"
	Network.send_packet(Packets.CRAFTING, {
		"opcode": Opcodes.Crafting.SELECT,
		"key": key,
	})


func _on_crafting_selected(details: Dictionary) -> void:
	_selected_key = str(details.get("key", _selected_key))
	_selected_details = details.duplicate(true)
	_refresh_selected_details()


func _on_amount_pressed(amount: int) -> void:
	_craft_amount = amount
	_refresh_selected_details()


func _refresh_selected_details() -> void:
	if not visible or _selected_details.is_empty():
		return
	_render_details()


func _render_details() -> void:
	_clear_requirements()
	_update_amount_buttons()

	var item_name := str(_selected_details.get("name", _selected_key))
	var result_count := int(_selected_details.get("result", 1))
	var required_level := int(_selected_details.get("level", 1))
	_result_label.text = "%s\n产出：x%d  ·  需求等级：%d" % [item_name, result_count * _craft_amount, required_level]

	var skill: Dictionary = GameState.skills.get(_skill_type, {})
	var level_met := int(skill.get("level", 0)) >= required_level
	var all_met := level_met
	var requirements: Array = _selected_details.get("requirements", [])
	for req: Dictionary in requirements:
		var key := str(req.get("key", ""))
		var required_count := int(req.get("count", 1)) * _craft_amount
		var have_count := _count_in_inventory(key)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		var icon := TextureRect.new()
		icon.texture = SpriteLibrary.get_item_texture("items/%s" % key)
		icon.custom_minimum_size = Vector2(24, 24)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		row.add_child(icon)

		var label := Label.new()
		label.text = "%s %d/%d" % [str(req.get("name", key)), have_count, required_count]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override(
			"font_color",
			Color(0.4, 1.0, 0.4) if have_count >= required_count else Color(1.0, 0.3, 0.3)
		)
		row.add_child(label)
		_req_list.add_child(row)
		if have_count < required_count:
			all_met = false

	if not level_met:
		var level_label := Label.new()
		level_label.text = "技能等级不足"
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		_req_list.add_child(level_label)

	_craft_button.text = "制作 x%d" % _craft_amount
	_craft_button.disabled = not all_met


func _update_amount_buttons() -> void:
	for amount: int in _amount_buttons:
		var button: Button = _amount_buttons[amount]
		button.disabled = amount == _craft_amount


func _count_in_inventory(item_key: String) -> int:
	var total := 0
	for index: int in GameState.inventory:
		var slot: Dictionary = GameState.inventory[index]
		if str(slot.get("key", "")) == item_key:
			total += int(slot.get("count", 1))
	return total


func _clear_requirements() -> void:
	for child: Node in _req_list.get_children():
		child.queue_free()
	_craft_button.disabled = true


func _on_craft_pressed() -> void:
	if _selected_key.is_empty():
		return
	Network.send_packet(Packets.CRAFTING, {
		"opcode": Opcodes.Crafting.CRAFT,
		"key": _selected_key,
		"count": _craft_amount,
	})
