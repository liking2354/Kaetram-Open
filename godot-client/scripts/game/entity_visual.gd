class_name EntityVisual
extends Node2D
## 实体可视化组件。
##
## 根据实体类型加载精灵并播放待机动画；玩家为多图层（base + 装备）。
## 左方向通过右方向动画 + flip_h 实现（与原端一致）。

## 服务端 `Modules.RankColours` 的 Godot 映射。
const RANK_COLOURS := {
	1: "#02f070", 2: "#3bbaff", 3: "#d84343", 4: "#db753c",
	5: "#b552f7", 6: "#ffffff", 7: "#db963c", 8: "#e6c843",
	9: "#d6e34b", 10: "#a9e03a", 11: "#7beb65", 12: "#77e691",
	13: "#77e691", 14: "#3bbaff", 15: "#f47fff",
}
## 由 Rank 自动授予的浏览器端皇冠（Artist、Patron Tier 1-7）。
const RANK_CROWNS := {
	5: "artist", 7: "tier1", 8: "tier2", 9: "tier3",
	10: "tier4", 11: "tier5", 12: "tier6", 13: "tier7",
}

## 实体当前朝向。
var orientation := Modules.Orientation.DOWN
## 是否正在移动（播放 walk 动画）。
var moving := false

## 精灵图层（玩家多层，其他单层）。
var _layers: Array[AnimatedSprite2D] = []
var _name_label: Label
var _level_label: Label
var _exclamation_label: Label
var _crown_icon: TextureRect
var _names_visible := true
var _levels_visible := true
## 血条（背景 + 填充）。
var _hp_bar_bg: ColorRect
var _hp_bar_fill: ColorRect
## 死亡后是否释放（供外部判断）。
var died := false
## 当前激活的状态效果集合 {effect: true}。
var _active_effects := {}
## 当前显示中的聊天/NPC 气泡（用于避免重复气泡叠加显示）。
var _bubble_label: Label
## 当前气泡的消失 tween（切换气泡时需要一并 kill，避免野指针回调）。
var _bubble_tween: Tween


## 播放攻击动画（一次），结束后回到待机/行走。
func play_attack() -> void:
	if died:
		return

	var dir := _direction_suffix()
	for layer: AnimatedSprite2D in _layers:
		var candidate := "atk_%s" % dir
		if not layer.sprite_frames.has_animation(candidate):
			continue
		layer.play(candidate)

	# 攻击动画播完后恢复当前状态动画。
	# 连续快速攻击（如连击）可能在上一次的 ONE_SHOT 回调触发前再次调用本函数，
	# 因此先判断是否已连接，避免 "Signal is already connected" 报错。
	for layer: AnimatedSprite2D in _layers:
		if not layer.is_playing():
			continue
		if not layer.animation_finished.is_connected(_play_current):
			layer.animation_finished.connect(_play_current, CONNECT_ONE_SHOT)
		break


## 受击表现：闪红 + 飘出伤害数字。
func show_hit(hit: Dictionary) -> void:
	if died:
		return

	_flash(Color(1.0, 0.3, 0.3))
	_spawn_damage_number(int(hit.get("damage", 0)), int(hit.get("type", 0)))


## 治疗表现：闪绿 + 绿色数字。
func show_heal(amount: int) -> void:
	if died:
		return
	_flash(Color(0.4, 1.0, 0.4))
	_spawn_damage_number(amount, 2) # Hits.Heal


## 更新血条。hit_points < 0 时忽略血量；满血时隐藏。
func set_health(hit_points: int, max_hit_points: int) -> void:
	if hit_points < 0 or max_hit_points <= 0:
		return

	if not _hp_bar_bg:
		_create_hp_bar()

	_hp_bar_bg.visible = hit_points < max_hit_points
	var ratio := clampf(float(hit_points) / float(max_hit_points), 0.0, 1.0)
	_hp_bar_fill.size.x = int(14.0 * ratio)
	_hp_bar_fill.color = Color(0.2, 0.85, 0.2) if ratio > 0.3 else Color(0.9, 0.2, 0.2)


## 播放死亡动画并淡出（无专用 death 动画时直接淡出）。
func play_death() -> void:
	if died:
		return
	died = true

	if _hp_bar_bg:
		_hp_bar_bg.visible = false

	var has_death := false
	for layer: AnimatedSprite2D in _layers:
		if layer.sprite_frames.has_animation("death"):
			has_death = true
			layer.play("death")

	# 淡出后自动隐藏（节点释放由外部负责）。
	var tween := create_tween()
	tween.tween_interval(0.8 if has_death else 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)


