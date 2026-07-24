class_name BankUI
extends DraggablePanel
## 银行界面：银行格子（左，点击取出）+ 背包格子（右，点击存入）。
## 与银行 NPC 对话时自动打开。

var _bank_grid: GridContainer
var _inv_grid: GridContainer


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(620, 400)

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
	title.text = "银行"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "点击银行物品取出，点击背包物品存入"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hint)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(columns)

	# 左侧：银行。
	var bank_side := _make_side(columns, "银行")
	_bank_grid = _make_grid(bank_side)

	# 右侧：背包。
	var inv_side := _make_side(columns, "背包")
	_inv_grid = _make_grid(inv_side)

	GameState.npc_bank.connect(_on_npc_bank)
	GameState.bank_updated.connect(refresh)
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


func _make_grid(side: VBoxContainer) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	side.get_meta("scroll").add_child(grid)
	return grid


func _on_npc_bank(_slots: Array) -> void:
	_open()


func _open() -> void:
	visible = true
	refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


## 固定容器大小与服务端 Modules.Constants 保持一致。
const BANK_SIZE := 420
const INVENTORY_SIZE := 25


func refresh() -> void:
	if not visible:
		return

	for child: Node in _bank_grid.get_children():
		child.queue_free()
	for child: Node in _inv_grid.get_children():
		child.queue_free()

	# 保留空槽，避免稀疏 Dictionary 导致背包区域看起来完全没有物品栏。
	for index: int in BANK_SIZE:
		_bank_grid.add_child(_make_slot(GameState.bank.get(index, {}), index, 0))
	for index: int in INVENTORY_SIZE:
		_inv_grid.add_child(_make_slot(GameState.inventory.get(index, {}), index, 1))


func _make_slot(slot_data: Dictionary, index: int, container_type: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(44, 44)
	slot.tooltip_text = str(slot_data.get("name", slot_data.get("key", "")))
	slot.gui_input.connect(_on_slot_input.bind(index, container_type))

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
	icon.custom_minimum_size = Vector2(36, 36)
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	slot.add_child(icon)

	var count := int(slot_data.get("count", 1))
	if count > 1:
		var count_label := Label.new()
		count_label.text = str(count)
		count_label.add_theme_font_size_override("font_size", 10)
		count_label.mouse_filter = MOUSE_FILTER_IGNORE
		count_label.position = Vector2(24, 28)
		slot.add_child(count_label)
	return slot


func _on_slot_input(event: InputEvent, index: int, from_container: int) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var source: Dictionary = GameState.bank if from_container == 0 else GameState.inventory
	if not source.has(index) or str(source[index].get("key", "")).is_empty():
		return
	_transfer(from_container, index)


## 容器间转移（from_container: 0=银行, 1=背包）。
func _transfer(from_container: int, from_index: int) -> void:
	var to_container := 1 if from_container == 0 else 0
	Network.send_packet(Packets.CONTAINER, {
		"opcode": Opcodes.Containers.SELECT,
		"type": 0, # ContainerType.Bank
		"fromContainer": from_container,
		"fromIndex": from_index,
		"toContainer": to_container,
	})
