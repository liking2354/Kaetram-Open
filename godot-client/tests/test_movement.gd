extends Node
## 移动 + 网络同步冒烟测试（场景方式运行，Autoload 可用）。
## 用法：Godot --headless --path . res://tests/test_movement.tscn
## 流程：访客登录 -> READY -> MAP -> 构建地图 -> 寻路移动到目标格
##       -> 校验到达目标且连接保持（服务端未判定作弊踢出）。

const MapManagerScript := preload("res://scripts/map/map_manager.gd")
const LocalPlayerScript := preload("res://scripts/game/local_player.gd")
const GVER := "0.5.5-beta"
## 测试总超时（秒）。
const TIMEOUT := 60.0

var _map_manager: MapManager
var _player: LocalPlayer

var _done := false
var _elapsed := 0.0
var _target := Vector2i.ZERO
var _move_started := false
var _arrived_at := -1.0


func _ready() -> void:
	_map_manager = MapManagerScript.new()
	add_child(_map_manager)

	GameState.map_loaded.connect(_on_map_loaded)
	Network.socket_closed.connect(_on_socket_closed)

	_log("connecting ...")
	Network.connect_to_server("82.157.143.36", 9001)

	# GameState 自动处理 handshake/guest 登录？不——本测试自行驱动登录流程。
	Network.packet_received.connect(_on_packet_received)


func _process(delta: float) -> void:
	if _done:
		return

	_elapsed += delta
	if _elapsed > TIMEOUT:
		_fail("timeout")
		return

	# 到达目标后再保持 2 秒，确认服务端不踢人。
	if _arrived_at >= 0.0 and _elapsed - _arrived_at > 2.0:
		_pass("moved to (%d, %d) and connection stable" % [_target.x, _target.y])


func _on_packet_received(packet_id: int, args: Array) -> void:
	match packet_id:
		Packets.CONNECTED:
			Network.send_packet(Packets.HANDSHAKE, { "gVer": GVER })
		Packets.HANDSHAKE:
			Network.send_packet(Packets.LOGIN, { "opcode": Opcodes.Login.GUEST })
			_log("guest login sent ...")


func _on_map_loaded(regions: Dictionary) -> void:
	_map_manager.apply_regions(regions)

	var grid := Vector2i(
		int(GameState.player_data.get("x", 0)),
		int(GameState.player_data.get("y", 0))
	)
	_log("player spawn grid: (%d, %d)" % [grid.x, grid.y])

	_target = _find_target(grid)
	if _target == Vector2i(-1, -1):
		_fail("no walkable target found near spawn")
		return

	_player = LocalPlayerScript.new()
	add_child(_player)
	_player.setup(_map_manager, grid, 220)

	_log("requesting move to (%d, %d) ..." % [_target.x, _target.y])
	_player.request_move(_target)
	_move_started = true


func _physics_process(_delta: float) -> void:
	if _done or not _move_started or _arrived_at >= 0.0:
		return
	if _player.grid_pos == _target and not _player.is_moving():
		_log("arrived at target (%d, %d)" % [_player.grid_pos.x, _player.grid_pos.y])
		_arrived_at = _elapsed


## 在出生点附近 3~5 格范围内找一个可行走格。
func _find_target(origin: Vector2i) -> Vector2i:
	for dist: int in range(3, 6):
		for dir: Array in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var candidate := origin + Vector2i(dir[0] * dist, dir[1] * dist)
			if not _map_manager.is_colliding(candidate.x, candidate.y):
				return candidate
	return Vector2i(-1, -1)


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
