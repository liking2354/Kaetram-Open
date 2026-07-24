extends Node
## 全局游戏状态（Autoload: GameState）
##
## 独立于界面场景，持续监听 Network 的数据包并缓存关键游戏数据，
## 使场景切换（登录界面 -> 游戏场景）时数据不丢失。

## 收到 Welcome 玩家数据（登录成功）。
signal welcome_received(data: Dictionary)
## 地图区域数据解压并解析完成。
signal map_loaded(regions: Dictionary)
## 实体进入视野。
signal entity_spawned(data: Dictionary)
## 实体离开视野。
signal entity_despawned(instance: String)
## 实体移动到新坐标（服务端广播的 Movement.Move）。
signal entity_moved(instance: String, x: int, y: int)
## 实体瞬移（门/传送点，服务端强制位置修正）。
signal entity_teleported(instance: String, x: int, y: int)
## 战斗命中（Combat.Hit 广播）。
signal combat_hit(attacker_instance: String, target_instance: String, hit: Dictionary)
## 实体血量/魔法更新（Points 包）。
signal points_updated(instance: String, hit_points: int, max_hit_points: int, mana: int, max_mana: int)
## 收到聊天消息（Chat 包）。
signal chat_received(info: Dictionary)
## 背包内容变化。
signal inventory_updated
## 本地玩家装备变化（Equip/Unequip）。
signal equipment_updated
## NPC 对话文本（气泡显示）。
signal npc_talk(instance: String, text: String)
## NPC 打开银行。
signal npc_bank(slots: Array)
## 资源状态变化（Default/Depleted）。
signal resource_state_changed(instance: String, state: int)
## 实体动作动画（砍树等），resource_instance 为被采集资源。
signal entity_animation(instance: String, action: int, resource_instance: String)
## 系统通知消息。
signal notification_received(message: String, colour: String)
## 区域音乐切换（Music 包）。
signal music_changed(song: String)
## 技能数据变化。
signal skills_updated
## 玩家经验/等级变化。
signal experience_updated
## 经验飘字（获得经验时）。amount=-1 表示升级提示。
signal experience_float(instance: String, amount: int, skill: int)
## 任务数据变化。
signal quests_updated
## 服务端请求玩家确认接取某个任务。
signal quest_start_requested(quest: Dictionary)
## 成就数据变化。
signal achievements_updated
## 银行内容变化。
signal bank_updated
## 商店打开（含商品列表）。
signal store_opened(key: String, currency: String, items: Array)
## 商店关闭。
signal store_closed
## 商店商品变化。
signal store_updated(items: Array)
## 制作界面打开（技能类型 + 可制作物品预览）。
signal crafting_opened(skill_type: int, previews: Array)
## 制作物品详情（选中后，含材料需求）。
signal crafting_selected(details: Dictionary)
## 实体状态效果变化（added=true 添加，false 移除）。
signal effect_changed(instance: String, effect: int, added: bool)
## 好友列表变化。
signal friends_updated
## 交易请求/打开/关闭。
signal trade_requested(from_username: String)
signal trade_opened
signal trade_closed
## 交易内容变化（自己的/对方的物品）。
signal trade_updated
## 公会数据变化。
signal guild_updated
## 可加入公会列表变化。
signal guild_list_updated(guilds: Array, total: int)
## 公会聊天消息。
signal guild_chat_received(username: String, server_id: int, message: String)
## 公会界面内错误。
signal guild_error_received(message: String)
## 战利品袋打开（含物品列表）。
signal lootbag_opened(items: Array)
## 战利品袋关闭。
signal lootbag_closed
## 战利品袋内某个物品已被拿走。
signal lootbag_item_taken(index: int)
## 本地玩家死亡。
signal player_died
## 本地玩家复活。
signal player_respawned
## 附魔界面打开。
signal enchant_opened
## 附魔物品选中变化。
signal enchant_item_selected(index: int, is_shard: bool)
## 技能数据变化。
signal abilities_updated
## 本地玩家 PVP 状态变化。
signal pvp_changed(state: bool)
## 玩家上线/下线通知（online=true 上线）。
signal player_status_changed(username: String, online: bool)
## 本地玩家排位变化。
signal rank_changed(rank: int)
## 实体技能冷却倒计时。
signal countdown_started(instance: String, time: int)
## 黑暗遮罩开关（洞穴/夜晚）。
signal darkness_changed(active: bool)
## 相机模式变化（Godot Camera2D drag_lock 语义）。
signal camera_mode_changed(lock_x: bool, lock_y: bool)
## 实体瞬移（Blink 特效）。
signal entity_blinked(instance: String)
## 小游戏状态变化（type=游戏类型, action=动作, info=数据含比分/倒计时）。
signal minigame_updated(type: int, action: int, info: Dictionary)
## 实体治疗（飘绿色数字）。
signal entity_healed(instance: String, amount: int)
## 本地玩家中毒状态变化。
signal poison_changed(active: bool)
## 玩家数据二次同步（属性/装备修正）。
signal player_synced
## 实体显示信息更新（改名等）。
signal entity_display_updated(infos: Array)
## 远端实体完整资料同步。
signal entity_synced(instance: String, data: Dictionary)
## 任务指针（opcode=Location/Entity/Relative/Remove）。
signal pointer_updated(opcode: int, info: Dictionary)
## 独立气泡（实体头顶或指定位置）。
signal bubble_shown(info: Dictionary)
## 服务端控制界面开关（opcode=Open/Close, identifier=界面ID）。
signal interface_toggled(opcode: int, identifier: int)
## 实体停止移动（Movement.Stop 广播）。
signal entity_stopped(instance: String)
## 实体跟随目标（Movement.Follow 广播）。
signal entity_following(instance: String, target_instance: String)
## 实体移动速度变化（Movement.Speed 广播）。
signal entity_speed_changed(instance: String, speed: int)
## 商店选中物品（显示售价信息）。
signal store_selected(item: Dictionary)
## 交易接受状态更新（message 为空表示重置状态）。
signal trade_accepted(message: String)
## 技能开关切换。
signal ability_toggled(key: String, enabled: bool)
## 弹窗通知（带音效）。
signal notification_popup(message: String, colour: String)
## 玩家攻击样式变化（近战/弓/法杖 + 攻击范围）。
signal equipment_style_changed(style: int, attack_range: int)
## 实体传送带动画（withAnimation=true 时先播死亡动画再传送）。
signal entity_teleport_animated(instance: String, x: int, y: int)
## 灯光效果（暗黑洞穴中玩家周围的光照圈）。
signal lamp_changed(active: bool)
## 管理命令（debug 切换调试, hide 隐身）。
signal command_received(command: String)

