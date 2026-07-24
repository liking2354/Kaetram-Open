class_name FriendsUI
extends DraggablePanel
## 好友面板：好友列表（在线状态）+ 添加/删除。F 键开关。

signal private_message_requested(username: String)

var _list: VBoxContainer
var _name_input: LineEdit


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(260, 320)

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
	title.text = "好友"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)

	# 添加好友行。
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	vbox.add_child(add_row)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "输入玩家名"
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(_name_input)

	var add_button := Button.new()
	add_button.text = "添加"
	add_button.pressed.connect(_on_add_pressed)
	add_row.add_child(add_button)

	# 好友列表。
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	GameState.friends_updated.connect(refresh)


func toggle() -> void:
	visible = not visible
	if visible:
		# 好友列表由登录和状态推送同步；服务端不接受客户端 Friends.List 请求。
		refresh()


func refresh() -> void:
	if not visible:
		return

	for child: Node in _list.get_children():
		child.queue_free()

	if GameState.friends.is_empty():
		var hint := Label.new()
		hint.text = "暂无好友"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_list.add_child(hint)
		return

	for username: String in GameState.friends:
		_list.add_child(_make_friend_row(username))


func _make_friend_row(username: String) -> Control:
	var info: Dictionary = GameState.friends[username]
	var online := bool(info.get("online", false))

	var row := HBoxContainer.new()

	var status := Label.new()
	status.text = "●"
	status.add_theme_color_override(
		"font_color",
		Color(0.4, 0.9, 0.4) if online else Color(0.4, 0.4, 0.4)
	)
	row.add_child(status)

	var name_label := Label.new()
	name_label.text = username
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not online:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	row.add_child(name_label)

	if online:
		var message_button := Button.new()
		message_button.text = "私聊"
		message_button.add_theme_font_size_override("font_size", 10)
		message_button.pressed.connect(_on_message_pressed.bind(username))
		row.add_child(message_button)

	var remove_button := Button.new()
	remove_button.text = "删除"
	remove_button.add_theme_font_size_override("font_size", 10)
	remove_button.pressed.connect(_remove_friend.bind(username))
	row.add_child(remove_button)
	return row


func _on_message_pressed(username: String) -> void:
	private_message_requested.emit(username)


func _on_add_pressed() -> void:
	var username := _name_input.text.strip_edges()
	if username.is_empty():
		return
	Network.send_packet(Packets.FRIENDS, {
		"opcode": Opcodes.Friends.ADD,
		"username": username,
	})
	_name_input.clear()


func _remove_friend(username: String) -> void:
	Network.send_packet(Packets.FRIENDS, {
		"opcode": Opcodes.Friends.REMOVE,
		"username": username,
	})
