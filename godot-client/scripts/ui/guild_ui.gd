class_name GuildUI
extends DraggablePanel
## 公会：公共列表、创建、加入、成员管理、在线状态与公会聊天。

const MAX_MEMBERS := 50
const RANK_NAMES := ["新兵", "初级成员", "正式成员", "熟练成员", "资深成员", "精英成员", "大师成员", "领主"]
const BANNER_COLORS := ["grey", "green", "fuchsia", "red", "brown", "cyan", "darkgrey", "teal", "goldenyellow"]
const CRESTS := ["none", "star", "hawk", "phoenix"]

var _tabs: TabContainer
var _browse_page: VBoxContainer
var _member_list: VBoxContainer
var _guild_list: VBoxContainer
var _chat_log: RichTextLabel
var _chat_input: LineEdit
var _guild_name_input: LineEdit
var _banner_color: OptionButton
var _outline_color: OptionButton
var _crest: OptionButton
var _info_label: Label
var _error_label: Label
var _leave_button: Button
var _refresh_button: Button


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(510, 470)

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
	title.text = "公会"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	root.add_child(title)

	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	root.add_child(_info_label)

	_error_label = Label.new()
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.add_theme_font_size_override("font_size", 11)
	_error_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	root.add_child(_error_label)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_tabs)

	_create_browse_page()
	_create_members_page()
	_create_chat_page()

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)

	_refresh_button = Button.new()
	_refresh_button.text = "刷新"
	_refresh_button.pressed.connect(_request_list)
	controls.add_child(_refresh_button)

	_leave_button = Button.new()
	_leave_button.text = "离开公会"
	_leave_button.pressed.connect(_on_leave_pressed)
	controls.add_child(_leave_button)

	GameState.guild_updated.connect(refresh)
	GameState.guild_list_updated.connect(_on_guild_list_updated)
	GameState.guild_chat_received.connect(_on_guild_chat_received)
	GameState.guild_error_received.connect(_on_guild_error_received)


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()
		if not _has_guild():
			_request_list()


func show_guild() -> void:
	visible = true
	refresh()
	if not _has_guild():
		_request_list()


func _create_browse_page() -> void:
	_browse_page = VBoxContainer.new()
	_browse_page.name = "浏览/创建"
	_browse_page.add_theme_constant_override("separation", 8)
	_tabs.add_child(_browse_page)

	var description := Label.new()
	description.text = "公开公会"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_browse_page.add_child(description)

	var guild_scroll := ScrollContainer.new()
	guild_scroll.custom_minimum_size = Vector2(0, 160)
	guild_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_browse_page.add_child(guild_scroll)
	_guild_list = VBoxContainer.new()
	_guild_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_guild_list.add_theme_constant_override("separation", 4)
	guild_scroll.add_child(_guild_list)

	var separator := HSeparator.new()
	_browse_page.add_child(separator)

	var create_title := Label.new()
	create_title.text = "创建公会（需要完成教程与 30,000 金币）"
	create_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	create_title.add_theme_font_size_override("font_size", 11)
	_browse_page.add_child(create_title)

	var create_row := HBoxContainer.new()
	create_row.add_theme_constant_override("separation", 6)
	_browse_page.add_child(create_row)
	_guild_name_input = LineEdit.new()
	_guild_name_input.placeholder_text = "公会名称（3-16 字符）"
	_guild_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_row.add_child(_guild_name_input)
	var create_button := Button.new()
	create_button.text = "创建"
	create_button.pressed.connect(_on_create_pressed)
	create_row.add_child(create_button)

	var decoration_row := HBoxContainer.new()
	decoration_row.add_theme_constant_override("separation", 5)
	_browse_page.add_child(decoration_row)
	_banner_color = _make_option(decoration_row, "旗帜")
	_outline_color = _make_option(decoration_row, "边框")
	_crest = _make_option(decoration_row, "徽章")
	for color: String in BANNER_COLORS:
		_banner_color.add_item(color)
		_outline_color.add_item(color)
	_banner_color.select(0)
	_outline_color.select(BANNER_COLORS.find("goldenyellow"))
	for crest: String in CRESTS:
		_crest.add_item(crest)


