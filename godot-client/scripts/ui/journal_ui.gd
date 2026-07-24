class_name JournalUI
extends DraggablePanel
## 日志面板：任务列表/详情与按区域分组的成就。

var _tab: TabContainer
var _quest_list: VBoxContainer
var _quest_detail: RichTextLabel
var _achievement_list: VBoxContainer
var _region_option: OptionButton
var _selected_quest_key := ""
var _regions: Array[String] = []


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(540, 440)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	_tab = TabContainer.new()
	margin.add_child(_tab)
	_create_quest_page()
	_create_achievement_page()

	GameState.quests_updated.connect(refresh)
	GameState.achievements_updated.connect(refresh)


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


## 显示指定标签页（0=任务，1=成就），供服务端 InterfacePacket 路由调用。
func show_tab(index: int) -> void:
	visible = true
	_tab.current_tab = clampi(index, 0, _tab.get_tab_count() - 1)
	refresh()


func _create_quest_page() -> void:
	var page := HBoxContainer.new()
	page.name = "任务"
	page.add_theme_constant_override("separation", 10)
	_tab.add_child(page)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(180, 0)
	page.add_child(list_scroll)
	_quest_list = VBoxContainer.new()
	_quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quest_list.add_theme_constant_override("separation", 4)
	list_scroll.add_child(_quest_list)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(detail_scroll)
	_quest_detail = RichTextLabel.new()
	_quest_detail.bbcode_enabled = true
	_quest_detail.fit_content = true
	_quest_detail.scroll_active = false
	_quest_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(_quest_detail)


func _create_achievement_page() -> void:
	var page := VBoxContainer.new()
	page.name = "成就"
	page.add_theme_constant_override("separation", 7)
	_tab.add_child(page)

	_region_option = OptionButton.new()
	_region_option.item_selected.connect(_on_region_selected)
	page.add_child(_region_option)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	_achievement_list = VBoxContainer.new()
	_achievement_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_achievement_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_achievement_list)


func refresh() -> void:
	if not visible:
		return
	_refresh_quests()
	_refresh_achievements()


func _refresh_quests() -> void:
	for child: Node in _quest_list.get_children():
		child.queue_free()
	if GameState.quests.is_empty():
		_quest_detail.text = "暂无任务"
		return

	var keys: Array[String] = []
	for key: String in GameState.quests:
		keys.append(key)
	keys.sort()
	if _selected_quest_key.is_empty() or not GameState.quests.has(_selected_quest_key):
		_selected_quest_key = keys[0]

	for key: String in keys:
		var quest: Dictionary = GameState.quests[key]
		_quest_list.add_child(_make_quest_button(key, quest))
	_show_quest_details(GameState.quests[_selected_quest_key])


func _make_quest_button(key: String, quest: Dictionary) -> Button:
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "%s\n%s" % [str(quest.get("name", key)), _quest_status(quest)]
	button.tooltip_text = "查看任务详情"
	button.toggle_mode = true
	button.button_pressed = key == _selected_quest_key
	button.pressed.connect(_on_quest_selected.bind(key))
	var state := _quest_state(quest)
	if state == 2:
		button.add_theme_color_override("font_color", Color(0.5, 0.95, 0.5))
	elif state == 1:
		button.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	return button


func _on_quest_selected(key: String) -> void:
	_selected_quest_key = key
	_refresh_quests()


func _show_quest_details(quest: Dictionary) -> void:
	var description := str(quest.get("description", ""))
	var pieces := description.split("|", false)
	var short_description := str(pieces[0]) if not pieces.is_empty() else ""
	var full_description := str(pieces[1]) if pieces.size() > 1 else short_description
	var lines: Array[String] = []
	lines.append("[font_size=18][b]%s[/b][/font_size]" % str(quest.get("name", quest.get("key", ""))))
	lines.append("[color=#f2cc66]%s[/color]" % _quest_status(quest))
	if not short_description.is_empty():
		lines.append("[b]%s[/b]" % short_description)
	if not full_description.is_empty() and full_description != short_description:
		lines.append(full_description)

	var rewards: Array = quest.get("rewards", [])
	if not rewards.is_empty():
		lines.append("[color=#8fe68f][b]奖励[/b][/color]\n%s" % "\n".join(rewards))

	var requirements: Array[String] = []
	for quest_key: Variant in quest.get("questRequirements", []):
		var required: Dictionary = GameState.quests.get(str(quest_key), {})
		requirements.append("完成任务：%s" % str(required.get("name", quest_key)))
	var skill_requirements: Dictionary = quest.get("skillRequirements", {})
	for skill_key: String in skill_requirements:
		requirements.append("技能要求：%s %d" % [_format_name(skill_key), int(skill_requirements[skill_key])])
	if requirements.is_empty():
		lines.append("[b]要求[/b]\n无")
	else:
		lines.append("[b]要求[/b]\n%s" % "\n".join(requirements))
	_quest_detail.text = "\n\n".join(lines)


