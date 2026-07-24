class_name MinigameUI
extends VBoxContainer
## 小游戏状态显示（顶部居中）：大厅倒计时 / 比分 / 结束。

var _status_label: Label
var _score_label: Label


func _ready() -> void:
	visible = false
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 4)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	add_child(_status_label)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 14)
	add_child(_score_label)

	GameState.minigame_updated.connect(_on_minigame)


func _on_minigame(game_type: int, action: int, info: Dictionary) -> void:
	var type_name := "团队战" if game_type == Opcodes.Minigame.TEAM_WAR else "竞速赛"

	match action:
		Opcodes.MinigameActions.SCORE:
			visible = true
			_status_label.text = "%s 进行中" % type_name
			var red := int(info.get("redTeamKills", 0))
			var blue := int(info.get("blueTeamKills", 0))
			_score_label.text = "红队 %d : %d 蓝队" % [red, blue]
		Opcodes.MinigameActions.LOBBY:
			visible = true
			_status_label.text = "%s 大厅等待中" % type_name
			var countdown := int(info.get("countdown", 0))
			_score_label.text = "开始倒计时：%d 秒" % countdown if countdown > 0 else "等待更多玩家加入……"
		Opcodes.MinigameActions.END:
			visible = true
			_status_label.text = "%s 已结束" % type_name
			_score_label.text = ""
			await get_tree().create_timer(5.0).timeout
			visible = false
		Opcodes.MinigameActions.EXIT:
			visible = false