func _make_option(parent: Control, label_text: String) -> OptionButton:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 9)
	column.add_child(label)
	var option := OptionButton.new()
	column.add_child(option)
	return option


func _create_members_page() -> void:
	var page := VBoxContainer.new()
	page.name = "成员"
	page.add_theme_constant_override("separation", 6)
	_tabs.add_child(page)

	var hint := Label.new()
	hint.text = "点击其他成员进行晋升、降级或踢出；权限由服务器验证。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	page.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	_member_list = VBoxContainer.new()
	_member_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_member_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_member_list)


func _create_chat_page() -> void:
	var page := VBoxContainer.new()
	page.name = "聊天"
	page.add_theme_constant_override("separation", 6)
	_tabs.add_child(page)

	_chat_log = RichTextLabel.new()
	_chat_log.bbcode_enabled = true
	_chat_log.fit_content = false
	_chat_log.scroll_following = true
	_chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_log.add_theme_font_size_override("normal_font_size", 12)
	page.add_child(_chat_log)

	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "输入公会消息，按 Enter 发送"
	_chat_input.text_submitted.connect(_on_chat_submitted)
	page.add_child(_chat_input)


func refresh() -> void:
	if not visible:
		return
	_clear_error()
	var has_guild := _has_guild()
	var guild: Dictionary = GameState.guild

	_info_label.text = "%s  ·  %d/%d 成员  ·  公会经验 %d" % [
		str(guild.get("name", "未加入公会")),
		guild.get("members", []).size() if has_guild else 0,
		MAX_MEMBERS,
		int(guild.get("experience", 0)),
	]
	_leave_button.visible = has_guild
	_leave_button.text = "解散公会" if _is_owner() else "离开公会"
	_refresh_button.text = "刷新成员" if has_guild else "刷新列表"
	_browse_page.visible = not has_guild
	_tabs.set_tab_hidden(0, has_guild)
	_tabs.set_tab_hidden(1, not has_guild)
	_tabs.set_tab_hidden(2, not has_guild)
	if has_guild and _tabs.current_tab == 0:
		_tabs.current_tab = 1
	elif not has_guild and _tabs.current_tab != 0:
		_tabs.current_tab = 0

	_refresh_members()
	_refresh_guild_list()


func _refresh_members() -> void:
	for child: Node in _member_list.get_children():
		child.queue_free()
	if not _has_guild():
		return

	var members: Array = GameState.guild.get("members", [])
	members.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("rank", 0)) > int(b.get("rank", 0))
	)
	for member: Dictionary in members:
		_member_list.add_child(_make_member_row(member))


func _make_member_row(member: Dictionary) -> Button:
	var username := str(member.get("username", ""))
	var rank := clampi(int(member.get("rank", 0)), 0, RANK_NAMES.size() - 1)
	var online := int(member.get("serverId", -1)) >= 0
	var row := Button.new()
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.text = "%s  [%s]  %s" % [username, RANK_NAMES[rank], "在线" if online else "离线"]
	row.tooltip_text = "点击管理成员" if username != _local_username() else "这是你自己"
	row.disabled = username.is_empty() or username == _local_username()
	row.pressed.connect(_show_member_actions.bind(username, rank))
	return row