func _quest_state(quest: Dictionary) -> int:
	var stage := int(quest.get("stage", 0))
	var stage_count := int(quest.get("stageCount", 0))
	if stage_count > 0 and stage >= stage_count:
		return 2
	if stage > 0:
		return 1
	return 0


func _quest_status(quest: Dictionary) -> String:
	var state := _quest_state(quest)
	if state == 2:
		return "已完成"
	if state == 1:
		var stage := int(quest.get("stage", 0))
		var stage_count := int(quest.get("stageCount", 0))
		return "进行中 · 阶段 %d/%d" % [stage, stage_count] if stage_count > 0 else "进行中"
	return "未开始"


func _refresh_achievements() -> void:
	_regions = _achievement_regions()
	var previous_region := _region_option.get_item_text(_region_option.selected) if _region_option.item_count > 0 else ""
	_region_option.clear()
	for region: String in _regions:
		_region_option.add_item(region)
	var index := _regions.find(previous_region)
	_region_option.select(maxi(index, 0))
	_render_achievement_region(_regions[maxi(index, 0)] if not _regions.is_empty() else "其他")


func _achievement_regions() -> Array[String]:
	var regions: Array[String] = []
	for key: String in GameState.achievements:
		var region := str(GameState.achievements[key].get("region", "其他"))
		if region.is_empty():
			region = "其他"
		if not regions.has(region):
			regions.append(region)
	regions.sort()
	if regions.has("其他"):
		regions.erase("其他")
		regions.append("其他")
	if regions.is_empty():
		regions.append("其他")
	return regions


func _on_region_selected(index: int) -> void:
	if index >= 0 and index < _regions.size():
		_render_achievement_region(_regions[index])


func _render_achievement_region(region: String) -> void:
	for child: Node in _achievement_list.get_children():
		child.queue_free()
	var any := false
	for key: String in GameState.achievements:
		var achievement: Dictionary = GameState.achievements[key]
		var achievement_region := str(achievement.get("region", "其他"))
		if achievement_region.is_empty():
			achievement_region = "其他"
		if achievement_region != region:
			continue
		any = true
		_achievement_list.add_child(_make_achievement_entry(achievement))
	if not any:
		var hint := Label.new()
		hint.text = "该区域暂无成就"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_achievement_list.add_child(hint)


func _make_achievement_entry(achievement: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	var done := _achievement_finished(achievement)
	style.bg_color = Color(0.25, 0.21, 0.1, 0.85) if done else Color(0.14, 0.14, 0.18, 0.85)
	style.border_color = Color(0.95, 0.72, 0.2) if done else Color(0.35, 0.3, 0.25)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = str(achievement.get("name", achievement.get("key", "")))
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.25) if done else Color.WHITE)
	box.add_child(title)
	var description := Label.new()
	description.text = str(achievement.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 10)
	description.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	box.add_child(description)

	if not done and int(achievement.get("stage", 0)) > 0:
		var count := int(achievement.get("stageCount", 0))
		if count > 1:
			var progress := Label.new()
			progress.text = "%d/%d" % [maxi(int(achievement.get("stage", 0)) - 1, 0), count - 1]
			progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			progress.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
			box.add_child(progress)
	return panel


func _achievement_finished(achievement: Dictionary) -> bool:
	var count := int(achievement.get("stageCount", 0))
	return count > 0 and int(achievement.get("stage", 0)) >= count


func _format_name(value: String) -> String:
	return value.capitalize().replace("_", " ")
