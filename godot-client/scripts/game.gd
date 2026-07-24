extends Node2D
## 游戏场景主控制器。
## 地图渲染、本地玩家移动/攻击、其他实体同步显示、战斗表现。

const EntityMarkerScene := preload("res://scripts/game/entity_marker.gd")
const LocalPlayerScene := preload("res://scripts/game/local_player.gd")
const ChatUIScene := preload("res://scripts/ui/chat_ui.gd")
const InventoryUIScene := preload("res://scripts/ui/inventory_ui.gd")
const CharacterUIScene := preload("res://scripts/ui/character_ui.gd")
const EquipmentUIScene := preload("res://scripts/ui/equipment_ui.gd")
const SettingsUIScene := preload("res://scripts/ui/settings_ui.gd")
const NotificationUIScene := preload("res://scripts/ui/notification_ui.gd")
const JournalUIScene := preload("res://scripts/ui/journal_ui.gd")
const StoreUIScene := preload("res://scripts/ui/store_ui.gd")
const BankUIScene := preload("res://scripts/ui/bank_ui.gd")
const CraftingUIScene := preload("res://scripts/ui/crafting_ui.gd")
const FriendsUIScene := preload("res://scripts/ui/friends_ui.gd")
const TradeUIScene := preload("res://scripts/ui/trade_ui.gd")
const GuildUIScene := preload("res://scripts/ui/guild_ui.gd")
const LootBagUIScene := preload("res://scripts/ui/lootbag_ui.gd")
const DeathUIScene := preload("res://scripts/ui/death_ui.gd")
const EnchantUIScene := preload("res://scripts/ui/enchant_ui.gd")
const QuickslotsUIScene := preload("res://scripts/ui/quickslots_ui.gd")
const WarpUIScene := preload("res://scripts/ui/warp_ui.gd")
const WelcomeUIScene := preload("res://scripts/ui/welcome_ui.gd")
const LeaderboardUIScene := preload("res://scripts/ui/leaderboard_ui.gd")
const QuestUIScene := preload("res://scripts/ui/quest_ui.gd")
const MinigameUIScene := preload("res://scripts/ui/minigame_ui.gd")
const MinimapUIScene := preload("res://scripts/ui/minimap_ui.gd")

@onready var _map_manager: MapManager = $MapManager
@onready var _camera: Camera2D = $Camera2D
@onready var _entity_layer: Node2D = $EntityLayer
@onready var _loading_label: Label = $UILayer/LoadingLabel
@onready var _ui_layer: CanvasLayer = $UILayer

var _local_player: LocalPlayer
var _chat_ui: ChatUI
## instance -> EntityMarker
var _markers := {}
var _inventory_ui: InventoryUI
var _character_ui: CharacterUI
var _equipment_ui: Control
var _settings_ui: SettingsUI
var _journal_ui: JournalUI
var _bank_ui: BankUI
var _friends_ui: FriendsUI
var _guild_ui: GuildUI
var _quickslots_ui: QuickslotsUI
var _warp_ui: WarpUI
var _leaderboard_ui: LeaderboardUI
var _welcome_ui: WelcomeUI
var _quest_ui: Control
var _store_ui: StoreUI
var _crafting_ui: CraftingUI
var _enchant_ui: EnchantUI
var _trade_ui: TradeUI
var _lootbag_ui: LootBagUI
var _notification_ui: NotificationUI
var _fps_label: Label
var _darkness_rect: ColorRect
var _lamp_overlay: ColorRect
var _darkness_active := false
var _world_modulate: CanvasModulate
## 虚拟摇杆（触屏设备移动控制，Godot 4.7 内置节点）。
var _joystick: VirtualJoystick


var _map_initialized := false


func _ready() -> void:
	# 窗口重新聚焦时请求实体重同步（防掉线期间状态漂移）。
	get_window().focus_entered.connect(func() -> void:
		Network.send_packet(Packets.FOCUS)
	)

	GameState.entity_spawned.connect(_on_entity_spawned)
	GameState.entity_despawned.connect(_on_entity_despawned)
	GameState.entity_moved.connect(_on_entity_moved)
	GameState.entity_synced.connect(_on_entity_synced)
	GameState.entity_display_updated.connect(_on_entity_display_updated)
	GameState.entity_teleported.connect(_on_entity_teleported)
	GameState.combat_hit.connect(_on_combat_hit)
	GameState.points_updated.connect(_on_points_updated)
	GameState.chat_received.connect(_on_chat_received)

	if GameState.map_ready:
		_on_map_loaded(GameState.regions)

	# 后续跨区域时服务端会再次下发 MAP 包，做增量合并。
	GameState.map_loaded.connect(_on_map_loaded)

	# 场景切换前可能已有实体进入视野。
	for instance: String in GameState.entities:
		_spawn_marker(GameState.entities[instance])

	# 挂载聊天 UI（左下角）。
	_chat_ui = ChatUIScene.new()
	_chat_ui.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_chat_ui.position = Vector2(10, -170)
	_ui_layer.add_child(_chat_ui)

	# 挂载背包 UI（右下角）。
	_inventory_ui = InventoryUIScene.new()
	_inventory_ui.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_inventory_ui.position = Vector2(-290, -280)
	_ui_layer.add_child(_inventory_ui)

	# 挂载角色面板（右侧居中）。
	_character_ui = CharacterUIScene.new()
	_character_ui.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_character_ui.position = Vector2(-300, -200)
	_ui_layer.add_child(_character_ui)

	# 挂载装备面板（居中）。
	_equipment_ui = EquipmentUIScene.new()
	_equipment_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_equipment_ui)

	# 挂载设置面板（居中）。
	_settings_ui = SettingsUIScene.new()
	_settings_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_settings_ui)
	_settings_ui.show_names_changed.connect(_on_show_names_changed)
	_settings_ui.show_levels_changed.connect(_on_show_levels_changed)
	_settings_ui.debug_mode_changed.connect(_on_debug_mode_changed)
	_settings_ui.joystick_enabled_changed.connect(_on_joystick_enabled_changed)
	_settings_ui.audio_enabled_changed.connect(_on_audio_enabled_changed)
	_settings_ui.brightness_changed.connect(_on_brightness_changed)
	_settings_ui.low_power_changed.connect(_on_low_power_changed)
	_settings_ui.fps_limit_changed.connect(_on_fps_limit_changed)

	_world_modulate = CanvasModulate.new()
	add_child(_world_modulate)
	_on_show_names_changed(_settings_ui.is_show_names_enabled())
	_on_show_levels_changed(_settings_ui.is_show_levels_enabled())
	_on_debug_mode_changed(_settings_ui.is_debug_enabled())
	_on_audio_enabled_changed(_settings_ui.is_audio_enabled())
	_on_brightness_changed(_settings_ui.get_brightness())
	_on_low_power_changed(_settings_ui.is_low_power_enabled())
	_on_fps_limit_changed(_settings_ui.get_fps_limit())

	# 虚拟摇杆（左下角，触屏设备移动控制；action_up/down/left/right 默认绑定
	# ui_up/ui_down/ui_left/ui_right，与 WASD/方向键共用同一套移动逻辑）。
	# _ui_layer 是 CanvasLayer，子节点 position 是绝对屏幕坐标。
	_joystick = VirtualJoystick.new()
	_joystick.joystick_mode = VirtualJoystick.JOYSTICK_FOLLOWING
	_joystick.visibility_mode = VirtualJoystick.VISIBILITY_ALWAYS
	_joystick.deadzone_ratio = 0.2
	_joystick.custom_minimum_size = Vector2(120, 120)
	_joystick.size = Vector2(120, 120)
	_joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	_joystick.visible = _settings_ui.is_joystick_enabled()
	_ui_layer.add_child(_joystick)
	# 延迟一帧定位到屏幕左下角（此时 size 已计算好）。
	_position_joystick.call_deferred()
	_create_remaining_ui()


