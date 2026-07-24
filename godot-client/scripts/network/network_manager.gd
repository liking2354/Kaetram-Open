extends Node
## 全局网络管理器（Autoload: Network）
##
## 负责与 Kaetram 游戏服务端的 WebSocket 通信与包分发。
## 协议格式（与服务端完全一致）：
##   C -> S：JSON 字符串 [packetId, data]
##   S -> C：JSON 字符串 [[packetId, data], [packetId, opcode, data], ...]

## 收到服务端数据包。args 为包内除 packetId 以外的全部元素
## （有 opcode 的包 args[0] 为 opcode，args[1] 为数据）。
signal packet_received(packet_id: int, args: Array)
## WebSocket 底层连接建立（此时服务端尚未下发 Connected 包）。
signal socket_opened
## WebSocket 连接关闭。服务端主动拒绝时 code 为 1010，reason 为原因字符串。
signal socket_closed(code: int, reason: String)

## 入站缓冲（字节）。服务端登录后下发的 Map/Spawn 批量包可能达数 MB，
## 默认 64KB 会导致 1009 (Message too big) 断连。
const INBOUND_BUFFER_SIZE := 16 * 1024 * 1024
## 出站缓冲（字节）。
const OUTBOUND_BUFFER_SIZE := 4 * 1024 * 1024
## 最大排队包数。
const MAX_QUEUED_PACKETS := 8192

var _ws := WebSocketPeer.new()
var _opened := false


## 建立到游戏服务端的 WebSocket 连接。
func connect_to_server(host: String, port: int, use_ssl := false) -> Error:
	var url := "wss://%s" % host if use_ssl else "ws://%s:%d" % [host, port]
	_opened = false

	# 必须在 connect_to_url 之前设置缓冲。
	_ws.set_inbound_buffer_size(INBOUND_BUFFER_SIZE)
	_ws.set_outbound_buffer_size(OUTBOUND_BUFFER_SIZE)
	_ws.set_max_queued_packets(MAX_QUEUED_PACKETS)

	return _ws.connect_to_url(url)


## 主动断开连接。
func close_socket() -> void:
	_ws.close()
	_opened = false


## 发送数据包。data 会被放入 [packetId, data] 结构后 JSON 序列化发出。
func send_packet(packet_id: int, data: Variant = null) -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_ws.send_text(JSON.stringify([packet_id, data]))


func is_socket_open() -> bool:
	return _ws.get_ready_state() == WebSocketPeer.STATE_OPEN


func _process(_delta: float) -> void:
	var state_before := _ws.get_ready_state()
	if state_before == WebSocketPeer.STATE_CLOSED:
		return

	_ws.poll()

	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _opened:
				_opened = true
				socket_opened.emit()
			while _ws.get_available_packet_count() > 0:
				_handle_raw_packet(_ws.get_packet())
		WebSocketPeer.STATE_CLOSED:
			# 连接失败（CONNECTING -> CLOSED）或正常断开（OPEN -> CLOSED）各通知一次。
			if _opened or state_before == WebSocketPeer.STATE_CONNECTING:
				_opened = false
				socket_closed.emit(_ws.get_close_code(), _ws.get_close_reason())


func _handle_raw_packet(raw: PackedByteArray) -> void:
	var text := raw.get_string_from_utf8()
	if not text.begins_with("["):
		return

	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Array:
		return

	# 服务端始终以包数组形式下发，逐包分发。
	for item: Variant in parsed:
		if item is Array and not item.is_empty():
			_dispatch(item)


func _dispatch(packet: Array) -> void:
	var packet_id := int(packet[0])
	var args := packet.slice(1)
	packet_received.emit(packet_id, args)
