class_name InventoryUI
extends DraggablePanel
## 背包界面：物品网格 + 拖拽排序 + 双击快速操作 + 右键动作菜单。
## I 键或 B 键开关。

## 网格列数。
const COLUMNS := 6
## 服务端 Modules.Constants.INVENTORY_SIZE = 25。
const MAX_SLOTS := 25
## 槽位像素尺寸。
const SLOT_SIZE := Vector2(40, 40)
## 双击间隔阈值（秒）。
const DOUBLE_CLICK_TIME := 0.35

var _grid: GridContainer
var _sync_label: Label
## 槽位控件缓存 {index: {icon, count_label, panel}}
var _slot_widgets := {}
## 拖拽源槽位（-1 表示未拖拽）。
var _drag_source := -1
## 上次单击的槽位和时间（用于双击检测）。
var _last_click_index := -1
var _last_click_time := 0.0


func _ready() -> void:
	super._ready()
	visible = false

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "背包"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	_sync_label = Label.new()
	_sync_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sync_label.add_theme_font_size_override("font_size", 10)
	_sync_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35))
	vbox.add_child(_sync_label)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(_grid)

	# 预创建槽位控件。
	for i: int in MAX_SLOTS:
		_slot_widgets[i] = _create_slot(i)

	GameState.inventory_updated.connect(refresh)


## 切换显示。
func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


## 刷新整个背包显示。
func refresh() -> void:
	if not visible:
		return

	if not GameState.inventory_initialized:
		_sync_label.text = "正在接收背包数据……"
	elif GameState.inventory_pickup_pending:
		_sync_label.text = "正在等待服务器确认拾取……"
	else:
		_sync_label.text = ""

	for i: int in MAX_SLOTS:
		var widgets: Dictionary = _slot_widgets[i]
		if GameState.inventory.has(i):
			_fill_slot(i, GameState.inventory[i], widgets)
		else:
			_clear_slot(widgets)


## 获取指定槽位物品数量（供外部调用）。
func get_count(index: int) -> int:
	if not GameState.inventory.has(index):
		return 0
	return _to_int(GameState.inventory[index].get("count", 1))


## 安全地将 Variant 转换为 int。
## 避免 Godot 4.0 早期版本中 int(Variant) 在 Variant 为 Dictionary/Array 时报
## "Nonexistent 'int' constructor" 错误的兼容性问题。
func _to_int(value: Variant) -> int:
	if value == null:
		return 0
	if value is int:
		return value
	if value is float:
		return int(value)
	if value is String:
		# String.to_int() 比 int(String) 更稳定。
		return value.to_int() if value.is_valid_int() else int(value)
	if value is bool:
		return 1 if value else 0
	return 0


## 判断槽位是否为空。
func is_empty(index: int) -> bool:
	return not GameState.inventory.has(index) or GameState.inventory[index].is_empty()


func _create_slot(index: int) -> Dictionary:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.mouse_filter = MOUSE_FILTER_STOP
	slot.set_meta("slot_index", index)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.85)
	style.border_color = Color(0.35, 0.3, 0.25)
	style.set_border_width_all(1)
	slot.add_theme_stylebox_override("panel", style)

	var icon := TextureRect.new()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.custom_minimum_size = Vector2(32, 32)
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	slot.add_child(icon)

	var count := Label.new()
	count.add_theme_font_size_override("font_size", 10)
	count.add_theme_color_override("font_shadow_color", Color.BLACK)
	count.add_theme_constant_override("shadow_offset_x", 1)
	count.add_theme_constant_override("shadow_offset_y", 1)
	count.mouse_filter = MOUSE_FILTER_IGNORE
	icon.add_child(count)
	count.position = Vector2(20, 22)

	# 鼠标输入：左键单击/双击/拖拽，右键动作菜单。
	slot.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					_on_slot_left_clicked(index, slot)
				MOUSE_BUTTON_RIGHT:
					_on_slot_right_clicked(index, slot)
	)

	_grid.add_child(slot)
	return { "icon": icon, "count": count, "panel": slot }


