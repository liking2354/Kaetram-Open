class_name LocalPlayer
extends Node2D
## 本地玩家控制器。
##
## 点击目标格 -> AStarGrid2D 寻路 -> 逐格移动，
## 全程按服务端协议发送 Movement 包（Request/Started/Step/Stop）。
## 外观由 EntityVisual 渲染（多图层精灵）。

const EntityVisualScene := preload("res://scripts/game/entity_visual.gd")

## 移动动画缓动时长（秒），略小于步进间隔保证平滑。
const TWEEN_DURATION := 0.2

## 玩家当前网格坐标。
var grid_pos := Vector2i.ZERO
## 每格移动耗时（毫秒），来自服务端 movementSpeed。
var movement_speed := 220
## 当前朝向（Stop 包需要）。
var orientation := Modules.Orientation.DOWN
## 传送/死亡期间冻结移动输入，与浏览器端 player.frozen/disableAction 对应。
## 服务端 handleMovementRequest 一旦检测到 >2 格落差就会把 invalidateMovement
## 永久置为 true（无重置逻辑，只能重连恢复），所以传送瞬间必须在客户端
## 提前拦截，禁止用旧 grid_pos 发出 Request/Step 包。
var frozen := false

var _astar := AStarGrid2D.new()
var _map_manager: MapManager
var _path: PackedVector2Array = []
var _step_timer := 0.0
var _moving := false
var _target_grid := Vector2i.ZERO
var _move_tween: Tween
var _visual: EntityVisual

## 当前攻击目标。
var _attack_target: EntityMarker
## 攻击距离（格，近战为 1）。
var _attack_range := 1
## 是否已与目标交战（避免重复发送攻击包）。
var _attack_engaged := false


## 攻击指定实体：寻路到目标身旁 -> 进入攻击范围 -> 发送 Target.Attack。
func attack_entity(marker: EntityMarker) -> void:
	if frozen:
		return
	_follow_target = null
	_attack_target = marker

	if _in_attack_range(marker.grid_pos):
		_send_attack()
		return

	# 找目标四周的可行走格。
	var adjacent := _find_adjacent_walkable(marker.grid_pos)
	if adjacent == Vector2i(-1, -1):
		print("[LocalPlayer] No walkable tile near target.")
		return

	request_move(adjacent)
	# 移动完成后在 _finish_move 里发起攻击。


## 当前是否处于攻击范围内（曼哈顿距离）。
func _in_attack_range(target: Vector2i) -> bool:
	return absi(target.x - grid_pos.x) + absi(target.y - grid_pos.y) <= _attack_range


## 服务端装备同步的攻击范围；最小为 1，防止无效包导致无法近战。
func set_attack_range(attack_range: int) -> void:
	_attack_range = maxi(attack_range, 1)


func _find_adjacent_walkable(target: Vector2i) -> Vector2i:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for dir: Vector2i in dirs:
		var candidate := target + dir
		if candidate == grid_pos:
			return candidate
		if not _map_manager.is_colliding(candidate.x, candidate.y):
			return candidate
	return Vector2i(-1, -1)


func _send_attack() -> void:
	if not _attack_target or _attack_target.dead:
		return

	# 面向目标。
	_visual.face_delta(grid_pos, _attack_target.grid_pos)
	orientation = _visual.orientation

	# 客户端发送格式：[Packets.Target, [opcode, instance, x, y]]
	Network.send_packet(Packets.TARGET, [
		Opcodes.Target.ATTACK,
		_attack_target.instance,
		_attack_target.grid_pos.x,
		_attack_target.grid_pos.y,
	])


## 初始化：绑定地图、出生坐标、移动速度，并构建寻路网格。
func setup(map_manager: MapManager, spawn_grid: Vector2i, speed: int) -> void:
	_map_manager = map_manager
	grid_pos = spawn_grid
	movement_speed = speed if speed > 0 else 220
	position = _map_manager.grid_to_world(grid_pos.x, grid_pos.y)

	# 用 Welcome 数据渲染玩家外观（base + 装备图层）。
	_visual = EntityVisualScene.new()
	add_child(_visual)
	_visual.setup(GameState.player_data)

	_build_astar()