func _refresh_guild_list() -> void:
	for child: Node in _guild_list.get_children():
		child.queue_free()
	if _has_guild():
		return

	if GameState.available_guilds.is_empty():
		var empty := Label.new()
		empty.text = "暂无可加入的公开公会"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_guild_list.add_child(empty)
		return

	for guild: Dictionary in GameState.available_guilds:
		var guild_name := str(guild.get("name", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var label := Label.new()
		label.text = "%s  %d/%d" % [guild_name, int(guild.get("members", 0)), MAX_MEMBERS]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var join := Button.new()
		join.text = "加入"
		join.disabled = guild_name.is_empty()
		join.pressed.connect(_join_guild.bind(guild_name.to_lower()))
		row.add_child(join)
		_guild_list.add_child(row)


func _request_list() -> void:
	if _has_guild():
		return
	Network.send_packet(Packets.GUILD, {
		"opcode": Opcodes.Guild.LIST,
		"from": 0,
		"to": 50,
	})


func _join_guild(identifier: String) -> void:
	if identifier.is_empty():
		return
	Network.send_packet(Packets.GUILD, {
		"opcode": Opcodes.Guild.JOIN,
		"identifier": identifier,
	})


func _on_create_pressed() -> void:
	var guild_name := _guild_name_input.text.strip_edges()
	if guild_name.length() < 3 or guild_name.length() > 16:
		_show_error("公会名称必须为 3-16 个字符")
		return
	Network.send_packet(Packets.GUILD, {
		"opcode": Opcodes.Guild.CREATE,
		"name": guild_name,
		"colour": _banner_color.get_item_text(_banner_color.selected),
		"outline": 0,
		"outlineColour": _outline_color.get_item_text(_outline_color.selected),
		"crest": _crest.get_item_text(_crest.selected),
	})
	_guild_name_input.clear()


func _on_leave_pressed() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "确认"
	dialog.dialog_text = "确定要%s吗？" % ("解散公会" if _is_owner() else "离开公会")
	dialog.ok_button_text = "确认"
	dialog.confirmed.connect(_confirm_leave.bind(dialog))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(280, 120))


func _confirm_leave(dialog: ConfirmationDialog) -> void:
	Network.send_packet(Packets.GUILD, { "opcode": Opcodes.Guild.LEAVE })
	dialog.queue_free()


func _show_member_actions(username: String, _rank: int) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "管理成员：%s" % username
	dialog.dialog_text = "服务器会验证你的公会权限。"
	dialog.ok_button_text = "关闭"
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 6)
	dialog.add_child(actions)
	for action: Dictionary in [
		{ "label": "晋升", "opcode": Opcodes.Guild.PROMOTE },
		{ "label": "降级", "opcode": Opcodes.Guild.DEMOTE },
		{ "label": "踢出", "opcode": Opcodes.Guild.KICK },
	]:
		var button := Button.new()
		button.text = str(action["label"])
		button.pressed.connect(_send_member_action.bind(dialog, username, int(action["opcode"])))
		actions.add_child(button)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(330, 140))


func _send_member_action(dialog: ConfirmationDialog, username: String, opcode: int) -> void:
	Network.send_packet(Packets.GUILD, {
		"opcode": opcode,
		"username": username,
	})
	dialog.queue_free()


func _on_chat_submitted(message: String) -> void:
	var content := message.strip_edges()
	if content.is_empty() or not _has_guild():
		return
	Network.send_packet(Packets.GUILD, {
		"opcode": Opcodes.Guild.CHAT,
		"message": content,
	})
	_chat_input.clear()


func _on_guild_list_updated(_guilds: Array, _total: int) -> void:
	if visible:
		_refresh_guild_list()


func _on_guild_chat_received(username: String, server_id: int, message: String) -> void:
	if message.is_empty():
		return
	# 以纯文本插入玩家内容，避免消息中的 BBCode 改写聊天界面。
	_chat_log.push_color(Color("8ac6ff"))
	_chat_log.add_text("[W%d] %s" % [server_id, username])
	_chat_log.pop()
	_chat_log.add_text(" » %s\n" % message)


func _on_guild_error_received(message: String) -> void:
	_show_error(message)


func _show_error(message: String) -> void:
	_error_label.text = message


func _clear_error() -> void:
	_error_label.text = ""


func _has_guild() -> bool:
	return not GameState.guild.is_empty() and not str(GameState.guild.get("name", "")).is_empty()


func _local_username() -> String:
	return str(GameState.player_data.get("username", GameState.player_data.get("name", "")))


func _is_owner() -> bool:
	return _has_guild() and str(GameState.guild.get("owner", "")) == _local_username()