func _fill_slot(_index: int, slot_data: Dictionary, widgets: Dictionary) -> void:
	var key := str(slot_data.get("key", ""))
	var texture := SpriteLibrary.get_item_texture("items/%s" % key)
	widgets.icon.texture = texture

	# 构建详细 tooltip（含攻击/防御属性、附魔等）。
	var tooltip := str(slot_data.get("name", key))
	var count := _to_int(slot_data.get("count", 1))
	if count > 1:
		tooltip += " x%d" % count
	widgets.count.text = str(count) if count > 1 else ""

	# 攻击/防御属性（服务端为五维 Dictionary）。
	var attack_stats: Dictionary = slot_data.get("attackStats", {})
	var defense_stats: Dictionary = slot_data.get("defenseStats", {})
	tooltip += _format_stat_group("攻击", attack_stats, ["crush", "slash", "stab", "archery", "magic"])
	tooltip += _format_stat_group("防御", defense_stats, ["crush", "slash", "stab", "archery", "magic"])

	# 附魔信息。
	var enchants: Dictionary = slot_data.get("enchantments", {})
	if not enchants.is_empty():
		tooltip += "\n附魔:"
		for enchant_key: Variant in enchants:
			var enchantment: Variant = enchants[enchant_key]
			var level := _to_int(enchantment.get("level", 0)) if enchantment is Dictionary else _to_int(enchantment)
			tooltip += " %s+%d" % [str(enchant_key), level]

	# 操作提示。
	var hints: Array[String] = []
	if slot_data.get("equippable", false):
		hints.append("双击装备")
	elif slot_data.get("edible", false):
		hints.append("双击食用")
	elif slot_data.get("interactable", false):
		hints.append("双击使用")
	if not hints.is_empty():
		tooltip += "\n" + "\n".join(hints)

	widgets.icon.tooltip_text = tooltip


func _clear_slot(widgets: Dictionary) -> void:
	widgets.icon.texture = null
	widgets.icon.tooltip_text = ""
	widgets.count.text = ""


## 左键单击：检测双击 → 快速操作；否则开始拖拽。
func _on_slot_left_clicked(index: int, _slot: Control) -> void:
	if not GameState.inventory.has(index):
		# 拖拽放置目标为空槽位时由 _handle_drop 处理。
		return

	var now := Time.get_ticks_msec() / 1000.0
	if index == _last_click_index and (now - _last_click_time) < DOUBLE_CLICK_TIME:
		# 双击：快速操作。
		_quick_action(index)
		_last_click_index = -1
	else:
		# 单击：开始拖拽。
		_last_click_index = index
		_last_click_time = now
		_drag_source = index


## 双击快速操作：根据物品类型自动装备/食用/使用。
func _quick_action(index: int) -> void:
	if not GameState.inventory.has(index):
		return
	Network.send_packet(Packets.CONTAINER, {
		"opcode": Opcodes.Containers.SELECT,
		"type": 1, # ContainerType.Inventory
		"fromIndex": index,
	})


## 拖拽放置：交换槽位。
func _handle_drop(target_index: int, _slot: Control) -> void:
	if _drag_source < 0 or _drag_source == target_index:
		_drag_source = -1
		return

	# 发送 Container.Swap 包交换两个槽位。
	Network.send_packet(Packets.CONTAINER, {
		"opcode": Opcodes.Containers.SWAP,
		"type": 1, # ContainerType.Inventory
		"fromIndex": _drag_source,
		"value": target_index,
	})
	_drag_source = -1


## 拖拽放置：全局检测鼠标抬起，找到目标槽位并交换。
func _input(event: InputEvent) -> void:
	if not visible or _drag_source < 0:
		return
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target_index := _find_slot_at_mouse()
		if target_index >= 0 and target_index != _drag_source:
			Network.send_packet(Packets.CONTAINER, {
				"opcode": Opcodes.Containers.SWAP,
				"type": 1,
				"fromIndex": _drag_source,
				"value": target_index,
			})
		_drag_source = -1


## 通过全局鼠标坐标找到鼠标下方的槽位索引。
func _find_slot_at_mouse() -> int:
	var mouse_pos := get_global_mouse_position()
	for i: int in MAX_SLOTS:
		var widgets: Dictionary = _slot_widgets[i]
		var panel: PanelContainer = widgets.panel
		if panel.get_global_rect().has_point(mouse_pos):
			return i
	return -1


