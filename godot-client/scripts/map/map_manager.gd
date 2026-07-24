class_name MapManager
extends Node2D
## 地图管理器。
##
## 从 map.json 加载瓦片集元数据，运行时构建 Godot TileSet，
## 并将服务端下发的区域数据（RegionData）填充到 TileMapLayer 中渲染。
##
## 图层设计（自底向上）：
##   GroundLayer0~3：堆叠瓦片（z_index 0~3）
##   HighLayer：     高位瓦片，渲染在角色之上（z_index 10）

## 地图渲染完成（所有区域瓦片填充完毕）。
signal map_rendered

## Tiled 翻转标志位（高位）。
const FLAG_HORIZONTAL := 0x80000000
const FLAG_VERTICAL := 0x40000000
const FLAG_DIAGONAL := 0x20000000
const FLAG_MASK := ~(FLAG_HORIZONTAL | FLAG_VERTICAL | FLAG_DIAGONAL)

## 地面堆叠层数量。
const GROUND_LAYER_COUNT := 4
## 高位层 z_index（角色位于 5）。
const HIGH_LAYER_Z := 10

## 地图宽度（格）。
var width := 0
## 地图高度（格）。
var height := 0
## 瓦片像素尺寸。
var tile_size := 16

## 碰撞网格（width * height，1 表示碰撞）。
var collisions := PackedByteArray()
## 可交互对象坐标集合 {Vector2i: true}。
var objects := {}
## 光标类型 {index: String}。
var cursor_tiles := {}

## 高位瓦片 GID 集合（渲染在角色之上）。
var _high_set := {}
## 动画瓦片定义 {gid: [{duration, tileId}]}。
var _animations := {}
## 已应用到地图的动画瓦片格子
## {"layer,x,y": {layer, coords, frames: [{source_id, atlas_coords}], durations: [ms], index, elapsed}}
var _animated_cells := {}

## 瓦片集元数据（来自 map.json）。
var _tileset_meta: Array = []
## 全局 GID -> {source_id, atlas_coords} 的快速映射缓存。
var _gid_cache := {}
## Godot 运行时构建的 TileSet。
var _godot_tileset: TileSet

var _ground_layers: Array[TileMapLayer] = []
var _high_layer: TileMapLayer

## 摄像机边界（地图范围像素）。
var camera_limit_left := 0
var camera_limit_top := 0
var camera_limit_right := 0
var camera_limit_bottom := 0


func _ready() -> void:
	_load_metadata()
	_build_tileset()
	_create_layers()


## 解析 map.json 元数据。
func _load_metadata() -> void:
	var file := FileAccess.open("res://assets/data/map.json", FileAccess.READ)
	if not file:
		push_error("[MapManager] Cannot open map.json")
		return

	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary:
		push_error("[MapManager] Invalid map.json")
		return

	width = int(data.get("width", 0))
	height = int(data.get("height", 0))
	tile_size = int(data.get("tileSize", 16))
	_tileset_meta = data.get("tilesets", [])
	collisions.resize(width * height)

	# 高位瓦片 GID 集合。
	for gid: Variant in data.get("high", []):
		_high_set[int(gid)] = true

	# 动画瓦片定义（key 为起始 GID，帧列表含 duration/tileId）。
	for gid_str: String in data.get("animations", {}):
		_animations[int(gid_str)] = data["animations"][gid_str]

	print("[MapManager] Metadata: %dx%d, tile %dpx, %d tilesets, %d high, %d anims." % [
		width, height, tile_size, _tileset_meta.size(), _high_set.size(), _animations.size()
	])


## 运行时从 PNG 构建 Godot TileSet（每个 tilesheet 一个 AtlasSource）。
func _build_tileset() -> void:
	_godot_tileset = TileSet.new()
	_godot_tileset.tile_size = Vector2i(tile_size, tile_size)

	for meta: Dictionary in _tileset_meta:
		var path := str(meta.get("path", "")).replace("../public/img/", "res://assets/")
		# 路径兼容处理：map.json 中 path 形如 "../public/img/tilesets/tilesheet-1.png"
		if path.begins_with("tilesets/"):
			path = "res://assets/" + path

		var texture: Texture2D = load(path)
		if not texture:
			push_warning("[MapManager] Missing tileset texture: %s" % path)
			continue

		var source := TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(tile_size, tile_size)

		# map.json 不含行列信息，从图片实际尺寸计算。
		var columns := texture.get_width() / tile_size
		var rows := texture.get_height() / tile_size

		# 预创建所有瓦片格子。
		for y: int in rows:
			for x: int in columns:
				source.create_tile(Vector2i(x, y))

		var source_id := _godot_tileset.add_source(source)
		meta["_source_id"] = source_id
		meta["_columns"] = columns
		print("[MapManager] Tileset %s: %dx%d tiles (source %d)." % [path, columns, rows, source_id])


## 创建地面堆叠层 + 高位层。
func _create_layers() -> void:
	for i: int in GROUND_LAYER_COUNT:
		var layer := TileMapLayer.new()
		layer.name = "GroundLayer%d" % i
		layer.tile_set = _godot_tileset
		layer.z_index = i
		add_child(layer)
		_ground_layers.append(layer)

	_high_layer = TileMapLayer.new()
	_high_layer.name = "HighLayer"
	_high_layer.tile_set = _godot_tileset
	_high_layer.z_index = HIGH_LAYER_Z
	add_child(_high_layer)

	# 摄像机边界（地图范围）。
	camera_limit_left = 0
	camera_limit_top = 0
	camera_limit_right = width * tile_size
	camera_limit_bottom = height * tile_size