func _build_astar() -> void:
	_astar.region = Rect2i(0, 0, _map_manager.width, _map_manager.height)
	# cell_size 固定为 1，使 get_point_path 直接返回网格坐标而非像素坐标。
	_astar.cell_size = Vector2(1, 1)
	# 对角寻路（与原版一致，不穿实心墙角），4 方向会漏掉对角缝隙路径。
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()

	for y: int in _map_manager.height:
		for x: int in _map_manager.width:
			if _map_manager.is_colliding(x, y):
				_astar.set_point_solid(Vector2i(x, y), true)

	print("[LocalPlayer] AStar grid built: %dx%d." % [_map_manager.width, _map_manager.height])


## 键盘方向移动（WASD/方向键，单格步进）。
func move_direction(offset: Vector2i) -> void:
	if frozen or _moving:
		return
	stop_attack()
	request_move(grid_pos + offset)


## 停止攻击/追击（点击地面或其他目标时调用）。
func stop_attack() -> void:
	_attack_target = null
	_attack_engaged = false
	_talk_target = null
	_interact_target = null
	_pickup_target = null
	_trade_target = null
	_follow_target = null


## 请求移动到目标格。点击地图时调用。
func request_move(target: Vector2i) -> void:
	if frozen:
		return
	if target == grid_pos:
		return
	if _map_manager.is_colliding(target.x, target.y):
		return

	var path := _astar.get_point_path(grid_pos, target)
	if path.is_empty():
		print("[LocalPlayer] No path from %s to %s." % [grid_pos, target])
		return

	_target_grid = target
	_path = path
	# get_point_path 首元素是当前位置，移除。
	if not _path.is_empty() and Vector2i(_path[0]) == grid_pos:
		_path.remove_at(0)
	if _path.is_empty():
		return

	# 1) Request
	var target_instance := _pickup_target.instance if _pickup_target and not _pickup_target.dead else ""
	var request_data: Dictionary = {
		"opcode": Opcodes.Movement.REQUEST,
		"requestX": target.x,
		"requestY": target.y,
		"playerX": grid_pos.x,
		"playerY": grid_pos.y,
	}
	if not target_instance.is_empty():
		request_data["targetInstance"] = target_instance
	Network.send_packet(Packets.MOVEMENT, request_data)

	# 2) Started
	var started_data: Dictionary = {
		"opcode": Opcodes.Movement.STARTED,
		"requestX": target.x,
		"requestY": target.y,
		"playerX": grid_pos.x,
		"playerY": grid_pos.y,
		"movementSpeed": movement_speed,
	}
	if not target_instance.is_empty():
		started_data["targetInstance"] = target_instance
	Network.send_packet(Packets.MOVEMENT, started_data)

	_moving = true
	_step_timer = 0.0
	_visual.set_moving(true)


func _process(delta: float) -> void:
	# 追击与跟随目标（即使当前未在走步也持续尝试）。
	_pursue_target(delta)
	_follow_target_player(delta)

	if not _moving:
		return

	_step_timer += delta * 1000.0
	if _step_timer < movement_speed:
		return
	_step_timer = 0.0
	_do_step()


func _do_step() -> void:
	if _path.is_empty():
		_finish_move()
		return

	var next := Vector2i(_path[0])
	_path.remove_at(0)

	# 更新朝向（对角步进取水平优先方向）。
	if next.x < grid_pos.x: orientation = Modules.Orientation.LEFT
	elif next.x > grid_pos.x: orientation = Modules.Orientation.RIGHT
	elif next.y < grid_pos.y: orientation = Modules.Orientation.UP
	elif next.y > grid_pos.y: orientation = Modules.Orientation.DOWN
	_visual.set_orientation(orientation)

	# 与浏览器端完全一致：Step 上报本步开始前的服务器权威坐标，
	# nextGrid 指向即将进入的格子。提前上报 next 会让下一次 Request 的
	# playerX/playerY 超过服务器位置两格，触发服务端 No-clip 防护。
	Network.send_packet(Packets.MOVEMENT, {
		"opcode": Opcodes.Movement.STEP,
		"playerX": grid_pos.x,
		"playerY": grid_pos.y,
		"nextGridX": next.x,
		"nextGridY": next.y,
		"timestamp": Time.get_ticks_msec() - GameState.time_offset,
	})
	grid_pos = next

	# 平滑过渡到新格子。
	if _move_tween:
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.tween_property(
		self, "position",
		_map_manager.grid_to_world(next.x, next.y),
		TWEEN_DURATION
	)

	if _path.is_empty():
		_finish_move()


## 追击节流（避免每帧重复寻路）。
var _pursuit_cooldown := 0.0


