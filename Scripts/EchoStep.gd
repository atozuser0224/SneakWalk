extends Control

class FootprintPair:
	extends Node2D

	const FOOT_TEXTURE := preload("res://Assets/Art/UI/footprint.png")

	var status := "preview"
	var feet: Array[Sprite2D] = []

	func _ready() -> void:
		feet.append(_make_foot(Vector2(-19, 6), 1.42, false))
		feet.append(_make_foot(Vector2(19, -6), 1.72, true))
		_apply_color()

	func _make_foot(offset: Vector2, angle: float, mirrored: bool) -> Sprite2D:
		var foot := Sprite2D.new()
		foot.texture = FOOT_TEXTURE
		foot.position = offset
		foot.rotation = angle
		foot.flip_h = mirrored
		foot.scale = Vector2(0.14, 0.14)
		add_child(foot)
		return foot

	func set_status(value: String) -> void:
		status = value
		_apply_color()

	func _apply_color() -> void:
		var color := Color(0.42, 0.85, 0.86, 0.72)
		match status:
			"hit":
				color = Color(0.98, 0.79, 0.36, 0.28)
			"miss":
				color = Color(0.90, 0.36, 0.50, 0.38)
		for foot in feet:
			foot.modulate = color

const SCENE_MENU := "res://Scenes/StartScreen.tscn"
const RANK_S := preload("res://Assets/Art/UI/rank_s.png")
const RANK_A := preload("res://Assets/Art/UI/rank_a.png")
const RANK_B := preload("res://Assets/Art/UI/rank_b.png")
const RANK_FAIL := preload("res://Assets/Art/UI/rank_fail.png")
const BPM := 96.0
const BEAT := 60.0 / BPM
const PATTERN_START_BEATS := 4.0
const BEATS_PER_PATTERN := 8
const BEATS_PER_ROUND := BEATS_PER_PATTERN * 2
const RHYTHM_PATTERNS := [
	[0, 1, 4, 6],
	[0, 2, 3, 7],
	[1, 3, 4, 6],
]
const RESPONSE_WINDOW := 0.18
const PERFECT_WINDOW := 0.045
const GOOD_WINDOW := 0.15
const STEP_DIST := 170.0
const CAMERA_START := 2400.0
const PLAYER_Y := 751.735
const PLAYER_SCALE := 1.0

@onready var panorama: Node2D = %Panorama
@onready var player: AnimatedSprite2D = %PlayerSprite
@onready var shadow: TextureRect = %PlayerShadow
@onready var stop_cue: Control = %StopCue
@onready var judgment: Label = %Judgment
@onready var combo_label: Label = %Combo
@onready var noise_bar: ProgressBar = %NoiseBar
@onready var noise_value: Label = %NoiseValue
@onready var beat_dot: Panel = %BeatDot
@onready var phase_label: Label = %PhaseLabel
@onready var start_overlay: Control = %StartOverlay
@onready var result_overlay: Control = %ResultOverlay
@onready var result_title: Label = %ResultTitle
@onready var result_desc: Label = %ResultDesc
@onready var rank_badge: TextureRect = %RankBadge
@onready var music: AudioStreamPlayer = %Music
@onready var sfx_perfect: AudioStreamPlayer = %SfxPerfect
@onready var sfx_good: AudioStreamPlayer = %SfxGood
@onready var sfx_miss: AudioStreamPlayer = %SfxMiss
@onready var call_cue: AudioStreamPlayer = %CallCue
@onready var test_mode: Control = %TestMode

var started := false
var finished := false
var song_time := 0.0
var camera_x := CAMERA_START
var noise := 18.0
var combo := 0
var max_combo := 0
var perfect_count := 0
var good_count := 0
var miss_count := 0
var last_beat := -1
var autoplay := false
var call_notes: Array[Dictionary] = []
var response_notes: Array[Dictionary] = []
var footprint_marks: Array = []
var current_round := -1
var current_phase := "ready"
var heard_count := 0
var response_hit_count := 0
var frames_processed := 0
var chart_clock := 0.0


