extends Node
## NPC 对话冒烟测试（场景方式运行）。
## 流程：访客登录 -> 等待 NPC 实体出现 -> 走到身旁对话 -> 验证收到对话文本。

const MapManagerScript := preload("res://scripts/map/map_manager.gd")
const LocalPlayerScript := preload("res://scripts/game/local_player.gd")
const EntityMarkerScript := preload("res://scripts/game/entity_marker.gd")
const GVER := "0.5.5-beta"
const TIMEOUT := 45.0

var _map_manager: MapManager
var _player: LocalPlayer

var _done := false
var _elapsed := 0.0


func _ready() -> void:
	_map_manager = MapManagerScript.new()
	add_child(_map_manager)

	Network.packet_received.connect(_on_packet_received)
	Network.socket_closed.connect(_on_socket_closed)
	GameState.map_loaded.connect(_on_map_loaded)
	GameState.entity_spawned.connect(_on_entity_spawned)
	GameState.npc_talk.connect(_on_npc_talk)

	Network.connect_to_server("82.157.143.36", 9001)


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	if _elapsed > TIMEOUT:
		_fail("timeout")


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
	_player = LocalPlayerScript.new()
	add_child(_player)
	_player.setup(
		_map_manager,
		Vector2i(int(GameState.player_data.get("x", 0)), int(GameState.player_data.get("y", 0))),
		220
	)
	_log("player ready, waiting for NPC ...")

	# 玩家就绪后补扫已存在的附近 NPC（Spawn 可能早于玩家创建）。
	for instance: String in GameState.entities:
		_on_entity_spawned(GameState.entities[instance])
		if _done:
			return


func _on_entity_spawned(data: Dictionary) -> void:
	if _done or not _player:
		return
	if int(data.get("type", -1)) != Modules.EntityType.NPC:
		return

	# 只与 15 格内最近的 NPC 对话，避免追着远处 NPC 跑。
	var npc_grid := Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
	var dist := absi(npc_grid.x - _player.grid_pos.x) + absi(npc_grid.y - _player.grid_pos.y)
	if dist > 15:
		return

	_log("NPC appeared: %s (%d tiles away), walking to talk ..." % [data.get("name", ""), dist])

	var marker: EntityMarker = EntityMarkerScript.new()
	add_child(marker)
	marker.setup(_map_manager, data)

	_player.talk_to(marker)


func _on_npc_talk(_instance: String, text: String) -> void:
	_log("NPC says: %s" % text)
	_pass("NPC dialogue received")


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