func _finish_move() -> void:
	_moving = false
	_visual.set_moving(false)

	# 4) Stop —— 携带 targetInstance 让服务端判断是否停在物品/战利品袋上。
	var stop_data: Dictionary = {
		"opcode": Opcodes.Movement.STOP,
		"playerX": grid_pos.x,
		"playerY": grid_pos.y,
		"orientation": orientation,
	}
	if _pickup_target and not _pickup_target.dead:
		stop_data["targetInstance"] = _pickup_target.instance
	Network.send_packet(Packets.MOVEMENT, stop_data)
	# Stop 包已携带实例；立即清理，避免下一次普通移动复用旧掉落物目标。
	_pickup_target = null

	# 移动完成后执行等待中的近距离交互。
	if _attack_target and not _attack_target.dead and _in_attack_range(_attack_target.grid_pos):
		_send_attack()
	if _talk_target and _in_attack_range(_talk_target.grid_pos):
		_send_talk()
	if _interact_target and _in_interact_range(_interact_target.grid_pos):
		_send_interact()
	if _trade_target and _in_attack_range(_trade_target.grid_pos):
		_send_trade()


## 追击循环：目标游走导致未进范围时，持续寻路追击。
func _pursue_target(delta: float) -> void:
	if not _attack_target or _attack_target.dead:
		return
	if _moving:
		return
	if _in_attack_range(_attack_target.grid_pos):
		# 已进入范围：首次进入时发起攻击，服务端接管自动连击。
		if not _attack_engaged:
			_send_attack()
			_attack_engaged = true
		return

	# 脱离范围则重置交战标记，重新追击。
	_attack_engaged = false

	_pursuit_cooldown -= delta
	if _pursuit_cooldown > 0.0:
		return
	_pursuit_cooldown = 0.4

	# 朝目标当前位置重新寻路。
	var adjacent := _find_adjacent_walkable(_attack_target.grid_pos)
	if adjacent != Vector2i(-1, -1):
		request_move(adjacent)

	# 移动完成后若存在对话目标，发起对话。
	if _talk_target and _in_attack_range(_talk_target.grid_pos):
		_send_talk()

	# 移动完成后若存在资源交互目标，发起交互。
	if _interact_target and _in_interact_range(_interact_target.grid_pos):
		_send_interact()


## 持续跟随其他玩家：目标移动或拉开距离时，自动重新寻路至相邻格。
func follow_player(marker: EntityMarker) -> void:
	_follow_target = marker
	_follow_cooldown = 0.0


func _follow_target_player(delta: float) -> void:
	if not _follow_target or _follow_target.dead:
		_follow_target = null
		return
	var follow_distance := absi(_follow_target.grid_pos.x - grid_pos.x) + absi(_follow_target.grid_pos.y - grid_pos.y)
	if _moving or follow_distance <= 1:
		return
	_follow_cooldown -= delta
	if _follow_cooldown > 0.0:
		return
	_follow_cooldown = 0.45
	var adjacent := _find_adjacent_walkable(_follow_target.grid_pos)
	if adjacent != Vector2i(-1, -1):
		request_move(adjacent)


## 本地玩家的血量更新（Points 包）。
func set_health(hit_points: int, max_hit_points: int) -> void:
	_visual.set_health(hit_points, max_hit_points)


## 本地玩家受击表现。
func show_hit(hit: Dictionary) -> void:
	_visual.show_hit(hit)


## 本地玩家攻击动画。
func play_attack() -> void:
	_visual.play_attack()


## 获取可视化组件（气泡等）。
func get_visual() -> EntityVisual:
	return _visual


## 装备变化时刷新外观图层。
func refresh_visual() -> void:
	_visual.rebuild(GameState.player_data)


## 与 NPC 对话：寻路到身旁 -> 发送 Target.Talk。
func talk_to(marker: EntityMarker) -> void:
	_talk_target = marker

	if _in_attack_range(marker.grid_pos):
		_send_talk()
		return

	var adjacent := _find_adjacent_walkable(marker.grid_pos)
	if adjacent == Vector2i(-1, -1):
		return
	request_move(adjacent)


var _talk_target: EntityMarker
var _interact_target: EntityMarker
var _trade_target: EntityMarker
var _follow_target: EntityMarker
var _follow_cooldown := 0.0
## 拾取目标（掉落物品 / 战利品袋）：移动到目标格后通过 Movement.Stop
## 包携带 targetInstance 通知服务端触发拾取/打开。
var _pickup_target: EntityMarker