## 玩家数据已缓存（场景切换后可读取）。
var player_data: Dictionary = {}
## 已解析的地图区域数据 {regionId: [{x, y, data, c?, ...}]}。
var regions: Dictionary = {}
## 地图数据是否已就绪。
var map_ready := false

## 当前视野内的实体 {instance: EntityData}。
var entities: Dictionary = {}
## 先于 Spawn 到达的 EntityDisplayInfo {instance: info}。
var _pending_display_infos: Dictionary = {}
## 本地玩家的 instance id。
var player_instance := ""
## 服务器 ID。
var server_id := -1
## 背包 {index: SlotData}。
var inventory: Dictionary = {}
## 是否已收到服务端的首个背包快照或增量包。
var inventory_initialized := false
## 是否正在等待掉落物拾取的服务端背包确认。
var inventory_pickup_pending := false
var _inventory_pickup_pending_until := 0
## 技能 {type: SkillData}（type=经验/等级/升级所需经验/百分比）。
var skills: Dictionary = {}
## 任务 {key: QuestData}。
var quests: Dictionary = {}
## 成就 {key: AchievementData}。
var achievements: Dictionary = {}
## 银行 {index: SlotData}。
var bank: Dictionary = {}
## 当前商店 key（空 = 未打开）。
var store_key := ""
## 当前商店货币。
var store_currency := ""
## 当前商店商品列表。
var store_items: Array = []
## 好友列表 {username: {online, serverId}}。
var friends: Dictionary = {}
## 交易中自己的物品 {index: slot}。
var trade_my_items: Dictionary = {}
## 交易中对方的物品 {index: slot}。
var trade_their_items: Dictionary = {}
## 当前交易对方的实体实例 ID。
var trade_other_instance := ""
## 是否处于交易中。
var trading := false
## 当前公会数据（Login 包快照及后续增量同步）。
var guild: Dictionary = {}
## 可加入公会列表（Guild.List）。
var available_guilds: Array = []
var available_guild_total := 0
## 技能 {key: AbilityData}。
var abilities: Dictionary = {}
## 本地玩家 PVP 状态。
var pvp := false
## 本地玩家排位。
var rank := 0

## 服务端时间与本地时间（msec）的偏移，用于 Step 包时间戳。
## 计算方式：handshake 时刻 local_msec - serverTime。
var time_offset := 0
## 未知实体移动时请求 List.Spawns 的节流时间戳。
var _last_entity_list_request_msec := 0


func _ready() -> void:
	Network.packet_received.connect(_on_packet_received)


func _process(_delta: float) -> void:
	if inventory_pickup_pending and Time.get_ticks_msec() >= _inventory_pickup_pending_until:
		inventory_pickup_pending = false
		inventory_updated.emit()


func reset() -> void:
	player_data = {}
	regions = {}
	map_ready = false
	entities = {}
	_pending_display_infos = {}
	_last_entity_list_request_msec = 0
	player_instance = ""
	server_id = -1
	time_offset = 0
	inventory = {}
	inventory_initialized = false
	inventory_pickup_pending = false
	_inventory_pickup_pending_until = 0
	skills = {}
	quests = {}
	achievements = {}
	bank = {}
	store_key = ""
	store_currency = ""
	store_items = []
	friends = {}
	trade_my_items = {}
	trade_their_items = {}
	trade_other_instance = ""
	trading = false
	guild = {}
	abilities = {}
	pvp = false
	rank = -1


