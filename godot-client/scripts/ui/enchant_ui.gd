class_name EnchantUI
extends DraggablePanel
## 附魔界面：分别选择可附魔装备与碎片，再向服务端确认。

const INVENTORY_SIZE := 25

var _grid: GridContainer
var _status_label: Label
var _selected_label: Label
var _enchant_button: Button
var _selected_equipment := -1
var _selected_shard := -1


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(400, 330)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "附魔"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "先选择装备，再选择碎片"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hint)

	_selected_label = Label.new()
	_selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selected_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_selected_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(_grid)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35))
	vbox.add_child(_status_label)

	_enchant_button = Button.new()
	_enchant_button.text = "附魔"
	_enchant_button.disabled = true
	_enchant_button.pressed.connect(_on_enchant_pressed)
	vbox.add_child(_enchant_button)

	GameState.enchant_opened.connect(_on_opened)
	GameState.enchant_item_selected.connect(_on_item_selected)
	GameState.inventory_updated.connect(refresh)


func _on_opened() -> void:
	visible = true
	_selected_equipment = -1
	_selected_shard = -1
	_status_label.text = ""
	_update_selection_text()
	refresh()


func _on_item_selected(index: int, is_shard: bool) -> void:
	if index < 0:
		return
	if is_shard:
		_selected_shard = index
	else:
		_selected_equipment = index
	_status_label.text = ""
	_update_selection_text()
	refresh()


func _update_selection_text() -> void:
	var equipment_name := _slot_name(_selected_equipment)
	var shard_name := _slot_name(_selected_shard)
	_selected_label.text = "装备：%s    碎片：%s" % [equipment_name, shard_name]
	_enchant_button.disabled = _selected_equipment < 0 or _selected_shard < 0


func _slot_name(index: int) -> String:
	if index < 0 or not GameState.inventory.has(index):
		return "未选择"
	return str(GameState.inventory[index].get("name", GameState.inventory[index].get("key", "未选择")))


func refresh() -> void:
	if not visible:
		return
	for child: Node in _grid.get_children():
		child.queue_free()
	for index: int in INVENTORY_SIZE:
		_grid.add_child(_make_slot(index, GameState.inventory.get(index, {})))
	_update_selection_text()


func _make_slot(index: int, slot_data: Dictionary) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(44, 44)
	slot.tooltip_text = str(slot_data.get("name", slot_data.get("key", "")))
	slot.gui_input.connect(_on_slot_input.bind(index))

	var is_equipment := index == _selected_equipment
	var is_shard := index == _selected_shard
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.35, 0.5, 0.9) if is_equipment else Color(0.35, 0.25, 0.5, 0.9) if is_shard else Color(0.15, 0.15, 0.2, 0.85)
	style.border_color = Color(0.4, 0.75, 1.0) if is_equipment else Color(0.8, 0.55, 1.0) if is_shard else Color(0.35, 0.3, 0.25)
	style.set_border_width_all(1)
	slot.add_theme_stylebox_override("panel", style)

	var item_key := str(slot_data.get("key", ""))
	if item_key.is_empty():
		return slot

	var icon := TextureRect.new()
	icon.texture = SpriteLibrary.get_item_texture("items/%s" % item_key)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(36, 36)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)

	var count := int(slot_data.get("count", 1))
	if count > 1:
		var count_label := Label.new()
		count_label.text = str(count)
		count_label.add_theme_font_size_override("font_size", 9)
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.position = Vector2(22, 26)
		slot.add_child(count_label)
	return slot


func _on_slot_input(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not GameState.inventory.has(index) or str(GameState.inventory[index].get("key", "")).is_empty():
		return
	Network.send_packet(Packets.ENCHANT, {
		"opcode": Opcodes.Enchant.SELECT,
		"index": index,
	})


func _on_enchant_pressed() -> void:
	if _selected_equipment < 0 or _selected_shard < 0:
		return
	Network.send_packet(Packets.ENCHANT, {
		"opcode": Opcodes.Enchant.CONFIRM,
		"index": _selected_equipment,
		"shardIndex": _selected_shard,
	})
	_enchant_button.disabled = true
	_status_label.text = "正在附魔……"
