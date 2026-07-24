extends Control
## 登录界面主控制器。
## 实现与服务端一致的握手/登录流程：
##   连接 -> 收到 Connected -> 发送 Handshake(gVer)
##   -> 收到 Handshake(instance/serverId) -> 发送 Login -> 收到 Welcome

## 与服务端 config.gver 保持一致（.env 中的 GVER）。
const GVER := "0.5.5-beta"

@onready var _host_input: LineEdit = %HostInput
@onready var _port_input: LineEdit = %PortInput
@onready var _username_input: LineEdit = %UsernameInput
@onready var _password_input: LineEdit = %PasswordInput
@onready var _email_input: LineEdit = %EmailInput
@onready var _status_label: Label = %StatusLabel
@onready var _login_button: Button = %LoginButton
@onready var _guest_button: Button = %GuestButton
@onready var _register_button: Button = %RegisterButton

var _guest := false
var _registering := false
var _server_id := -1
var _instance := ""


func _ready() -> void:
	Network.packet_received.connect(_on_packet_received)
	Network.socket_opened.connect(_on_socket_opened)
	Network.socket_closed.connect(_on_socket_closed)
	_login_button.pressed.connect(_on_login_pressed)
	_guest_button.pressed.connect(_on_guest_pressed)
	_register_button.pressed.connect(_on_register_pressed)
	_set_status("未连接")


func _on_login_pressed() -> void:
	_guest = false
	_start_connect()


func _on_guest_pressed() -> void:
	_guest = true
	_registering = false
	_start_connect()


func _on_register_pressed() -> void:
	# 首次点击展开邮箱栏进入注册模式，再次点击执行注册。
	if not _registering:
		_registering = true
		_email_input.visible = true
		_email_input.get_parent().get_child(_email_input.get_index() - 1).visible = true
		_register_button.text = "确认注册"
		_login_button.disabled = true
		_guest_button.disabled = true
		_set_status("填写用户名/密码/邮箱后点击确认注册")
		return

	if _email_input.text.strip_edges().is_empty():
		_set_status("注册需要填写邮箱")
		return

	_guest = false
	_start_connect()


func _start_connect() -> void:
	var host := _host_input.text.strip_edges()
	var port := int(_port_input.text.strip_edges())

	if host.is_empty() or port <= 0:
		_set_status("服务器地址或端口无效")
		return

	if not _guest:
		if _username_input.text.strip_edges().is_empty():
			_set_status("请输入用户名")
			return
		if _password_input.text.is_empty():
			_set_status("请输入密码")
			return

	# Autoload 会跨登录场景保留，发起新会话前必须清除上一角色的背包和实体缓存。
	GameState.reset()
	_set_busy(true)
	_set_status("正在连接服务器……")

	var err := Network.connect_to_server(host, port)
	if err != OK:
		_set_busy(false)
		_set_status("连接失败（错误码 %d）" % err)


func _on_socket_opened() -> void:
	_set_status("已连接，等待握手……")


func _on_socket_closed(code: int, reason: String) -> void:
	_set_busy(false)
	if code == 1010 and not reason.is_empty():
		_set_status("服务器拒绝连接：%s" % _translate_reject_reason(reason))
	else:
		_set_status("连接已断开（code %d）" % code)


func _on_packet_received(packet_id: int, args: Array) -> void:
	match packet_id:
		Packets.CONNECTED:
			_handle_connected()
		Packets.HANDSHAKE:
			_handle_handshake(args[0] as Dictionary)
		Packets.WELCOME:
			_handle_welcome(args[0] as Dictionary)


## 服务端下发 Connected，开始发送握手包。
func _handle_connected() -> void:
	Network.send_packet(Packets.HANDSHAKE, { "gVer": GVER })
	_set_status("正在握手……")


## 握手成功，服务端返回 instance / serverId，随后发送登录包。
func _handle_handshake(data: Dictionary) -> void:
	_instance = data.get("instance", "")
	_server_id = int(data.get("serverId", -1))
	_set_status("握手成功，正在登录……")

	if _guest:
		Network.send_packet(Packets.LOGIN, { "opcode": Opcodes.Login.GUEST })
		return

	var username := _username_input.text.strip_edges()
	var password := _password_input.text

	if _registering:
		Network.send_packet(Packets.LOGIN, {
			"opcode": Opcodes.Login.REGISTER,
			"username": username,
			"password": password,
			"email": _email_input.text.strip_edges(),
		})
		return

	Network.send_packet(Packets.LOGIN, {
		"opcode": Opcodes.Login.LOGIN,
		"username": username,
		"password": password,
	})


## 登录成功，收到玩家完整数据。切换到游戏场景。
func _handle_welcome(data: Dictionary) -> void:
	_set_busy(false)
	var player_name := str(data.get("name", ""))
	_set_status("登录成功！角色：%s，正在进入游戏……" % player_name)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _set_status(text: String) -> void:
	_status_label.text = text


func _set_busy(busy: bool) -> void:
	_login_button.disabled = busy
	_guest_button.disabled = busy


func _translate_reject_reason(reason: String) -> String:
	match reason:
		"updated": return "客户端版本过旧，请更新"
		"loggedin": return "该账号已在线"
		"invalidpassword": return "密码不符合要求"
		"worldfull": return "服务器已满"
		"timeout": return "连接超时"
		"ratelimit": return "请求过于频繁"
		"disallowed": return "服务器暂时不接受连接"
		"lost": return "握手未完成"
		_: return reason