func _on_packet_received(packet_id: int, args: Array) -> void:
	match packet_id:
		Packets.HANDSHAKE:
			_handle_handshake(args)
		Packets.WELCOME:
			_handle_welcome(args)
		Packets.MAP:
			_handle_map(args)
		Packets.SPAWN:
			_handle_spawn(args)
		Packets.DESPAWN:
			_handle_despawn(args)
		Packets.MOVEMENT:
			_handle_movement(args)
		Packets.TELEPORT:
			_handle_teleport(args)
		Packets.COMBAT:
			_handle_combat(args)
		Packets.POINTS:
			_handle_points(args)
		Packets.CHAT:
			_handle_chat(args)
		Packets.CONTAINER:
			_handle_container(args)
		Packets.EQUIPMENT:
			_handle_equipment(args)
		Packets.NPC:
			_handle_npc(args)
		Packets.LIST:
			_handle_list(args)
		Packets.RESOURCE:
			_handle_resource(args)
		Packets.ANIMATION:
			_handle_animation(args)
		Packets.NOTIFICATION:
			_handle_notification(args)
		Packets.MUSIC:
			_handle_music(args)
		Packets.SKILL:
			_handle_skill(args)
		Packets.EXPERIENCE:
			_handle_experience(args)
		Packets.QUEST:
			_handle_quest(args)
		Packets.ACHIEVEMENT:
			_handle_achievement(args)
		Packets.STORE:
			_handle_store(args)
		Packets.CRAFTING:
			_handle_crafting(args)
		Packets.EFFECT:
			_handle_effect(args)
		Packets.FRIENDS:
			_handle_friends(args)
		Packets.TRADE:
			_handle_trade(args)
		Packets.GUILD:
			_handle_guild(args)
		Packets.LOOT_BAG:
			_handle_lootbag(args)
		Packets.DEATH:
			_handle_death(args)
		Packets.RESPAWN:
			_handle_respawn(args)
		Packets.ENCHANT:
			_handle_enchant(args)
		Packets.ABILITY:
			_handle_ability(args)
		Packets.PVP:
			_handle_pvp(args)
		Packets.PLAYER:
			_handle_player(args)
		Packets.RANK:
			_handle_rank(args)
		Packets.COUNTDOWN:
			_handle_countdown(args)
		Packets.NETWORK:
			_handle_network(args)
		Packets.OVERLAY:
			_handle_overlay(args)
		Packets.CAMERA:
			_handle_camera(args)
		Packets.BLINK:
			_handle_blink(args)
		Packets.MINIGAME:
			_handle_minigame(args)
		Packets.HEAL:
			_handle_heal(args)
		Packets.POISON:
			_handle_poison(args)
		Packets.SYNC:
			_handle_sync(args)
		Packets.UPDATE:
			_handle_update(args)
		Packets.POINTER:
			_handle_pointer(args)
		Packets.BUBBLE:
			_handle_bubble(args)
		Packets.INTERFACE:
			_handle_interface(args)
		Packets.COMMAND:
			_handle_command(args)