## 复活：重置死亡状态，恢复透明度和待机动画。
func revive() -> void:
	died = false
	modulate.a = 1.0
	if _hp_bar_bg:
		_hp_bar_bg.visible = true
	_play_current()


func _flash(color: Color) -> void:
	for layer: AnimatedSprite2D in _layers:
		layer.modulate = color

	var tween := create_tween()
	tween.tween_interval(0.12)
	tween.tween_callback(func() -> void:
		for layer: AnimatedSprite2D in _layers:
			layer.modulate = Color.WHITE
	)


func _spawn_damage_number(amount: int, hit_type: int) -> void:
	var label := Label.new()
	label.text = str(amount) if amount > 0 else "MISS"
	label.position = Vector2(-20, -34)
	label.custom_minimum_size = Vector2(40, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_color", _hit_color(hit_type))
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 22.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


## 伤害类型颜色（对应 Modules.Hits）。
func _hit_color(hit_type: int) -> Color:
	match hit_type:
		0: return Color(1.0, 0.35, 0.3) # Normal 红
		1: return Color(0.5, 0.9, 0.3) # Poison 绿
		2: return Color(0.35, 0.95, 0.35) # Heal 绿
		3: return Color(0.4, 0.6, 1.0) # Mana 蓝
		4: return Color(1.0, 0.85, 0.3) # Experience 黄
		5: return Color(1.0, 0.9, 0.2) # LevelUp 金
		6: return Color(1.0, 0.6, 0.1) # Critical 橙
		_: return Color.WHITE


## 添加/移除状态效果并更新着色。
func set_effect(effect: int, added: bool) -> void:
	if added:
		_active_effects[effect] = true
	else:
		_active_effects.erase(effect)
	_apply_effect_tint()


func _apply_effect_tint() -> void:
	var tint := Color.WHITE
	# 优先级：冰冻 > 燃烧 > 中毒 > 流血 > 眩晕。
	if _active_effects.has(Modules.Effects.FREEZING):
		tint = Color(0.6, 0.85, 1.0)
	elif _active_effects.has(Modules.Effects.BURNING):
		tint = Color(1.0, 0.6, 0.4)
	elif _active_effects.has(Modules.Effects.POISONBALL):
		tint = Color(0.6, 0.9, 0.4)
	elif _active_effects.has(Modules.Effects.BLEED):
		tint = Color(1.0, 0.7, 0.7)
	elif _active_effects.has(Modules.Effects.STUN):
		tint = Color(0.7, 0.7, 0.7)
	modulate = tint


## 资源被采集时的摇晃动画（trees/rocks 等有 shake 帧）。
func shake() -> void:
	for layer: AnimatedSprite2D in _layers:
		if layer.sprite_frames.has_animation("shake"):
			layer.play("shake")
			if not layer.animation_finished.is_connected(_play_current):
				layer.animation_finished.connect(_play_current, CONNECT_ONE_SHOT)


## 资源状态（0=Default 正常，1=Depleted 耗尽）。
func set_resource_state(state: int) -> void:
	for layer: AnimatedSprite2D in _layers:
		if state == 1 and layer.sprite_frames.has_animation("exhausted"):
			layer.play("exhausted")
		elif state == 0 and layer.sprite_frames.has_animation("idle"):
			layer.play("idle")


## 显示聊天气泡（duration 秒后自动消失，默认 4 秒）。
## 若已有气泡在显示，会先移除旧气泡（及其 tween）再显示新文本，避免文字叠加堆积
## 或旧 tween 回调访问已释放节点导致崩溃。
func show_bubble(text: String, duration := 4.0) -> void:
	if died:
		return

	# 先停止上一个气泡的 tween（避免其回调稍后访问已释放的 label），再移除旧气泡。
	if is_instance_valid(_bubble_tween):
		_bubble_tween.kill()
		_bubble_tween = null
	if is_instance_valid(_bubble_label):
		_bubble_label.queue_free()
	_bubble_label = null

	var label := Label.new()
	label.text = text
	label.position = Vector2(-70, -52)
	label.custom_minimum_size = Vector2(140, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	_bubble_label = label

	var tween := create_tween()
	_bubble_tween = tween
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func() -> void:
		if _bubble_label == label:
			_bubble_label = null
			_bubble_tween = null
		if is_instance_valid(label):
			label.queue_free()
	)


func _create_hp_bar() -> void:
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.size = Vector2(16, 3)
	_hp_bar_bg.position = Vector2(-8, -24)
	_hp_bar_bg.color = Color(0.1, 0.1, 0.1, 0.8)
	add_child(_hp_bar_bg)

	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.size = Vector2(14, 1)
	_hp_bar_fill.position = Vector2(1, 1)
	_hp_bar_fill.color = Color(0.2, 0.85, 0.2)
	_hp_bar_bg.add_child(_hp_bar_fill)


## 根据实体数据初始化外观。
## data 为 Spawn/Welcome 的 EntityData。
func setup(data: Dictionary) -> void:
	var type := int(data.get("type", -1))

	if type == Modules.EntityType.PLAYER:
		_setup_player_layers(data)
	else:
		var key := _entity_sprite_key(type, str(data.get("key", "")))
		_add_sprite_layer(key)

	_setup_name_label(data)
	if data.get("displayInfo", {}) is Dictionary:
		set_display_info(data.get("displayInfo", {}))
	_play_current()


## 非玩家实体的精灵 key 映射（与浏览器端 controllers/entities.ts 的 prefix 表一致）。
func _entity_sprite_key(type: int, key: String) -> String:
	var prefix: String = SpriteLibrary.ENTITY_TYPE_PREFIXES.get(type, "items")
	return "%s/%s" % [prefix, key]


## 玩家多图层：base + 各装备层（按渲染顺序）。
func _setup_player_layers(data: Dictionary) -> void:
	_add_sprite_layer("player/base")

	# 装备槽位 -> 装备数据
	var equipped := {}
	for equipment: Dictionary in data.get("equipments", []):
		var slot := int(equipment.get("type", -1))
		var key := str(equipment.get("key", ""))
		if not key.is_empty():
			equipped[slot] = key

	for slot: int in SpriteLibrary.EQUIPMENT_RENDER_ORDER:
		if not equipped.has(slot):
			continue
		var folder: String = SpriteLibrary.EQUIPMENT_FOLDERS.get(slot, "")
		if folder.is_empty():
			continue
		_add_sprite_layer("player/%s/%s" % [folder, equipped[slot]])


## 添加一个精灵图层。
func _add_sprite_layer(key: String) -> void:
	var frames := SpriteLibrary.get_sprite_frames(key)
	if not frames:
		push_warning("[EntityVisual] Sprite not found: %s" % key)
		return

	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = true
	# 精灵原点在格中心；32px 角色脚部贴合格底。
	add_child(sprite)
	_layers.append(sprite)


func _setup_name_label(data: Dictionary) -> void:
	var entity_name := str(data.get("name", ""))
	if entity_name.is_empty():
		return

	_name_label = Label.new()
	_name_label.text = entity_name
	_name_label.position = Vector2(-40, -32)
	_name_label.custom_minimum_size = Vector2(80, 0)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 8)
	var rank := int(data.get("rank", 0))
	var rank_colour := str(RANK_COLOURS.get(rank, ""))
	_name_label.add_theme_color_override(
		"font_color",
		Color("fcda5c") if str(data.get("instance", "")) == GameState.player_instance else Color.from_string(rank_colour, Color.WHITE)
	)
	_name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_name_label)

	var level := int(data.get("level", 0))
	if level > 0:
		_level_label = Label.new()
		_level_label.text = "Lv. %d" % level
		_level_label.position = Vector2(-40, -22)
		_level_label.custom_minimum_size = Vector2(80, 0)
		_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_level_label.add_theme_font_size_override("font_size", 7)
		_level_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35))
		_level_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		_level_label.add_theme_constant_override("shadow_offset_x", 1)
		_level_label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(_level_label)

	_setup_rank_crown(rank)