func _ready() -> void:
	_build_chart()
	_reset_state()
	start_overlay.show()
	result_overlay.hide()
	test_mode.pause_changed.connect(_on_test_pause_changed)
	player.animation_finished.connect(_on_player_animation_finished)

	var flags := _flags()
	if "autoplay" in flags:
		autoplay = true
	if "capture" in flags:
		autoplay = true
		_capture_flow()
	elif "capture_response" in flags:
		autoplay = true
		_capture_response_flow()
	elif "capture_result" in flags:
		autoplay = true
		_capture_result_flow()
	elif "test_pause" in flags:
		_run_pause_test()
	elif "test_pause_capture" in flags:
		_capture_pause_flow()
	elif "capture_intro" in flags:
		_capture_intro_flow()
	elif "capture_anim" in flags:
		_capture_anim_flow()


func _flags() -> Array[String]:
	var result: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		result.append(arg.lstrip("-"))
	return result


func _build_chart() -> void:
	call_notes.clear()
	response_notes.clear()

	for round_index in RHYTHM_PATTERNS.size():
		var call_base := (PATTERN_START_BEATS + float(round_index * BEATS_PER_ROUND)) * BEAT
		var response_base := (PATTERN_START_BEATS + float(round_index * BEATS_PER_ROUND + BEATS_PER_PATTERN)) * BEAT
		for step_order in RHYTHM_PATTERNS[round_index].size():
			var beat_index := int(RHYTHM_PATTERNS[round_index][step_order])
			call_notes.append({
				"time": call_base + float(beat_index) * BEAT,
				"round": round_index,
				"beat": beat_index,
				"step_order": step_order,
				"played": false,
				"mark": null,
			})
			response_notes.append({
				"time": response_base + float(beat_index) * BEAT,
				"round": round_index,
				"beat": beat_index,
				"step_order": step_order,
				"judged": false,
				"mark": null,
			})

func _reset_state() -> void:
	started = false
	finished = false
	song_time = 0.0
	camera_x = CAMERA_START
	noise = 18.0
	combo = 0
	max_combo = 0
	perfect_count = 0
	good_count = 0
	miss_count = 0
	last_beat = -1
	current_round = -1
	current_phase = "ready"
	heard_count = 0
	response_hit_count = 0
	chart_clock = 0.0
	for note in call_notes:
		note["played"] = false
		note["mark"] = null
	for note in response_notes:
		note["judged"] = false
		note["mark"] = null
	for mark in footprint_marks:
		if is_instance_valid(mark):
			mark.queue_free()
	footprint_marks.clear()
	player.position = Vector2(960.28, PLAYER_Y)
	player.scale = Vector2.ONE * PLAYER_SCALE
	player.play("idle")
	_set_camera(CAMERA_START)
	stop_cue.hide()
	_update_noise_ui()
	combo_label.text = ""
	judgment.modulate = Color(1, 1, 1, 0)
	phase_label.text = "준비"


func _start() -> void:
	_reset_state()
	start_overlay.hide()
	result_overlay.hide()
	started = true
	test_mode.set_active(true)
	music.play()


func _on_test_pause_changed(paused: bool) -> void:
	music.stream_paused = paused
	call_cue.stream_paused = paused


func _on_player_animation_finished() -> void:
	if finished:
		return
	player.play("idle")


func _play_surprise() -> void:
	if finished:
		return
	player.play("surprise")


func test_mode_info() -> String:
	var beat_index := int(floor(song_time / BEAT)) + 1
	return "박자 %d · %.1f초 · 소음 %d%%\nPERFECT %d / GOOD %d / MISS %d · 콤보 %d" % [
		beat_index, song_time, int(noise), perfect_count, good_count, miss_count, combo,
	]


func _set_camera(value: float) -> void:
	camera_x = value
	panorama.position.x = 960.0 - value


func _get_song_time() -> float:
	if not music.playing:
		# 메트로놈(25.5초)이 차트(32.5초)보다 짧아서, 음악이 끝난 뒤에도
		# 차트 시계가 계속 흘러야 마지막 라운드와 결과 화면까지 도달한다.
		return maxf(song_time, chart_clock)
	var t := music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return maxf(t, 0.0)


func _process(delta: float) -> void:
	if not started or finished:
		return
	frames_processed += 1
	chart_clock += delta
	song_time = _get_song_time()
	_update_phase()
	_update_call_notes()
	_update_response_notes()
	_update_beat()

	if autoplay:
		for note in response_notes:
			if not note["judged"] and song_time >= float(note["time"]):
				_judge_response(note, 0.0)

	if song_time >= (PATTERN_START_BEATS + float(RHYTHM_PATTERNS.size() * BEATS_PER_ROUND)) * BEAT:
		_finish(true)


