extends Node
## 可视化冒烟测试（真实窗口运行，非无头）。
## 用法：Godot --path . res://tests/test_visual.tscn
## 流程：访客登录远程服务器 -> 进入游戏场景 -> 等待渲染 -> 截图 -> 退出。

const GVER := "0.5.5-beta"
## 截图保存路径。
const SCREENSHOT_PATH := "/tmp/kaetram_visual.png"
## 进入游戏后等待的截图时间（秒）。
const CAPTURE_DELAY := 6.0

var _elapsed := 0.0
var _phase := 0


func _ready() -> void:
	Network.packet_received.connect(_on_packet_received)
	Network.socket_closed.connect(func(code: int, reason: String) -> void:
		_fail("socket closed: %d %s" % [code, reason]))
	GameState.map_loaded.connect(_on_map_loaded, CONNECT_ONE_SHOT)

	_log("connecting to remote server ...")
	Network.connect_to_server("82.157.143.36", 9001)


func _on_packet_received(packet_id: int, _args: Array) -> void:
	match packet_id:
		Packets.CONNECTED:
			Network.send_packet(Packets.HANDSHAKE, { "gVer": GVER })
		Packets.HANDSHAKE:
			Network.send_packet(Packets.LOGIN, { "opcode": Opcodes.Login.GUEST })
			_log("guest login sent ...")


func _on_map_loaded(_regions: Dictionary) -> void:
	_log("map loaded, entering game scene ...")
	_phase = 1
	# 实例化游戏场景而非切换场景，保持本测试脚本存活以便截图。
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	add_child(game_scene.instantiate())


func _process(delta: float) -> void:
	if _phase != 1:
		return

	_elapsed += delta
	if _elapsed > CAPTURE_DELAY:
		_phase = 2
		_capture()


func _capture() -> void:
	# 等两帧确保渲染完成。
	await get_tree().process_frame
	await get_tree().process_frame

	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(SCREENSHOT_PATH)
	if err != OK:
		_fail("screenshot save failed: %d" % err)
		return

	_log("TEST_PASS: screenshot saved to %s (%dx%d)" % [SCREENSHOT_PATH, image.get_width(), image.get_height()])
	get_tree().quit(0)


func _log(msg: String) -> void:
	print("[TEST] %s" % msg)


func _fail(msg: String) -> void:
	print("[TEST] TEST_FAIL: %s" % msg)
	get_tree().quit(1)
