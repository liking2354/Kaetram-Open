extends Node
## 区域传送冒烟测试（场景方式运行）。
## 流程：访客登录 -> 加载地图 -> 向南走出房间（触发门传送）
##       -> 验证收到 Teleport 包且位置跳变到新区域。

const MapManagerScript := preload("res://scripts/map/map_manager.gd")
const LocalPlayerScript := preload("res://scripts/game/local_player.gd")
const GVER := "0.5.5-beta"
const TIMEOUT := 90.0

var _map_manager: MapManager
var _player: LocalPlayer

var _done := false
var _elapsed := 0.0
var _spawn := Vector2i.ZERO
var _teleported := false
var _walk_targets: Array[Vector2i] = []
var _walk_index := 0


func _ready() -> void:
	_map_manager = MapManagerScript.new()
	add_child(_map_manager)

	Network.packet_received.connect(_on_packet_received)
	Network.socket_closed.connect(_on_socket_closed)
	GameState.map_loaded.connect(_on_map_loaded)
	GameState.entity_teleported.connect(_on_teleported)

	Network.connect_to_server("82.157.143.36", 9001)


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	if _elapsed > TIMEOUT:
		_fail("timeout (player at %s, teleported=%s)" % [_player.grid_pos if _player else "?", _teleported])
		return

	# 到达当前目标后向下一个目标走。
	if _player and not _player.is_moving() and _walk_index < _walk_targets.size() and not _teleported:
		_player.request_move(_walk_targets[_walk_index])
		_walk_index += 1


func _on_packet_received(packet_id: int, _args: Array) -> void:
	match packet_id:
		Packets.CONNECTED:
			Network.send_packet(Packets.HANDSHAKE, { "gVer": GVER })
		Packets.HANDSHAKE:
			Network.send_packet(Packets.LOGIN, { "opcode": Opcodes.Login.GUEST })


func _on_map_loaded(_regions: Dictionary) -> void:
	if _player:
		return
	_map_manager.apply_regions(GameState.regions)

	_spawn = Vector2i(
		int(GameState.player_data.get("x", 0)),
		int(GameState.player_data.get("y", 0))
	)
	_log("spawn at %s" % _spawn)

	_player = LocalPlayerScript.new()
	add_child(_player)
	_player.setup(_map_manager, _spawn, 220)

	# 向南逐段走（门在房间南侧）。
	for i: int in range(2, 16, 2):
		_walk_targets.append(_spawn + Vector2i(0, i))


func _on_teleported(instance: String, x: int, y: int) -> void:
	if instance != GameState.player_instance:
		return
	# 忽略登录时的初始落点传送（玩家尚未加载/未行走）。
	if not _player or _walk_index == 0:
		_log("initial spawn teleport to (%d, %d), ignored" % [x, y])
		return
	_teleported = true
	_log("door teleported to (%d, %d) — moved %d tiles" % [
		x, y, absi(x - _spawn.x) + absi(y - _spawn.y)
	])
	_pass("door teleport works")


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
