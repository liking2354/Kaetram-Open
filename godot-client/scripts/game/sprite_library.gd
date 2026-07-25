class_name SpriteLibrary
## 精灵库（静态单例用法）。
##
## 解析 sprites.json，按需把精灵 PNG 切片构建为 SpriteFrames 并缓存。
## 动画数据格式（与浏览器端一致）：
##   精灵表按行排列动画，row 为行号，length 为帧数；
##   左方向动画复用右方向 + 水平翻转（由使用方 flip_h）。

## 精灵元数据 {key: data}。
static var _meta: Dictionary = {}
## SpriteFrames 缓存 {key: SpriteFrames}。
static var _frames_cache: Dictionary = {}
## 纹理缓存 {path: Texture2D}。
static var _texture_cache: Dictionary = {}
## 是否已加载元数据。
static var _loaded := false

## 玩家装备槽 -> 精灵子目录。
const EQUIPMENT_FOLDERS := {
	0: "helmet", # Helmet
	3: "chestplate", # Chestplate
	4: "weapon", # Weapon
	5: "shield", # Shield
	7: "skin", # ArmourSkin
	8: "weapon", # WeaponSkin（与武器同目录）
	9: "legplates", # Legplates
	10: "cape", # Cape
}

## 装备渲染顺序（自底向上，与浏览器端 EquipmentRenderOrder 一致）。
const EQUIPMENT_RENDER_ORDER: Array[int] = [10, 9, 3, 0, 7, 5, 4, 8]

## 非玩家实体类型 -> 精灵子目录前缀（与浏览器端 controllers/entities.ts 的 prefix 一致）。
const ENTITY_TYPE_PREFIXES := {
	1: "npcs", # NPC
	2: "items", # Item
	3: "mobs", # Mob
	4: "objects", # Chest
	5: "projectiles", # Projectile
	7: "pets", # Pet
	8: "items", # LootBag
	9: "effectentity", # Effect
	10: "trees", # Tree
	11: "rocks", # Rock
	12: "bushes", # Foraging
	13: "fishspots", # FishSpot
}


## 获取精灵的 SpriteFrames（未命中返回 null）。
static func get_sprite_frames(key: String) -> SpriteFrames:
	_ensure_loaded()

	if _frames_cache.has(key):
		return _frames_cache[key]

	if not _meta.has(key):
		return null

	var data: Dictionary = _meta[key]
	var texture := _load_texture(key)
	if not texture:
		return null

	var frames := _build_frames(key, data, texture)
	_frames_cache[key] = frames
	return frames


## 获取精灵锚点偏移（像素）。
static func get_offset(key: String) -> Vector2:
	_ensure_loaded()
	if not _meta.has(key):
		return Vector2.ZERO
	var data: Dictionary = _meta[key]
	return Vector2(float(data.get("offsetX", 0)), float(data.get("offsetY", 0)))


## 精灵是否存在。
static func has_sprite(key: String) -> bool:
	_ensure_loaded()
	return _meta.has(key)


## 获取物品图标纹理（idle 动画第一帧）。
static func get_item_texture(key: String) -> Texture2D:
	var frames := get_sprite_frames(key)
	if not frames:
		return null
	if frames.has_animation("idle") and frames.get_frame_count("idle") > 0:
		return frames.get_frame_texture("idle", 0)
	var names := frames.get_animation_names()
	if not names.is_empty() and frames.get_frame_count(names[0]) > 0:
		return frames.get_frame_texture(names[0], 0)
	return null


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true

	var file := FileAccess.open("res://assets/data/sprites.json", FileAccess.READ)
	if not file:
		push_error("[SpriteLibrary] Cannot open sprites.json")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Array:
		push_error("[SpriteLibrary] Invalid sprites.json")
		return

	for entry: Dictionary in parsed:
		var id := str(entry.get("id", ""))
		if not id.is_empty():
			_meta[id] = entry

	print("[SpriteLibrary] Loaded %d sprite definitions." % _meta.size())


