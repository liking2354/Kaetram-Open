class_name EntityMarker
extends Node2D
## 其他实体的显示节点（真实精灵渲染 + 战斗表现）。

const EntityVisualScene := preload("res://scripts/game/entity_visual.gd")

## 实体 instance id。
var instance := ""
## 实体当前网格坐标。
var grid_pos := Vector2i.ZERO
## 实体类型（Modules.EntityType）。
var entity_type := -1
## 实体是否已死亡。
var dead := false
## 每格移动耗时（毫秒），由服务端 Movement.Speed 同步。
var movement_speed := 220
## 服务端 Movement.Follow 指定的当前目标实例。
var following_instance := ""

var _map_manager: MapManager
var _visual: EntityVisual
var _move_tween: Tween


## 根据实体数据初始化。
func setup(map_manager: MapManager, data: Dictionary) -> void:
	_map_manager = map_manager
	instance = str(data.get("instance", ""))
	entity_type = int(data.get("type", -1))
	movement_speed = maxi(int(data.get("movementSpeed", 220)), 1)
	grid_pos = Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
	position = _map_manager.grid_to_world(grid_pos.x, grid_pos.y)

	_visual = EntityVisualScene.new()
	add_child(_visual)
	_visual.setup(data)


## 处理服务端广播的移动：推断朝向、播放行走动画、平滑过渡。
func move_to(x: int, y: int) -> void:
	if dead:
		return

	var from := grid_pos
	grid_pos = Vector2i(x, y)

	_visual.face_delta(from, grid_pos)
	_visual.set_moving(true)

	if _move_tween:
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.tween_property(
		self, "position",
		_map_manager.grid_to_world(x, y),
		clampf(movement_speed / 1000.0, 0.05, 0.5)
	)
	_move_tween.tween_callback(func() -> void: _visual.set_moving(false))


func set_follow_target(target_instance: String) -> void:
	following_instance = target_instance


## 播放攻击动画。
func play_attack() -> void:
	if not dead:
		_visual.play_attack()


## 受击表现（闪红 + 伤害数字）。
func show_hit(hit: Dictionary) -> void:
	if not dead:
		_visual.show_hit(hit)


## 更新血条。
func set_health(hit_points: int, max_hit_points: int) -> void:
	_visual.set_health(hit_points, max_hit_points)


## 是否为可攻击的怪物。
func is_mob() -> bool:
	return entity_type == Modules.EntityType.MOB and not dead


## 播放死亡动画，完成后由 game 释放。
func play_death() -> void:
	if dead:
		return
	dead = true
	_visual.play_death()


## 应用服务器 Sync 包中的完整远端实体资料。
func sync_data(data: Dictionary) -> void:
	movement_speed = maxi(int(data.get("movementSpeed", movement_speed)), 1)
	if data.has("orientation"):
		_visual.set_orientation(int(data.get("orientation", Modules.Orientation.DOWN)))
	_visual.rebuild(data)


## 获取可视化组件（气泡等）。
func get_visual() -> EntityVisual:
	return _visual