func _setup_rank_crown(rank: int) -> void:
	var crown_key := str(RANK_CROWNS.get(rank, ""))
	if crown_key.is_empty():
		return
	var texture := load("res://assets/sprites/crowns/%s.png" % crown_key) as Texture2D
	if not texture:
		return
	_crown_icon = TextureRect.new()
	_crown_icon.texture = texture
	_crown_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crown_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crown_icon.custom_minimum_size = Vector2(18, 18)
	_crown_icon.position = Vector2(-9, -51)
	_crown_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crown_icon)


## 重建外观图层（装备变化时调用）。
func rebuild(data: Dictionary) -> void:
	for layer: AnimatedSprite2D in _layers:
		layer.queue_free()
	_layers.clear()

	if _name_label:
		_name_label.queue_free()
		_name_label = null
	if _level_label:
		_level_label.queue_free()
		_level_label = null
	if _exclamation_label:
		_exclamation_label.queue_free()
		_exclamation_label = null

	setup(data)


## 设置名字标签可见性（设置面板"显示名字"开关）。
func set_name_visible(visible_now: bool) -> void:
	_names_visible = visible_now
	if _name_label:
		_name_label.visible = visible_now and not _exclamation_label


func set_level_visible(visible_now: bool) -> void:
	_levels_visible = visible_now
	if _level_label:
		_level_label.visible = visible_now and not _exclamation_label


