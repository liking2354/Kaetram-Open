class_name EquipmentUI
extends DraggablePanel
## 装备面板：展示 12 个服务端装备槽、汇总属性、卸装与攻击样式。

const SLOT_NAMES: Array[String] = [
	"头盔", "项链", "箭矢", "胸甲", "武器", "盾牌",
	"戒指", "护甲皮肤", "武器皮肤", "护腿", "披风", "靴子",
]
const STAT_KEYS: Array[String] = ["crush", "slash", "stab", "archery", "magic"]
const STAT_NAMES: Array[String] = ["粉碎", "劈砍", "刺击", "箭术", "魔法"]
const BONUS_KEYS: Array[String] = ["accuracy", "strength", "archery", "magic"]
const BONUS_NAMES: Array[String] = ["精准", "力量", "箭术", "魔法"]
const ATTACK_STYLE_NAMES := {
	Modules.AttackStyle.NONE: "无",
	Modules.AttackStyle.STAB: "刺击",
	Modules.AttackStyle.SLASH: "劈砍",
	Modules.AttackStyle.DEFENSIVE: "防御",
	Modules.AttackStyle.CRUSH: "粉碎",
	Modules.AttackStyle.SHARED: "均衡",
	Modules.AttackStyle.HACK: "重砍",
	Modules.AttackStyle.CHOP: "斩击",
	Modules.AttackStyle.ACCURATE: "精准",
	Modules.AttackStyle.FAST: "快速",
	Modules.AttackStyle.FOCUSED: "专注",
	Modules.AttackStyle.LONG_RANGE: "远距",
}

var _slot_grid: GridContainer
var _attack_stats: VBoxContainer
var _defense_stats: VBoxContainer
var _bonus_stats: VBoxContainer
var _style_option: OptionButton
var _style_label: Label
var _slot_widgets: Dictionary = {}
var _setting_style := false


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(520, 455)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var title := Label.new()
	title.text = "装备"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	root.add_child(title)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	var equipment_side := VBoxContainer.new()
	equipment_side.custom_minimum_size = Vector2(255, 0)
	body.add_child(equipment_side)

	var hint := Label.new()
	hint.text = "点击已装备物品可卸下"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	equipment_side.add_child(hint)

	_slot_grid = GridContainer.new()
	_slot_grid.columns = 3
	_slot_grid.add_theme_constant_override("h_separation", 5)
	_slot_grid.add_theme_constant_override("v_separation", 5)
	equipment_side.add_child(_slot_grid)
	for slot_type: int in SLOT_NAMES.size():
		_slot_widgets[slot_type] = _make_slot(slot_type)

	var stats_side := VBoxContainer.new()
	stats_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_side.add_theme_constant_override("separation", 6)
	body.add_child(stats_side)

	var style_title := Label.new()
	style_title.text = "攻击样式"
	stats_side.add_child(style_title)
	_style_option = OptionButton.new()
	_style_option.disabled = true
	_style_option.item_selected.connect(_on_style_selected)
	stats_side.add_child(_style_option)
	_style_label = Label.new()
	_style_label.add_theme_font_size_override("font_size", 10)
	_style_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	stats_side.add_child(_style_label)

	_attack_stats = _make_stats_section(stats_side, "攻击属性")
	_defense_stats = _make_stats_section(stats_side, "防御属性")
	_bonus_stats = _make_stats_section(stats_side, "额外加成")

	GameState.equipment_updated.connect(refresh)


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


func show_equipment() -> void:
	visible = true
	refresh()


func refresh() -> void:
	if not visible:
		return
	var equipments := _equipment_by_type()
	for slot_type: int in SLOT_NAMES.size():
		_fill_slot(slot_type, equipments.get(slot_type, {}))
	_refresh_stats(equipments)
	_refresh_attack_styles(equipments.get(Modules.Equipment.WEAPON, {}))


func _make_slot(slot_type: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(78, 70)
	panel.tooltip_text = SLOT_NAMES[slot_type]
	panel.gui_input.connect(_on_slot_input.bind(slot_type))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.19, 0.9)
	style.border_color = Color(0.38, 0.32, 0.24)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(42, 42)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(icon)

	var label := Label.new()
	label.text = SLOT_NAMES[slot_type]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)

	_slot_grid.add_child(panel)
	return { "panel": panel, "icon": icon, "label": label }


func _fill_slot(slot_type: int, equipment: Dictionary) -> void:
	var widgets: Dictionary = _slot_widgets[slot_type]
	var icon: TextureRect = widgets["icon"]
	var label: Label = widgets["label"]
	var panel: PanelContainer = widgets["panel"]
	var key := str(equipment.get("key", ""))
	icon.texture = SpriteLibrary.get_item_texture("items/%s" % key) if not key.is_empty() else null
	label.text = str(equipment.get("name", SLOT_NAMES[slot_type])) if not key.is_empty() else SLOT_NAMES[slot_type]
	panel.tooltip_text = _equipment_tooltip(slot_type, equipment)