## 把虚拟摇杆定位到屏幕左下角偏移 30px 处。
func _position_joystick() -> void:
	if not _joystick:
		return
	var vp_size := get_viewport_rect().size
	_joystick.position = Vector2(30, vp_size.y - _joystick.size.y - 30)
	# 同步应用可见性（_settings_ui._ready() 此时已执行）。
	_apply_joystick_visibility()


## 根据设置面板当前状态同步摇杆可见性。
func _apply_joystick_visibility() -> void:
	if _joystick and _settings_ui:
		_joystick.visible = _settings_ui.is_joystick_enabled()


## 创建其余游戏面板与状态信号连接。
func _create_remaining_ui() -> void:
	# 挂载日志面板（左侧居中）。
	_journal_ui = JournalUIScene.new()
	_journal_ui.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_journal_ui.position = Vector2(20, -200)
	_ui_layer.add_child(_journal_ui)

	# 挂载商店/银行面板（居中）。
	_store_ui = StoreUIScene.new()
	_store_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_store_ui)

	_bank_ui = BankUIScene.new()
	_bank_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_bank_ui)

	# 挂载制作面板（居中）。
	_crafting_ui = CraftingUIScene.new()
	_crafting_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_crafting_ui)

	# 挂载社交面板。
	_friends_ui = FriendsUIScene.new()
	_friends_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_friends_ui)
	_friends_ui.private_message_requested.connect(_on_friend_private_message_requested)

	var trade_ui: TradeUI = TradeUIScene.new()
	trade_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(trade_ui)
	_trade_ui = trade_ui

	_guild_ui = GuildUIScene.new()
	_guild_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_guild_ui)

	# 战利品袋（右下偏移）。
	var lootbag_ui: LootBagUI = LootBagUIScene.new()
	lootbag_ui.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	lootbag_ui.position = Vector2(-220, -320)
	_ui_layer.add_child(lootbag_ui)
	_lootbag_ui = lootbag_ui

	# 附魔界面（居中）。
	_enchant_ui = EnchantUIScene.new()
	_enchant_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_enchant_ui)

	# 底部按钮栏（右下角，与浏览器端 #buttons 一致）。
	_create_button_bar()

	# 快捷栏（底部居中）。
	_quickslots_ui = QuickslotsUIScene.new()
	_quickslots_ui.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_quickslots_ui.position = Vector2(-90, -56)
	_ui_layer.add_child(_quickslots_ui)

	# 传送面板（居中）。
	_warp_ui = WarpUIScene.new()
	_warp_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_warp_ui)

	# 排行榜面板（居中）。
	_leaderboard_ui = LeaderboardUIScene.new()
	_leaderboard_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_leaderboard_ui)

	# 欢迎弹窗（登录后显示一次）。
	_welcome_ui = WelcomeUIScene.new()
	_welcome_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_welcome_ui)
	GameState.map_loaded.connect(func(_r: Dictionary) -> void: _welcome_ui.show_once(), CONNECT_ONE_SHOT)

	# 服务端任务接取确认窗口。
	_quest_ui = QuestUIScene.new()
	_quest_ui.set_anchors_preset(Control.PRESET_CENTER)
	_ui_layer.add_child(_quest_ui)

	# 黑暗遮罩层（全屏半透明，初始隐藏）。
	_darkness_rect = ColorRect.new()
	_darkness_rect.color = Color(0, 0, 0, 0.55)
	_darkness_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_darkness_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_darkness_rect.visible = false
	_ui_layer.add_child(_darkness_rect)
	GameState.darkness_changed.connect(_on_darkness_changed)
	GameState.camera_mode_changed.connect(_on_camera_mode)

	# 死亡界面（全屏，置于最上层）。
	var death_ui: DeathUI = DeathUIScene.new()
	death_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_layer.add_child(death_ui)

	# 交易请求弹窗。
	GameState.trade_requested.connect(_on_trade_requested)

	# 复活后重定位玩家与摄像机。
	GameState.player_respawned.connect(_on_player_respawned)

	# FPS 调试标签（右上角）。
	_fps_label = Label.new()
	_fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.position = Vector2(-150, 10)
	_fps_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	_fps_label.visible = _settings_ui.is_debug_enabled()
	_ui_layer.add_child(_fps_label)

	# 通知弹窗（顶部居中）。
	var notification_ui: NotificationUI = NotificationUIScene.new()
	notification_ui.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification_ui.position = Vector2(-200, 16)
	notification_ui.custom_minimum_size = Vector2(400, 0)
	_ui_layer.add_child(notification_ui)
	_notification_ui = notification_ui

	# 小游戏状态（顶部居中，通知下方）。
	var minigame_ui: MinigameUI = MinigameUIScene.new()
	minigame_ui.set_anchors_preset(Control.PRESET_CENTER_TOP)
	minigame_ui.position = Vector2(-120, 80)
	_ui_layer.add_child(minigame_ui)

	# 装备变化时刷新本地玩家外观。
	GameState.equipment_updated.connect(_on_equipment_updated)

	# NPC 对话气泡。
	GameState.npc_talk.connect(_on_npc_talk)

	# 资源状态与采集动画。
	GameState.resource_state_changed.connect(_on_resource_state)
	GameState.entity_animation.connect(_on_entity_animation)

	# 区域音乐。
	GameState.music_changed.connect(func(song: String) -> void: Audio.play_music(song))

	# 经验飘字。
	GameState.experience_float.connect(_on_experience_float)

	# 状态效果。
	GameState.effect_changed.connect(_on_effect_changed)

	# PVP 状态。
	GameState.pvp_changed.connect(_on_pvp_changed)

	# 玩家上下线。
	GameState.player_status_changed.connect(_on_player_status)
	GameState.rank_changed.connect(_on_rank_changed)

	# 技能冷却。
	GameState.countdown_started.connect(_on_countdown)

	# 瞬移特效。
	GameState.entity_blinked.connect(_on_entity_blinked)

	# 治疗飘字。
	GameState.entity_healed.connect(_on_entity_healed)

	# 中毒状态。
	GameState.poison_changed.connect(_on_poison_changed)

	# 任务指针。
	GameState.pointer_updated.connect(_on_pointer)

	# 独立气泡。
	GameState.bubble_shown.connect(_on_bubble_shown)

	# 服务端界面开关（记录日志，预留扩展）。
	GameState.interface_toggled.connect(_on_interface_toggled)
	GameState.entity_stopped.connect(_on_entity_stopped)
	GameState.entity_following.connect(_on_entity_following)
	GameState.entity_speed_changed.connect(_on_entity_speed_changed)
	GameState.store_selected.connect(_on_store_selected)
	GameState.trade_accepted.connect(_on_trade_accepted)
	GameState.notification_popup.connect(_on_notification_popup)
	GameState.entity_teleport_animated.connect(_on_entity_teleport_animated)
	GameState.lamp_changed.connect(_on_lamp_changed)
	GameState.command_received.connect(_on_command_received)
	GameState.equipment_style_changed.connect(_on_equipment_style_changed)
	GameState.ability_toggled.connect(_on_ability_toggled)
	GameState.player_died.connect(_on_player_died)


