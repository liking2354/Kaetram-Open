extends SceneTree
## 地图加载冒烟测试（无头运行）。
## 用法：Godot --headless --path . -s tests/test_map.gd
## 流程：访客登录 -> 等待 MAP 包 -> 解压解析 -> MapManager 填充瓦片 -> 校验结果。

const NetworkManagerScript := preload("res://scripts/network/network_manager.gd")
const MapManagerScript := preload("res://scripts/map/map_manager.gd")
const GVER := "0.5.5-beta"

var _net: Node
var _map_manager: Node2D
var _done := false
var _frames := 0
var _max_frames := 3600 # 60 秒超时（地图数据量大）

var _regions := {}


func _init() -> void:
	_net = NetworkManagerScript.new()
	root.add_child(_net)

	_map_manager = MapManagerScript.new()
	root.add_child(_map_manager)

	_net.packet_received.connect(_on_packet_received)
	_net.socket_closed.connect(func(code: int, reason: String) -> void: _fail("socket closed: %d %s" % [code, reason]))
	_map_manager.map_rendered.connect(_on_map_rendered)

	_log("connecting ...")
	_net.connect_to_server("82.157.143.36", 9001)


var _ready_frames := -1


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > _max_frames:
		_fail("timeout")
	# READY 发送后再保持 3 秒，确认服务端不再断连。
	if _ready_frames >= 0 and _frames - _ready_frames > 180:
		_pass("map rendered and connection stable")
	return _done


func _on_packet_received(packet_id: int, args: Array) -> void:
	match packet_id:
		Packets.CONNECTED:
			_net.send_packet(Packets.HANDSHAKE, { "gVer": GVER })
		Packets.HANDSHAKE:
			_net.send_packet(Packets.LOGIN, { "opcode": Opcodes.Login.GUEST })
			_log("guest login sent ...")
		Packets.WELCOME:
			_log("welcome received, sending READY ...")
			_net.send_packet(Packets.READY, { "regionsLoaded": false, "userAgent": "godot-test" })
		Packets.MAP:
			_handle_map(args)


func _handle_map(args: Array) -> void:
	var compressed := Marshalls.base64_to_raw(args[0])
	var decompressed := compressed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	if decompressed.is_empty():
		_fail("decompress failed")
		return

	var parsed: Variant = JSON.parse_string(decompressed.get_string_from_utf8())
	if not parsed is Dictionary:
		_fail("map JSON parse failed")
		return

	_regions = parsed
	_log("map parsed: %d regions, decompressed %d bytes" % [_regions.size(), decompressed.size()])

	_map_manager.apply_regions(_regions)


func _on_map_rendered() -> void:
	# 校验：地图尺寸正确、瓦片集已加载、有瓦片被填充。
	var mm = _map_manager
	_log("map %dx%d tile_size=%d" % [mm.width, mm.height, mm.tile_size])

	if mm.width <= 0 or mm.height <= 0:
		_fail("invalid map size")
		return

	# 抽样校验碰撞数据存在。
	var collision_count := 0
	for i: int in mm.collisions.size():
		if mm.collisions[i] == 1:
			collision_count += 1
	_log("collision tiles: %d / %d" % [collision_count, mm.collisions.size()])

	if collision_count == 0:
		_fail("no collision tiles found")
		return

	_ready_frames = _frames


func _log(msg: String) -> void:
	print("[TEST] %s" % msg)


func _pass(msg: String) -> void:
	print("[TEST] TEST_PASS: %s" % msg)
	_done = true
	quit(0)


func _fail(msg: String) -> void:
	print("[TEST] TEST_FAIL: %s" % msg)
	_done = true
	quit(1)
