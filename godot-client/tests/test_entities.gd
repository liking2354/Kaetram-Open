extends Node
## 诊断：列出登录后视野内的所有实体（场景方式运行）。
const GVER := "0.5.5-beta"


func _ready() -> void:
	Network.packet_received.connect(_on_packet)
	GameState.map_loaded.connect(_on_map_loaded, CONNECT_ONE_SHOT)
	Network.connect_to_server("82.157.143.36", 9001)


func _on_packet(packet_id: int, _args: Array) -> void:
	if packet_id == Packets.CONNECTED:
		Network.send_packet(Packets.HANDSHAKE, { "gVer": GVER })
	elif packet_id == Packets.HANDSHAKE:
		Network.send_packet(Packets.LOGIN, { "opcode": Opcodes.Login.GUEST })


func _on_map_loaded(_regions: Dictionary) -> void:
	print("[TEST] player at: ", GameState.player_data.get("x"), ",", GameState.player_data.get("y"))
	print("[TEST] entities in view: ", GameState.entities.size())
	var names := ["PLAYER", "NPC", "ITEM", "MOB", "CHEST", "PROJ", "OBJ", "PET", "LOOT", "FX", "TREE", "ROCK", "FORAGE", "FISH"]
	for instance: String in GameState.entities:
		var e: Dictionary = GameState.entities[instance]
		var type := int(e.get("type", -1))
		var type_name: String = names[type] if type >= 0 and type < names.size() else str(type)
		print("[TEST]   %s type=%s key=%s name=%s at (%d,%d)" % [instance, type_name, e.get("key", ""), e.get("name", ""), int(e.get("x", 0)), int(e.get("y", 0))])
	get_tree().quit(0)