func _update_phase() -> void:
	var elapsed_beats := song_time / BEAT - PATTERN_START_BEATS
	if elapsed_beats < 0.0:
		current_round = -1
		current_phase = "ready"
		phase_label.text = "준비"
		return
	current_round = mini(int(floor(elapsed_beats / BEATS_PER_ROUND)), RHYTHM_PATTERNS.size() - 1)
	var round_beat := fposmod(elapsed_beats, float(BEATS_PER_ROUND))
	if round_beat < BEATS_PER_PATTERN:
		current_phase = "call"
		phase_label.text = "듣기  %d/%d" % [current_round + 1, RHYTHM_PATTERNS.size()]
	else:
		current_phase = "response"
		phase_label.text = "따라 걷기  %d/%d" % [current_round + 1, RHYTHM_PATTERNS.size()]


func _update_call_notes() -> void:
	for note in call_notes:
		if note["played"] or song_time < float(note["time"]):
			continue
		note["played"] = true
		heard_count += 1
		call_cue.play()
		var mark := _place_footprints(note)
		note["mark"] = mark
		var mark_pulse := create_tween()
		mark_pulse.tween_property(mark, "scale", Vector2(1.2, 1.2), 0.12)
		mark_pulse.tween_property(mark, "scale", Vector2.ONE, 0.2)


func _place_footprints(call_note: Dictionary) -> FootprintPair:
	var mark := FootprintPair.new()
	mark.position = Vector2(
		camera_x + STEP_DIST * float(int(call_note["step_order"]) + 1),
		PLAYER_Y + 185.0 + float(int(call_note["step_order"]) % 2) * 8.0
	)
	mark.z_index = 4
	panorama.add_child(mark)
	footprint_marks.append(mark)
	for response_note in response_notes:
		if int(response_note["round"]) == int(call_note["round"]) and int(response_note["beat"]) == int(call_note["beat"]):
			response_note["mark"] = mark
			break
	return mark


func _update_response_notes() -> void:
	for note in response_notes:
		if note["judged"]:
			continue
		if song_time > float(note["time"]) + RESPONSE_WINDOW:
			note["judged"] = true
			miss_count += 1
			combo = 0
			_add_noise(8.0)
			_flash("MISS")
			_shake()
			sfx_miss.play()
			_play_surprise()
			if is_instance_valid(note["mark"]):
				note["mark"].set_status("miss")
			_update_combo()


func _update_beat() -> void:
	var beat_index := int(floor(song_time / BEAT))
	if beat_index == last_beat:
		return
	last_beat = beat_index
	beat_dot.pivot_offset = beat_dot.size / 2.0
	beat_dot.scale = Vector2(1.6, 1.6)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(beat_dot, "scale", Vector2.ONE, 0.18)


func _press_step() -> void:
	if finished:
		return
	if current_phase != "response":
		if current_phase == "call":
			_add_noise(4.0)
			_flash("쉿")
			sfx_miss.play()
			_play_surprise()
		else:
			_flash("준비")
			_play_surprise()
		return

	var target: Dictionary = {}
	var best_err := 9.0
	for note in response_notes:
		if note["judged"]:
			continue
		var err: float = song_time - float(note["time"])
		if absf(err) <= RESPONSE_WINDOW and absf(err) < absf(best_err):
			best_err = err
			target = note
	if target.is_empty():
		combo = 0
		_add_noise(4.0)
		_flash("MISS")
		sfx_miss.play()
		_update_combo()
		return
	_judge_response(target, best_err)


func _judge_response(note: Dictionary, timing_error: float) -> void:
	if note["judged"]:
		return
	note["judged"] = true
	response_hit_count += 1
	var footprint: FootprintPair = note["mark"]
	var abs_error := absf(timing_error)
	if abs_error <= PERFECT_WINDOW:
		perfect_count += 1
		combo += 1
		_add_noise(-1.0)
		sfx_perfect.play()
		_flash("PERFECT")
		if is_instance_valid(footprint):
			footprint.set_status("hit")
		_do_step()
	elif abs_error <= GOOD_WINDOW:
		good_count += 1
		combo += 1
		sfx_good.play()
		_flash("GOOD")
		if is_instance_valid(footprint):
			footprint.set_status("hit")
		_do_step()
	else:
		miss_count += 1
		combo = 0
		_add_noise(8.0)
		sfx_miss.play()
		_play_surprise()
		_flash("MISS")
		if is_instance_valid(footprint):
			footprint.set_status("miss")
		_shake()
	max_combo = maxi(max_combo, combo)
	_update_combo()


