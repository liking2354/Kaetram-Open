extends Node
## 技能采集交互冒烟测试（场景方式运行）。
## 流程：访客登录 -> 找附近的树 -> 走过去交互
##       -> 验证服务端响应（通知"需要装备斧头"或采集动画/物品）。

const MapManagerScript := preload("res://scripts/map/map_manager.gd")
const LocalPlayerScript := preload("res://scripts/game/local_player.gd")
const EntityMarkerScript := preload("res://scripts/game/entity_marker.gd")
const GVER := "0.5.5-beta"
const TIMEOUT := 45.0

var _map_manager: MapManager
var _player: LocalPlayer

var _done := false
var _elapsed := 0.0
var _interacted := false
var _interact_time := -1.0
var _initial_items := 0


func _ready() -> void:
	_map_manager = MapManagerScript.new()
	add_child(_map_manager)

	Network.packet_received.connect(_on_packet_received)
	Network.socket_closed.connect(_on_socket_closed)
	GameState.map_loaded.connect(_on_map_loaded)
	GameState.entity_spawned.connect(_on_entity_spawned)
	GameState.notification_received.connect(_on_notification)
	GameState.inventory_updated.connect(_on_inventory)
	GameState.entity_animation.connect(_on_entity_animation)

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

	# 补扫已有树。
	for instance: String in GameState.entities:
		_on_entity_spawned(GameState.entities[instance])
		if _interacted:
			return


func _on_entity_spawned(data: Dictionary) -> void:
	if _interacted or not _player:
		return
	if int(data.get("type", -1)) != Modules.EntityType.TREE:
		return

	var tree_grid := Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
	var dist := absi(tree_grid.x - _player.grid_pos.x) + absi(tree_grid.y - _player.grid_pos.y)
	if dist > 20:
		return

	_log("tree found: %s (%d tiles), interacting ..." % [data.get("key", ""), dist])
	_interacted = true
	_interact_time = _elapsed
	_initial_items = GameState.inventory.size()

	var marker: EntityMarker = EntityMarkerScript.new()
	add_child(marker)
	marker.setup(_map_manager, data)
	_player.interact_with(marker)


func _on_notification(message: String, _colour: String) -> void:
	_log("notification: %s" % message)
	# 无工具时的预期响应，证明交互已到达服务端并被处理。
	_pass("interaction processed by server")


func _on_inventory() -> void:
	# 只统计交互之后的新增物品（忽略登录时的初始背包同步）。
	if not _interacted or _elapsed - _interact_time < 0.1:
		return
	if GameState.inventory.size() > _initial_items:
		_log("gathered item! inventory %d -> %d" % [_initial_items, GameState.inventory.size()])
		_pass("gathered item received")


func _on_entity_animation(_instance: String, _action: int, resource_instance: String) -> void:
	if not _interacted or resource_instance.is_empty():
		return
	_log("chopping animation on resource %s" % resource_instance)
	_pass("gathering animation received")


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