func _unhandled_input(event: InputEvent) -> void:
	if not _local_player:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_I, KEY_B:
				_inventory_ui.toggle()
				get_viewport().set_input_as_handled()
				return
			KEY_C:
				_character_ui.toggle()
				get_viewport().set_input_as_handled()
				return
			KEY_E:
				_equipment_ui.call("toggle")
				get_viewport().set_input_as_handled()
				return
			KEY_ESCAPE:
				_settings_ui.toggle()
				get_viewport().set_input_as_handled()
				return
			KEY_Q:
				_journal_ui.toggle()
				get_viewport().set_input_as_handled()
				return
			KEY_V:
				_bank_ui.toggle()
				get_viewport().set_input_as_handled()
				return
			KEY_F:
				_friends_ui.toggle()
				get_viewport().set_input_as_handled()
				return
			KEY_G:
				_guild_ui.toggle()
				get_viewport().set_input_as_handled()
				return
			KEY_1, KEY_2, KEY_3, KEY_4:
				_quickslots_ui.activate(event.keycode - KEY_1)
				get_viewport().set_input_as_handled()
				return
			KEY_M:
				_warp_ui.toggle()
				get_viewport().set_input_as_handled()
				return
			KEY_L:
				_leaderboard_ui.toggle()
				get_viewport().set_input_as_handled()
				return

	# 滚轮缩放视角（0.5x ~ 4x）。
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.zoom = (_camera.zoom * 1.1).clamp(Vector2(0.5, 0.5), Vector2(4, 4))
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.zoom = (_camera.zoom / 1.1).clamp(Vector2(0.5, 0.5), Vector2(4, 4))
			get_viewport().set_input_as_handled()
			return

		var world_pos := get_global_mouse_position()
		var target := Vector2i(
			int(floor(world_pos.x / _map_manager.tile_size)),
			int(floor(world_pos.y / _map_manager.tile_size))
		)

		# 右键：宠物拾取 / 玩家交互菜单 / 查看怪物或物品描述。
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var pet := _find_pet_at(target)
			if pet:
				Network.send_packet(Packets.PET, { "opcode": Opcodes.Pet.PICKUP })
				get_viewport().set_input_as_handled()
				return
			var other_player := _find_player_at(target)
			if other_player:
				_show_player_actions(other_player, event.position)
				get_viewport().set_input_as_handled()
				return
			var examine_target := _find_any_entity_at(target)
			if examine_target:
				Network.send_packet(Packets.EXAMINE, [examine_target.instance])
				get_viewport().set_input_as_handled()
			return

		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		# 点击世界时关闭欢迎弹窗。
		if _welcome_ui and _welcome_ui.visible:
			_welcome_ui.visible = false

		# Ctrl+左键：GM 传送到目标格（服务端校验权限）。
		if event.ctrl_pressed:
			Network.send_packet(Packets.COMMAND, [
				Opcodes.Command.CTRL_CLICK,
				{
					"x": target.x * _map_manager.tile_size,
					"y": target.y * _map_manager.tile_size,
					"gridX": target.x,
					"gridY": target.y,
				},
			])
			get_viewport().set_input_as_handled()
			return

		# PVP 状态下左键其他玩家发起攻击；服务端继续校验区域、阵营和等级。
		var pvp_player := _find_player_at(target)
		if GameState.pvp and pvp_player and pvp_player.instance != GameState.player_instance:
			_local_player.attack_entity(pvp_player)
			get_viewport().set_input_as_handled()
			return

		# 点击怪物 -> 攻击；NPC -> 对话；资源/战利品袋 -> 交互；地面 -> 移动。
		var mob := _find_mob_at(target)
		if mob:
			_local_player.attack_entity(mob)
			get_viewport().set_input_as_handled()
			return
		var npc := _find_npc_at(target)
		if npc:
			_local_player.talk_to(npc)
			get_viewport().set_input_as_handled()
			return
		var resource := _find_resource_at(target)
		if resource:
			_local_player.interact_with(resource)
			get_viewport().set_input_as_handled()
			return
		var lootbag := _find_lootbag_at(target)
		if lootbag:
			_local_player.move_to_pickup(lootbag)
			get_viewport().set_input_as_handled()
			return
		# 掉落物品（Item 类型实体）也走拾取流程；显示等待服务端背包确认的状态。
		var item := _find_item_at(target)
		if item:
			GameState.expect_inventory_pickup()
			_local_player.move_to_pickup(item)
			get_viewport().set_input_as_handled()
			return
		# 点击空地移动，取消当前攻击/追击。
		_local_player.stop_attack()
		_local_player.request_move(target)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _local_player:
		_camera.position = _local_player.position

		# WASD/方向键持续移动（未打开输入框时）。
		if not get_viewport().gui_get_focus_owner():
			_handle_keyboard_movement()

		# 玩家被高瓦片遮挡时淡出遮罩层。
		_update_high_layer_fade()

		# 任务指针朝向目标。
		_update_pointer_arrow()
		_update_lamp_position()

	if _fps_label.visible:
		_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


## 显示名字开关：更新所有实体标签可见性。
func _on_show_names_changed(enabled: bool) -> void:
	for marker: EntityMarker in _markers.values():
		marker.get_visual().set_name_visible(enabled)
	if _local_player:
		_local_player.get_visual().set_name_visible(enabled)


## 显示等级开关：更新所有实体等级标签可见性。
func _on_show_levels_changed(enabled: bool) -> void:
	for marker: EntityMarker in _markers.values():
		marker.get_visual().set_level_visible(enabled)
	if _local_player:
		_local_player.get_visual().set_level_visible(enabled)


## 调试模式开关：显示/隐藏 FPS。
func _on_debug_mode_changed(enabled: bool) -> void:
	if _fps_label:
		_fps_label.visible = enabled