static func _load_texture(key: String) -> Texture2D:
	var path := "res://assets/sprites/%s.png" % key
	if _texture_cache.has(path):
		return _texture_cache[path]
	# Use load() directly instead of ResourceLoader.exists() which may fail in editor
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		push_warning("[SpriteLibrary] Cannot load texture: %s" % path)
		return null
	_texture_cache[path] = texture
	return texture


## 根据精灵元数据构建 SpriteFrames。
static func _build_frames(key: String, data: Dictionary, texture: Texture2D) -> SpriteFrames:
	var width := int(data.get("width", _default_dimension(key)))
	var height := int(data.get("height", _default_dimension(key)))
	var idle_speed := int(data.get("idleSpeed", 250))

	var animations: Dictionary = data.get("animations", {})
	if animations.is_empty():
		animations = _default_animations(key)

	var frames := SpriteFrames.new()

	for anim_name: String in animations:
		var info: Dictionary = animations[anim_name]
		var length := int(info.get("length", 1))
		var row := int(info.get("row", 0))

		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)

		# 待机使用 idleSpeed，其余动画统一 120ms/帧。
		var speed_ms := idle_speed if anim_name.begins_with("idle") else 120
		frames.set_animation_speed(anim_name, 1000.0 / speed_ms)

		for i: int in length:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * width, row * height, width, height)
			frames.add_frame(anim_name, atlas)

	return frames


## 精灵 key 的一级类型（player/mobs/npcs/items/...）。
static func _type_of(key: String) -> String:
	if not key.contains("/"):
		return "items"
	return key.split("/")[0]


## 装备类精灵的默认帧尺寸（与原端 getDefaultEquipmentDimension 一致）。
static func _default_dimension(key: String) -> int:
	if _type_of(key) != "player":
		return 16

	var blocks := key.split("/")
	var subtype := blocks[1] if blocks.size() >= 3 else ""

	match subtype:
		"effects", "skin", "cape", "legplates", "chestplate", "helmet": # 32px 装备层
			return 32
		"shield", "weapon":
			return 48
		_:
			return 16


## 未在 sprites.json 中显式定义动画时的默认动画表
## （与原端 getDefaultAnimations 一致）。
static func _default_animations(key: String) -> Dictionary:
	match _type_of(key):
		"items", "cursors":
			return { "idle": { "length": 1, "row": 0 } }
		"npcs":
			return { "idle_down": { "length": 2, "row": 0 } }
		"trees", "rocks", "fishspots", "bushes":
			return {
				"idle": { "length": 1, "row": 0 },
				"shake": { "length": 1, "row": 1 },
				"exhausted": { "length": 1, "row": 2 },
			}
		"mobs":
			return {
				"atk_right": { "length": 5, "row": 0 },
				"walk_right": { "length": 4, "row": 1 },
				"idle_right": { "length": 2, "row": 2 },
				"atk_up": { "length": 5, "row": 3 },
				"walk_up": { "length": 4, "row": 4 },
				"idle_up": { "length": 2, "row": 5 },
				"atk_down": { "length": 5, "row": 6 },
				"walk_down": { "length": 4, "row": 7 },
				"idle_down": { "length": 2, "row": 8 },
			}
		_:
			# 玩家角色默认动画。
			return {
				"idle_down": { "length": 4, "row": 0 },
				"idle_right": { "length": 4, "row": 1 },
				"idle_up": { "length": 4, "row": 2 },
				"walk_down": { "length": 4, "row": 3 },
				"walk_right": { "length": 4, "row": 4 },
				"walk_up": { "length": 4, "row": 5 },
				"atk_down": { "length": 4, "row": 6 },
				"atk_right": { "length": 4, "row": 7 },
				"atk_up": { "length": 4, "row": 8 },
				"bow_atk_down": { "length": 4, "row": 9 },
				"bow_atk_right": { "length": 4, "row": 10 },
				"bow_atk_up": { "length": 4, "row": 11 },
			}
