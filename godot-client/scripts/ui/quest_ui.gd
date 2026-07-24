class_name QuestUI
extends DraggablePanel
## 任务接取确认界面：由服务端 Quest.Start 包触发，确认后仅提交任务 key。

var _title_label: Label
var _difficulty_label: Label
var _description_label: Label
var _requirements_label: Label
var _rewards_label: Label
var _accept_button: Button
var _active_key := ""


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(390, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_title_label)

	_difficulty_label = Label.new()
	_difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_label.add_theme_font_size_override("font_size", 11)
	_difficulty_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	vbox.add_child(_difficulty_label)

	var separator := HSeparator.new()
	vbox.add_child(separator)

	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_font_size_override("font_size", 12)
	_description_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(_description_label)

	_requirements_label = Label.new()
	_requirements_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_requirements_label.add_theme_font_size_override("font_size", 11)
	_requirements_label.add_theme_color_override("font_color", Color(0.75, 0.8, 1.0))
	vbox.add_child(_requirements_label)

	_rewards_label = Label.new()
	_rewards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rewards_label.add_theme_font_size_override("font_size", 11)
	_rewards_label.add_theme_color_override("font_color", Color(0.5, 0.95, 0.5))
	vbox.add_child(_rewards_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	vbox.add_child(buttons)

	var cancel_button := Button.new()
	cancel_button.text = "稍后再说"
	cancel_button.pressed.connect(_close)
	buttons.add_child(cancel_button)

	_accept_button = Button.new()
	_accept_button.text = "接受任务"
	_accept_button.pressed.connect(_accept)
	buttons.add_child(_accept_button)

	GameState.quest_start_requested.connect(show_quest)


func show_quest(quest: Dictionary) -> void:
	_active_key = str(quest.get("key", ""))
	if _active_key.is_empty():
		return

	_title_label.text = str(quest.get("name", _active_key))
	var difficulty := str(quest.get("difficulty", ""))
	_difficulty_label.text = "难度：%s" % difficulty if not difficulty.is_empty() else ""
	_description_label.text = _format_description(str(quest.get("description", "")))
	_requirements_label.text = _format_requirements(quest)
	_rewards_label.text = _format_rewards(quest.get("rewards", []))
	_accept_button.disabled = false
	visible = true


func hide_quest() -> void:
	_close()


func _accept() -> void:
	if _active_key.is_empty():
		return
	Network.send_packet(Packets.QUEST, { "key": _active_key })
	_accept_button.disabled = true
	visible = false
	_active_key = ""


func _close() -> void:
	visible = false
	_active_key = ""


func _format_description(description: String) -> String:
	if description.is_empty():
		return "与 NPC 对话以开始这项任务。"
	var parts := description.split("|", false)
	return str(parts[parts.size() - 1]) if parts.size() > 1 else description


func _format_requirements(quest: Dictionary) -> String:
	var lines: Array[String] = []
	var skill_requirements: Dictionary = quest.get("skillRequirements", {})
	for skill_key: String in skill_requirements:
		lines.append("技能要求：%s %d" % [skill_key, int(skill_requirements[skill_key])])
	var quest_requirements: Array = quest.get("questRequirements", [])
	if not quest_requirements.is_empty():
		lines.append("前置任务：%s" % ", ".join(quest_requirements))
	return "\n".join(lines)


func _format_rewards(rewards: Variant) -> String:
	if not rewards is Array or rewards.is_empty():
		return ""
	var values: Array[String] = []
	for reward: Variant in rewards:
		values.append(str(reward))
	return "奖励：%s" % ", ".join(values)