## 总音频开关。
func _on_audio_enabled_changed(enabled: bool) -> void:
	Audio.set_audio_enabled(enabled)


## 世界亮度（UI CanvasLayer 不受影响）。
func _on_brightness_changed(percent: int) -> void:
	if not _world_modulate:
		return
	var brightness := clampf(percent / 100.0, 0.3, 1.0)
	_world_modulate.color = Color(brightness, brightness, brightness, 1.0)


## 低功耗模式降低帧率并暂停动态地块动画。
func _on_low_power_changed(enabled: bool) -> void:
	_map_manager.set_animated_tiles_enabled(not enabled)
	if enabled:
		Engine.max_fps = 30
	else:
		_on_fps_limit_changed(_settings_ui.get_fps_limit())


## 手动帧率上限；低功耗模式始终优先使用 30 FPS。
func _on_fps_limit_changed(limit: int) -> void:
	if _settings_ui and _settings_ui.is_low_power_enabled():
		Engine.max_fps = 30
		return
	Engine.max_fps = maxi(limit, 0)


## 虚拟摇杆开关（设置面板切换，触屏设备移动控制）。
func _on_joystick_enabled_changed(enabled: bool) -> void:
	_joystick.visible = enabled


## 查找点击位置附近可攻击的怪物（允许 1 格容差）。
func _find_mob_at(grid: Vector2i) -> EntityMarker:
	for marker: EntityMarker in _markers.values():
		if not marker.is_mob():
			continue
		var dist := absi(marker.grid_pos.x - grid.x) + absi(marker.grid_pos.y - grid.y)
		if dist <= 1:
			return marker
	return null


## 查找点击位置的 NPC。
func _find_npc_at(grid: Vector2i) -> EntityMarker:
	for marker: EntityMarker in _markers.values():
		if marker.entity_type != Modules.EntityType.NPC:
			continue
		var dist := absi(marker.grid_pos.x - grid.x) + absi(marker.grid_pos.y - grid.y)
		if dist <= 1:
			return marker
	return null


## 查找点击位置的其他玩家，用于 Shift+点击发起交易。
func _find_player_at(grid: Vector2i) -> EntityMarker:
	for marker: EntityMarker in _markers.values():
		if marker.entity_type != Modules.EntityType.PLAYER:
			continue
		var dist := absi(marker.grid_pos.x - grid.x) + absi(marker.grid_pos.y - grid.y)
		if dist <= 1:
			return marker
	return null


## 玩家右键交互菜单：跟随、交易及添加好友。
func _show_player_actions(marker: EntityMarker, screen_position: Vector2) -> void:
	var player_info: Dictionary = GameState.entities.get(marker.instance, {})
	var username := str(player_info.get("username", player_info.get("name", "玩家")))
	if username.is_empty():
		return

	var menu := PopupMenu.new()
	menu.add_item("跟随 %s" % username, 0)
	menu.add_item("与 %s 交易" % username, 1)
	if not GameState.friends.has(username):
		menu.add_item("添加 %s 为好友" % username, 2)
	menu.id_pressed.connect(_on_player_action_selected.bind(menu, marker, username))
	menu.popup_hide.connect(menu.queue_free)
	_ui_layer.add_child(menu)
	menu.position = Vector2i(screen_position)
	menu.popup()


func _on_player_action_selected(id: int, menu: PopupMenu, marker: EntityMarker, username: String) -> void:
	match id:
		0:
			_local_player.follow_player(marker)
		1:
			_local_player.trade_with(marker)
		2:
			Network.send_packet(Packets.FRIENDS, {
				"opcode": Opcodes.Friends.ADD,
				"username": username,
			})
	menu.hide()


## 查找点击位置的可采集资源（树/岩石/鱼点/灌木）。
func _find_resource_at(grid: Vector2i) -> EntityMarker:
	for marker: EntityMarker in _markers.values():
		match marker.entity_type:
			Modules.EntityType.TREE, Modules.EntityType.ROCK, \
			Modules.EntityType.FISH_SPOT, Modules.EntityType.FORAGING:
				pass
			_:
				continue
		var dist := absi(marker.grid_pos.x - grid.x) + absi(marker.grid_pos.y - grid.y)
		if dist <= 1:
			return marker
	return null


## 查找点击位置的宠物。
func _find_pet_at(grid: Vector2i) -> EntityMarker:
	for marker: EntityMarker in _markers.values():
		if marker.entity_type != Modules.EntityType.PET:
			continue
		var dist := absi(marker.grid_pos.x - grid.x) + absi(marker.grid_pos.y - grid.y)
		if dist <= 1:
			return marker
	return null


## 查找点击位置的任意可查看实体（怪物/物品）。
func _find_any_entity_at(grid: Vector2i) -> EntityMarker:
	for marker: EntityMarker in _markers.values():
		match marker.entity_type:
			Modules.EntityType.MOB, Modules.EntityType.ITEM:
				pass
			_:
				continue
		var dist := absi(marker.grid_pos.x - grid.x) + absi(marker.grid_pos.y - grid.y)
		if dist <= 1:
			return marker
	return null


## 查找点击位置的战利品袋。
func _find_lootbag_at(grid: Vector2i) -> EntityMarker:
	for marker: EntityMarker in _markers.values():
		if marker.entity_type != Modules.EntityType.LOOT_BAG:
			continue
		var dist := absi(marker.grid_pos.x - grid.x) + absi(marker.grid_pos.y - grid.y)
		if dist <= 1:
			return marker
	return null


## 查找点击位置的掉落物品（Item 类型实体，与战利品袋拾取流程相同）。
func _find_item_at(grid: Vector2i) -> EntityMarker:
	for marker: EntityMarker in _markers.values():
		if marker.entity_type != Modules.EntityType.ITEM:
			continue
		var dist := absi(marker.grid_pos.x - grid.x) + absi(marker.grid_pos.y - grid.y)
		if dist <= 1:
			return marker
	return null


## 玩家在高位瓦片下方时淡出遮罩（树顶不挡视线）。
var _high_fade_tween: Tween


func _update_high_layer_fade() -> void:
	var high_layer := _map_manager.get_node_or_null("HighLayer") as TileMapLayer
	if not high_layer or not _local_player:
		return

	var pos := _local_player.grid_pos
	var covered := (
		high_layer.get_cell_source_id(pos) != -1
		or high_layer.get_cell_source_id(pos + Vector2i(0, -1)) != -1
	)
	var target_alpha := 0.45 if covered else 1.0

	if absf(high_layer.modulate.a - target_alpha) > 0.05:
		if _high_fade_tween:
			_high_fade_tween.kill()
		_high_fade_tween = create_tween()
		_high_fade_tween.tween_property(high_layer, "modulate:a", target_alpha, 0.2)


