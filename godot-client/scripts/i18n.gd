extends Node
## 国际化（Autoload: I18n）
##
## 加载中文翻译表，解析服务端下发的 i18n 键消息。
## 消息格式："namespace:KEY;param=value;param2=value2"

var _translations: Dictionary = {}


func _ready() -> void:
	var file := FileAccess.open("res://assets/data/i18n/zh.json", FileAccess.READ)
	if not file:
		push_error("[I18n] Cannot open zh.json")
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		_translations = data


## 解析服务端消息为可读文本。
## 输入形如 "misc:WELCOME_BACK;name=Kaetram" 或纯文本。
func parse(message: String) -> String:
	# 非 i18n 键（不含命名空间前缀）直接返回。
	if not message.contains(":"):
		return message

	var ns := message.get_slice(":", 0)
	if not _translations.has(ns):
		return message

	var rest := message.substr(ns.length() + 1)
	var key := rest.get_slice(";", 0)
	var params: Dictionary = {}
	for pair: String in rest.split(";", false):
		if pair == key or pair.is_empty():
			continue
		var eq := pair.find("=")
		if eq > 0:
			params[pair.left(eq)] = pair.substr(eq + 1)

	return t(ns, key, params)


## 查表翻译，支持 {{param}} 插值。
func t(ns: String, key: String, params: Dictionary = {}) -> String:
	var table: Dictionary = _translations.get(ns, {})
	var text: String = table.get(key, "%s:%s" % [ns, key])

	for param: String in params:
		text = text.replace("{{%s}}" % param, str(params[param]))

	return text