func _equipment_tooltip(slot_type: int, equipment: Dictionary) -> String:
	var key := str(equipment.get("key", ""))
	if key.is_empty():
		return "%s：空" % SLOT_NAMES[slot_type]
	var text := "%s\n%s" % [SLOT_NAMES[slot_type], str(equipment.get("name", key))]
	var count := int(equipment.get("count", 1))
	if count > 1:
		text += " x%d" % count
	var enchants: Dictionary = equipment.get("enchantments", {})
	if not enchants.is_empty():
		text += "\n附魔："
		for enchantment: Variant in enchants:
			var info: Variant = enchants[enchantment]
			var level := int(info.get("level", 0)) if info is Dictionary else int(info)
			text += " %s+%d" % [str(enchantment), level]
	text += "\n点击卸下"
	return text


func _on_slot_input(event: InputEvent, slot_type: int) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var equipment: Dictionary = _equipment_by_type().get(slot_type, {})
	if str(equipment.get("key", "")).is_empty():
		return
	Network.send_packet(Packets.EQUIPMENT, {
		"opcode": Opcodes.Equipment.UNEQUIP,
		"type": slot_type,
	})


func _make_stats_section(parent: Control, title_text: String) -> VBoxContainer:
	var title := Label.new()
	title.text = title_text
	title.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	parent.add_child(title)
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 1)
	parent.add_child(section)
	return section


func _refresh_stats(equipments: Dictionary) -> void:
	var attack := _sum_stats(equipments, "attackStats", STAT_KEYS)
	var defense := _sum_stats(equipments, "defenseStats", STAT_KEYS)
	var bonuses := _sum_stats(equipments, "bonuses", BONUS_KEYS)
	_fill_stat_section(_attack_stats, STAT_NAMES, STAT_KEYS, attack)
	_fill_stat_section(_defense_stats, STAT_NAMES, STAT_KEYS, defense)
	_fill_stat_section(_bonus_stats, BONUS_NAMES, BONUS_KEYS, bonuses)


func _sum_stats(equipments: Dictionary, data_key: String, keys: Array[String]) -> Dictionary:
	var totals := {}
	for key: String in keys:
		totals[key] = 0
	for slot_type: int in equipments:
		var stat_data: Dictionary = equipments[slot_type].get(data_key, {})
		for key: String in keys:
			totals[key] += int(stat_data.get(key, 0))
	return totals


func _fill_stat_section(section: VBoxContainer, names: Array[String], keys: Array[String], values: Dictionary) -> void:
	for child: Node in section.get_children():
		child.queue_free()
	for index: int in keys.size():
		var value := int(values.get(keys[index], 0))
		var label := Label.new()
		label.text = "%s：%s%d" % [names[index], "+" if value >= 0 else "", value]
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.75, 0.9, 0.75) if value > 0 else Color(0.75, 0.75, 0.75))
		section.add_child(label)


func _refresh_attack_styles(weapon: Dictionary) -> void:
	_setting_style = true
	_style_option.clear()
	var styles: Array = weapon.get("attackStyles", [])
	var current_style := int(GameState.player_data.get("attackStyle", weapon.get("attackStyle", Modules.AttackStyle.NONE)))
	for style: Variant in styles:
		var style_value := int(style)
		_style_option.add_item(str(ATTACK_STYLE_NAMES.get(style_value, "样式 %d" % style_value)))
		_style_option.set_item_metadata(_style_option.item_count - 1, style_value)
		if style_value == current_style:
			_style_option.select(_style_option.item_count - 1)
	_style_option.disabled = styles.is_empty()
	var attack_range := int(GameState.player_data.get("attackRange", weapon.get("attackRange", 1)))
	_style_label.text = "攻击范围：%d 格" % attack_range if not styles.is_empty() else "装备武器后可选择攻击样式"
	_setting_style = false


func _on_style_selected(index: int) -> void:
	if _setting_style or index < 0:
		return
	var style := int(_style_option.get_item_metadata(index))
	Network.send_packet(Packets.EQUIPMENT, {
		"opcode": Opcodes.Equipment.STYLE,
		"style": style,
	})


func _equipment_by_type() -> Dictionary:
	var result := {}
	for equipment: Variant in GameState.player_data.get("equipments", []):
		if equipment is Dictionary:
			var slot_type := int(equipment.get("type", -1))
			if slot_type >= 0 and slot_type < SLOT_NAMES.size():
				result[slot_type] = equipment
	return result
