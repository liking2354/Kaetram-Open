class_name WelcomeUI
extends DraggablePanel
## 登录欢迎弹窗：显示玩家信息与操作指引（每次登录显示一次）。

const CONTROLS_HINT := "移动：点击地面\n攻击：点击怪物\n对话/采集：点击 NPC / 资源\n\nC 角色  Q 日志  I 背包  V 银行\nF 好友  G 公会  M 传送  Esc 设置\nEnter 聊天  1-4 技能  右键 物品菜单"


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(340, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "欢迎来到 Kaetram！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var info := Label.new()
	info.text = "角色：%s" % str(GameState.player_data.get("name", ""))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

	var separator := HSeparator.new()
	vbox.add_child(separator)

	var controls := Label.new()
	controls.text = CONTROLS_HINT
	controls.add_theme_font_size_override("font_size", 12)
	controls.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(controls)

	var button := Button.new()
	button.text = "开始冒险"
	button.pressed.connect(_hide)
	vbox.add_child(button)


## 隐藏欢迎面板。
func _hide() -> void:
	visible = false


func show_once() -> void:
	if not visible:
		visible = true
		# 8 秒后自动关闭。
		get_tree().create_timer(8.0).timeout.connect(_hide)