func _send_talk() -> void:
	if not _talk_target:
		return
	Network.send_packet(Packets.TARGET, [
		Opcodes.Target.TALK,
		_talk_target.instance,
	])
	_talk_target = null


## 与资源交互（采集）：寻路到附近 -> 发送 Target.Object。
func interact_with(marker: EntityMarker) -> void:
	_interact_target = marker

	if _in_interact_range(marker.grid_pos):
		_send_interact()
		return

	var adjacent := _find_adjacent_walkable(marker.grid_pos)
	if adjacent == Vector2i(-1, -1):
		return
	request_move(adjacent)


## 资源可在 2 格内交互（服务端校验 getDistance <= 2）。
func _in_interact_range(target: Vector2i) -> bool:
	return absi(target.x - grid_pos.x) + absi(target.y - grid_pos.y) <= 2


func _send_interact() -> void:
	if not _interact_target:
		return
	Network.send_packet(Packets.TARGET, [
		Opcodes.Target.OBJECT,
		_interact_target.instance,
	])
	_interact_target = null


## 向目标玩家请求交易：移动到相邻格后发送 Trade.Request。
func trade_with(marker: EntityMarker) -> void:
	_follow_target = null
	_trade_target = marker
	if _in_attack_range(marker.grid_pos):
		_send_trade()
		return
	var adjacent := _find_adjacent_walkable(marker.grid_pos)
	if adjacent == Vector2i(-1, -1):
		_trade_target = null
		return
	request_move(adjacent)


func _send_trade() -> void:
	if not _trade_target or _trade_target.dead:
		return
	Network.send_packet(Packets.TRADE, {
		"opcode": Opcodes.Trade.REQUEST,
		"instance": _trade_target.instance,
	})
	_trade_target = null


## 拾取掉落物品 / 打开战利品袋：移动到实体所在格，Stop 携带 targetInstance。
## 服务端会在应用 Stop 坐标前验证到 LootBag 的距离；浏览器端因此将路径终点
## 设为 Item/LootBag 的实际格，而不是相邻格。
func move_to_pickup(marker: EntityMarker) -> void:
	if frozen or marker.dead:
		return
	_pickup_target = marker

	if marker.grid_pos == grid_pos:
		# 已站在掉落物格时也必须走 Request -> Started -> Stop 顺序；
		# 服务端拒绝没有 Started 的孤立 Stop 包。
		_begin_stationary_pickup()
		return

	# 地面 Item 与 LootBag 都是不碰撞实体，直接走到其所在格。
	request_move(marker.grid_pos)


func _begin_stationary_pickup() -> void:
	if not _pickup_target or _pickup_target.dead:
		_pickup_target = null
		return
	var target_instance := _pickup_target.instance
	Network.send_packet(Packets.MOVEMENT, {
		"opcode": Opcodes.Movement.REQUEST,
		"requestX": grid_pos.x,
		"requestY": grid_pos.y,
		"playerX": grid_pos.x,
		"playerY": grid_pos.y,
		"targetInstance": target_instance,
	})
	Network.send_packet(Packets.MOVEMENT, {
		"opcode": Opcodes.Movement.STARTED,
		"requestX": grid_pos.x,
		"requestY": grid_pos.y,
		"playerX": grid_pos.x,
		"playerY": grid_pos.y,
		"movementSpeed": movement_speed,
		"targetInstance": target_instance,
	})
	_finish_move()


## 当前是否正在移动。
func is_moving() -> bool:
	return _moving


## 传送：取消当前移动并瞬移到新坐标（门/传送点触发）。
func teleport(x: int, y: int) -> void:
	# 立即冻结输入，防止传送瞬间残留的按键/点击用旧 grid_pos 发出移动包，
	# 触发服务端永久性的 invalidateMovement（No-clip 检测）。
	frozen = true
	_path.clear()
	_moving = false
	_attack_target = null
	_follow_target = null
	_pickup_target = null
	_step_timer = 0.0
	if _move_tween:
		_move_tween.kill()

	grid_pos = Vector2i(x, y)
	position = _map_manager.grid_to_world(x, y)
	_visual.set_moving(false)

	# 与浏览器端 setTimeout(() => teleporting = false, 500) 对应；
	# 服务端也在 character.ts teleport() 里用 500ms 解除传送标记。
	get_tree().create_timer(0.5).timeout.connect(_unfreeze)


func _unfreeze() -> void:
	frozen = false