func _do_step() -> void:
	var target := camera_x + STEP_DIST
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_camera, camera_x, target, 0.24)
	camera_x = target
	player.position.x = 1020.0
	player.position.y = PLAYER_Y - 14.0
	player.scale = Vector2(PLAYER_SCALE * 1.42 / 1.3, PLAYER_SCALE * 1.14 / 1.3)
	var lunge := create_tween()
	lunge.set_parallel(true)
	lunge.tween_property(player, "position:x", 960.28, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lunge.tween_property(player, "position:y", PLAYER_Y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var squash := create_tween()
	squash.tween_property(player, "scale", Vector2.ONE * PLAYER_SCALE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	player.play("sneak")


func _update_combo() -> void:
	combo_label.text = "" if combo < 2 else "COMBO %d" % combo


func _add_noise(amount: float) -> void:
	noise = clampf(noise + amount, 0.0, 100.0)
	_update_noise_ui()
	if noise >= 100.0 and not finished:
		_finish(false)


func _update_noise_ui() -> void:
	noise_bar.value = noise
	noise_value.text = "%d%%" % int(noise)


func _flash(text: String) -> void:
	judgment.text = text
	judgment.pivot_offset = judgment.size / 2.0
	judgment.scale = Vector2(1.18, 1.18)
	judgment.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(judgment, "scale", Vector2.ONE, 0.12)
	tween.tween_property(judgment, "modulate:a", 0.0, 0.5).set_delay(0.28)


func _shake() -> void:
	if not Settings.screen_shake:
		return
	var tween := create_tween()
	for i in 5:
		tween.tween_property(shadow, "position", Vector2(850.0 + randf_range(-8.0, 8.0), 890.0 + randf_range(-6.0, 6.0)), 0.03)
	tween.tween_property(shadow, "position", Vector2(850.0, 890.0), 0.06)
	var p := create_tween()
	for i in 5:
		p.tween_property(player, "position:x", 960.28 + randf_range(-9.0, 9.0), 0.03)
	p.tween_property(player, "position:x", 960.28, 0.06)


func _finish(success: bool) -> void:
	finished = true
	started = false
	test_mode.set_active(false)
	music.stop()
	call_cue.stop()
	stop_cue.hide()
	result_overlay.show()
	player.play("relieved" if success else "caught")
	if success:
		var rank := "B"
		if miss_count == 0 and perfect_count == RHYTHM_PATTERNS.size() * 4:
			rank = "S"
		elif miss_count == 0:
			rank = "A"
		result_title.text = "성공"
		rank_badge.texture = RANK_S if rank == "S" else (RANK_A if rank == "A" else RANK_B)
		result_desc.text = "PERFECT %d · GOOD %d · MISS %d\n콤보 %d · 소음 %d%%" % [perfect_count, good_count, miss_count, max_combo, int(noise)]
	else:
		result_title.text = "들켰다"
		rank_badge.texture = RANK_FAIL
		result_desc.text = "소음 100%%\nPERFECT %d · GOOD %d · MISS %d" % [perfect_count, good_count, miss_count]


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(SCENE_MENU)
		return
	if finished:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
			get_tree().reload_current_scene()
		return
	if not started:
		if event.is_action_pressed("ui_accept"):
			_start()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_press_step()


func _capture_flow() -> void:
	await get_tree().create_timer(0.4).timeout
	_start()
	await get_tree().create_timer(5.2).timeout
	_save_shot("echo_step.png")
	get_tree().quit()


func _capture_response_flow() -> void:
	await get_tree().create_timer(0.4).timeout
	_start()
	await get_tree().create_timer(9.0).timeout
	_save_shot("echo_step_response.png")
	get_tree().quit()


func _capture_result_flow() -> void:
	await get_tree().create_timer(0.4).timeout
	_start()
	await get_tree().create_timer(33.0).timeout
	_save_shot("echo_step_result.png")
	get_tree().quit()


func _run_pause_test() -> void:
	## `--test_pause` 인자로 실행하면 일시정지 동작을 실제로 확인하고 종료한다.
	var failures: Array[String] = []
	await get_tree().create_timer(0.4).timeout
	_start()
	await get_tree().create_timer(0.8).timeout
	_expect(not get_tree().paused, "시작 직후에는 게임이 멈춰 있지 않아야 함", failures)
	_expect(bool(test_mode.get("active")), "테스트 모드가 활성화되어야 함", failures)
	_expect(test_mode.call("is_pause_button_visible"), "일시정지 버튼이 보여야 함", failures)
	# 안내음이 재생 중일 때 멈추는지 확인한다 (끝난 뒤에는 stream_paused가 초기화된다).
	call_cue.play()
	test_mode.get_node("PauseButton").pressed.emit()
	await get_tree().create_timer(0.3).timeout
	_expect(get_tree().paused, "버튼을 누르면 씬 트리가 멈춰야 함", failures)
	_expect(bool(test_mode.get("paused")), "테스트 모드가 일시정지 상태여야 함", failures)
	_expect(music.stream_paused and call_cue.stream_paused, "음악과 리듬 안내음도 함께 멈춰야 함", failures)
	_expect(test_mode.call("is_panel_visible"), "일시정지 안내 패널이 보여야 함", failures)
	_expect(not test_mode.call("is_pause_button_visible"), "일시정지 중에는 버튼이 숨겨져야 함", failures)
	var frames_at_pause := frames_processed
	await get_tree().create_timer(0.5).timeout
	_expect(frames_processed == frames_at_pause, "멈춘 동안 게임 로직이 진행되지 않아야 함", failures)
	test_mode.call("toggle_pause")
	await get_tree().create_timer(0.3).timeout
	_expect(not get_tree().paused, "다시 누르면 씬 트리가 재개되어야 함", failures)
	_expect(not music.stream_paused and not call_cue.stream_paused, "음악과 리듬 안내음도 다시 재생되어야 함", failures)
	_expect(not test_mode.call("is_panel_visible"), "재개하면 안내 패널이 숨겨져야 함", failures)
	_expect(frames_processed > frames_at_pause, "재개 후 게임 로직이 다시 진행되어야 함", failures)
	var p_key := InputEventKey.new()
	p_key.keycode = KEY_P
	p_key.pressed = true
	Input.parse_input_event(p_key)
	await get_tree().create_timer(0.25).timeout
	_expect(get_tree().paused, "P 키로도 일시정지되어야 함", failures)
	var tree := get_tree()
	test_mode.get_node("PausePanel").find_child("메뉴", true, false).pressed.emit()
	_expect(not tree.paused, "메뉴로 나갈 때 일시정지가 먼저 풀려야 함", failures)
	if failures.is_empty():
		print("TEST_PAUSE_OK")
		tree.quit(0)
	else:
		for failure in failures:
			printerr("TEST_PAUSE_FAIL: " + failure)
		tree.quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _capture_intro_flow() -> void:
	await get_tree().create_timer(0.6).timeout
	_save_shot("echo_step_intro.png")
	get_tree().quit()


func _capture_anim_flow() -> void:
	await get_tree().create_timer(0.4).timeout
	_start()
	await get_tree().create_timer(2.0).timeout
	player.play("sneak")
	await get_tree().create_timer(0.08).timeout
	_save_shot("anim_sneak.png")
	player.play("surprise")
	await get_tree().create_timer(0.12).timeout
	_save_shot("anim_surprise.png")
	get_tree().quit()


func _capture_pause_flow() -> void:
	await get_tree().create_timer(0.4).timeout
	_start()
	await get_tree().create_timer(3.0).timeout
	_save_shot("test_mode_button.png")
	var button_center := Vector2(1852, 176)
	var window_scale := Vector2(get_window().size) / get_viewport().get_visible_rect().size
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = button_center * window_scale
		click.global_position = click.position
		Input.parse_input_event(click)
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(0.5).timeout
	print("CAPTURE_PAUSED=" + str(get_tree().paused))
	_save_shot("test_mode_pause.png")
	get_tree().quit(0)


func _save_shot(file_name: String) -> void:
	var dir := "res://Design/shots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var image := get_viewport().get_texture().get_image()
	image.save_png(dir + "/" + file_name)