## 任务指针旋转朝向目标格（显示在屏幕边缘）。
func _update_pointer_arrow() -> void:
	if not _pointer_arrow or not _pointer_arrow.visible:
		return
	if not _pointer_entity_instance.is_empty():
		if _pointer_entity_instance == GameState.player_instance and _local_player:
			_pointer_target = _local_player.grid_pos
		elif _markers.has(_pointer_entity_instance):
			_pointer_target = _markers[_pointer_entity_instance].grid_pos
		else:
			_pointer_arrow.visible = false
			return
	if _pointer_target.x < 0 or not _local_player:
		return

	var target_world := _map_manager.grid_to_world(_pointer_target.x, _pointer_target.y)
	var direction := target_world - _local_player.position
	if direction.length() < 48.0:
		# 已接近目标，隐藏指针。
		_pointer_arrow.visible = false
		return

	_pointer_arrow.rotation = direction.angle()
	# 固定在屏幕顶部中央位置。
	_pointer_arrow.position = Vector2(
		get_viewport().get_visible_rect().size.x * 0.5 - 12,
		60.0
	)


## WASD/方向键移动。
func _handle_keyboard_movement() -> void:
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		_local_player.move_direction(Vector2i(0, -1))
	elif Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		_local_player.move_direction(Vector2i(0, 1))
	elif Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		_local_player.move_direction(Vector2i(-1, 0))
	elif Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		_local_player.move_direction(Vector2i(1, 0))


func _on_map_loaded(regions: Dictionary) -> void:
	# 首次全量构建；后续为跨区域增量合并。
	_map_manager.apply_regions(regions)

	# 摄像机限制在地图范围内。
	_camera.limit_left = _map_manager.camera_limit_left
	_camera.limit_top = _map_manager.camera_limit_top
	_camera.limit_right = _map_manager.camera_limit_right
	_camera.limit_bottom = _map_manager.camera_limit_bottom

	if not _map_initialized:
		_map_initialized = true
		_spawn_local_player()
		_loading_label.visible = false


func _on_entity_teleported(instance: String, x: int, y: int) -> void:
	if instance == GameState.player_instance:
		_local_player.teleport(x, y)
		_camera.position = _local_player.position
	elif _markers.has(instance):
		_markers[instance].grid_pos = Vector2i(x, y)
		_markers[instance].position = _map_manager.grid_to_world(x, y)


func _spawn_local_player() -> void:
	var data := GameState.player_data
	var grid := Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
	var speed := int(data.get("movementSpeed", 220))

	_local_player = LocalPlayerScene.new()
	_local_player.setup(_map_manager, grid, speed)
	_local_player.z_index = 5
	add_child(_local_player)

	_camera.position = _local_player.position

	# 小地图（右上角）。
	var minimap: MinimapUI = MinimapUIScene.new()
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.position = Vector2(-160, 10)
	minimap.setup(_map_manager, _local_player, _markers)
	_ui_layer.add_child(minimap)

	print("[Game] Local player at grid (%d, %d)." % [grid.x, grid.y])


func _on_entity_spawned(data: Dictionary) -> void:
	_spawn_marker(data)


func _spawn_marker(data: Dictionary) -> void:
	var instance := str(data.get("instance", ""))
	# 本地玩家不重复显示。
	if instance.is_empty() or instance == GameState.player_instance:
		return
	if _markers.has(instance):
		return

	var marker: EntityMarker = EntityMarkerScene.new()
	marker.setup(_map_manager, data)
	marker.z_index = 5
	_entity_layer.add_child(marker)
	if _settings_ui:
		marker.get_visual().set_name_visible(_settings_ui.is_show_names_enabled())
		marker.get_visual().set_level_visible(_settings_ui.is_show_levels_enabled())
	_markers[instance] = marker


func _on_entity_despawned(instance: String) -> void:
	if not _markers.has(instance):
		return

	var marker: EntityMarker = _markers[instance]
	_markers.erase(instance)

	# 怪物死亡音效。
	if marker.is_mob():
		Audio.play_sfx("kill1")

	# 播放死亡动画后释放节点。
	marker.play_death()
	await get_tree().create_timer(1.4).timeout
	if is_instance_valid(marker):
		marker.queue_free()


func _on_entity_moved(instance: String, x: int, y: int) -> void:
	if _markers.has(instance):
		_markers[instance].move_to(x, y)


func _on_entity_synced(instance: String, data: Dictionary) -> void:
	if _markers.has(instance):
		_markers[instance].sync_data(data)
		_markers[instance].get_visual().set_name_visible(_settings_ui.is_show_names_enabled())
		_markers[instance].get_visual().set_level_visible(_settings_ui.is_show_levels_enabled())


func _on_entity_display_updated(infos: Array) -> void:
	for info: Variant in infos:
		if not info is Dictionary:
			continue
		var instance := str(info.get("instance", ""))
		if instance == GameState.player_instance and _local_player:
			_local_player.get_visual().set_display_info(info)
		elif _markers.has(instance):
			_markers[instance].get_visual().set_display_info(info)


func _on_combat_hit(attacker_instance: String, target_instance: String, hit: Dictionary) -> void:
	# 攻击方播放攻击动画。
	if attacker_instance == GameState.player_instance:
		_local_player.play_attack()
	elif _markers.has(attacker_instance):
		_markers[attacker_instance].play_attack()

	# 远程攻击（距离 > 2 格）显示弹道。
	_spawn_projectile_if_ranged(attacker_instance, target_instance)

	# 受击方闪红 + 伤害数字 + 音效。
	if target_instance == GameState.player_instance:
		_local_player.show_hit(hit)
		Audio.play_sfx("hurt")
	elif _markers.has(target_instance):
		_markers[target_instance].show_hit(hit)
		Audio.play_sfx("hit1")


## 距离超过 2 格的攻击生成一个飞行弹道（箭/魔法弹的简化表现）。
func _spawn_projectile_if_ranged(attacker_instance: String, target_instance: String) -> void:
	var from_pos := Vector2.ZERO
	var to_pos := Vector2.ZERO

	if attacker_instance == GameState.player_instance:
		from_pos = _local_player.position
	elif _markers.has(attacker_instance):
		from_pos = _markers[attacker_instance].position
	else:
		return

	if target_instance == GameState.player_instance:
		to_pos = _local_player.position
	elif _markers.has(target_instance):
		to_pos = _markers[target_instance].position
	else:
		return

	# 近战（距离近）不生成弹道。
	if from_pos.distance_to(to_pos) < 40.0:
		return

	var projectile := ColorRect.new()
	projectile.size = Vector2(6, 6)
	projectile.color = Color(1.0, 0.9, 0.4)
	projectile.position = from_pos - projectile.size * 0.5
	projectile.z_index = 15
	add_child(projectile)

	var duration := from_pos.distance_to(to_pos) / 400.0
	var tween := create_tween()
	tween.tween_property(projectile, "position", to_pos - projectile.size * 0.5, maxf(duration, 0.1))
	tween.tween_callback(projectile.queue_free)


