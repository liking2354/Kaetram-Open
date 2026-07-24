class_name ChatUI
extends VBoxContainer
## 聊天界面：消息日志 + 输入框。
## Enter 聚焦输入/发送，Esc 取消聚焦。

## 最大保留消息条数。
const MAX_MESSAGES := 60
## 消息显示颜色默认值。
const DEFAULT_COLOR := "#ffffff"
const RANK_TITLES := {
	1: "Mod", 2: "Admin", 3: "Veteran", 4: "Patron", 5: "Artist",
	6: "Cheater", 7: "T1 Patron", 8: "T2 Patron", 9: "T3 Patron",
	10: "T4 Patron", 11: "T5 Patron", 12: "T6 Patron", 13: "T7 Patron",
	14: "Admin", 15: "Booster",
}

var _log: RichTextLabel
var _input: LineEdit
## 消息缓存（用于颜色渲染）。
var _messages: Array[Dictionary] = []


func _ready() -> void:
	custom_minimum_size = Vector2(380, 0)
	mouse_filter = MOUSE_FILTER_IGNORE

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_active = true
	_log.custom_minimum_size = Vector2(380, 140)
	_log.mouse_filter = MOUSE_FILTER_IGNORE
	_log.fit_content = false
	add_child(_log)

	_input = LineEdit.new()
	_input.placeholder_text = "输入消息，Enter 发送"
	_input.max_length = 256
	_input.visible = false
	_input.mouse_filter = MOUSE_FILTER_STOP
	add_child(_input)

	_input.text_submitted.connect(_on_text_submitted)

	GameState.chat_received.connect(_on_chat_received)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER:
				if _input.has_focus():
					_send()
				else:
					_input.visible = true
					_input.grab_focus()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				if _input.has_focus():
					_release()
					get_viewport().set_input_as_handled()


func _on_text_submitted(_text: String) -> void:
	_send()


func _send() -> void:
	var text := _input.text.strip_edges()
	if not text.is_empty():
		# 服务端在 Chat 包内解析 / 与 ; 命令，必须保留原始前缀。
		Network.send_packet(Packets.CHAT, [text])
	_input.clear()
	_release()


func _release() -> void:
	_input.release_focus()
	_input.visible = false


## 打开输入框并预填指定好友的服务器私聊命令。
func compose_private_message(username: String) -> void:
	if username.is_empty():
		return
	_input.text = "/pm *%s* " % username
	_input.visible = true
	_input.grab_focus()
	_input.caret_column = _input.text.length()


## 服务端下发的聊天消息。
func _on_chat_received(info: Dictionary) -> void:
	var message := str(info.get("message", ""))
	if message.is_empty():
		return

	var source := str(info.get("source", ""))
	var colour := str(info.get("colour", DEFAULT_COLOR))

	# 静态消息（系统/全局）直接显示；玩家消息带名字前缀。
	var sender_name := ""
	if source.is_empty():
		sender_name = _entity_name(str(info.get("instance", "")))
	else:
		sender_name = source

	_append(sender_name, message, colour)


## 将消息追加到日志（带颜色）。
func _append(sender_name: String, message: String, colour: String) -> void:
	_messages.append({ "name": sender_name, "message": message, "colour": colour })
	if _messages.size() > MAX_MESSAGES:
		_messages.pop_front()
	_render()


func _render() -> void:
	_log.clear()
	for msg: Dictionary in _messages:
		_log.push_color(_parse_colour(str(msg.get("colour", DEFAULT_COLOR))))
		var sender := str(msg.get("name", ""))
		if not sender.is_empty():
			_log.add_text("%s: " % sender)
		_log.add_text(str(msg.get("message", "")))
		_log.pop()
		_log.newline()


func _entity_name(instance: String) -> String:
	var data: Dictionary = {}
	if instance == GameState.player_instance:
		data = GameState.player_data
	elif GameState.entities.has(instance):
		data = GameState.entities[instance]
	else:
		return ""

	var entity_name := str(data.get("name", ""))
	var title := str(RANK_TITLES.get(int(data.get("rank", 0)), ""))
	return "[%s] %s" % [title, entity_name] if not title.is_empty() else entity_name


func _parse_colour(value: String) -> Color:
	var text := value.strip_edges()
	if text.begins_with("rgb(") or text.begins_with("rgba("):
		var body := text.substr(text.find("(") + 1).trim_suffix(")")
		var parts := body.split(",", false)
		if parts.size() >= 3:
			var alpha := float(parts[3].strip_edges()) if parts.size() >= 4 else 1.0
			return Color(
				clampf(float(parts[0].strip_edges()) / 255.0, 0.0, 1.0),
				clampf(float(parts[1].strip_edges()) / 255.0, 0.0, 1.0),
				clampf(float(parts[2].strip_edges()) / 255.0, 0.0, 1.0),
				clampf(alpha, 0.0, 1.0)
			)
	return Color.from_string(text, Color.WHITE)
