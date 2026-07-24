class_name CharacterUI
extends DraggablePanel
## 角色面板：属性 + 技能 双标签页。C 键开关。

## 显示的技能列表（排除制作子类 Chiseling/Smelting）。
const DISPLAY_SKILLS: Array[int] = [
	Modules.Skills.HEALTH,
	Modules.Skills.ACCURACY,
	Modules.Skills.STRENGTH,
	Modules.Skills.DEFENSE,
	Modules.Skills.ARCHERY,
	Modules.Skills.MAGIC,
	Modules.Skills.LUMBERJACKING,
	Modules.Skills.MINING,
	Modules.Skills.FISHING,
	Modules.Skills.COOKING,
	Modules.Skills.SMITHING,
	Modules.Skills.CRAFTING,
	Modules.Skills.FLETCHING,
	Modules.Skills.FORAGING,
	Modules.Skills.EATING,
	Modules.Skills.LOITERING,
	Modules.Skills.ALCHEMY,
]

var _tab: TabContainer
## 属性页控件。
var _name_label: Label
var _level_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _mp_bar: ProgressBar
var _mp_label: Label
var _exp_bar: ProgressBar
var _exp_label: Label
## 技能页容器。
var _skills_list: VBoxContainer
## 技能行控件缓存 {type: {level, bar}}
var _skill_rows := {}


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(280, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	_tab = TabContainer.new()
	margin.add_child(_tab)

	_build_stats_tab()
	_build_skills_tab()

	GameState.experience_updated.connect(refresh)
	GameState.skills_updated.connect(refresh)


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


## 显示指定标签页（0=属性，1=技能），供服务端 InterfacePacket 路由调用。
func show_tab(index: int) -> void:
	visible = true
	_tab.current_tab = clampi(index, 0, _tab.get_tab_count() - 1)
	refresh()


## 属性页。
func _build_stats_tab() -> void:
	var page := VBoxContainer.new()
	page.name = "属性"
	page.add_theme_constant_override("separation", 8)
	_tab.add_child(page)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 16)
	page.add_child(_name_label)

	_level_label = Label.new()
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(_level_label)

	_hp_bar = _make_bar(page, Color(0.85, 0.25, 0.25))
	_hp_label = _make_bar_label(_hp_bar)

	_mp_bar = _make_bar(page, Color(0.25, 0.5, 0.95))
	_mp_label = _make_bar_label(_mp_bar)

	_exp_bar = _make_bar(page, Color(0.95, 0.75, 0.2))
	_exp_label = _make_bar_label(_exp_bar)


func _make_bar(parent: Control, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 20)
	bar.show_percentage = false

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)

	parent.add_child(bar)
	return bar


func _make_bar_label(bar: ProgressBar) -> Label:
	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	bar.add_child(label)
	return label


## 技能页。
func _build_skills_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "技能"
	_tab.add_child(scroll)

	_skills_list = VBoxContainer.new()
	_skills_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skills_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_skills_list)

	for skill_type: int in DISPLAY_SKILLS:
		_skill_rows[skill_type] = _create_skill_row(skill_type)


func _create_skill_row(skill_type: int) -> Dictionary:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var header := HBoxContainer.new()
	row.add_child(header)

	var name_label := Label.new()
	name_label.text = Modules.SKILL_NAMES.get(skill_type, "?")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var level_label := Label.new()
	level_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	header.add_child(level_label)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 6)
	bar.show_percentage = false
	bar.max_value = 100
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.4, 0.7, 0.4)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)

	_skills_list.add_child(row)
	return { "level": level_label, "bar": bar }


## 刷新全部数据。
func refresh() -> void:
	if not visible:
		return
	_refresh_stats()
	_refresh_skills()


func _refresh_stats() -> void:
	var data := GameState.player_data
	if data.is_empty():
		return

	_name_label.text = str(data.get("name", ""))
	_level_label.text = "等级 %d" % int(data.get("level", 1))

	var hp := int(data.get("hitPoints", 0))
	var max_hp := int(data.get("maxHitPoints", 1))
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_hp_label.text = "生命 %d / %d" % [hp, max_hp]

	var mana := int(data.get("mana", 0))
	var max_mana := int(data.get("maxMana", 1))
	_mp_bar.max_value = maxi(max_mana, 1)
	_mp_bar.value = mana
	_mp_label.text = "魔法 %d / %d" % [mana, max_mana]

	var exp_val := int(data.get("experience", 0))
	var next_exp := int(data.get("nextExperience", 0))
	if next_exp > 0:
		var prev_exp := int(data.get("prevExperience", 0))
		_exp_bar.max_value = next_exp - prev_exp
		_exp_bar.value = exp_val - prev_exp
		_exp_label.text = "经验 %d / %d" % [exp_val, next_exp]
	else:
		_exp_bar.max_value = 1
		_exp_bar.value = 1
		_exp_label.text = "经验已满级"


func _refresh_skills() -> void:
	for skill_type: int in DISPLAY_SKILLS:
		var row: Dictionary = _skill_rows[skill_type]
		if not GameState.skills.has(skill_type):
			row.level.text = "Lv 1"
			row.bar.value = 0
			continue

		var skill: Dictionary = GameState.skills[skill_type]
		row.level.text = "Lv %d" % int(skill.get("level", 1))
		row.bar.value = float(skill.get("percentage", 0.0))