## 治疗飘字（绿色 +N）。
func _on_entity_healed(instance: String, amount: int) -> void:
	var pos := Vector2.ZERO
	if instance == GameState.player_instance and _local_player:
		pos = _local_player.position
	elif _markers.has(instance):
		pos = _markers[instance].position
	else:
		return

	# 负数 amount 表示魔法恢复（蓝色飘字），正数为生命恢复（绿色飘字）。
	var is_mana := amount < 0
	var display_amount := absi(amount)

	var label := Label.new()
	label.text = "+%d" % display_amount
	label.add_theme_font_size_override("font_size", 12)
	if is_mana:
		label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	else:
		label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.position = pos + Vector2(-10, -30)
	label.z_index = 20
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 24, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.2)
	tween.chain().tween_callback(label.queue_free)


## 中毒状态：本地玩家泛绿着色提示。
func _on_poison_changed(active: bool) -> void:
	if _local_player:
		_local_player.get_visual().set_effect(Modules.Effects.POISONBALL, active)


## 任务指针：朝向目标格或动态实体的指示箭头。
var _pointer_arrow: Label
var _pointer_target := Vector2i(-1, -1)
var _pointer_entity_instance := ""


func _on_pointer(opcode: int, info: Dictionary) -> void:
	match opcode:
		Opcodes.Pointer.LOCATION:
			_pointer_entity_instance = ""
			_pointer_target = Vector2i(int(info.get("x", 0)), int(info.get("y", 0)))
			_show_pointer()
		Opcodes.Pointer.ENTITY:
			var instance := str(info.get("instance", ""))
			if instance == GameState.player_instance or GameState.entities.has(instance):
				_pointer_entity_instance = instance
				_show_pointer()
		Opcodes.Pointer.REMOVE:
			_pointer_target = Vector2i(-1, -1)
			_pointer_entity_instance = ""
			if _pointer_arrow:
				_pointer_arrow.visible = false


func _show_pointer() -> void:
	if not _pointer_arrow:
		_pointer_arrow = Label.new()
		_pointer_arrow.text = "➤"
		_pointer_arrow.add_theme_font_size_override("font_size", 22)
		_pointer_arrow.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		_ui_layer.add_child(_pointer_arrow)
	_pointer_arrow.visible = true


