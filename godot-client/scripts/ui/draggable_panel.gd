class_name DraggablePanel
extends PanelContainer
## 可拖拽面板基类。
##
## 点击面板自身的空白区域（边框/边距区域）即可拖拽移动整个面板。
## 子控件（按钮、滑块等）默认 MOUSE_FILTER_STOP 会拦截鼠标事件，
## 不会触发面板拖拽——这正好实现"点控件交互、点空白拖拽"的效果。
## 子类只需在 _ready() 开头调用 super._ready() 即可。

var _dragging := false
var _drag_offset := Vector2.ZERO


func _ready() -> void:
	# 面板自身接收鼠标输入（落在非子控件区域的点击会到达这里）。
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_panel_gui_input)


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_offset = get_global_mouse_position() - global_position
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _drag_offset