## 将服务端下发的区域数据填充到图层中。
func apply_regions(regions: Dictionary) -> void:
	var tile_count := 0

	for region_id: String in regions:
		var tiles: Array = regions[region_id]
		for tile: Dictionary in tiles:
			_apply_tile(tile)
			tile_count += 1

	print("[MapManager] Rendered %d tiles across %d regions." % [tile_count, regions.size()])
	map_rendered.emit()


## 解析单个瓦片并写入对应图层。
func _apply_tile(tile: Dictionary) -> void:
	var x := int(tile.get("x", 0))
	var y := int(tile.get("y", 0))
	var coords := Vector2i(x, y)

	# 碰撞标记。
	if tile.get("c", false):
		_set_collision(x, y, true)

	# 可交互对象标记。
	if tile.get("o", false):
		objects[coords] = true

	# 瓦片数据：单个数值或堆叠数组。
	var data: Variant = tile.get("data", 0)
	var stack: Array = data if data is Array else [data]

	for i: int in stack.size():
		var gid := _unwrap_gid(int(stack[i]))
		if gid <= 0:
			continue

		var cell := _gid_to_cell(gid)
		if cell.is_empty():
			continue

		# 高位瓦片渲染在角色之上。
		var target_layer: TileMapLayer
		if _high_set.has(gid):
			target_layer = _high_layer
		elif i < _ground_layers.size():
			target_layer = _ground_layers[i]
		else:
			continue
		target_layer.set_cell(coords, cell.source_id, cell.atlas_coords)

		# 动画瓦片注册动态换帧。
		if _animations.has(gid):
			_register_animated_cell(target_layer, coords, gid)


## 去除 Tiled 翻转标志位，返回原始 GID。
## TODO: 翻转瓦片当前按未翻转渲染，后续用 alternative tile 处理。
func _unwrap_gid(gid: int) -> int:
	return gid & FLAG_MASK


## 全局 GID -> TileSet source_id + atlas 坐标（带缓存）。
func _gid_to_cell(gid: int) -> Dictionary:
	if _gid_cache.has(gid):
		return _gid_cache[gid]

	for meta: Dictionary in _tileset_meta:
		var first_gid := int(meta.get("firstGid", 0))
		var last_gid := int(meta.get("lastGid", -1))
		if gid < first_gid or gid > last_gid:
			continue

		var local := gid - first_gid
		var columns := maxi(int(meta.get("_columns", 1)), 1)
		var cell := {
			"source_id": int(meta.get("_source_id", -1)),
			"atlas_coords": Vector2i(local % columns, local / columns),
		}
		_gid_cache[gid] = cell
		return cell

	return {}


func _set_collision(x: int, y: int, colliding: bool) -> void:
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	collisions[y * width + x] = 1 if colliding else 0


## 查询某格是否碰撞。
func is_colliding(x: int, y: int) -> bool:
	if x < 0 or x >= width or y < 0 or y >= height:
		return true
	return collisions[y * width + x] == 1


## 格坐标 -> 世界像素坐标（格中心）。
func grid_to_world(grid_x: int, grid_y: int) -> Vector2:
	return Vector2(grid_x * tile_size + tile_size * 0.5, grid_y * tile_size + tile_size * 0.5)


## 注册一个动画瓦片格子。
func _register_animated_cell(layer: TileMapLayer, coords: Vector2i, gid: int) -> void:
	var frames: Array[Dictionary] = []
	var durations: Array[int] = []

	for frame: Dictionary in _animations[gid]:
		# 帧 tileId 是瓦片集内局部 id，动画均来自 tilesheet-1（firstGid=0），
		# 局部 id 与 GID 一致，直接查表。
		var cell := _gid_to_cell(int(frame.get("tileId", 0)))
		if cell.is_empty():
			continue
		frames.append(cell)
		durations.append(int(frame.get("duration", 300)))

	if frames.size() < 2:
		return

	var key := "%d,%d,%d" % [layer.get_index(), coords.x, coords.y]
	_animated_cells[key] = {
		"layer": layer,
		"coords": coords,
		"frames": frames,
		"durations": durations,
		"index": 0,
		"elapsed": 0.0,
	}


## 动态地块开关：低功耗模式暂停瓦片动画以降低渲染和脚本开销。
var _animated_tiles_enabled := true


func set_animated_tiles_enabled(enabled: bool) -> void:
	_animated_tiles_enabled = enabled


func _process(delta: float) -> void:
	if not _animated_tiles_enabled or _animated_cells.is_empty():
		return

	for key: String in _animated_cells:
		var cell: Dictionary = _animated_cells[key]
		cell["elapsed"] += delta * 1000.0

		var durations: Array = cell["durations"]
		var index: int = cell["index"]
		if cell["elapsed"] < durations[index]:
			continue

		cell["elapsed"] = 0.0
		index = (index + 1) % cell["frames"].size()
		cell["index"] = index

		var frame: Dictionary = cell["frames"][index]
		cell["layer"].set_cell(cell["coords"], frame.source_id, frame.atlas_coords)