func _handle_handshake(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	var data: Dictionary = args[0]
	server_id = int(data.get("serverId", -1))
	player_instance = str(data.get("instance", ""))
	time_offset = Time.get_ticks_msec() - int(data.get("serverTime", 0))


func _handle_welcome(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	player_data = args[0]
	# Welcome 中的 instance 可能与 handshake 一致，以此为准。
	if player_data.has("instance"):
		player_instance = str(player_data["instance"])
	welcome_received.emit(player_data)

	# 登录成功后必须立即发送 READY，否则服务端 7 秒后会主动断开连接，
	# 且服务端只在收到 READY 之后才会下发 MAP 包。
	Network.send_packet(Packets.READY, {
		"regionsLoaded": false,
		"userAgent": "godot-client",
	})


## MAP 包：args[0] 为 base64(gzip(JSON.stringify(RegionData))) 字符串。
func _handle_map(args: Array) -> void:
	if args.is_empty() or not args[0] is String:
		push_warning("[GameState] MAP packet malformed.")
		return

	var compressed := Marshalls.base64_to_raw(args[0])
	var decompressed := compressed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	if decompressed.is_empty():
		push_error("[GameState] Failed to decompress map data.")
		return

	var parsed: Variant = JSON.parse_string(decompressed.get_string_from_utf8())
	if not parsed is Dictionary:
		push_error("[GameState] Failed to parse map region JSON.")
		return

	regions = parsed
	map_ready = true
	map_loaded.emit(regions)
	print("[GameState] Map loaded: %d regions." % regions.size())


func _handle_spawn(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	var data: Dictionary = args[0]
	var instance := str(data.get("instance", ""))
	if instance.is_empty():
		return
	var entity_data := data.duplicate(true)
	if _pending_display_infos.has(instance):
		entity_data["displayInfo"] = _pending_display_infos[instance]
		_pending_display_infos.erase(instance)
	entities[instance] = entity_data
	entity_spawned.emit(entity_data)


func _handle_despawn(args: Array) -> void:
	if args.is_empty():
		return
	# DespawnPacket 序列化为 [Packets.Despawn, {instance:"xxx"}]
	# args[0] 是 Dictionary，需从中提取 instance 字段。
	var instance := ""
	if args[0] is Dictionary:
		instance = str(args[0].get("instance", ""))
	else:
		instance = str(args[0])
	if instance.is_empty():
		return
	if entities.erase(instance):
		entity_despawned.emit(instance)


func _handle_movement(args: Array) -> void:
	# args = [opcode, info]
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]
	var instance := str(info.get("instance", ""))
	if instance.is_empty():
		return

	# 本地玩家不在 entities 表；其他未知实体说明 Spawn 与 Movement 乱序。
	if instance != player_instance and not entities.has(instance):
		_request_entity_list_if_needed()
		return

	match opcode:
		Opcodes.Movement.MOVE:
			var x := int(info.get("x", 0))
			var y := int(info.get("y", 0))
			if entities.has(instance):
				entities[instance]["x"] = x
				entities[instance]["y"] = y
			entity_moved.emit(instance, x, y)
		Opcodes.Movement.STOP:
			if entities.has(instance):
				entities[instance]["x"] = int(info.get("x", 0))
				entities[instance]["y"] = int(info.get("y", 0))
			entity_stopped.emit(instance)
		Opcodes.Movement.FOLLOW:
			entity_following.emit(instance, str(info.get("target", "")))
		Opcodes.Movement.SPEED:
			var movement_speed := int(info.get("movementSpeed", 1))
			if entities.has(instance):
				entities[instance]["movementSpeed"] = movement_speed
			entity_speed_changed.emit(instance, movement_speed)


func _request_entity_list_if_needed() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_entity_list_request_msec <= 5000:
		return
	_last_entity_list_request_msec = now
	Network.send_packet(Packets.LIST)


func _handle_combat(args: Array) -> void:
	# args = [opcode, info]，仅处理 Hit（其余为战斗状态同步）。
	if args.size() < 2 or int(args[0]) != Opcodes.Combat.HIT or not args[1] is Dictionary:
		return

	var info: Dictionary = args[1]
	combat_hit.emit(
		str(info.get("instance", "")),
		str(info.get("target", "")),
		info.get("hit", {})
	)


func _handle_points(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return

	var info: Dictionary = args[0]
	points_updated.emit(
		str(info.get("instance", "")),
		int(info.get("hitPoints", -1)),
		int(info.get("maxHitPoints", -1)),
		int(info.get("mana", -1)),
		int(info.get("maxMana", -1)),
	)


func _handle_teleport(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return

	var info: Dictionary = args[0]
	var instance := str(info.get("instance", ""))
	var x := int(info.get("x", 0))
	var y := int(info.get("y", 0))
	var with_animation := bool(info.get("withAnimation", false))

	if entities.has(instance):
		entities[instance]["x"] = x
		entities[instance]["y"] = y

	# 本地玩家的初始落点传送可能与 Welcome 坐标不一致，同步修正。
	if instance == player_instance and not player_data.is_empty():
		player_data["x"] = x
		player_data["y"] = y

	if with_animation:
		entity_teleport_animated.emit(instance, x, y)
	else:
		entity_teleported.emit(instance, x, y)


func _handle_chat(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	chat_received.emit(args[0])


## CONTAINER 包：背包（Inventory=1）/ 银行（Bank=0）的批量/增删同步。
func _handle_container(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]
	var container_type := int(info.get("type", -1))

	match container_type:
		1: # Inventory
			match opcode:
				Opcodes.Containers.BATCH:
					inventory.clear()
					var data: Dictionary = info.get("data", {})
					for slot: Dictionary in data.get("slots", []):
						_apply_inventory_slot(slot)
				Opcodes.Containers.ADD:
					_apply_inventory_slot(info.get("slot", {}))
				Opcodes.Containers.REMOVE:
					var slot: Dictionary = info.get("slot", {})
					if not slot.is_empty():
						inventory.erase(int(slot.get("index", -1)))
			inventory_initialized = true
			inventory_pickup_pending = false
			_inventory_pickup_pending_until = 0
			inventory_updated.emit()
		0: # Bank
			match opcode:
				Opcodes.Containers.BATCH:
					bank.clear()
					var data: Dictionary = info.get("data", {})
					for slot: Dictionary in data.get("slots", []):
						bank[int(slot.get("index", 0))] = slot
				Opcodes.Containers.ADD:
					var slot: Dictionary = info.get("slot", {})
					if not slot.is_empty():
						bank[int(slot.get("index", 0))] = slot
				Opcodes.Containers.REMOVE:
					var slot: Dictionary = info.get("slot", {})
					if not slot.is_empty():
						bank.erase(int(slot.get("index", 0)))
			bank_updated.emit()


func _apply_inventory_slot(slot_data: Variant) -> void:
	if not slot_data is Dictionary:
		return
	var index := int(slot_data.get("index", -1))
	var key := str(slot_data.get("key", ""))
	var count := int(slot_data.get("count", 0))
	if index < 0:
		return
	if key.is_empty() or count < 1:
		inventory.erase(index)
		return
	inventory[index] = slot_data.duplicate(true)


## 在点击地面掉落物时标记待确认状态；只在服务端 Container 包到达后显示物品。
func expect_inventory_pickup() -> void:
	inventory_pickup_pending = true
	_inventory_pickup_pending_until = Time.get_ticks_msec() + 5000
	inventory_updated.emit()


## EQUIPMENT 包：装备穿上/脱下同步，更新玩家外观。
func _handle_equipment(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	match opcode:
		Opcodes.Equipment.BATCH:
			# 服务端结构为 {data: {equipments: [...]}}，而非直接 equipments。
			if player_data.is_empty():
				return
			var batch_data: Dictionary = info.get("data", {})
			player_data["equipments"] = batch_data.get("equipments", [])
		Opcodes.Equipment.EQUIP:
			var data: Dictionary = info.get("data", {})
			_update_player_equipment(int(data.get("type", -1)), data)
		Opcodes.Equipment.UNEQUIP:
			var slot_type := int(info.get("type", -1))
			var remaining_count := int(info.get("count", 0))
			if remaining_count > 0:
				_update_player_equipment_count(slot_type, remaining_count)
			else:
				_update_player_equipment(slot_type, {})
		Opcodes.Equipment.STYLE:
			# 服务端字段是 attackStyle，不是 style。
			var style := int(info.get("attackStyle", Modules.AttackStyle.NONE))
			var attack_range := int(info.get("attackRange", 1))
			if not player_data.is_empty():
				player_data["attackStyle"] = style
				player_data["attackRange"] = attack_range
			equipment_style_changed.emit(style, attack_range)

	equipment_updated.emit()


## 更新玩家数据中的装备槽位。
func _update_player_equipment(slot_type: int, equipment: Dictionary) -> void:
	if player_data.is_empty() or slot_type < 0:
		return
	var equipments: Array = player_data.get("equipments", [])
	var found := false
	for i: int in equipments.size():
		if int(equipments[i].get("type", -1)) == slot_type:
			if equipment.is_empty():
				equipments.remove_at(i)
			else:
				equipments[i] = equipment.duplicate(true)
			found = true
			break
	if not found and not equipment.is_empty():
		equipments.append(equipment.duplicate(true))
	player_data["equipments"] = equipments


func _update_player_equipment_count(slot_type: int, count: int) -> void:
	if player_data.is_empty() or slot_type < 0:
		return
	var equipments: Array = player_data.get("equipments", [])
	for equipment: Dictionary in equipments:
		if int(equipment.get("type", -1)) == slot_type:
			equipment["count"] = count
			break
	player_data["equipments"] = equipments


func _handle_npc(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	match opcode:
		Opcodes.NPC.TALK:
			var text := str(info.get("text", ""))
			# 空文本表示对话结束，清除气泡。
			npc_talk.emit(str(info.get("instance", "")), text)
		Opcodes.NPC.BANK:
			bank.clear()
			for slot: Dictionary in info.get("slots", []):
				bank[int(slot.get("index", 0))] = slot
			npc_bank.emit(info.get("slots", []))
		Opcodes.NPC.ENCHANT:
			enchant_opened.emit()


## LIST 包：服务端下发区域内实体 ID 列表。
## 客户端对比后清理离开区域的实体，并用 WHO 请求未知实体的 Spawn 数据。
func _handle_list(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	match opcode:
		Opcodes.List.SPAWNS:
			var server_ids: Array = info.get("entities", [])

			# 清理不在列表中的实体（本地玩家除外）。
			var to_remove: Array[String] = []
			for instance: String in entities:
				if instance == player_instance:
					continue
				if instance not in server_ids:
					to_remove.append(instance)
			for instance: String in to_remove:
				entities.erase(instance)
				entity_despawned.emit(instance)

			# 请求未知实体的 Spawn 数据。
			var new_ids: Array = []
			for id: Variant in server_ids:
				var instance := str(id)
				if instance != player_instance and not entities.has(instance):
					new_ids.append(instance)

			if not new_ids.is_empty():
				Network.send_packet(Packets.WHO, new_ids)

		Opcodes.List.POSITIONS:
			# 服务端批量位置同步：positions 是 {instance: {x, y}} 字典。
			var positions: Dictionary = info.get("positions", {})
			for pos_instance: String in positions.keys():
				var pos_data: Dictionary = positions[pos_instance]
				if entities.has(pos_instance):
					entities[pos_instance]["x"] = int(pos_data.get("x", 0))
					entities[pos_instance]["y"] = int(pos_data.get("y", 0))
					entity_moved.emit(pos_instance, int(pos_data.get("x", 0)), int(pos_data.get("y", 0)))


func _handle_resource(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	var info: Dictionary = args[0]
	resource_state_changed.emit(
		str(info.get("instance", "")),
		int(info.get("state", 0))
	)


func _handle_animation(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	var info: Dictionary = args[0]
	entity_animation.emit(
		str(info.get("instance", "")),
		int(info.get("action", 0)),
		str(info.get("resourceInstance", ""))
	)


func _handle_notification(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return
	var opcode := int(args[0])
	var info: Dictionary = args[1]
	var message := str(info.get("message", ""))
	var colour := str(info.get("colour", ""))

	match opcode:
		Opcodes.Notification.TEXT:
			# 交易请求通过通知包而非 Trade.Request 包下发。
			if message.begins_with("misc:TRADE_REQUEST_OTHER"):
				var requester_name := _notification_parameter(message, "username")
				if not requester_name.is_empty():
					trade_requested.emit(requester_name)
			notification_received.emit(message, colour)
		Opcodes.Notification.POPUP:
			# 弹窗通知（带音效），同时作为 toast 显示。
			notification_received.emit(message, colour)
			notification_popup.emit(message, colour)


func _notification_parameter(message: String, parameter: String) -> String:
	var prefix := ";%s=" % parameter
	var position := message.find(prefix)
	if position < 0:
		return ""
	return message.substr(position + prefix.length()).split(";", true, 1)[0]


func _handle_music(args: Array) -> void:
	# Music 包数据为歌曲名字符串（无 opcode 时 args[0] 即数据）。
	if args.is_empty():
		return
	var song := ""
	if args[0] is String:
		song = args[0]
	elif args[0] is Dictionary:
		song = str(args[0].get("newSong", args[0].get("song", "")))
	if not song.is_empty():
		music_changed.emit(song)


## SKILL 包：Batch 为全量 {skills:[...]}，Update 为单个 SkillData。
func _handle_skill(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	match opcode:
		Opcodes.Skill.BATCH:
			for skill: Dictionary in info.get("skills", []):
				skills[int(skill.get("type", -1))] = skill
		Opcodes.Skill.UPDATE:
			skills[int(info.get("type", -1))] = info

	skills_updated.emit()


## EXPERIENCE 包：Sync 同步玩家等级/经验，Skill 为某技能获得经验（飘字）。
func _handle_experience(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]
	var instance := str(info.get("instance", ""))

	# 经验飘字（仅本地玩家）。
	if instance == player_instance and info.has("amount"):
		experience_float.emit(instance, int(info.get("amount", 0)), int(info.get("skill", -1)))

	match opcode:
		Opcodes.Experience.SYNC:
			if instance == player_instance and not player_data.is_empty():
				if info.has("level"):
					player_data["level"] = int(info["level"])
				experience_updated.emit()
		Opcodes.Experience.SKILL:
			experience_updated.emit()


## QUEST 包：Batch 全量任务，Progress 更新单个，Finish 完成。
func _handle_quest(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	match opcode:
		Opcodes.Quest.BATCH:
			for quest: Dictionary in info.get("quests", []):
				quests[str(quest.get("key", ""))] = quest
			quests_updated.emit()
		Opcodes.Quest.PROGRESS:
			var progress_key := str(info.get("key", ""))
			if quests.has(progress_key):
				quests[progress_key]["stage"] = int(info.get("stage", 0))
				quests[progress_key]["subStage"] = int(info.get("subStage", 0))
			else:
				quests[progress_key] = info.duplicate(true)
			quests_updated.emit()
		Opcodes.Quest.START:
			var start_key := str(info.get("key", ""))
			var quest: Dictionary = quests.get(start_key, info).duplicate(true)
			if not quest.is_empty():
				quest_start_requested.emit(quest)
		Opcodes.Quest.FINISH:
			var finish_key := str(info.get("key", ""))
			if quests.has(finish_key):
				quests[finish_key]["finished"] = true
			quests_updated.emit()


## ACHIEVEMENT 包：Batch 全量，Progress 更新单个。
func _handle_achievement(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	match opcode:
		Opcodes.Achievement.BATCH:
			achievements.clear()
			for achievement: Dictionary in info.get("achievements", []):
				var achievement_key := str(achievement.get("key", ""))
				if not achievement_key.is_empty():
					achievements[achievement_key] = achievement.duplicate(true)
		Opcodes.Achievement.PROGRESS:
			var progress_key := str(info.get("key", ""))
			if not progress_key.is_empty():
				var merged: Dictionary = achievements.get(progress_key, {}).duplicate(true)
				merged.merge(info, true)
				achievements[progress_key] = merged

	achievements_updated.emit()


## STORE 包：Open 打开商店（含商品），Close 关闭，Update 更新商品。
func _handle_store(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	match opcode:
		Opcodes.Store.OPEN:
			store_key = str(info.get("key", ""))
			store_currency = str(info.get("currency", ""))
			store_items = info.get("items", [])
			store_opened.emit(store_key, store_currency, store_items)
		Opcodes.Store.CLOSE:
			store_key = ""
			store_items = []
			store_closed.emit()
		Opcodes.Store.UPDATE:
			store_items = info.get("items", [])
			store_updated.emit(store_items)
		Opcodes.Store.SELECT:
			var selected_item: Dictionary = info.get("item", {})
			if not selected_item.is_empty():
				store_selected.emit(selected_item)


## CRAFTING 包：Open 打开界面，Select 返回物品详情。
func _handle_crafting(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	match opcode:
		Opcodes.Crafting.OPEN:
			crafting_opened.emit(int(info.get("type", -1)), info.get("previews", []))
		Opcodes.Crafting.SELECT:
			crafting_selected.emit(info)


## EFFECT 包：Add/Remove 实体状态效果。
func _handle_effect(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	effect_changed.emit(
		str(info.get("instance", "")),
		int(info.get("effect", 0)),
		opcode == Opcodes.Effect.ADD
	)


## FRIENDS 包：List 全量，Status 单个上下线。
func _handle_friends(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	match opcode:
		Opcodes.Friends.LIST:
			friends = info.get("list", {})
		Opcodes.Friends.STATUS:
			var username := str(info.get("username", ""))
			if friends.has(username):
				friends[username]["online"] = bool(info.get("status", false))
				friends[username]["serverId"] = int(info.get("serverId", -1))
		Opcodes.Friends.REMOVE:
			friends.erase(str(info.get("username", "")))
		Opcodes.Friends.ADD:
			var add_name := str(info.get("username", ""))
			if not add_name.is_empty():
				friends[add_name] = {
					"online": bool(info.get("status", false)),
					"serverId": int(info.get("serverId", -1)),
				}

	friends_updated.emit()


## TRADE 包：Open 含交易对方实例，Add/Remove 用 instance 标识物品归属。
func _handle_trade(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]
	var source_instance := str(info.get("instance", ""))

	match opcode:
		Opcodes.Trade.REQUEST:
			var requester: Dictionary = entities.get(source_instance, {})
			trade_requested.emit(str(requester.get("username", requester.get("name", source_instance))))
		Opcodes.Trade.OPEN:
			trading = true
			trade_other_instance = source_instance
			trade_my_items.clear()
			trade_their_items.clear()
			trade_opened.emit()
		Opcodes.Trade.ADD:
			var slot := {
				"index": int(info.get("index", -1)),
				"key": str(info.get("key", "")),
				"count": int(info.get("count", 1)),
			}
			if int(slot["index"]) < 0 or str(slot["key"]).is_empty():
				return
			if source_instance == player_instance:
				trade_my_items[int(slot["index"])] = slot
			else:
				trade_their_items[int(slot["index"])] = slot
			trade_updated.emit()
		Opcodes.Trade.REMOVE:
			var index := int(info.get("index", -1))
			if index < 0:
				return
			if source_instance == player_instance:
				trade_my_items.erase(index)
			else:
				trade_their_items.erase(index)
			trade_updated.emit()
		Opcodes.Trade.CLOSE:
			trading = false
			trade_other_instance = ""
			trade_my_items.clear()
			trade_their_items.clear()
			trade_closed.emit()
		Opcodes.Trade.ACCEPT:
			trade_accepted.emit(str(info.get("message", "")))


## GUILD 包：完整快照、成员增量、目录、聊天和错误。
func _handle_guild(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]
	var username := str(info.get("username", ""))
	var local_username := str(player_data.get("username", player_data.get("name", "")))

	match opcode:
		Opcodes.Guild.LOGIN:
			guild = info.duplicate(true)
			guild_updated.emit()
		Opcodes.Guild.JOIN:
			if not username.is_empty() and not guild.is_empty() and not _guild_has_member(username):
				var members: Array = guild.get("members", [])
				members.append({
					"username": username,
					"rank": 0,
					"serverId": int(info.get("serverId", -1)),
				})
				guild["members"] = members
				guild_updated.emit()
		Opcodes.Guild.LEAVE:
			if username.is_empty() or username == local_username:
				guild = {}
			else:
				_remove_guild_member(username)
			guild_updated.emit()
		Opcodes.Guild.RANK:
			_update_guild_member(username, { "rank": int(info.get("rank", 0)) })
			guild_updated.emit()
		Opcodes.Guild.UPDATE:
			for member: Dictionary in info.get("members", []):
				_update_guild_member(str(member.get("username", "")), {
					"serverId": int(member.get("serverId", -1)),
				})
			guild_updated.emit()
		Opcodes.Guild.EXPERIENCE:
			if not guild.is_empty():
				guild["experience"] = int(info.get("experience", 0))
				guild_updated.emit()
		Opcodes.Guild.LIST:
			available_guilds = info.get("guilds", []).duplicate(true)
			available_guild_total = int(info.get("total", available_guilds.size()))
			guild_list_updated.emit(available_guilds, available_guild_total)
		Opcodes.Guild.CHAT:
			guild_chat_received.emit(
				username,
				int(info.get("serverId", -1)),
				str(info.get("message", ""))
			)
		Opcodes.Guild.ERROR:
			guild_error_received.emit(str(info.get("message", "guilds:UNKNOWN_ERROR")))


func _guild_has_member(username: String) -> bool:
	for member: Dictionary in guild.get("members", []):
		if str(member.get("username", "")) == username:
			return true
	return false


func _update_guild_member(username: String, changes: Dictionary) -> void:
	if username.is_empty() or guild.is_empty():
		return
	var members: Array = guild.get("members", [])
	for member: Dictionary in members:
		if str(member.get("username", "")) == username:
			member.merge(changes, true)
			break
	guild["members"] = members


func _remove_guild_member(username: String) -> void:
	if username.is_empty() or guild.is_empty():
		return
	var members: Array = guild.get("members", [])
	members = members.filter(func(member: Dictionary) -> bool:
		return str(member.get("username", "")) != username
	)
	guild["members"] = members


## LOOT_BAG 包：Open 打开（含物品），Take 指定被取走的服务端槽位，Close 关闭。
func _handle_lootbag(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return

	var opcode := int(args[0])
	var info: Dictionary = args[1]

	match opcode:
		Opcodes.LootBag.OPEN:
			lootbag_opened.emit(info.get("items", []))
		Opcodes.LootBag.TAKE:
			lootbag_item_taken.emit(int(info.get("index", -1)))
		Opcodes.LootBag.CLOSE:
			lootbag_closed.emit()


## DEATH 包：实体死亡。若是本地玩家则触发死亡界面。
func _handle_death(args: Array) -> void:
	if args.is_empty():
		return
	if str(args[0]) == player_instance:
		player_died.emit()


## RESPAWN 包：服务端确认复活，更新位置。
func _handle_respawn(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	var info: Dictionary = args[0]
	player_data["x"] = int(info.get("x", 0))
	player_data["y"] = int(info.get("y", 0))
	player_respawned.emit()


## ENCHANT 包：Select 返回选中状态。
func _handle_enchant(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return
	var info: Dictionary = args[1]
	if int(args[0]) == Opcodes.Enchant.SELECT:
		enchant_item_selected.emit(
			int(info.get("index", -1)),
			bool(info.get("isShard", false))
		)


## ABILITY 包：Batch 全量技能，Add/Update 单个。
func _handle_ability(args: Array) -> void:
	if args.size() < 2:
		return

	var opcode := int(args[0])
	var info: Variant = args[1]

	match opcode:
		Opcodes.Ability.BATCH:
			if info is Dictionary:
				abilities.clear()
				for ability: Dictionary in info.get("abilities", []):
					var ability_key := str(ability.get("key", ""))
					if not ability_key.is_empty():
						abilities[ability_key] = ability.duplicate(true)
		Opcodes.Ability.ADD, Opcodes.Ability.UPDATE:
			if info is Dictionary:
				var update_key := str(info.get("key", ""))
				if not update_key.is_empty():
					# Update 包不带 type，需合并已有信息以免能力从配置列表消失。
					var merged: Dictionary = abilities.get(update_key, {}).duplicate(true)
					merged.merge(info, true)
					abilities[update_key] = merged
		Opcodes.Ability.TOGGLE:
			if info is Dictionary:
				var toggle_key := str(info.get("key", ""))
				if abilities.has(toggle_key):
					var is_active := not bool(abilities[toggle_key].get("active", false))
					abilities[toggle_key]["active"] = is_active
					ability_toggled.emit(toggle_key, is_active)

	abilities_updated.emit()


## PVP 包：本地玩家 PVP 状态 {state}。
func _handle_pvp(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	pvp = bool(args[0].get("state", false))
	pvp_changed.emit(pvp)


## PLAYER 包：好友/公会成员上下线 {opcode, username, serverId?}。
func _handle_player(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return
	var info: Dictionary = args[1]
	player_status_changed.emit(
		str(info.get("username", "")),
		int(args[0]) == Opcodes.Player.LOGIN
	)


## RANK 包：本地玩家排位（直接为排位数值）。
func _handle_rank(args: Array) -> void:
	if args.is_empty():
		return
	rank = int(args[0])
	rank_changed.emit(rank)


## COUNTDOWN 包：实体技能冷却 {instance, time}。
func _handle_countdown(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	countdown_started.emit(
		str(args[0].get("instance", "")),
		int(args[0].get("time", 0))
	)


## NETWORK 包：仅响应服务端 Ping，并在服务器要求时校正移动时间偏移。
func _handle_network(args: Array) -> void:
	if args.is_empty():
		return
	match int(args[0]):
		Opcodes.Network.PING:
			Network.send_packet(Packets.NETWORK, [Opcodes.Network.PONG])
		Opcodes.Network.SYNC:
			if args.size() > 1 and args[1] is Dictionary:
				var timestamp := float(args[1].get("timestamp", 0.0))
				if timestamp > 0.0:
					time_offset = int(Time.get_ticks_msec() - timestamp)


## OVERLAY 包：Set 开启黑暗遮罩（带 image/colour）、Remove 移除、Lamp 灯光。
func _handle_overlay(args: Array) -> void:
	if args.is_empty():
		return
	var opcode := int(args[0])
	match opcode:
		Opcodes.Overlay.SET:
			# 服务端发送 {image, colour} 表示开启黑暗遮罩。
			darkness_changed.emit(true)
		Opcodes.Overlay.REMOVE:
			darkness_changed.emit(false)
		Opcodes.Overlay.LAMP:
			# 灯光效果（暗黑洞穴中玩家周围的光照圈）。
			lamp_changed.emit(true)
		Opcodes.Overlay.REMOVE_LAMPS:
			lamp_changed.emit(false)


## CAMERA 包：LockX/LockY 锁定相机轴，FreeFlow 自由跟随。
func _handle_camera(args: Array) -> void:
	if args.is_empty():
		return
	match int(args[0]):
		Opcodes.Camera.LOCK_X:
			camera_mode_changed.emit(true, false)
		Opcodes.Camera.LOCK_Y:
			camera_mode_changed.emit(false, true)
		Opcodes.Camera.FREE_FLOW, Opcodes.Camera.PLAYER:
			camera_mode_changed.emit(false, false)


## BLINK 包：实体瞬移（args[0] 为 instance）。
func _handle_blink(args: Array) -> void:
	if args.is_empty():
		return
	entity_blinked.emit(str(args[0]))


## MINIGAME 包：大厅/比分/结束状态同步。
func _handle_minigame(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return
	minigame_updated.emit(int(args[0]), int(args[1].get("action", -1)), args[1])


## HEAL 包：实体治疗 {instance, type, amount}。type 是字符串：'passive'/'hitpoints'/'mana'。
func _handle_heal(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	var info: Dictionary = args[0]
	var instance := str(info.get("instance", ""))
	var amount := int(info.get("amount", 0))
	var heal_type := str(info.get("type", ""))
	# 魔法恢复用负数 amount 区分，让 game.gd 显示蓝色飘字。
	if heal_type == "mana":
		entity_healed.emit(instance, -amount)
	else:
		entity_healed.emit(instance, amount)


## POISON 包：本地玩家中毒状态（args[0] 为 0/1）。
func _handle_poison(args: Array) -> void:
	if args.is_empty():
		return
	poison_changed.emit(int(args[0]) == 1)


## SYNC 包：服务端会将附近玩家的资料广播给其他客户端，必须按 instance 路由。
func _handle_sync(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	var data: Dictionary = args[0]
	var instance := str(data.get("instance", ""))
	if instance.is_empty():
		return
	if instance == player_instance:
		player_data.merge(data, true)
		player_synced.emit()
		inventory_updated.emit()
		equipment_updated.emit()
	elif entities.has(instance):
		var merged: Dictionary = entities[instance].duplicate(true)
		merged.merge(data, true)
		entities[instance] = merged
		entity_synced.emit(instance, merged)


## UPDATE 包：实体显示信息批量更新（名称颜色、缩放、感叹号）。
func _handle_update(args: Array) -> void:
	if args.is_empty() or not args[0] is Array:
		return
	var updates: Array = args[0]
	for info: Variant in updates:
		if not info is Dictionary:
			continue
		var instance := str(info.get("instance", ""))
		if instance.is_empty():
			continue
		if instance == player_instance:
			player_data["displayInfo"] = info.duplicate(true)
		elif entities.has(instance):
			entities[instance]["displayInfo"] = info.duplicate(true)
		else:
			_pending_display_infos[instance] = info.duplicate(true)
	entity_display_updated.emit(updates)


## POINTER 包：任务指引箭头（Location/Entity/Relative/Remove）。
func _handle_pointer(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return
	pointer_updated.emit(int(args[0]), args[1])


## BUBBLE 包：独立气泡（实体头顶或指定坐标）。
func _handle_bubble(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return
	bubble_shown.emit(args[1])


## INTERFACE 包：服务端控制界面开关。
func _handle_interface(args: Array) -> void:
	if args.size() < 2 or not args[1] is Dictionary:
		return
	interface_toggled.emit(int(args[0]), int(args[1].get("identifier", -1)))


## COMMAND 包：服务端管理命令（debug 切换调试，hide 隐身切换）。
func _handle_command(args: Array) -> void:
	if args.is_empty() or not args[0] is Dictionary:
		return
	# CommandPacket 无 opcode，数据直接为 {command: "xxx"}。
	var command := str(args[0].get("command", ""))
	if not command.is_empty():
		command_received.emit(command)