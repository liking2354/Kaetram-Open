extends SceneTree
## 登录流程冒烟测试（无头运行）。
## 用法：
##   Godot --headless --path . -s tests/test_login.gd -- [host] [port] [username] [password]
## 不带用户名时以访客身份登录。
## 输出 [TEST] 前缀日志，成功打印 TEST_PASS 后退出码 0，失败打印 TEST_FAIL 退出码 1。

const NetworkManagerScript := preload("res://scripts/network/network_manager.gd")
const GVER := "0.5.5-beta"

var _net: Node
var _done := false
var _success := false
var _start_msec := 0
var _timeout_msec := 20000 # 20 秒真实时间超时

var _host := "127.0.0.1"
var _port := 9001
var _username := ""
var _password := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		_host = args[0]
		_port = int(args[1])
	if args.size() >= 4:
		_username = args[2]
		_password = args[3]

	_net = NetworkManagerScript.new()
	root.add_child(_net)

	_net.packet_received.connect(_on_packet_received)
	_net.socket_opened.connect(func() -> void: _log("socket opened"))
	_net.socket_closed.connect(_on_socket_closed)

	_log("connecting to %s:%d ..." % [_host, _port])
	var err: Error = _net.connect_to_server(_host, _port)
	if err != OK:
		_fail("connect_to_server error: %d" % err)


func _process(_delta: float) -> bool:
	if _start_msec == 0:
		_start_msec = Time.get_ticks_msec()
	if Time.get_ticks_msec() - _start_msec > _timeout_msec:
		_fail("timeout waiting for login flow")
	return _done


func _on_packet_received(packet_id: int, args: Array) -> void:
	match packet_id:
		Packets.CONNECTED:
			_log("CONNECTED received, sending handshake ...")
			_net.send_packet(Packets.HANDSHAKE, { "gVer": GVER })
		Packets.HANDSHAKE:
			_log("HANDSHAKE received: %s" % JSON.stringify(args))
			if _username.is_empty():
				_net.send_packet(Packets.LOGIN, { "opcode": Opcodes.Login.GUEST })
				_log("sent guest login ...")
			else:
				_net.send_packet(Packets.LOGIN, {
					"opcode": Opcodes.Login.LOGIN,
					"username": _username,
					"password": _password,
				})
				_log("sent account login for %s ..." % _username)
		Packets.WELCOME:
			_log("WELCOME received: %s" % JSON.stringify(args[0]).left(300))
			_pass("login flow completed")
		Packets.MAP:
			_log("MAP packet received (regions data)")
		Packets.SPAWN:
			_log("SPAWN packet received")


func _on_socket_closed(code: int, reason: String) -> void:
	if _done:
		return
	_fail("socket closed: code=%d reason=%s" % [code, reason])


func _log(msg: String) -> void:
	print("[TEST] %s" % msg)


func _pass(msg: String) -> void:
	print("[TEST] TEST_PASS: %s" % msg)
	_success = true
	_done = true
	quit(0)


func _fail(msg: String) -> void:
	print("[TEST] TEST_FAIL: %s" % msg)
	_done = true
	quit(1)
