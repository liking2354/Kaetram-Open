class_name Modules
## packages/common/network/modules.ts 中游戏客户端所需的枚举子集。

## 朝向。
enum Orientation { UP, DOWN, LEFT, RIGHT }

## 实体类型。
enum EntityType {
	PLAYER,
	NPC,
	ITEM,
	MOB,
	CHEST,
	PROJECTILE,
	OBJECT,
	PET,
	LOOT_BAG,
	EFFECT,
	TREE,
	ROCK,
	FORAGING,
	FISH_SPOT,
}

## 服务端 InterfacePacket 使用的界面 ID，与 common Modules.Interfaces 顺序一致。
enum Interfaces {
	INVENTORY,
	CRAFTING,
	SPELLS,
	BANK,
	STORE,
	QUESTS,
	QUEST,
	ACHIEVEMENTS,
	SKILLS,
	TRADE,
	SETTINGS,
	WARP,
	LEADERBOARDS,
	GUILDS,
	FRIENDS,
	ENCHANT,
	CUSTOMIZATION,
	BOOK,
	LOOTBAG,
	EQUIPMENTS,
	WELCOME,
}

## 装备槽位，与服务端 Equipment enum 一一对应。
enum Equipment {
	HELMET,
	PENDANT,
	ARROWS,
	CHESTPLATE,
	WEAPON,
	SHIELD,
	RING,
	ARMOUR_SKIN,
	WEAPON_SKIN,
	LEGPLATES,
	CAPE,
	BOOTS,
}

## 武器攻击样式，与服务端 AttackStyle enum 一一对应。
enum AttackStyle {
	NONE,
	STAB,
	SLASH,
	DEFENSIVE,
	CRUSH,
	SHARED,
	HACK,
	CHOP,
	ACCURATE,
	FAST,
	FOCUSED,
	LONG_RANGE,
}

## 技能能力类型。
enum AbilityType {
	ACTIVE,
	PASSIVE,
}

## 技能类型（顺序即数值，与服务端 modules.ts 一致）。
enum Skills {
	LUMBERJACKING, ## 0 伐木
	ACCURACY, ## 1 精准
	ARCHERY, ## 2 箭术
	HEALTH, ## 3 生命
	MAGIC, ## 4 魔法
	MINING, ## 5 采矿
	STRENGTH, ## 6 力量
	DEFENSE, ## 7 防御
	FISHING, ## 8 钓鱼
	COOKING, ## 9 烹饪
	SMITHING, ## 10 锻造
	CRAFTING, ## 11 制作
	CHISELING, ## 12 凿刻（制作子类，非独立技能）
	FLETCHING, ## 13 箭羽
	SMELTING, ## 14 熔炼（锻造子类，非独立技能）
	FORAGING, ## 15 觅食
	EATING, ## 16 进食
	LOITERING, ## 17 闲逛
	ALCHEMY, ## 18 炼金
}

## 状态效果（与服务端 modules.ts Effects 一致）。
enum Effects {
	NONE,
	CRITICAL,
	TERROR,
	TERROR_STATUS,
	STUN,
	HEALING,
	FIREBALL,
	ICEBALL,
	POISONBALL,
	BOULDER,
	RUNNING,
	HOT_SAUCE,
	DUALISTS_MARK,
	THICK_SKIN,
	SNOW_POTION,
	FIRE_POTION,
	BURNING,
	FREEZING,
	INVINCIBLE,
	ACCURACY_BUFF,
	STRENGTH_BUFF,
	DEFENSE_BUFF,
	MAGIC_BUFF,
	ARCHERY_BUFF,
	ACCURACY_SUPER_BUFF,
	STRENGTH_SUPER_BUFF,
	DEFENSE_SUPER_BUFF,
	MAGIC_SUPER_BUFF,
	ARCHERY_SUPER_BUFF,
	BLEED,
}

## 技能中文名（面板展示用）。
const SKILL_NAMES := {
	Skills.LUMBERJACKING: "伐木",
	Skills.ACCURACY: "精准",
	Skills.ARCHERY: "箭术",
	Skills.HEALTH: "生命",
	Skills.MAGIC: "魔法",
	Skills.MINING: "采矿",
	Skills.STRENGTH: "力量",
	Skills.DEFENSE: "防御",
	Skills.FISHING: "钓鱼",
	Skills.COOKING: "烹饪",
	Skills.SMITHING: "锻造",
	Skills.CRAFTING: "制作",
	Skills.CHISELING: "凿刻",
	Skills.FLETCHING: "箭羽",
	Skills.SMELTING: "熔炼",
	Skills.FORAGING: "觅食",
	Skills.EATING: "进食",
	Skills.LOITERING: "闲逛",
	Skills.ALCHEMY: "炼金",
}
