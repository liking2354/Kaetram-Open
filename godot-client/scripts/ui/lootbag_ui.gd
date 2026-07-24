class_name LootBagUI
extends DraggablePanel
## 战利品袋界面：按服务端槽位索引显示并拾取物品。

var _grid: GridContainer
var _items: Dictionary = {}


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(240, 180)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "战利品"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "点击物品拾取"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	vbox.add_child(hint)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(_grid)

	GameState.lootbag_opened.connect(_on_opened)
	GameState.lootbag_item_taken.connect(_on_item_taken)
	GameState.lootbag_closed.connect(_close)


func _on_opened(items: Array) -> void:
	_items.clear()
	for slot: Dictionary in items:
		var index := int(slot.get("index", -1))
		if index >= 0 and not str(slot.get("key", "")).is_empty():
			_items[index] = slot
	_refresh()
	visible = not _items.is_empty()


func _on_item_taken(index: int) -> void:
	if index < 0:
		return
	_items.erase(index)
	_refresh()
	if _items.is_empty():
		visible = false


func _close() -> void:
	_items.clear()
	for child: Node in _grid.get_children():
		child.queue_free()
	visible = false


func _refresh() -> void:
	for child: Node in _grid.get_children():
		child.queue_free()
	for index: int in _items:
		_grid.add_child(_make_slot(_items[index], index))


func _make_slot(slot_data: Dictionary, index: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(44, 44)
	slot.tooltip_text = str(slot_data.get("name", slot_data.get("key", "")))
	slot.gui_input.connect(_on_slot_input.bind(index))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.85)
	style.border_color = Color(0.35, 0.3, 0.25)
	style.set_border_width_all(1)
	slot.add_theme_stylebox_override("panel", style)

	var icon := TextureRect.new()
	icon.texture = SpriteLibrary.get_item_texture("items/%s" % str(slot_data.get("key", "")))
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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Network.send_packet(Packets.LOOT_BAG, {
			"opcode": Opcodes.LootBag.TAKE,
			"index": index,
		})
