extends Control

const SCENE_MENU := "res://Scenes/StartScreen.tscn"
const ARROW_LEFT := preload("res://Assets/Art/UI/arrow_left.svg")
const ARROW_RIGHT := preload("res://Assets/Art/UI/arrow_right.svg")

const BPM := 96.0
const BEAT := 60.0 / BPM
const PATTERN_START_BEATS := 4.0
const LOOP_BEATS := 8.0
const LOOPS := 4
const HOLD_OFFSET := 4.0
const HOLD_DURATION := 1.0

const STEP_DIST := 130.0
const CAMERA_START := 2400.0
const PLAYER_Y := 760.0
const LANE_LINE_X := 960.0
const LANE_SPAWN_X := 1750.0
const LANE_Y := 990.0
const APPROACH_BEATS := 2.0

const STEPS := [
	{"offset": 0.0, "dir": 1},
	{"offset": 1.0, "dir": 1},
	{"offset": 2.0, "dir": -1},
	{"offset": 3.0, "dir": 1},
	{"offset": 6.0, "dir": 1},
	{"offset": 7.0, "dir": 1},
]

@onready var panorama: Sprite2D = %Panorama
@onready var player: Sprite2D = %PlayerSprite
@onready var shadow: TextureRect = %PlayerShadow
@onready var note_layer: Control = %NoteLayer
@onready var stop_cue: Control = %StopCue
@onready var stop_icon: TextureRect = $Stage/StopCue/StopIcon
@onready var hold_bar: ProgressBar = %HoldBar
@onready var judgment: Label = %Judgment
@onready var combo_label: Label = %Combo
@onready var noise_bar: ProgressBar = %NoiseBar
@onready var noise_value: Label = %NoiseValue
@onready var beat_dot: Panel = %BeatDot
@onready var start_overlay: Control = %StartOverlay
@onready var result_overlay: Control = %ResultOverlay
@onready var result_title: Label = %ResultTitle
@onready var result_desc: Label = %ResultDesc
@onready var music: AudioStreamPlayer = %Music
@onready var sfx_perfect: AudioStreamPlayer = %SfxPerfect
@onready var sfx_good: AudioStreamPlayer = %SfxGood
@onready var sfx_miss: AudioStreamPlayer = %SfxMiss

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
var step_anim_time := -1.0
var pot_step_dir := 1
var space_held := false
var hold_active := false
var active_hold: Dictionary = {}
var capture_mode := false
var autoplay := false
var step_notes: Array = []
var hold_notes: Array = []


func _ready() -> void:
	_build_chart()
	_reset_state()
	start_overlay.show()
	result_overlay.hide()

	var flags := _flags()
	if "autoplay" in flags:
		autoplay = true
	if "capture" in flags:
		capture_mode = true
		autoplay = true
		_capture_flow()
	elif "capture_result" in flags:
		capture_mode = true
		autoplay = true
		_capture_result_flow()


func _flags() -> Array[String]:
	var result: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		result.append(arg.lstrip("-"))
	return result


