class_name Opcodes
## 各数据包的子操作码，与 packages/common/network/opcodes.ts 一一对应。
## 访问方式：Opcodes.Login.GUEST、Opcodes.Movement.REQUEST 等。

enum Login { LOGIN, REGISTER, GUEST }

enum List { SPAWNS, POSITIONS }

enum Equipment { BATCH, EQUIP, UNEQUIP, STYLE }

enum Movement { REQUEST, STARTED, STEP, STOP, MOVE, FOLLOW, ENTITY, SPEED }

enum Target { TALK, ATTACK, NONE, OBJECT }

enum Combat { INITIATE, HIT, FINISH, SYNC }

enum Projectile { STATIC, DYNAMIC, CREATE, UPDATE, IMPACT }

enum Network { PING, PONG, SYNC }

enum Containers { BATCH, ADD, REMOVE, SELECT, SWAP }

enum Ability { BATCH, ADD, UPDATE, USE, QUICK_SLOT, TOGGLE }

enum Quest { BATCH, PROGRESS, FINISH, START }

enum Achievement { BATCH, PROGRESS }

enum Notification { OK, YES_NO, TEXT, POPUP }

enum Experience { SYNC, SKILL }

enum NPC { TALK, STORE, BANK, ENCHANT, COUNTDOWN }

enum Trade { REQUEST, ADD, REMOVE, ACCEPT, CLOSE, OPEN }

enum Enchant { SELECT, CONFIRM }

enum Guild {
	CREATE,
	LOGIN,
	LOGOUT,
	JOIN,
	LEAVE,
	RANK,
	UPDATE,
	EXPERIENCE,
	BANNER,
	LIST,
	ERROR,
	CHAT,
	PROMOTE,
	DEMOTE,
	KICK,
}

enum Pointer { LOCATION, ENTITY, RELATIVE, REMOVE }

enum Store { OPEN, CLOSE, BUY, SELL, UPDATE, SELECT }

enum Overlay { SET, REMOVE, LAMP, REMOVE_LAMPS, DARKNESS }

enum Camera { LOCK_X, LOCK_Y, FREE_FLOW, PLAYER }

enum Command { CTRL_CLICK }

enum Skill { BATCH, UPDATE }

enum Minigame { TEAM_WAR, COURSING }

enum MinigameState { LOBBY, END, EXIT }

enum MinigameActions { SCORE, END, LOBBY, EXIT }

enum Bubble { ENTITY, POSITION }

enum Effect { ADD, REMOVE }

enum Friends { LIST, ADD, REMOVE, STATUS, SYNC }

enum Player { LOGIN, LOGOUT }

enum Crafting { OPEN, SELECT, CRAFT }

enum LootBag { OPEN, TAKE, CLOSE }

enum Pet { PICKUP }

enum Interface { OPEN, CLOSE }