## 右键动作菜单：显示详情及根据物品属性动态生成可用操作。
func _on_slot_right_clicked(index: int, anchor: Control) -> void:
	if not GameState.inventory.has(index):
		return

	var slot: Dictionary = GameState.inventory[index]
	var popup := PopupMenu.new()
	popup.add_item("查看详情", 0)
	var action_id := 1

	if slot.get("edible", false):
		popup.add_item("食用", action_id)
		action_id += 1
	if slot.get("equippable", false):
		popup.add_item("装备", action_id)
		action_id += 1
	if slot.get("interactable", false):
		popup.add_item("使用", action_id)
		action_id += 1

	popup.add_item("丢弃 1 个", action_id)
	action_id += 1
	if _to_int(slot.get("count", 1)) > 1:
		popup.add_item("丢弃全部", action_id)

	popup.id_pressed.connect(_on_item_action_pressed.bind(popup, index, slot))
	popup.popup_hide.connect(popup.queue_free)
	add_child(popup)
	popup.position = Vector2i(anchor.global_position + Vector2(0, anchor.size.y))
	popup.popup()


func _on_item_action_pressed(action_id: int, popup: PopupMenu, index: int, slot: Dictionary) -> void:
	_execute_action(index, slot, action_id)
	popup.hide()


## 执行右键菜单选中的动作。
func _execute_action(index: int, slot: Dictionary, action_id: int) -> void:
	if action_id == 0:
		_show_item_details(slot)
		return
	var current_id := 1

	if slot.get("edible", false):
		if action_id == current_id:
			_quick_action(index)
			return
		current_id += 1
	if slot.get("equippable", false):
		if action_id == current_id:
			_quick_action(index)
			return
		current_id += 1
	if slot.get("interactable", false):
		if action_id == current_id:
			_quick_action(index)
			return
		current_id += 1

	if action_id == current_id:
		_drop_item(index, false)
	elif action_id == current_id + 1:
		_drop_item(index, true)


func _show_item_details(slot: Dictionary) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = str(slot.get("name", slot.get("key", "物品")))
	dialog.ok_button_text = "关闭"
	var details := Label.new()
	details.custom_minimum_size = Vector2(330, 0)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.text = _format_item_details(slot)
	dialog.add_child(details)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(400, 320))


func _format_item_details(slot: Dictionary) -> String:
	var lines: Array[String] = []
	var description := str(slot.get("description", ""))
	if not description.is_empty():
		lines.append(description)
	var count := _to_int(slot.get("count", 1))
	lines.append("数量：%d" % count)
	if slot.has("level"):
		lines.append("需求等级：%d" % _to_int(slot.get("level", 0)))
	if slot.has("skill"):
		lines.append("需求技能：%s" % str(slot.get("skill", "")))
	if slot.has("attackRange"):
		lines.append("攻击范围：%d 格" % _to_int(slot.get("attackRange", 1)))
	if slot.has("attackRate"):
		lines.append("攻击速度：%d" % _to_int(slot.get("attackRate", 0)))
	lines.append(_format_stat_group("攻击", slot.get("attackStats", {}), ["crush", "slash", "stab", "archery", "magic"]).strip_edges())
	lines.append(_format_stat_group("防御", slot.get("defenseStats", {}), ["crush", "slash", "stab", "archery", "magic"]).strip_edges())
	lines.append(_format_stat_group("加成", slot.get("bonuses", {}), ["accuracy", "strength", "archery", "magic"]).strip_edges())
	var enchants: Dictionary = slot.get("enchantments", {})
	if not enchants.is_empty():
		var values: Array[String] = []
		for enchantment_key: Variant in enchants:
			var enchantment: Variant = enchants[enchantment_key]
			var level := _to_int(enchantment.get("level", 0)) if enchantment is Dictionary else _to_int(enchantment)
			values.append("%s +%d" % [str(enchantment_key), level])
		lines.append("附魔：%s" % ", ".join(values))
	return "\n".join(lines.filter(func(line: String) -> bool: return not line.is_empty()))


func _format_stat_group(title: String, values: Variant, keys: Array[String]) -> String:
	if not values is Dictionary:
		return ""
	var parts: Array[String] = []
	for stat_key: String in keys:
		var value := _to_int(values.get(stat_key, 0))
		if value != 0:
			parts.append("%s %s%d" % [stat_key, "+" if value > 0 else "", value])
	return "\n%s：%s" % [title, ", ".join(parts)] if not parts.is_empty() else ""


## 丢弃物品（1 个或全部）。
func _drop_item(index: int, drop_all: bool) -> void:
	var slot: Dictionary = GameState.inventory.get(index, {})
	var count := _to_int(slot.get("count", 1)) if drop_all else 1

	Network.send_packet(Packets.CONTAINER, {
		"opcode": Opcodes.Containers.REMOVE,
		"type": 1, # ContainerType.Inventory
		"fromIndex": index,
		"value": count,
	})
