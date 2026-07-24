extends Node
## 聊天冒烟测试（场景方式运行）。
## 流程：访客登录 -> 加载地图 -> 发送聊天 -> 验证服务端回广播收到。

const MapManagerScript := preload("res://scripts/map/map_manager.gd")
const GVER := "0.5.5-beta"
const TIMEOUT := 30.0
const TEST_MESSAGE := "你好，Kaetram！"

var _done := false
var _elapsed := 0.0


func _ready() -> void:
	Network.packet_received.connect(_on_packet_received)
	Network.socket_closed.connect(_on_socket_closed)
	GameState.map_loaded.connect(_on_map_loaded, CONNECT_ONE_SHOT)
	GameState.chat_received.connect(_on_chat_received)

	Network.connect_to_server("82.157.143.36", 9001)


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	if _elapsed > TIMEOUT:
		_fail("timeout waiting for chat echo")


func _on_packet_received(packet_id: int, _args: Array) -> void:
	match packet_id:
		Packets.CONNECTED:
			Network.send_packet(Packets.HANDSHAKE, { "gVer": GVER })
		Packets.HANDSHAKE:
			Network.send_packet(Packets.LOGIN, { "opcode": Opcodes.Login.GUEST })


func _on_map_loaded(_regions: Dictionary) -> void:
	_log("map loaded, sending chat ...")
	Network.send_packet(Packets.CHAT, [TEST_MESSAGE])


func _on_chat_received(info: Dictionary) -> void:
	var message := str(info.get("message", ""))
	_log("chat received: %s (bubble=%s)" % [message, info.get("withBubble")])

	if message == TEST_MESSAGE:
		_pass("chat echo received")


func _on_socket_closed(code: int, reason: String) -> void:
	if not _done:
		_fail("socket closed: %d %s" % [code, reason])


func _log(msg: String) -> void:
	print("[TEST] %s" % msg)


func _pass(msg: String) -> void:
	print("[TEST] TEST_PASS: %s" % msg)
	_done = true
	get_tree().quit(0)


func _fail(msg: String) -> void:
	print("[TEST] TEST_FAIL: %s" % msg)
	_done = true
	get_tree().quit(1)