func _build_chart() -> void:
	for loop in LOOPS:
		var base := PATTERN_START_BEATS + float(loop) * LOOP_BEATS
		for step in STEPS:
			var node := TextureRect.new()
			node.texture = ARROW_RIGHT if int(step["dir"]) > 0 else ARROW_LEFT
			node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.custom_minimum_size = Vector2(58, 58)
			node.size = Vector2(58, 58)
			node.visible = false
			note_layer.add_child(node)
			step_notes.append({
				"time": (base + float(step["offset"])) * BEAT,
				"dir": int(step["dir"]),
				"judged": false,
				"node": node,
			})
		hold_notes.append({
			"start": (base + HOLD_OFFSET) * BEAT,
			"end": (base + HOLD_OFFSET + HOLD_DURATION) * BEAT,
			"judged": false,
			"active": false,
			"press_err": 0.0,
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
	step_anim_time = -1.0
	space_held = false
	hold_active = false
	active_hold = {}
	for note in step_notes:
		note["judged"] = false
		var node: TextureRect = note["node"]
		node.visible = false
	for hold in hold_notes:
		hold["judged"] = false
		hold["active"] = false
		hold["press_err"] = 0.0
	player.position = Vector2(960.0, PLAYER_Y)
	player.scale = Vector2(1.3, 1.3)
	player.frame = 0
	_set_camera(CAMERA_START)
	stop_cue.hide()
	hold_bar.value = 0.0
	_update_noise_ui()
	combo_label.text = ""
	judgment.modulate = Color(1, 1, 1, 0)


func _start() -> void:
	_reset_state()
	start_overlay.hide()
	result_overlay.hide()
	started = true
	music.play()


func _set_camera(value: float) -> void:
	camera_x = value
	panorama.position.x = 960.0 - value


func _get_song_time() -> float:
	if not music.playing:
		return song_time
	var t := music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return maxf(t, 0.0)


func _process(delta: float) -> void:
	if not started or finished:
		return
	song_time = _get_song_time()

	if autoplay:
		for note in step_notes:
			if not note["judged"] and song_time >= float(note["time"]):
				_press_arrow(int(note["dir"]))
		if not hold_active:
			for hold in hold_notes:
				if not hold["judged"] and song_time >= float(hold["start"]):
					_begin_hold()
					break
		if hold_active and song_time >= float(active_hold["end"]):
			_complete_hold()

	_update_notes()
	_update_holds()
	_update_beat()
	_update_step_anim(delta)

	if song_time >= (PATTERN_START_BEATS + float(LOOPS) * LOOP_BEATS) * BEAT:
		_finish(true)


func _update_notes() -> void:
	var approach := APPROACH_BEATS * BEAT
	for note in step_notes:
		if note["judged"]:
			continue
		var node: TextureRect = note["node"]
		var remain: float = float(note["time"]) - song_time
		if remain > approach or remain < -0.3:
			node.visible = false
		else:
			var progress := 1.0 - clampf(remain / approach, 0.0, 1.0)
			var x := lerpf(LANE_SPAWN_X, LANE_LINE_X, progress)
			node.visible = true
			node.position = Vector2(x - node.size.x * 0.5, LANE_Y)
		if song_time > float(note["time"]) + 0.16:
			note["judged"] = true
			node.visible = false
			miss_count += 1
			combo = 0
			_add_noise(12.0)
			_flash("MISS")
			_shake()
			sfx_miss.play()
			_update_combo()


func _update_holds() -> void:
	var cue_visible := false
	for hold in hold_notes:
		if hold["judged"]:
			continue
		if hold["active"]:
			cue_visible = true
			hold_bar.value = clampf((song_time - float(hold["start"])) / (float(hold["end"]) - float(hold["start"])) * 100.0, 0.0, 100.0)
			break
		var remain: float = float(hold["start"]) - song_time
		if remain <= BEAT * 1.6 and remain >= -0.2:
			cue_visible = true
			var pulse := 1.0 + 0.12 * sin(song_time * 10.0)
			stop_icon.scale = Vector2(pulse, pulse)
			break

	stop_cue.visible = cue_visible

	for hold in hold_notes:
		if hold["judged"] or hold["active"]:
			continue
		if song_time > float(hold["start"]) + 0.15:
			hold["judged"] = true
			miss_count += 1
			combo = 0
			_add_noise(12.0)
			_flash("MISS")
			_shake()
			sfx_miss.play()
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


func _update_step_anim(delta: float) -> void:
	if step_anim_time < 0.0:
		return
	step_anim_time += delta
	var t := step_anim_time / 0.2
	if t >= 1.0:
		step_anim_time = -1.0
		player.frame = 0
	else:
		player.frame = int(t * 8.0) % 8


func _press_arrow(dir: int) -> void:
	if finished:
		return

	var target: Dictionary = {}
	var best_err := 9.0
	for note in step_notes:
		if note["judged"]:
			continue
		var err: float = song_time - float(note["time"])
		if absf(err) <= 0.18 and absf(err) < absf(best_err):
			best_err = err
			target = note

	if target.is_empty():
		combo = 0
		_add_noise(4.0)
		_flash("MISS")
		sfx_miss.play()
		_update_combo()
		return

	if int(target["dir"]) != dir:
		combo = 0
		_add_noise(6.0)
		_flash("MISS")
		_update_combo()
		return

	target["judged"] = true
	var node: TextureRect = target["node"]
	node.visible = false
	var aerr := absf(best_err)

	if aerr <= 0.030:
		perfect_count += 1
		combo += 1
		_add_noise(-1.0)
		sfx_perfect.play()
		_flash("PERFECT")
		_do_step(int(target["dir"]))
	elif aerr <= 0.070:
		good_count += 1
		combo += 1
		sfx_good.play()
		_flash("GOOD")
		_do_step(int(target["dir"]))
	else:
		miss_count += 1
		combo = 0
		_add_noise(12.0)
		sfx_miss.play()
		_flash("MISS")
		_shake()

	max_combo = maxi(max_combo, combo)
	_update_combo()


func _do_step(dir: int) -> void:
	var target := camera_x + float(dir) * STEP_DIST
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_camera, camera_x, target, 0.24)
	camera_x = target

	player.position.x = 960.0 + float(dir) * 60.0
	player.position.y = PLAYER_Y - 14.0
	player.scale = Vector2(1.42, 1.14)
	pot_step_dir = dir

	var lunge := create_tween()
	lunge.set_parallel(true)
	lunge.tween_property(player, "position:x", 960.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lunge.tween_property(player, "position:y", PLAYER_Y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var squash := create_tween()
	squash.tween_property(player, "scale", Vector2(1.3, 1.3), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	step_anim_time = 0.0


func _begin_hold() -> void:
	if finished:
		return
	space_held = true

	var target: Dictionary = {}
	var best_err := 9.0
	for hold in hold_notes:
		if hold["judged"] or hold["active"]:
			continue
		var err: float = song_time - float(hold["start"])
		if absf(err) <= 0.18 and absf(err) < absf(best_err):
			best_err = err
			target = hold

	if target.is_empty():
		combo = 0
		_add_noise(4.0)
		_flash("MISS")
		sfx_miss.play()
		_update_combo()
		return

	target["active"] = true
	target["press_err"] = best_err
	active_hold = target
	hold_active = true
	hold_bar.value = 0.0
	stop_cue.show()
	player.frame = 0


func _release_hold() -> void:
	space_held = false
	if not hold_active:
		return
	if song_time >= float(active_hold["end"]) - 0.03:
		_complete_hold()
	else:
		active_hold["judged"] = true
		active_hold["active"] = false
		hold_active = false
		miss_count += 1
		combo = 0
		_add_noise(12.0)
		_flash("MISS")
		_shake()
		sfx_miss.play()
		stop_cue.hide()
		_update_combo()


func _complete_hold() -> void:
	if not hold_active:
		return
	var hold := active_hold
	hold["judged"] = true
	hold["active"] = false
	hold_active = false
	var aerr := absf(float(hold["press_err"]))
	if aerr <= 0.030:
		perfect_count += 1
		combo += 1
		_add_noise(-2.0)
		sfx_perfect.play()
		_flash("HOLD!")
	elif aerr <= 0.10:
		good_count += 1
		combo += 1
		sfx_good.play()
		_flash("HOLD!")
	else:
		miss_count += 1
		combo = 0
		_add_noise(12.0)
		sfx_miss.play()
		_flash("MISS")
	max_combo = maxi(max_combo, combo)
	stop_cue.hide()
	hold_bar.value = 0.0
	_update_combo()


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
		tween.tween_property(shadow, "position", Vector2(960.0 - 110.0 + randf_range(-8.0, 8.0), 890.0 + randf_range(-6.0, 6.0)), 0.03)
	tween.tween_property(shadow, "position", Vector2(850.0, 890.0), 0.06)
	var p := create_tween()
	for i in 5:
		p.tween_property(player, "position:x", 960.0 + randf_range(-9.0, 9.0), 0.03)
	p.tween_property(player, "position:x", 960.0, 0.06)


func _finish(success: bool) -> void:
	finished = true
	started = false
	music.stop()
	stop_cue.hide()
	for note in step_notes:
		var node: TextureRect = note["node"]
		node.visible = false
	result_overlay.show()
	if success:
		var rank := "B"
		if miss_count == 0 and perfect_count >= 20:
			rank = "S"
		elif miss_count == 0:
			rank = "A"
		result_title.text = "성공!  %s" % rank
		result_desc.text = "PERFECT %d · GOOD %d · MISS %d\n최대 콤보 %d · 소음 %d%%" % [perfect_count, good_count, miss_count, max_combo, int(noise)]
	else:
		result_title.text = "들켰다!"
		result_desc.text = "소음이 100%%가 되었습니다.\nPERFECT %d · GOOD %d · MISS %d" % [perfect_count, good_count, miss_count]


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

	if event is InputEventKey and not event.echo:
		if event.pressed:
			match event.keycode:
				KEY_LEFT, KEY_A:
					_press_arrow(-1)
				KEY_RIGHT, KEY_D:
					_press_arrow(1)
				KEY_SPACE:
					_begin_hold()
		elif event.keycode == KEY_SPACE:
			_release_hold()


func _capture_flow() -> void:
	await get_tree().create_timer(0.4).timeout
	_start()
	await get_tree().create_timer(5.2).timeout
	var dir := "res://Design/shots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var image := get_viewport().get_texture().get_image()
	image.save_png(dir + "/echo_step.png")
	get_tree().quit()


func _capture_result_flow() -> void:
	await get_tree().create_timer(0.4).timeout
	_start()
	await get_tree().create_timer(24.0).timeout
	var dir := "res://Design/shots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var image := get_viewport().get_texture().get_image()
	image.save_png(dir + "/echo_step_result.png")
	get_tree().quit()
