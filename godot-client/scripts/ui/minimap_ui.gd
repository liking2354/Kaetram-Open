class_name MinimapUI
extends Control
## 小地图（右上角雷达）：地形概览 + 玩家/实体位置标记。

## 每格地形采样跨度（瓦片/像素）。
const SAMPLE := 8
## 地图显示尺寸。
const VIEW_SIZE := Vector2(150, 130)

var _map_manager: MapManager
var _local_player: LocalPlayer
var _markers: Dictionary = {}
var _terrain: ImageTexture
## 地形缩放比例。
var _scale := Vector2.ONE


func setup(map_manager: MapManager, local_player: LocalPlayer, markers: Dictionary) -> void:
	_map_manager = map_manager
	_local_player = local_player
	_markers = markers
	custom_minimum_size = VIEW_SIZE
	size = VIEW_SIZE
	_build_terrain()
	set_process(true)


## 由碰撞网格生成地形概览图（碰撞=浅，可行走=深）。
func _build_terrain() -> void:
	if not _map_manager or _map_manager.width == 0:
		return

	var w := ceili(_map_manager.width / float(SAMPLE))
	var h := ceili(_map_manager.height / float(SAMPLE))
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.08, 0.12, 0.08, 0.75))

	for py: int in h:
		for px: int in w:
			# 采样块内有碰撞则显示为浅色。
			var colliding := false
			for dy: int in SAMPLE:
				for dx: int in SAMPLE:
					var gx: int = px * SAMPLE + dx
					var gy: int = py * SAMPLE + dy
					if gx < _map_manager.width and gy < _map_manager.height and _map_manager.is_colliding(gx, gy):
						colliding = true
						break
				if colliding:
					break
			if colliding:
				image.set_pixel(px, py, Color(0.4, 0.35, 0.28, 0.85))

	_terrain = ImageTexture.create_from_image(image)
	_scale = VIEW_SIZE / Vector2(w, h)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# 背景。
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))

	if _terrain:
		draw_texture_rect(_terrain, Rect2(Vector2.ZERO, size), false)

	if not _map_manager or not _local_player:
		return

	# 实体标记。
	for instance: String in _markers:
		var marker: EntityMarker = _markers[instance]
		if not is_instance_valid(marker):
			continue
		draw_circle(_grid_to_minimap(marker.grid_pos), 2.0, _marker_color(marker.entity_type))

	# 本地玩家（亮色 + 描边）。
	var p := _grid_to_minimap(_local_player.grid_pos)
	draw_circle(p, 3.0, Color(1, 1, 1, 0.9))
	draw_arc(p, 3.5, 0, TAU, 8, Color(1, 0.85, 0.3), 1.5)

	# 边框。
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 0.35, 0.3, 0.9), false, 1.0)


func _grid_to_minimap(grid: Vector2i) -> Vector2:
	return Vector2(
		grid.x / float(SAMPLE) * _scale.x,
		grid.y / float(SAMPLE) * _scale.y
	)


func _marker_color(entity_type: int) -> Color:
	match entity_type:
		Modules.EntityType.MOB: return Color(0.95, 0.35, 0.35)
		Modules.EntityType.NPC: return Color(0.4, 0.9, 0.4)
		Modules.EntityType.PLAYER: return Color(0.4, 0.7, 1.0)
		Modules.EntityType.ITEM: return Color(1.0, 0.85, 0.3)
		_: return Color(0.6, 0.6, 0.6)
