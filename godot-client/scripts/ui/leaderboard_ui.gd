class_name LeaderboardUI
extends DraggablePanel
## 排行榜：总经验、PVP、所有技能及 Hub 动态返回的怪物击杀榜。

## Hub API 由部署环境提供；仅使用固定基址，动态参数均经过 URL 编码。
const API_BASE_URL := "http://82.157.143.36:9526/leaderboards"

var _option: OptionButton
var _list: VBoxContainer
var _http: HTTPRequest
var _status_label: Label
var _loaded_mobs := false


func _ready() -> void:
	super._ready()
	visible = false
	custom_minimum_size = Vector2(340, 400)

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
	title.text = "排行榜"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)

	_option = OptionButton.new()
	_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_category("总经验", "total", "")
	_add_category("PVP 击杀", "pvp", "")
	for skill_type: int in Modules.SKILL_NAMES:
		_add_category(str(Modules.SKILL_NAMES[skill_type]), "skill", skill_type)
	_option.item_selected.connect(_on_category_selected)
	vbox.add_child(_option)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_status_label)

	var header := HBoxContainer.new()
	var header_rank := Label.new()
	header_rank.text = "排名"
	header_rank.custom_minimum_size = Vector2(42, 0)
	header.add_child(header_rank)
	var header_name := Label.new()
	header_name.text = "玩家"
	header_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_name)
	var header_value := Label.new()
	header_value.text = "数值"
	header_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_value.custom_minimum_size = Vector2(95, 0)
	header.add_child(header_value)
	vbox.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 3)
	scroll.add_child(_list)

	_http = HTTPRequest.new()
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)


func _add_category(label: String, category_type: String, key: Variant) -> void:
	_option.add_item(label)
	_option.set_item_metadata(_option.item_count - 1, { "type": category_type, "key": key })


func toggle() -> void:
	visible = not visible
	if visible:
		_fetch()


func _on_category_selected(_index: int) -> void:
	if visible:
		_fetch()


func _fetch() -> void:
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http.cancel_request()
	_status_label.text = "加载中……"
	_clear_list()

	var metadata: Dictionary = _option.get_item_metadata(_option.selected)
	var request_url := API_BASE_URL
	match str(metadata.get("type", "total")):
		"skill":
			request_url += "?skill=%d" % int(metadata.get("key", 0))
		"pvp":
			request_url += "?pvp=1"
		"mob":
			request_url += "?mob=%s" % str(metadata.get("key", "")).uri_encode()

	var request_error := _http.request(request_url)
	if request_error != OK:
		_status_label.text = "无法请求排行榜服务"


func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_status_label.text = "排行榜服务不可用"
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary or str(parsed.get("status", "")) != "success":
		_status_label.text = "排行榜数据错误"
		return

	if not _loaded_mobs:
		_add_mob_categories(parsed.get("availableMobs", {}))

	var entries: Array = parsed.get("list", [])
	if entries.is_empty():
		_status_label.text = "暂无数据"
		return

	_status_label.text = ""
	_render(entries)


func _add_mob_categories(available_mobs: Variant) -> void:
	_loaded_mobs = true
	if not available_mobs is Dictionary:
		return
	for mob_key: String in available_mobs:
		_add_category("击杀：%s" % str(available_mobs[mob_key]), "mob", mob_key)


func _render(entries: Array) -> void:
	_clear_list()
	var category: Dictionary = _option.get_item_metadata(_option.selected)
	var category_type := str(category.get("type", "total"))
	for i: int in entries.size():
		var entry: Variant = entries[i]
		if not entry is Dictionary:
			continue
		_list.add_child(_make_row(i + 1, entry, category_type))


func _make_row(rank_number: int, entry: Dictionary, category_type: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var is_cheater := bool(entry.get("cheater", false))
	var text_color := Color(1.0, 0.35, 0.35) if is_cheater else Color.WHITE

	var rank := Label.new()
	rank.text = "%d." % rank_number
	rank.custom_minimum_size = Vector2(42, 0)
	rank.add_theme_color_override("font_color", text_color)
	row.add_child(rank)

	var name_label := Label.new()
	name_label.text = str(entry.get("username", "未知"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", text_color)
	row.add_child(name_label)

	var value := Label.new()
	value.text = _format_entry_value(entry, category_type)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(95, 0)
	value.add_theme_color_override("font_color", text_color)
	row.add_child(value)
	return row


func _format_entry_value(entry: Dictionary, category_type: String) -> String:
	match category_type:
		"total":
			return _format_number(int(entry.get("totalExperience", 0)))
		"skill":
			return _format_number(int(entry.get("experience", 0)))
		"pvp":
			return "%d 击杀" % int(entry.get("pvpKills", 0))
		"mob":
			return "%d 击杀" % int(entry.get("kills", 0))
	return "0"


func _format_number(value: int) -> String:
	var text := str(maxi(value, 0))
	var result := ""
	while text.length() > 3:
		result = "," + text.right(3) + result
		text = text.left(text.length() - 3)
	return text + result


func _clear_list() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
