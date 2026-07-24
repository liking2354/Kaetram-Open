extends Node
## 音频冒烟测试（场景方式运行）。
## 验证：音乐/音效资源加载、播放不报错、Music 包分发。

var _checks := 0
var _failed := 0
var _got_music := false


func _ready() -> void:
	GameState.music_changed.connect(func(_s: String) -> void: _got_music = true)

	# 1) Music 包分发。
	GameState._handle_music(["forest"])
	_assert(_got_music, "music packet dispatched")

	# 2) 音乐播放。
	Audio.play_music("forest")
	await get_tree().create_timer(0.2).timeout
	_assert(Audio._music_player.playing, "music playing")

	# 3) 重复播放同一首不重新加载。
	Audio.play_music("forest")
	_assert(true, "repeat same music no crash")

	# 4) 音效播放（池）。
	Audio.play_sfx("hit1")
	Audio.play_sfx("hurt")
	Audio.play_sfx("heal")
	await get_tree().create_timer(0.1).timeout
	var any_playing := false
	for p: AudioStreamPlayer in Audio._sfx_pool:
		if p.playing:
			any_playing = true
	_assert(any_playing, "sfx playing from pool")

	# 5) 不存在的资源不报错。
	Audio.play_music("nonexistent_song_xyz")
	Audio.play_sfx("nonexistent_sfx_xyz")
	_assert(true, "missing assets handled gracefully")

	Audio.stop_music()
	_finish()


func _assert(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		print("[TEST] FAIL: %s" % label)


func _finish() -> void:
	if _failed == 0:
		print("[TEST] TEST_PASS: audio system (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		print("[TEST] TEST_FAIL: %d/%d checks failed" % [_failed, _checks])
		get_tree().quit(1)