## 独立气泡：实体头顶或指定坐标。
func _on_bubble_shown(info: Dictionary) -> void:
	var instance := str(info.get("instance", ""))
	var text := str(info.get("text", ""))
	var duration := float(info.get("duration", 3.0))

	if instance == GameState.player_instance and _local_player:
		_local_player.get_visual().show_bubble(text, duration)
		return
	if _markers.has(instance):
		_markers[instance].get_visual().show_bubble(text, duration)
		return

	# Position 气泡的 instance 是坐标字符串（如 "x-y"），而不是实体 ID。
	if not info.has("x") or not info.has("y"):
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.position = _map_manager.grid_to_world(int(info.get("x", 0)), int(info.get("y", 0))) + Vector2(-45, -28)
	label.custom_minimum_size = Vector2(90, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 20
	add_child(label)
	get_tree().create_timer(maxf(duration, 0.1)).timeout.connect(label.queue_free)


## 服务端界面开关：按 common Modules.Interfaces 标识路由到对应 Godot 面板。
func _on_interface_toggled(opcode: int, identifier: int) -> void:
	var should_show := opcode == Opcodes.Interface.OPEN

	match identifier:
		Modules.Interfaces.INVENTORY:
			_set_panel_visible(_inventory_ui, should_show, true)
		Modules.Interfaces.CRAFTING:
			_set_panel_visible(_crafting_ui, should_show)
		Modules.Interfaces.BANK:
			_set_panel_visible(_bank_ui, should_show, true)
		Modules.Interfaces.STORE:
			_set_panel_visible(_store_ui, should_show, true)
		Modules.Interfaces.QUESTS:
			if should_show:
				_journal_ui.show_tab(0)
			else:
				_journal_ui.visible = false
		Modules.Interfaces.QUEST:
			if not should_show:
				_quest_ui.call("hide_quest")
		Modules.Interfaces.ACHIEVEMENTS:
			if should_show:
				_journal_ui.show_tab(1)
			else:
				_journal_ui.visible = false
		Modules.Interfaces.SKILLS:
			if should_show:
				_character_ui.show_tab(1)
			else:
				_character_ui.visible = false
		Modules.Interfaces.TRADE:
			_trade_ui.visible = should_show
		Modules.Interfaces.SETTINGS:
			_settings_ui.visible = should_show
		Modules.Interfaces.WARP:
			_warp_ui.visible = should_show
		Modules.Interfaces.LEADERBOARDS:
			_leaderboard_ui.visible = should_show
		Modules.Interfaces.GUILDS:
			_guild_ui.visible = should_show
		Modules.Interfaces.FRIENDS:
			_friends_ui.visible = should_show
		Modules.Interfaces.ENCHANT:
			_enchant_ui.visible = should_show
		Modules.Interfaces.LOOTBAG:
			_lootbag_ui.visible = should_show
		Modules.Interfaces.EQUIPMENTS:
			if should_show:
				_equipment_ui.call("show_equipment")
			else:
				_equipment_ui.visible = false
		Modules.Interfaces.WELCOME:
			_welcome_ui.visible = should_show
		_:
			# Spells / Customization / Book 当前服务端不会作为游戏内独立可操作面板下发。
			pass


func _set_panel_visible(panel: Control, should_show: bool, refresh := false) -> void:
	panel.visible = should_show
	if should_show and refresh and panel.has_method("refresh"):
		panel.call("refresh")


## 瞬移特效：实体位置白色闪光。
## Blink 包：掉落物品即将消失时开始闪烁（透明度脉动），而非瞬移闪光。
func _on_entity_blinked(instance: String) -> void:
	if instance == GameState.player_instance or not _markers.has(instance):
		return
	var visual: EntityVisual = _markers[instance].get_visual()
	if not visual:
		return
	# 持续闪烁直到实体被 despawn 移除。
	# 用 visual.create_tween() 绑定到节点，节点释放时 tween 自动 kill。
	var tween := visual.create_tween()
	tween.set_loops()
	tween.tween_property(visual, "modulate:a", 0.3, 0.3)
	tween.tween_property(visual, "modulate:a", 1.0, 0.3)


## 相机模式：锁定单轴或自由跟随。
func _on_camera_mode(lock_x: bool, lock_y: bool) -> void:
	_camera.drag_horizontal_enabled = lock_x
	_camera.drag_vertical_enabled = lock_y


## 玩家死亡：停止移动、播放死亡动画、停止音乐。
func _on_player_died() -> void:
	if _local_player:
		_local_player.stop_attack()
		_local_player.get_visual().set_moving(false)
		_local_player.get_visual().play_death()
	Audio.stop_music()
	# 关闭所有交互面板。
	_store_ui.visible = false
	_bank_ui.visible = false
	_crafting_ui.visible = false
	_enchant_ui.visible = false
	_trade_ui.visible = false
	_lootbag_ui.visible = false


## 复活：玩家位置重置到复活点，重置精灵、恢复待机动画。
func _on_player_respawned() -> void:
	if not _local_player:
		return
	var grid := Vector2i(
		int(GameState.player_data.get("x", 0)),
		int(GameState.player_data.get("y", 0))
	)
	_local_player.grid_pos = grid
	_local_player.position = _map_manager.grid_to_world(grid.x, grid.y)
	_camera.position = _local_player.position
	# 重置死亡状态：恢复透明度和待机动画。
	var visual: EntityVisual = _local_player.get_visual()
	visual.revive()
	Audio.play_sfx("respawn")


## 交易请求：服务端已记录发起方；用户同意时重发 Request 即可建立交易。
func _on_trade_requested(from_username: String) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "%s 请求与你交易，是否接受？" % from_username
	dialog.ok_button_text = "接受"
	dialog.cancel_button_text = "拒绝"
	dialog.confirmed.connect(_accept_trade_request.bind(dialog, from_username))
	dialog.canceled.connect(dialog.queue_free)
	_ui_layer.add_child(dialog)
	dialog.popup_centered()


func _accept_trade_request(dialog: ConfirmationDialog, from_username: String) -> void:
	for instance: String in GameState.entities:
		var entity: Dictionary = GameState.entities[instance]
		var player_name := str(entity.get("username", entity.get("name", "")))
		if player_name == from_username:
			Network.send_packet(Packets.TRADE, {
				"opcode": Opcodes.Trade.REQUEST,
				"instance": instance,
			})
			break
	dialog.queue_free()


## PVP 状态变化：头顶骷髅标记 + 通知。
func _on_pvp_changed(state: bool) -> void:
	if not _local_player:
		return
	if state:
		_local_player.get_visual().show_bubble("PVP", 999999.0)
	else:
		_local_player.get_visual().show_bubble("", 0.1)


## 玩家上下线通知。
func _on_player_status(username: String, online: bool) -> void:
	GameState.notification_received.emit(
		"%s %s" % [username, "已上线" if online else "已下线"],
		"#64c864" if online else "#969696"
	)


func _on_rank_changed(new_rank: int) -> void:
	GameState.player_data["rank"] = new_rank
	if _local_player:
		_local_player.refresh_visual()
		_local_player.get_visual().set_name_visible(_settings_ui.is_show_names_enabled())
		_local_player.get_visual().set_level_visible(_settings_ui.is_show_levels_enabled())


func _on_friend_private_message_requested(username: String) -> void:
	if _chat_ui:
		_chat_ui.compose_private_message(username)


## 技能冷却：在实体头顶显示倒计时数字。
func _on_countdown(instance: String, time: int) -> void:
	if time <= 0:
		return
	if instance == GameState.player_instance and _local_player:
		_local_player.get_visual().show_bubble("%d" % time, 1.0)
	elif _markers.has(instance):
		_markers[instance].get_visual().show_bubble("%d" % time, 1.0)


## 状态效果着色应用到实体。
func _on_effect_changed(instance: String, effect: int, added: bool) -> void:
	if instance == GameState.player_instance:
		if _local_player:
			_local_player.get_visual().set_effect(effect, added)
	elif _markers.has(instance):
		_markers[instance].get_visual().set_effect(effect, added)


func _on_points_updated(instance: String, hit_points: int, max_hit_points: int, _mana: int, _max_mana: int) -> void:
	if instance == GameState.player_instance:
		_local_player.set_health(hit_points, max_hit_points)
	elif _markers.has(instance):
		_markers[instance].set_health(hit_points, max_hit_points)


## 装备变化：刷新本地玩家外观图层。
func _on_equipment_updated() -> void:
	if not _local_player:
		return
	_local_player.refresh_visual()
	_local_player.get_visual().set_name_visible(_settings_ui.is_show_names_enabled())
	_local_player.get_visual().set_level_visible(_settings_ui.is_show_levels_enabled())
	var attack_range := 1
	for equipment: Variant in GameState.player_data.get("equipments", []):
		if equipment is Dictionary and int(equipment.get("type", -1)) == Modules.Equipment.WEAPON:
			attack_range = int(equipment.get("attackRange", 1))
			break
	_local_player.set_attack_range(attack_range)


## 资源状态变化（采集耗尽时切换 exhausted 帧）。
func _on_resource_state(instance: String, state: int) -> void:
	if _markers.has(instance):
		_markers[instance].get_visual().set_resource_state(state)


## 采集动作动画（砍树时树摇晃 + 玩家播放工作动画）。
func _on_entity_animation(instance: String, _action: int, resource_instance: String) -> void:
	# 本地玩家采集时播放工作动画（复用攻击动作）。
	if instance == GameState.player_instance and _local_player:
		_local_player.play_attack()

	# 被采集的资源播放摇晃动画。
	if not resource_instance.is_empty() and _markers.has(resource_instance):
		_markers[resource_instance].get_visual().shake()
	elif _markers.has(instance):
		_markers[instance].get_visual().shake()


## 经验飘字：在玩家头顶显示获得的经验值。
func _on_experience_float(_instance: String, amount: int, skill: int) -> void:
	if not _local_player:
		return

	var skill_name: String = Modules.SKILL_NAMES.get(skill, "") if skill >= 0 else ""
	var text := "+%d %s" % [amount, skill_name]

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.position = _local_player.position + Vector2(-20, -30)
	label.z_index = 20
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 24, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.2)
	tween.chain().tween_callback(label.queue_free)


## NPC 对话文本在其头顶显示（空文本表示对话结束，清除气泡）。
func _on_npc_talk(instance: String, text: String) -> void:
	if text.is_empty():
		# 对话结束，清除气泡。
		if _markers.has(instance):
			_markers[instance].get_visual().show_bubble("")
		return
	if _markers.has(instance):
		_markers[instance].get_visual().show_bubble(text)


## 实体停止移动。
func _on_entity_stopped(instance: String) -> void:
	if _markers.has(instance):
		_markers[instance].get_visual().set_moving(false)


## 实体跟随目标（宠物跟随主人）：具体位置仍由服务端 Movement 包驱动。
func _on_entity_following(instance: String, target: String) -> void:
	if _markers.has(instance):
		_markers[instance].set_follow_target(target)


## 实体速度变化。
func _on_entity_speed_changed(instance: String, speed: int) -> void:
	if _markers.has(instance):
		_markers[instance].movement_speed = maxi(speed, 1)


## 商店选中物品。
func _on_store_selected(item: Dictionary) -> void:
	_store_ui.show_selected(item)


## 交易接受状态由交易面板显示；真正完成由服务端通知包告知。
func _on_trade_accepted(_message: String) -> void:
	pass


## 弹窗通知（带音效）。
func _on_notification_popup(message: String, _colour: String) -> void:
	_notification_ui.push_text(message, Color(1.0, 0.8, 0.0))
	Audio.play_sfx("notification")


