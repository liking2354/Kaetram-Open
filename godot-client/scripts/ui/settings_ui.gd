class_name SettingsUI
extends DraggablePanel
## 设置面板：音频、显示、性能和触屏控制；配置持久化到 user://settings.cfg。

signal show_names_changed(enabled: bool)
signal show_levels_changed(enabled: bool)
signal debug_mode_changed(enabled: bool)
signal joystick_enabled_changed(enabled: bool)
signal audio_enabled_changed(enabled: bool)
signal brightness_changed(percent: int)
signal low_power_changed(enabled: bool)
signal fps_limit_changed(limit: int)

const CONFIG_PATH := "user://settings.cfg"

var _music_slider: HSlider
var _sfx_slider: HSlider
var _brightness_slider: HSlider
var _audio_check: CheckBox
var _names_check: CheckBox
var _levels_check: CheckBox
var _debug_check: CheckBox
var _joystick_check: CheckBox
var _low_power_check: CheckBox
var _fps_option: OptionButton


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(310, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	_add_section(vbox, "音频")
	_audio_check = _make_check_row(vbox, "启用音频")
	_music_slider = _make_slider_row(vbox, "音乐音量", 0, 100, 5)
	_sfx_slider = _make_slider_row(vbox, "音效音量", 0, 100, 5)

	_add_section(vbox, "显示")
	_brightness_slider = _make_slider_row(vbox, "世界亮度", 30, 100, 5)
	_names_check = _make_check_row(vbox, "显示名字")
	_levels_check = _make_check_row(vbox, "显示等级")
	_debug_check = _make_check_row(vbox, "调试信息（FPS / 延迟）")

	_add_section(vbox, "性能与控制")
	_low_power_check = _make_check_row(vbox, "低功耗模式（30 FPS，暂停动态地块）")
	_fps_option = OptionButton.new()
	_fps_option.add_item("帧率：不限")
	_fps_option.set_item_metadata(0, 0)
	_fps_option.add_item("帧率：30")
	_fps_option.set_item_metadata(1, 30)
	_fps_option.add_item("帧率：60")
	_fps_option.set_item_metadata(2, 60)
	_fps_option.add_item("帧率：120")
	_fps_option.set_item_metadata(3, 120)
	vbox.add_child(_fps_option)
	_joystick_check = _make_check_row(vbox, "虚拟摇杆（触屏设备）")
	# 非勾选的默认值：调试信息和低功耗模式必须由玩家显式开启。
	_debug_check.button_pressed = false
	_low_power_check.button_pressed = false

	var cache_hint := Label.new()
	cache_hint.text = "Godot 自动管理资源缓存，无需手动切换区域缓存。"
	cache_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cache_hint.add_theme_font_size_override("font_size", 10)
	cache_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(cache_hint)

	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_brightness_slider.value_changed.connect(_on_brightness_changed)
	_audio_check.toggled.connect(_on_audio_toggled)
	_names_check.toggled.connect(_on_names_toggled)
	_levels_check.toggled.connect(_on_levels_toggled)
	_debug_check.toggled.connect(_on_debug_toggled)
	_joystick_check.toggled.connect(_on_joystick_toggled)
	_low_power_check.toggled.connect(_on_low_power_toggled)
	_fps_option.item_selected.connect(_on_fps_selected)

	_load()


func toggle() -> void:
	visible = not visible


func is_joystick_enabled() -> bool:
	return _joystick_check.button_pressed


func is_show_names_enabled() -> bool:
	return _names_check.button_pressed


func is_show_levels_enabled() -> bool:
	return _levels_check.button_pressed


func is_debug_enabled() -> bool:
	return _debug_check.button_pressed


func is_audio_enabled() -> bool:
	return _audio_check.button_pressed


func get_brightness() -> int:
	return int(_brightness_slider.value)


func is_low_power_enabled() -> bool:
	return _low_power_check.button_pressed


func get_fps_limit() -> int:
	return int(_fps_option.get_item_metadata(_fps_option.selected))


func _add_section(parent: Control, text: String) -> void:
	var separator := HSeparator.new()
	parent.add_child(separator)
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	parent.add_child(label)


func _make_slider_row(parent: Control, label_text: String, minimum: int, maximum: int, step: int) -> HSlider:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = maximum
	parent.add_child(slider)
	return slider


func _make_check_row(parent: Control, label_text: String) -> CheckBox:
	var check := CheckBox.new()
	check.text = label_text
	check.button_pressed = true
	parent.add_child(check)
	return check


func _on_music_changed(value: float) -> void:
	Audio.set_music_volume(int(value))
	_save()


func _on_sfx_changed(value: float) -> void:
	Audio.set_sfx_volume(int(value))
	_save()


func _on_brightness_changed(value: float) -> void:
	brightness_changed.emit(int(value))
	_save()


func _on_audio_toggled(enabled: bool) -> void:
	audio_enabled_changed.emit(enabled)
	_save()


func _on_names_toggled(enabled: bool) -> void:
	show_names_changed.emit(enabled)
	_save()


func _on_levels_toggled(enabled: bool) -> void:
	show_levels_changed.emit(enabled)
	_save()


func _on_debug_toggled(enabled: bool) -> void:
	debug_mode_changed.emit(enabled)
	_save()


func _on_joystick_toggled(enabled: bool) -> void:
	joystick_enabled_changed.emit(enabled)
	_save()


func _on_low_power_toggled(enabled: bool) -> void:
	low_power_changed.emit(enabled)
	_save()


func _on_fps_selected(index: int) -> void:
	fps_limit_changed.emit(int(_fps_option.get_item_metadata(index)))
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "enabled", _audio_check.button_pressed)
	cfg.set_value("audio", "music", int(_music_slider.value))
	cfg.set_value("audio", "sfx", int(_sfx_slider.value))
	cfg.set_value("display", "brightness", int(_brightness_slider.value))
	cfg.set_value("display", "names", _names_check.button_pressed)
	cfg.set_value("display", "levels", _levels_check.button_pressed)
	cfg.set_value("display", "debug", _debug_check.button_pressed)
	cfg.set_value("display", "joystick", _joystick_check.button_pressed)
	cfg.set_value("performance", "low_power", _low_power_check.button_pressed)
	cfg.set_value("performance", "fps_limit", get_fps_limit())
	cfg.save(CONFIG_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		_audio_check.button_pressed = bool(cfg.get_value("audio", "enabled", true))
		_music_slider.value = int(cfg.get_value("audio", "music", 100))
		_sfx_slider.value = int(cfg.get_value("audio", "sfx", 100))
		_brightness_slider.value = int(cfg.get_value("display", "brightness", 100))
		_names_check.button_pressed = bool(cfg.get_value("display", "names", true))
		_levels_check.button_pressed = bool(cfg.get_value("display", "levels", true))
		_debug_check.button_pressed = bool(cfg.get_value("display", "debug", false))
		_joystick_check.button_pressed = bool(cfg.get_value("display", "joystick", true))
		_low_power_check.button_pressed = bool(cfg.get_value("performance", "low_power", false))
		var target_limit := int(cfg.get_value("performance", "fps_limit", 0))
		for index: int in _fps_option.item_count:
			if int(_fps_option.get_item_metadata(index)) == target_limit:
				_fps_option.select(index)
				break

	Audio.set_music_volume(int(_music_slider.value))
	Audio.set_sfx_volume(int(_sfx_slider.value))
