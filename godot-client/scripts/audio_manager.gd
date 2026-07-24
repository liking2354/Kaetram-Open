extends Node
## 全局音频管理器（Autoload: Audio）
##
## 音乐按区域切换（Music 包），音效通过对象池并发播放。

## 音乐播放器。
var _music_player: AudioStreamPlayer
## 音效播放器池。
var _sfx_pool: Array[AudioStreamPlayer] = []
## 音效池大小。
const SFX_POOL_SIZE := 8
## 当前音乐名（避免重复加载）。
var _current_music := ""
## 音效音量（线性 0.0~1.0）。
var sfx_volume := 1.0


## 总音频开关（使用 Master 总线静音，不丢失各自的音量设置）。
func set_audio_enabled(enabled: bool) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, not enabled)


## 设置音乐音量（0~100）。
func set_music_volume(percent: int) -> void:
	_music_player.volume_db = _percent_to_db(percent)


## 设置音效音量（0~100）。
func set_sfx_volume(percent: int) -> void:
	sfx_volume = percent / 100.0


func _percent_to_db(percent: int) -> float:
	if percent <= 0:
		return -80.0
	# 线性百分比 -> 分贝（100% = 0dB）。
	return 20.0 * log(percent / 100.0) / log(10.0)


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)

	for i: int in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_pool.append(player)


## 播放区域音乐（Music 包下发）。循环播放。
func play_music(song: String) -> void:
	if song.is_empty() or song == _current_music:
		return
	_current_music = song

	var path := "res://assets/audio/music/%s.mp3" % song
	if not ResourceLoader.exists(path):
		push_warning("[Audio] Music not found: %s" % path)
		return

	var stream: AudioStream = load(path)
	if stream is AudioStreamMP3:
		stream.loop = true
	_music_player.stream = stream
	_music_player.play()


## 停止音乐。
func stop_music() -> void:
	_current_music = ""
	_music_player.stop()


## 播放音效（从池中取空闲播放器）。
func play_sfx(sound: String, volume_db := 0.0) -> void:
	if sfx_volume <= 0.0:
		return

	var path := "res://assets/audio/sounds/%s.mp3" % sound
	if not ResourceLoader.exists(path):
		return

	var final_db := volume_db + _percent_to_db(int(sfx_volume * 100.0))

	for player: AudioStreamPlayer in _sfx_pool:
		if not player.playing:
			player.stream = load(path)
			player.volume_db = final_db
			player.play()
			return

	# 池满时占用第一个。
	_sfx_pool[0].stream = load(path)
	_sfx_pool[0].volume_db = final_db
	_sfx_pool[0].play()
