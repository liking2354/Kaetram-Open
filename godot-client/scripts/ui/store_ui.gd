class_name StoreUI
extends DraggablePanel
## 商店界面：购买数量选择、出售前价格确认，以及背包同步。

const INVENTORY_SIZE := 25

var _store_grid: GridContainer
var _sell_grid: GridContainer
var _title_label: Label
var _sell_info: Label
var _sell_button: Button
var _selected_sell: Dictionary = {}
var _pending_buy_index := -1


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(560, 400)

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

	_sell_info = Label.new()
	_sell_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_info.add_theme_font_size_override("font_size", 11)
	_sell_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_sell_info)

	_sell_button = Button.new()
	_sell_button.text = "出售所选物品"
	_sell_button.disabled = true
	_sell_button.pressed.connect(_on_sell_pressed)
	vbox.add_child(_sell_button)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(columns)

	var buy_side := _make_side(columns, "购买")
	_store_grid = _make_grid(buy_side, 5)
	var sell_side := _make_side(columns, "出售（点击背包物品查看价格）")
	_sell_grid = _make_grid(sell_side, 5)

	GameState.store_opened.connect(_on_store_opened)
	GameState.store_closed.connect(_on_store_closed)
	GameState.store_updated.connect(_on_store_updated)
	GameState.inventory_updated.connect(refresh)


func _make_side(parent: Control, title_text: String) -> VBoxContainer:
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 6)
	parent.add_child(side)

	var label := Label.new()
	label.text = title_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side.add_child(label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(scroll)
	side.set_meta("scroll", scroll)
	return side


func _make_grid(side: VBoxContainer, columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.get_meta("scroll").add_child(grid)
	return grid


func _on_store_opened(_key: String, currency: String, _items: Array) -> void:
	_title_label.text = "商店（货币：%s）" % (currency if not currency.is_empty() else "金币")
	visible = true
	_clear_sell_selection()
	refresh()


func _on_store_closed() -> void:
	visible = false
	_clear_sell_selection()


func _on_store_updated(_items: Array) -> void:
	refresh()


func refresh() -> void:
	if not visible:
		return
	_refresh_store_items()
	_refresh_sell_items()


func show_selected(item: Dictionary) -> void:
	if not visible:
		return
	if item.is_empty() or not item.has("index"):
		return
	_selected_sell = item.duplicate(true)
	_sell_info.text = "出售 %s x%d，可获得 %d %s" % [
		str(item.get("name", item.get("key", "物品"))),
		int(item.get("count", 1)),
		int(item.get("price", 0)),
		GameState.store_currency if not GameState.store_currency.is_empty() else "金币",
	]
	_sell_button.disabled = false


func _clear_sell_selection() -> void:
	_selected_sell.clear()
	_sell_info.text = ""
	_sell_button.disabled = true


func _refresh_store_items() -> void:
	for child: Node in _store_grid.get_children():
		child.queue_free()
	for index: int in GameState.store_items.size():
		var item: Dictionary = GameState.store_items[index]
		_store_grid.add_child(_make_store_slot(item, index))


func _refresh_sell_items() -> void:
	for child: Node in _sell_grid.get_children():
		child.queue_free()
	for index: int in INVENTORY_SIZE:
		_sell_grid.add_child(_make_inventory_slot(GameState.inventory.get(index, {}), index))


func _make_store_slot(item: Dictionary, index: int) -> PanelContainer:
	var price := int(item.get("price", 0))
	var badge := "%d %s" % [price, GameState.store_currency if not GameState.store_currency.is_empty() else "金币"]
	var slot := _make_item_slot(
		"items/%s" % str(item.get("key", "")),
		str(item.get("name", item.get("key", ""))),
		badge
	)
	slot.gui_input.connect(_on_store_slot_input.bind(index))
	return slot


func _make_inventory_slot(slot_data: Dictionary, index: int) -> PanelContainer:
	var item_key := str(slot_data.get("key", ""))
	var slot := _make_item_slot(
		"items/%s" % item_key,
		str(slot_data.get("name", item_key)),
		"x%d" % int(slot_data.get("count", 1)) if not item_key.is_empty() else ""
	)
	if not item_key.is_empty():
		slot.gui_input.connect(_on_inventory_slot_input.bind(index))
	return slot


func _make_item_slot(sprite_key: String, tooltip: String, badge: String) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(44, 44)
	slot.tooltip_text = tooltip

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.85)
	style.border_color = Color(0.35, 0.3, 0.25)
	style.set_border_width_all(1)
	slot.add_theme_stylebox_override("panel", style)

	if not sprite_key.ends_with("/"):
		var icon := TextureRect.new()
		icon.texture = SpriteLibrary.get_item_texture(sprite_key)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(36, 36)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)

	if not badge.is_empty():
		var badge_label := Label.new()
		badge_label.text = badge
		badge_label.add_theme_font_size_override("font_size", 9)
		badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_label.position = Vector2(2, 30)
		slot.add_child(badge_label)
	return slot


func _on_store_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pending_buy_index = index
		_show_buy_quantity_dialog()


func _on_inventory_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Network.send_packet(Packets.STORE, {
			"opcode": Opcodes.Store.SELECT,
			"key": GameState.store_key,
			"index": index,
			"count": 1,
		})


func _show_buy_quantity_dialog() -> void:
	if _pending_buy_index < 0:
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = "购买数量"
	dialog.ok_button_text = "确认"
	dialog.add_cancel_button("取消")
	var spin := SpinBox.new()
	spin.min_value = 1
	spin.max_value = 999
	spin.value = 1
	spin.suffix = " 个"
	dialog.add_child(spin)
	dialog.confirmed.connect(_on_buy_dialog_confirmed.bind(dialog, spin))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(220, 100))


func _on_buy_dialog_confirmed(dialog: ConfirmationDialog, spin: SpinBox) -> void:
	Network.send_packet(Packets.STORE, {
		"opcode": Opcodes.Store.BUY,
		"key": GameState.store_key,
		"index": _pending_buy_index,
		"count": int(spin.value),
	})
	_pending_buy_index = -1
	dialog.queue_free()


func _on_sell_pressed() -> void:
	if _selected_sell.is_empty():
		return
	Network.send_packet(Packets.STORE, {
		"opcode": Opcodes.Store.SELL,
		"key": GameState.store_key,
		"index": int(_selected_sell.get("index", -1)),
		"count": int(_selected_sell.get("count", 1)),
	})
	_clear_sell_selection()