## 应用 Update/Spawn 的非核心显示数据：名称颜色、缩放与任务感叹号。
func set_display_info(info: Dictionary) -> void:
	if info.has("colour") and _name_label:
		_name_label.add_theme_color_override(
			"font_color",
			_parse_display_colour(str(info.get("colour", "")))
		)
	if info.has("scale"):
		var display_scale := clampf(float(info.get("scale", 1.0)), 0.5, 3.0)
		scale = Vector2.ONE * display_scale
	if not info.has("exclamation"):
		return

	var kind := str(info.get("exclamation", ""))
	if kind.is_empty():
		if _exclamation_label:
			_exclamation_label.queue_free()
			_exclamation_label = null
		set_name_visible(_names_visible)
		set_level_visible(_levels_visible)
		return

	if not _exclamation_label:
		_exclamation_label = Label.new()
		_exclamation_label.text = "!"
		_exclamation_label.position = Vector2(-14, -50)
		_exclamation_label.custom_minimum_size = Vector2(28, 0)
		_exclamation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_exclamation_label.add_theme_font_size_override("font_size", 16)
		_exclamation_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		_exclamation_label.add_theme_constant_override("shadow_offset_x", 1)
		_exclamation_label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(_exclamation_label)
	_exclamation_label.add_theme_color_override(
		"font_color",
		Color("3b9eff") if kind == "blue" else Color("ffd73d")
	)
	# 浏览器端存在任务/成就感叹号时不会同时绘制名称和等级。
	if _name_label:
		_name_label.visible = false
	if _level_label:
		_level_label.visible = false


func _parse_display_colour(value: String) -> Color:
	var text := value.strip_edges()
	if text.begins_with("rgb(") or text.begins_with("rgba("):
		var body := text.substr(text.find("(") + 1).trim_suffix(")")
		var parts := body.split(",", false)
		if parts.size() >= 3:
			var alpha := float(parts[3].strip_edges()) if parts.size() >= 4 else 1.0
			return Color(
				clampf(float(parts[0].strip_edges()) / 255.0, 0.0, 1.0),
				clampf(float(parts[1].strip_edges()) / 255.0, 0.0, 1.0),
				clampf(float(parts[2].strip_edges()) / 255.0, 0.0, 1.0),
				clampf(alpha, 0.0, 1.0)
			)
	return Color.from_string(text, Color.WHITE)


## 设置朝向并刷新动画。
func set_orientation(value: int) -> void:
	if orientation == value:
		return
	orientation = value as Modules.Orientation
	_play_current()


## 设置移动状态并刷新动画。
func set_moving(value: bool) -> void:
	if moving == value:
		return
	moving = value
	_play_current()


## 根据朝向变化量推断朝向（用于服务端广播的移动）。
func face_delta(from_pos: Vector2i, to_pos: Vector2i) -> void:
	var dx := to_pos.x - from_pos.x
	var dy := to_pos.y - from_pos.y
	if dx < 0: set_orientation(Modules.Orientation.LEFT)
	elif dx > 0: set_orientation(Modules.Orientation.RIGHT)
	elif dy < 0: set_orientation(Modules.Orientation.UP)
	elif dy > 0: set_orientation(Modules.Orientation.DOWN)


## 播放与当前朝向/移动状态匹配的动画。
func _play_current() -> void:
	var dir := _direction_suffix()
	var flip := orientation == Modules.Orientation.LEFT

	for layer: AnimatedSprite2D in _layers:
		if not is_instance_valid(layer):
			continue

		layer.flip_h = flip

		var anim := _pick_animation(layer, dir)
		if layer.animation != anim or not layer.is_playing():
			layer.play(anim)


func _direction_suffix() -> String:
	match orientation:
		Modules.Orientation.UP: return "up"
		Modules.Orientation.LEFT, Modules.Orientation.RIGHT: return "right"
		_: return "down"


func _pick_animation(layer: AnimatedSprite2D, dir: String) -> StringName:
	var frames := layer.sprite_frames
	var prefix := "walk" if moving else "idle"
	var candidate := "%s_%s" % [prefix, dir]

	if frames.has_animation(candidate):
		return candidate
	if frames.has_animation("idle_%s" % dir):
		return "idle_%s" % dir
	if frames.has_animation("idle_down"):
		return "idle_down"
	if frames.has_animation("idle"):
		return "idle"

	# 兜底：第一个可用动画。
	var names := frames.get_animation_names()
	if names.is_empty():
		return &"default"
	return names[0]