## 实体动画传送（先播死亡动画再传送）。
func _on_entity_teleport_animated(instance: String, x: int, y: int) -> void:
	# 动画传送复用普通传送逻辑（已包含位置更新和视觉同步）。
	_on_entity_teleported(instance, x, y)


## 服务端黑暗区域状态；灯光启用时由径向遮罩替代普通全屏遮罩。
func _on_darkness_changed(active: bool) -> void:
	_darkness_active = active
	if _darkness_rect:
		_darkness_rect.visible = active and not _lamp_overlay


## 灯光效果开关：使用 Shader 生成随本地玩家屏幕位置移动的透明光圈。
func _on_lamp_changed(active: bool) -> void:
	if active:
		if not _lamp_overlay:
			_lamp_overlay = ColorRect.new()
			_lamp_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			_lamp_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var shader := Shader.new()
			shader.code = "shader_type canvas_item; uniform vec2 center = vec2(0.5); uniform float radius = 0.17; uniform float softness = 0.12; uniform float darkness = 0.72; void fragment() { float d = distance(UV, center); float a = smoothstep(radius, radius + softness, d) * darkness; COLOR = vec4(0.0, 0.0, 0.0, a); }"
			var shader_material := ShaderMaterial.new()
			shader_material.shader = shader
			_lamp_overlay.material = shader_material
			_ui_layer.add_child(_lamp_overlay)
		_update_lamp_position()
		if _darkness_rect:
			_darkness_rect.visible = false
	elif _lamp_overlay:
		_lamp_overlay.queue_free()
		_lamp_overlay = null
		if _darkness_rect:
			_darkness_rect.visible = _darkness_active


func _update_lamp_position() -> void:
	if not _lamp_overlay or not _local_player:
		return
	var shader_material := _lamp_overlay.material as ShaderMaterial
	if not shader_material:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var screen_position: Vector2 = get_viewport().get_canvas_transform() * _local_player.global_position
	shader_material.set_shader_parameter("center", Vector2(
		clampf(screen_position.x / viewport_size.x, 0.0, 1.0),
		clampf(screen_position.y / viewport_size.y, 0.0, 1.0)
	))


## 管理命令。
func _on_command_received(command: String) -> void:
	match command:
		"debug":
			_fps_label.visible = not _fps_label.visible
		"hide":
			# 隐身切换，本地玩家半透明显示。
			if not _local_player:
				return
			var visual: EntityVisual = _local_player.get_visual()
			if visual.modulate.a > 0.7:
				visual.modulate.a = 0.5
			else:
				visual.modulate.a = 1.0


## 装备攻击样式变化。
func _on_equipment_style_changed(_style: int, attack_range: int) -> void:
	if _local_player:
		_local_player.set_attack_range(attack_range)


## 技能开关切换。
func _on_ability_toggled(_key: String, _enabled: bool) -> void:
	# 技能开关状态变化，更新快捷栏显示。
	_quickslots_ui.refresh()


## 创建底部按钮栏（与浏览器端 #buttons 一致）。
## 每个按钮显示文字标签 + 对应快捷键提示，点击切换面板显隐。
## _ui_layer 是 CanvasLayer（不是 Control），所以子节点 position 是绝对屏幕坐标，
## 不能用 set_anchors_preset。需要用 get_viewport_rect() 算屏幕尺寸手动定位。
func _create_button_bar() -> void:
	var wrapper := VBoxContainer.new()
	wrapper.name = "ButtonBar"
	wrapper.add_theme_constant_override("separation", 2)
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	# 先 add_child 再调整位置（add_child 后才能正确计算 size）。
	_ui_layer.add_child(wrapper)

	# 第一行：主面板按钮（与浏览器端 #buttons 一致）。
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 2)
	row1.mouse_filter = Control.MOUSE_FILTER_PASS
	wrapper.add_child(row1)

	_make_bar_button(row1, "背包(I)", _inventory_ui)
	_make_bar_button(row1, "角色(C)", _character_ui)
	_make_bar_button(row1, "装备(E)", _equipment_ui)
	_make_bar_button(row1, "传送(M)", _warp_ui)
	_make_bar_button(row1, "好友(F)", _friends_ui)
	_make_bar_button(row1, "公会(G)", _guild_ui)
	_make_bar_button(row1, "排行(L)", _leaderboard_ui)

	# 第二行：辅助面板按钮。
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 2)
	row2.mouse_filter = Control.MOUSE_FILTER_PASS
	wrapper.add_child(row2)

	_make_bar_button(row2, "日志(Q)", _journal_ui)
	_make_bar_button(row2, "银行(V)", _bank_ui)
	_make_bar_button(row2, "商店", _store_ui)
	_make_bar_button(row2, "制作", _crafting_ui)
	_make_bar_button(row2, "附魔", _enchant_ui)
	_make_bar_button(row2, "交易", _trade_ui)
	_make_bar_button(row2, "拾取", _lootbag_ui)
	_make_bar_button(row2, "设置(Esc)", _settings_ui)

	# 用 get_viewport_rect() 获取屏幕尺寸，把按钮栏定位到屏幕右下角。
	# 延迟一帧让 layout 生效（否则 wrapper.size 还是 0）。
	_position_button_bar.call_deferred(wrapper)


## 把底部按钮栏定位到屏幕右下角偏移 10px 处。
func _position_button_bar(bar: Control) -> void:
	var vp_size := get_viewport_rect().size
	bar.position = Vector2(vp_size.x - bar.size.x - 10, vp_size.y - bar.size.y - 10)
	# 同步重置包装节点自身大小（VBoxContainer 不会自动设置）。
	bar.size = bar.get_minimum_size() if bar.size == Vector2.ZERO else bar.size


## 创建单个底部按钮（文字标签 + 点击 toggle 对应面板）。
func _make_bar_button(parent: HBoxContainer, label_text: String, panel: Control) -> void:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 28)
	btn.add_theme_font_size_override("font_size", 10)
	btn.tooltip_text = label_text
	# 用实例方法 + .bind() 替代 lambda，避免 lambda 闭包 self 失效导致
	# "Invalid access to property or key 'visible' on a base object of type 'Nil'"。
	btn.pressed.connect(_on_bar_button_pressed.bind(panel))
	parent.add_child(btn)


## 底部按钮点击：切换对应面板的显隐。
func _on_bar_button_pressed(panel: Control) -> void:
	if is_instance_valid(panel):
		panel.visible = not panel.visible


## 聊天消息：带气泡的玩家消息在对应实体头顶显示。
func _on_chat_received(info: Dictionary) -> void:
	if not bool(info.get("withBubble", false)):
		return

	var instance := str(info.get("instance", ""))
	var message := str(info.get("message", ""))
	if message.is_empty():
		return

	if instance == GameState.player_instance:
		_local_player.get_visual().show_bubble(message)
	elif _markers.has(instance):
		_markers[instance].get_visual().show_bubble(message)
