class_name WarpUI
extends DraggablePanel
## 传送点地图：世界地图上的传送点列表。M 键开关。

## 传送点数据（来自服务端 world.json areas.warps）。
const WARPS := [
	{ "id": 0, "name": "Mudwich", "requirement": "" },
	{ "id": 1, "name": "Aynor", "requirement": "需完成任务：Ancient Lands" },
	{ "id": 2, "name": "Lakesworld", "requirement": "需完成任务：Desert Quest" },
	{ "id": 3, "name": "Patsow", "requirement": "需完成成就：Patsow" },
	{ "id": 4, "name": "Crullfield", "requirement": "需完成任务：Desert Quest" },
	{ "id": 5, "name": "Undersea", "requirement": "需完成成就：Water Guardian" },
]

var _list: VBoxContainer


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(260, 300)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "传送"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	for warp: Dictionary in WARPS:
		_list.add_child(_make_warp_button(warp))


func toggle() -> void:
	visible = not visible


func _make_warp_button(warp: Dictionary) -> Control:
	var button := Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var text: String = warp["name"]
	if not str(warp.get("requirement", "")).is_empty():
		text += "（%s）" % warp["requirement"]
	button.text = text

	var warp_id: int = warp["id"]
	# 用实例方法 + .bind() 替代 lambda，避免 lambda 闭包 self 变成 Nil 的问题。
	button.pressed.connect(_on_warp_pressed.bind(warp_id))
	return button


## 传送按钮点击：发送 Warp 包并关闭面板。
func _on_warp_pressed(warp_id: int) -> void:
	Network.send_packet(Packets.WARP, { "id": warp_id })
	visible = false
