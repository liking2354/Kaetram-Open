class_name Packets
## 数据包 ID 枚举，与 packages/common/network/packets.ts 一一对应。
## 顺序即数值，严禁调整顺序。

enum {
	CONNECTED, ## 0
	HANDSHAKE, ## 1
	LOGIN, ## 2
	WELCOME, ## 3
	MAP, ## 4
	SPAWN, ## 5
	LIST, ## 6
	WHO, ## 7
	EQUIPMENT, ## 8
	READY, ## 9
	SYNC, ## 10
	MOVEMENT, ## 11
	TELEPORT, ## 12
	DESPAWN, ## 13
	TARGET, ## 14
	COMBAT, ## 15
	ANIMATION, ## 16
	POINTS, ## 17
	NETWORK, ## 18
	CHAT, ## 19
	COMMAND, ## 20
	CONTAINER, ## 21
	ABILITY, ## 22
	QUEST, ## 23
	ACHIEVEMENT, ## 24
	NOTIFICATION, ## 25
	BLINK, ## 26
	HEAL, ## 27
	EXPERIENCE, ## 28
	DEATH, ## 29
	MUSIC, ## 30
	NPC, ## 31
	RESPAWN, ## 32
	TRADE, ## 33
	ENCHANT, ## 34
	GUILD, ## 35
	POINTER, ## 36
	PVP, ## 37
	POISON, ## 38
	WARP, ## 39
	STORE, ## 40
	OVERLAY, ## 41
	CAMERA, ## 42
	BUBBLE, ## 43
	SKILL, ## 44
	UPDATE, ## 45
	MINIGAME, ## 46
	EFFECT, ## 47
	FRIENDS, ## 48
	FOCUS, ## 49
	RANK, ## 50
	EXAMINE, ## 51
	PLAYER, ## 52
	RELAY, ## 53
	CRAFTING, ## 54
	INTERFACE, ## 55
	LOOT_BAG, ## 56
	COUNTDOWN, ## 57
	PET, ## 58
	RESOURCE, ## 59
	ADMIN_SYNC, ## 60 (Hub <-> Admin，游戏客户端不使用)
}
