class_name TradeUI
extends DraggablePanel
## 交易界面：双方报价、背包物品数量选择、确认与取消。

const INVENTORY_SIZE := 25

var _my_grid: GridContainer
var _their_grid: GridContainer
var _inv_grid: GridContainer
var _accept_button: Button
var _close_button: Button
var _status_label: Label
var _title: Label


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(540, 500)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_title = Label.new()
	_title.text = "交易"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_title)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_status_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	vbox.add_child(columns)
	_my_grid = _make_labeled_grid(columns, "我方提供")
	_their_grid = _make_labeled_grid(columns, "对方提供")

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	vbox.add_child(actions)

	_accept_button = Button.new()
	_accept_button.text = "接受交易"
	_accept_button.pressed.connect(_on_accept_pressed)
	actions.add_child(_accept_button)

	_close_button = Button.new()
	_close_button.text = "取消交易"
	_close_button.pressed.connect(_on_close_pressed)
	actions.add_child(_close_button)

	var inv_label := Label.new()
	inv_label.text = "背包（左键加入 1 个，右键选择数量）"
	inv_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(inv_label)

	var inv_scroll := ScrollContainer.new()
	inv_scroll.custom_minimum_size = Vector2(0, 145)
	vbox.add_child(inv_scroll)
	_inv_grid = GridContainer.new()
	_inv_grid.columns = 8
	_inv_grid.add_theme_constant_override("h_separation", 4)
	_inv_grid.add_theme_constant_override("v_separation", 4)
	inv_scroll.add_child(_inv_grid)

	GameState.trade_opened.connect(_on_opened)
	GameState.trade_closed.connect(_close)
	GameState.trade_updated.connect(refresh)
	GameState.inventory_updated.connect(refresh)
	GameState.trade_accepted.connect(_on_trade_accepted)


func _make_labeled_grid(parent: Control, label_text: String) -> GridContainer:
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(side)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side.add_child(label)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	side.add_child(grid)
	return grid


func _on_opened() -> void:
	visible = true
	_status_label.text = ""
	var opponent: Dictionary = GameState.entities.get(GameState.trade_other_instance, {})
	var opponent_name := str(opponent.get("name", opponent.get("username", "对方")))
	_title.text = "交易 - %s" % opponent_name
	refresh()


func _close() -> void:
	visible = false
	_status_label.text = ""


func refresh() -> void:
	if not visible:
		return
	_fill_offer_grid(_my_grid, GameState.trade_my_items, true)
	_fill_offer_grid(_their_grid, GameState.trade_their_items, false)
	_fill_inventory()


func _fill_offer_grid(grid: GridContainer, items: Dictionary, mine: bool) -> void:
	for child: Node in grid.get_children():
		child.queue_free()
	for index: int in INVENTORY_SIZE:
		grid.add_child(_make_offer_slot(items.get(index, {}), index, mine))


func _fill_inventory() -> void:
	for child: Node in _inv_grid.get_children():
		child.queue_free()
	for index: int in INVENTORY_SIZE:
		_inv_grid.add_child(_make_inventory_slot(GameState.inventory.get(index, {}), index))


func _make_offer_slot(slot_data: Dictionary, trade_index: int, mine: bool) -> PanelContainer:
	var slot := _make_slot(slot_data)
	if mine and not str(slot_data.get("key", "")).is_empty():
		slot.gui_input.connect(_on_my_offer_input.bind(trade_index))
	return slot


func _make_inventory_slot(slot_data: Dictionary, inventory_index: int) -> PanelContainer:
	var slot := _make_slot(slot_data)
	if not str(slot_data.get("key", "")).is_empty():
		slot.gui_input.connect(_on_inventory_slot_input.bind(inventory_index))
	return slot


func _make_slot(slot_data: Dictionary) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(40, 40)
	slot.tooltip_text = str(slot_data.get("name", slot_data.get("key", "")))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.85)
	style.border_color = Color(0.35, 0.3, 0.25)
	style.set_border_width_all(1)
	slot.add_theme_stylebox_override("panel", style)

	var item_key := str(slot_data.get("key", ""))
	if item_key.is_empty():
		return slot

	var icon := TextureRect.new()
	icon.texture = SpriteLibrary.get_item_texture("items/%s" % item_key)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(32, 32)
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


func _on_my_offer_input(event: InputEvent, trade_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Network.send_packet(Packets.TRADE, {
			"opcode": Opcodes.Trade.REMOVE,
			"index": trade_index,
		})


func _on_inventory_slot_input(event: InputEvent, inventory_index: int) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		_offer_from_inventory(inventory_index, 1)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_show_count_dialog(inventory_index)


func _offer_from_inventory(inventory_index: int, count: int) -> void:
	Network.send_packet(Packets.TRADE, {
		"opcode": Opcodes.Trade.ADD,
		"index": inventory_index,
		"count": count,
	})


func _show_count_dialog(inventory_index: int) -> void:
	var item: Dictionary = GameState.inventory.get(inventory_index, {})
	var max_count := int(item.get("count", 1))
	if max_count < 2:
		_offer_from_inventory(inventory_index, 1)
		return

	var dialog := ConfirmationDialog.new()
	dialog.title = "加入交易的数量"
	dialog.ok_button_text = "确认"
	dialog.add_cancel_button("取消")
	var spin := SpinBox.new()
	spin.min_value = 1
	spin.max_value = max_count
	spin.value = 1
	spin.suffix = " 个"
	dialog.add_child(spin)
	dialog.confirmed.connect(_on_count_dialog_confirmed.bind(dialog, spin, inventory_index))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(220, 100))


func _on_count_dialog_confirmed(dialog: ConfirmationDialog, spin: SpinBox, inventory_index: int) -> void:
	_offer_from_inventory(inventory_index, int(spin.value))
	dialog.queue_free()


func _on_accept_pressed() -> void:
	Network.send_packet(Packets.TRADE, { "opcode": Opcodes.Trade.ACCEPT })
	_accept_button.disabled = true
	_status_label.text = "等待对方确认……"


func _on_close_pressed() -> void:
	Network.send_packet(Packets.TRADE, { "opcode": Opcodes.Trade.CLOSE })


func _on_trade_accepted(message: String) -> void:
	if not visible:
		return
	_accept_button.disabled = false
	match message:
		"misc:ACCEPTED_TRADE":
			_status_label.text = "你已确认，等待对方……"
		"misc:ACCEPTED_TRADE_OTHER":
			_status_label.text = "对方已确认"
		_:
			_status_label.text = ""
