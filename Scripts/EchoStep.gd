extends Control

class FootprintPair:
	extends Node2D

	const FOOT_TEXTURE := preload("res://Assets/Art/UI/footprint.png")
	const STOP_TEXTURE := preload("res://Assets/Art/UI/stop_symbol.svg")

	var status := "preview"
	var is_hold := false
	var is_left_step := true
	var feet: Array[Sprite2D] = []
	var hint_label: Label

	func _init(hold_mode: bool = false, left_step: bool = true) -> void:
		is_hold = hold_mode
		is_left_step = left_step

	func _ready() -> void:
		light_mask = 0
		if is_hold:
			var stop_spr := Sprite2D.new()
			stop_spr.texture = STOP_TEXTURE
			stop_spr.light_mask = 0
			stop_spr.scale = Vector2(0.46, 0.46)
			add_child(stop_spr)
			feet.append(stop_spr)
		else:
			feet.append(_make_foot(Vector2(-22, 7), 1.42, false))
			feet.append(_make_foot(Vector2(22, -7), 1.72, true))
		hint_label = Label.new()
		hint_label.text = "꾹!" if is_hold else ("←" if is_left_step else "→")
		hint_label.position = Vector2(-28, -76)
		hint_label.size = Vector2(56, 36)
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.light_mask = 0
		hint_label.add_theme_font_size_override("font_size", 26)
		hint_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72, 1.0))
		hint_label.add_theme_color_override("font_outline_color", Color(0.11, 0.09, 0.18, 0.95))
		hint_label.add_theme_constant_override("outline_size", 7)
		hint_label.visible = true
		add_child(hint_label)
		_apply_color()

	func _make_foot(offset: Vector2, angle: float, mirrored: bool) -> Sprite2D:
		var foot := Sprite2D.new()
		foot.texture = FOOT_TEXTURE
		foot.light_mask = 0
		foot.position = offset
		foot.rotation = angle
		foot.flip_h = mirrored
		foot.scale = Vector2(0.14, 0.14)
		add_child(foot)
		return foot

	func set_status(value: String) -> void:
		status = value
		_apply_color()
		if status == "hit":
			var fade := create_tween()
			fade.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.15)

	func _apply_color() -> void:
		var color := Color(0.50, 0.92, 0.98, 0.92)
		match status:
			"active":
				color = Color(1.0, 0.88, 0.40, 1.0)
			"hit":
				color = Color(1.0, 0.84, 0.42, 0.55)
			"miss":
				color = Color(0.96, 0.38, 0.52, 0.65)
		for foot in feet:
			foot.modulate = color
		if is_instance_valid(hint_label):
			if status == "hit" or status == "miss":
				hint_label.visible = false
			else:
				hint_label.visible = true
				var col := Color(1.0, 0.92, 0.45, 1.0) if status == "active" else (Color(0.98, 0.62, 0.78, 0.95) if is_hold else (Color(0.58, 0.94, 1.0, 0.92) if is_left_step else Color(1.0, 0.82, 0.48, 0.92)))
				hint_label.add_theme_color_override("font_color", col)
				hint_label.scale = Vector2(1.25, 1.25) if status == "active" else Vector2.ONE

const SCENE_MENU := "res://Scenes/StartScreen.tscn"
const RANK_S := preload("res://Assets/Art/UI/rank_s.png")
const RANK_A := preload("res://Assets/Art/UI/rank_a.png")
const RANK_B := preload("res://Assets/Art/UI/rank_b.png")
const RANK_FAIL := preload("res://Assets/Art/UI/rank_fail.png")
const NEIGHBOR_TEXTURES := [
	preload("res://Assets/Art/UI/neighbor_0_calm.svg"),
	preload("res://Assets/Art/UI/neighbor_1_alert.svg"),
	preload("res://Assets/Art/UI/neighbor_2_angry.svg"),
	preload("res://Assets/Art/UI/neighbor_3_furious.svg"),
]
const UNCLE_TEXTURES := [
	preload("res://Assets/Art/Characters/uncle/anger1_400x340.png"),
	preload("res://Assets/Art/Characters/uncle/anger2_400x340.png"),
	preload("res://Assets/Art/Characters/uncle/anger3_400x340.png"),
	preload("res://Assets/Art/Characters/uncle/fail_image.png"),
]
const PLAYER_FRAMES := preload("res://Assets/Art/Characters/me/player_frames.tres")
const KID_FRAMES := preload("res://Assets/Art/Characters/me/kid/kid_frames.tres")
const BPM := 120.0
const BEAT := 60.0 / BPM
const DIFFICULTY_BPMS := [120.0, 126.0, 134.0]
const PATTERN_START_BEATS := 1.0
const BEATS_PER_PATTERN := 4
const LEADIN_BEATS := 1.5
const BEATS_PER_ROUND := float(BEATS_PER_PATTERN) + LEADIN_BEATS + float(BEATS_PER_PATTERN)
# 못·망치(Built to Scale) 스타일의 12라운드 고정 패턴 (랜덤 없음, 4박자 단위):
# 난이도 1: 기본 · 정박 -> 연타 -> 엇박 -> 멈춤 -> 물 마시기 -> 피날레
const DIFFICULTY_1_PATTERNS := [
	[0.0, 2.0],
	[0.0, 1.0, 2.0],
	[0.0, 1.5, 3.0],
	[0.0, {"beat": 2.0, "hold": 1.5}],
	[0.0, 1.5, 2.5, 3.5],
	[0.0, {"beat": 1.0, "special": "drink_btn"}, {"beat": 1.5, "hold": 1.5, "special": "drink"}, {"beat": 3.5, "special": "drink_sip"}],
	[0.0, 0.5, 1.0, 1.5, 3.0],
	[{"beat": 0.0, "hold": 1.2}, 2.0, {"beat": 2.5, "hold": 1.2}],
	[0.0, 0.5, 2.0, 2.5, 3.5],
	[0.0, {"beat": 1.0, "hold": 1.5}, 3.0, 3.5],
	[0.0, 0.5, 1.0, 1.5, 2.5, 3.0, 3.5],
	[0.0, 1.0, 1.5, {"beat": 2.0, "hold": 1.2}, 3.5],
]
# 난이도 2: 빽빽한 8분음표 연타 & 엇박 + 더블 홀드 (126 BPM)
const DIFFICULTY_2_PATTERNS := [
	[0.0, 0.5, 1.0, 2.0, 2.5, 3.0],
	[0.0, 0.5, 1.5, 2.0, 2.5, 3.5],
	[0.0, 0.5, 1.0, {"beat": 2.0, "hold": 1.2}, 3.5],
	[0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 3.5],
	[{"beat": 0.0, "hold": 1.0}, 1.5, 2.0, 2.5, 3.0, 3.5],
	[0.0, 0.5, {"beat": 1.0, "special": "drink_btn"}, {"beat": 1.5, "hold": 1.2, "special": "drink"}, 3.0, {"beat": 3.5, "special": "drink_sip"}],
	[0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5],
	[{"beat": 0.0, "hold": 1.0}, 1.5, {"beat": 2.0, "hold": 1.0}, 3.5],
	[0.0, 0.5, 1.5, 2.0, 2.5, 3.0, 3.5],
	[0.0, 0.5, 1.0, {"beat": 1.5, "hold": 1.2}, 3.0, 3.5],
	[0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5],
	[0.0, 0.5, 1.0, 1.5, {"beat": 2.0, "hold": 1.0}, 3.5],
]
# 난이도 3: 초고밀도 8분음표 풀채움 & 고속 홀드 전환 (134 BPM)
const DIFFICULTY_3_PATTERNS := [
	[0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5],
	[0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5],
	[0.0, 0.5, 1.0, 1.5, {"beat": 2.0, "hold": 1.0}, 3.5],
	[0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5],
	[{"beat": 0.0, "hold": 0.8}, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5],
	[0.0, 0.5, {"beat": 1.0, "special": "drink_btn"}, {"beat": 1.5, "hold": 1.0, "special": "drink"}, 3.0, {"beat": 3.5, "special": "drink_sip"}],
	[0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5],
	[{"beat": 0.0, "hold": 0.8}, 1.0, 1.5, {"beat": 2.0, "hold": 0.8}, 3.0, 3.5],
	[0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5],
	[0.0, 0.5, {"beat": 1.0, "hold": 1.0}, 2.5, 3.0, 3.5],
	[0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5],
	[0.0, 0.5, 1.0, 1.5, 2.0, 2.5, {"beat": 3.0, "hold": 0.8}],
]
const RESPONSE_WINDOW := 0.215
const PERFECT_WINDOW := 0.095
const GOOD_WINDOW := 0.185
const BEAT_DIST := 160.0
const CAMERA_START := 2000.0
const PLAYER_Y := 751.735
const MAX_LIVES := 5

@export_enum("player", "kid") var character_variant := "player"
var player_base_scale := 0.72

const LIGHT_SPECS := [
	{"x": 1450.0, "y": 290.0, "scale": 8.5, "energy": 1.45, "color": Color(1.0, 0.87, 0.72), "kind": "window", "phase": 0.0},
	{"x": 1500.0, "y": 890.0, "scale": 5.5, "energy": 0.55, "color": Color(1.0, 0.84, 0.68), "kind": "static", "phase": 0.7},
	{"x": 1660.0, "y": 650.0, "scale": 2.4, "energy": 0.85, "color": Color(1.0, 0.78, 0.52), "kind": "lamp", "phase": 1.7},
	{"x": 2700.0, "y": 420.0, "scale": 6.0, "energy": 0.65, "color": Color(0.86, 0.78, 0.96), "kind": "static", "phase": 2.0},
	{"x": 3550.0, "y": 300.0, "scale": 7.0, "energy": 0.95, "color": Color(0.82, 0.82, 1.0), "kind": "static", "phase": 2.3},
	{"x": 3550.0, "y": 890.0, "scale": 5.5, "energy": 0.45, "color": Color(0.84, 0.82, 0.98), "kind": "static", "phase": 2.9},
	{"x": 3980.0, "y": 635.0, "scale": 3.6, "energy": 1.05, "color": Color(0.58, 0.76, 1.0), "kind": "tv", "phase": 0.0},
	{"x": 4750.0, "y": 420.0, "scale": 6.0, "energy": 0.65, "color": Color(0.76, 0.82, 0.98), "kind": "static", "phase": 3.0},
	{"x": 5450.0, "y": 300.0, "scale": 7.0, "energy": 1.05, "color": Color(0.82, 0.92, 1.0), "kind": "static", "phase": 3.1},
	{"x": 5450.0, "y": 890.0, "scale": 5.5, "energy": 0.5, "color": Color(0.82, 0.9, 1.0), "kind": "static", "phase": 3.7},
	{"x": 7800.0, "y": 320.0, "scale": 7.5, "energy": 1.0, "color": Color(0.86, 0.84, 1.0), "kind": "static", "phase": 4.1},
	{"x": 9600.0, "y": 320.0, "scale": 8.0, "energy": 1.15, "color": Color(1.0, 0.86, 0.78), "kind": "static", "phase": 4.7},
]

@onready var panorama: Node2D = %Panorama
@onready var player: AnimatedSprite2D = %PlayerSprite
@onready var shadow: TextureRect = %PlayerShadow
@onready var stop_cue: Control = %StopCue
@onready var stop_label: Label = $Stage/StopCue/StopLabel
@onready var hold_bar: ProgressBar = %HoldBar
@onready var judgment: Label = %Judgment
@onready var combo_label: Label = %Combo
@onready var noise_card: Panel = %NoiseCard
@onready var neighbor_portrait: TextureRect = %NeighborPortrait
@onready var neighbor_title: Label = %NeighborTitle
@onready var neighbor_speech: Label = %NeighborSpeech
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
var lives := MAX_LIVES
var noise := 0.0
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
var total_chart_duration := 0.0
var round_timings: Array[Dictionary] = []
var lighting: Lighting2D
var timeline_panel: Panel
var timeline_cursor: ColorRect
var timeline_dots: Array[Panel] = []
var timeline_round := -2
var next_key_badge: Panel
var next_key_label: Label
var last_next_key_text := ""
var neighbor_stage := -1
var life_dots: Array[Panel] = []
var step_foot_index := 0
var active_hold_note: Dictionary = {}
var space_held := false
var cutscene_active := false
var difficulty_level := 1
var active_bpm := 120.0
var active_patterns: Array = DIFFICULTY_1_PATTERNS
var downstairs_root: Control
var downstairs_bg: TextureRect
var downstairs_thud: Label
var downstairs_face: TextureRect
var downstairs_bubble: Panel
var downstairs_label: Label
var downstairs_stage_label: Label


func _ready() -> void:
	var flags := _flags()
	difficulty_level = clampi(Settings.current_chapter, 1, 3)
	for f in flags:
		if f.begins_with("chapter="):
			difficulty_level = clampi(int(f.trim_prefix("chapter=")), 1, 3)
	_apply_difficulty()
	_apply_character_variant()
	_build_chart()
	_setup_beat_timeline()
	_setup_downstairs_view()
	_setup_life_dots()
	_reset_state()
	start_overlay.show()
	result_overlay.hide()
	test_mode.pause_changed.connect(_on_test_pause_changed)
	player.animation_finished.connect(_on_player_animation_finished)
	lighting = Lighting2D.apply(
		self,
		panorama,
		$Stage,
		[get_node("UI"), start_overlay, result_overlay, test_mode],
		LIGHT_SPECS,
	)

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
	elif "capture_rooms" in flags:
		_capture_rooms_flow()
	elif "capture_audit" in flags:
		autoplay = true
		_capture_audit_flow()
	elif "capture_cutscene" in flags:
		_capture_cutscene_flow()


func _flags() -> Array[String]:
	var result: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		result.append(arg.lstrip("-"))
	return result


func _apply_difficulty() -> void:
	active_bpm = float(DIFFICULTY_BPMS[difficulty_level - 1])
	match difficulty_level:
		2:
			active_patterns = DIFFICULTY_2_PATTERNS
		3:
			active_patterns = DIFFICULTY_3_PATTERNS
		_:
			active_patterns = DIFFICULTY_1_PATTERNS
	var ui_title := get_node_or_null("UI/ChapterLabel") as Label
	if is_instance_valid(ui_title):
		ui_title.text = "난이도 %d · 살금 스텝" % difficulty_level
	var start_title := get_node_or_null("StartOverlay/Panel/Margin/VBox/Title") as Label
	if is_instance_valid(start_title):
		start_title.text = "살금 스텝 · %d단계" % difficulty_level
	var start_desc := get_node_or_null("StartOverlay/Panel/Margin/VBox/Desc") as Label
	if is_instance_valid(start_desc):
		match difficulty_level:
			2:
				start_desc.text = "빽빽한 8분음표 연타와 엇박 패턴! (126 BPM)"
			3:
				start_desc.text = "초고밀도 8분음표 풀채움 패턴! (134 BPM)"
			_:
				start_desc.text = "누나 발자국을 듣고 따라 걸어요. (120 BPM)"


func _apply_character_variant() -> void:
	if character_variant == "kid":
		player_base_scale = 1.0
		player.sprite_frames = KID_FRAMES
		player.offset = Vector2(-256.0, -421.0)
	else:
		player_base_scale = 0.72
		player.sprite_frames = PLAYER_FRAMES
		player.offset = Vector2(-256.0, -315.0)
	player.scale = Vector2.ONE * player_base_scale


func _build_chart() -> void:
	call_notes.clear()
	response_notes.clear()
	round_timings.clear()

	var ready_beat := 60.0 / active_bpm
	var cursor_time := PATTERN_START_BEATS * ready_beat
	var global_step_counter := 0

	for round_index in active_patterns.size():
		var bpm := active_bpm
		var beat_dur := 60.0 / bpm
		var call_base := cursor_time
		var leadin_base := cursor_time + float(BEATS_PER_PATTERN) * beat_dur
		var response_base := leadin_base + LEADIN_BEATS * beat_dur
		var round_end := cursor_time + BEATS_PER_ROUND * beat_dur
		round_timings.append({
			"round": round_index,
			"bpm": bpm,
			"beat": beat_dur,
			"start": call_base,
			"leadin": leadin_base,
			"response": response_base,
			"end": round_end,
		})
		var pattern: Array = active_patterns[round_index]
		for step_order in pattern.size():
			var entry: Variant = pattern[step_order]
			var beat_offset := 0.0
			var hold_beats := 0.0
			var special_kind := ""
			if entry is Dictionary:
				beat_offset = float(entry.get("beat", 0.0))
				hold_beats = float(entry.get("hold", 0.0))
				special_kind = String(entry.get("special", ""))
			else:
				beat_offset = float(entry)
			var is_hold := hold_beats > 0.0
			var is_left_step := true
			if not is_hold:
				is_left_step = (global_step_counter % 2 == 0)
				global_step_counter += 1
			var is_offbeat := not is_equal_approx(beat_offset, roundf(beat_offset))
			var is_last := step_order == pattern.size() - 1
			var target_x := CAMERA_START + (float(round_index * BEATS_PER_PATTERN) + beat_offset + 1.0) * BEAT_DIST
			call_notes.append({
				"time": call_base + beat_offset * beat_dur,
				"round": round_index,
				"beat": beat_offset,
				"hold_beats": hold_beats,
				"special": special_kind,
				"is_hold": is_hold,
				"is_left": is_left_step,
				"step_order": step_order,
				"target_x": target_x,
				"offbeat": is_offbeat,
				"is_last": is_last,
				"played": false,
				"mark": null,
			})
			response_notes.append({
				"time": response_base + beat_offset * beat_dur,
				"end_time": response_base + (beat_offset + hold_beats) * beat_dur,
				"round": round_index,
				"beat": beat_offset,
				"hold_beats": hold_beats,
				"special": special_kind,
				"is_hold": is_hold,
				"is_left": is_left_step,
				"step_order": step_order,
				"target_x": target_x,
				"offbeat": is_offbeat,
				"is_last": is_last,
				"judged": false,
				"holding": false,
				"start_error": 0.0,
				"mark": null,
			})
		cursor_time = round_end
	total_chart_duration = cursor_time

func _reset_state() -> void:
	started = false
	finished = false
	song_time = 0.0
	camera_x = CAMERA_START
	lives = MAX_LIVES
	noise = 0.0
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
		note["holding"] = false
		note["start_error"] = 0.0
		note["mark"] = null
	step_foot_index = 0
	active_hold_note = {}
	space_held = false
	cutscene_active = false
	hold_bar.value = 0.0
	_stop_poise_wobble()
	panorama.position.y = 0.0
	$Stage.position.y = 0.0
	if is_instance_valid(downstairs_root):
		downstairs_root.position.y = 1080.0
		downstairs_root.visible = false
	for mark in footprint_marks:
		if is_instance_valid(mark):
			mark.queue_free()
	footprint_marks.clear()
	player.position = Vector2(960.28, PLAYER_Y)
	player.rotation = 0.0
	player.scale = Vector2.ONE * player_base_scale
	player.play("idle")
	_set_camera(CAMERA_START)
	stop_cue.hide()
	neighbor_stage = -1
	_update_noise_ui()
	combo_label.text = ""
	judgment.modulate = Color(1, 1, 1, 0)
	phase_label.text = "준비"
	timeline_round = -2
	_clear_timeline_dots()
	if is_instance_valid(timeline_panel):
		timeline_panel.visible = false
	if is_instance_valid(next_key_badge):
		next_key_badge.visible = false
	if is_instance_valid(next_key_badge):
		next_key_badge.visible = false
	last_next_key_text = ""


func _start() -> void:
	_reset_state()
	start_overlay.hide()
	result_overlay.hide()
	started = true
	test_mode.set_active(true)
	music.pitch_scale = 1.18
	music.play(0.0)


func _on_test_pause_changed(paused: bool) -> void:
	music.stream_paused = paused
	call_cue.stream_paused = paused


func _on_player_animation_finished() -> void:
	if finished:
		return
	# 따라 걷기 중 스텝을 밟고 잠깐 멈춰 있을 때는 한 발을 들고 대기한다(건들거림 없음).
	if current_phase == "response" and (player.animation == "sneak_left" or player.animation == "sneak_right"):
		var pose := "poise_right" if step_foot_index % 2 == 1 else "poise_left"
		player.play(pose)
	elif player.animation != "poise_left" and player.animation != "poise_right":
		_stop_poise_wobble()
		player.play("idle")


func _stop_poise_wobble() -> void:
	player.rotation = 0.0
	player.position.y = PLAYER_Y


func _play_surprise() -> void:
	if finished:
		return
	_stop_poise_wobble()
	player.play("surprise")


func _current_beat_duration() -> float:
	if current_round >= 0 and current_round < round_timings.size():
		return float(round_timings[current_round]["beat"])
	if not round_timings.is_empty():
		return float(round_timings[0]["beat"])
	return 60.0 / active_bpm


func test_mode_info() -> String:
	var beat_dur := _current_beat_duration()
	var beat_index := int(floor(song_time / beat_dur)) + 1
	var bpm_now := int(roundf(60.0 / beat_dur))
	return "%d BPM · 박자 %d · 소음 %d%%\nPERFECT %d / GOOD %d / MISS %d · 콤보 %d" % [
		bpm_now, beat_index, int(noise), perfect_count, good_count, miss_count, combo,
	]


func _set_camera(value: float) -> void:
	camera_x = value
	panorama.position.x = 960.0 - value


func _get_song_time() -> float:
	return chart_clock


func _process(delta: float) -> void:
	if lighting != null:
		lighting.focus = Vector2(camera_x, PLAYER_Y)
		lighting.has_focus = true
	if not started or finished or cutscene_active:
		return
	frames_processed += 1
	chart_clock += delta
	song_time = _get_song_time()
	_update_phase()
	_update_call_notes()
	_update_response_notes()
	_update_active_hold()
	_update_beat()
	_update_beat_timeline()
	_highlight_next_footprint()

	if autoplay:
		for note in response_notes:
			if note["judged"]:
				continue
			if bool(note["is_hold"]):
				if not bool(note["holding"]) and song_time >= float(note["time"]):
					_begin_hold(note, 0.0)
			elif song_time >= float(note["time"]):
				_judge_response(note, 0.0)

	if song_time >= total_chart_duration:
		_finish(true)


func _update_phase() -> void:
	var prev_phase := current_phase
	var prev_round := current_round
	if round_timings.is_empty() or song_time < float(round_timings[0]["start"]):
		current_round = -1
		current_phase = "ready"
		phase_label.text = "준비"
		return
	for timing in round_timings:
		if song_time < float(timing["end"]) or int(timing["round"]) == round_timings.size() - 1:
			current_round = int(timing["round"])
			if song_time < float(timing["leadin"]):
				current_phase = "call"
				phase_label.text = "듣기  %d/%d" % [current_round + 1, active_patterns.size()]
			elif song_time < float(timing["response"]):
				current_phase = "leadin"
				var lead_elapsed := song_time - float(timing["leadin"])
				phase_label.text = "준비!" if lead_elapsed < float(timing["beat"]) * 0.75 else "시작!"
			else:
				current_phase = "response"
				phase_label.text = "따라 걷기  %d/%d" % [current_round + 1, active_patterns.size()]
			break
	if current_round != prev_round and current_round >= 0:
		# 이전 라운드 마지막 노트를 놓쳤더라도 다음 라운드 기준 X로 정렬
		var expected_x := CAMERA_START + float(current_round * BEATS_PER_PATTERN) * BEAT_DIST
		if absf(camera_x - expected_x) > 1.0:
			var align := create_tween()
			align.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			align.tween_method(_set_camera, camera_x, expected_x, 0.16)
			camera_x = expected_x
	if current_phase != prev_phase:
		if current_phase == "call":
			player.play("idle")
		phase_label.pivot_offset = phase_label.size / 2.0
		phase_label.scale = Vector2(1.16, 1.16)
		var pt := create_tween()
		pt.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pt.tween_property(phase_label, "scale", Vector2.ONE, 0.22)


func _update_call_notes() -> void:
	for note in call_notes:
		if note["played"] or song_time < float(note["time"]):
			continue
		note["played"] = true
		heard_count += 1
		# 못·망치처럼 정박/엇박/홀드/마무리 음에 음정 변화를 주어 패턴 기억을 돕는다.
		if bool(note.get("is_hold", false)):
			call_cue.pitch_scale = 0.82
		elif bool(note.get("is_last", false)):
			call_cue.pitch_scale = 1.22
		elif bool(note.get("offbeat", false)):
			call_cue.pitch_scale = 1.12
		else:
			call_cue.pitch_scale = 1.0
		call_cue.play()
		var mark := _place_footprints(note)
		note["mark"] = mark
		var mark_pulse := create_tween()
		mark_pulse.tween_property(mark, "scale", Vector2(1.24, 1.24), 0.1)
		mark_pulse.tween_property(mark, "scale", Vector2.ONE, 0.18)


func _place_footprints(call_note: Dictionary) -> FootprintPair:
	var is_hold := bool(call_note.get("is_hold", false))
	var is_left_step := bool(call_note.get("is_left", true))
	var mark := FootprintPair.new(is_hold, is_left_step)
	var step_idx := int(call_note["step_order"])
	mark.position = Vector2(
		float(call_note["target_x"]),
		PLAYER_Y + (140.0 if is_hold else (185.0 + float(step_idx % 2) * 8.0))
	)
	mark.z_index = 4
	panorama.add_child(mark)
	footprint_marks.append(mark)
	for response_note in response_notes:
		if int(response_note["round"]) == int(call_note["round"]) and int(response_note["step_order"]) == step_idx:
			response_note["mark"] = mark
			break
	return mark


func _setup_downstairs_view() -> void:
	downstairs_root = Control.new()
	downstairs_root.position = Vector2(0.0, 1080.0)
	downstairs_root.size = Vector2(1920.0, 1080.0)
	downstairs_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	downstairs_root.visible = false
	downstairs_root.z_index = 5
	add_child(downstairs_root)
	move_child(downstairs_root, get_node("UI").get_index())

	# 아랫집 방 전체 스테이지 (fail_image.png)
	downstairs_bg = TextureRect.new()
	downstairs_bg.size = Vector2(1920.0, 1080.0)
	downstairs_bg.pivot_offset = Vector2(960.0, 540.0)
	downstairs_bg.texture = UNCLE_TEXTURES[3]
	downstairs_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	downstairs_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	downstairs_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	downstairs_root.add_child(downstairs_bg)

	# 천장 "쿵!!" 충격 텍스트/이펙트
	downstairs_thud = Label.new()
	downstairs_thud.position = Vector2(560.0, 34.0)
	downstairs_thud.size = Vector2(800.0, 96.0)
	downstairs_thud.pivot_offset = Vector2(400.0, 48.0)
	downstairs_thud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	downstairs_thud.text = "쿵!!"
	downstairs_thud.add_theme_font_size_override("font_size", 72)
	downstairs_thud.add_theme_color_override("font_color", Color(1.0, 0.42, 0.56, 1.0))
	downstairs_thud.add_theme_color_override("font_outline_color", Color(0.10, 0.08, 0.16, 1.0))
	downstairs_thud.add_theme_constant_override("outline_size", 14)
	downstairs_thud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	downstairs_root.add_child(downstairs_thud)

	# 아저씨 반응 얼굴 (소파 위 아저씨 위치에 겹쳐 동적으로 표정·애니메이션 연출)
	downstairs_face = TextureRect.new()
	downstairs_face.position = Vector2(575.0, 275.0)
	downstairs_face.size = Vector2(380.0, 323.0)
	downstairs_face.pivot_offset = Vector2(190.0, 161.5)
	downstairs_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	downstairs_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	downstairs_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	downstairs_root.add_child(downstairs_face)

	# 아저씨 옆 만화 말풍선
	downstairs_bubble = Panel.new()
	downstairs_bubble.position = Vector2(950.0, 225.0)
	downstairs_bubble.size = Vector2(590.0, 180.0)
	downstairs_bubble.pivot_offset = Vector2(0.0, 90.0)
	downstairs_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.99, 0.98, 0.96, 0.97)
	bs.border_color = Color(0.14, 0.12, 0.18, 1.0)
	bs.set_border_width_all(4)
	bs.set_corner_radius_all(28)
	bs.shadow_color = Color(0.05, 0.04, 0.10, 0.35)
	bs.shadow_size = 12
	downstairs_bubble.add_theme_stylebox_override("panel", bs)
	downstairs_root.add_child(downstairs_bubble)

	downstairs_stage_label = Label.new()
	downstairs_stage_label.position = Vector2(28.0, 24.0)
	downstairs_stage_label.size = Vector2(564.0, 44.0)
	downstairs_stage_label.add_theme_font_size_override("font_size", 28)
	downstairs_stage_label.add_theme_color_override("font_color", Color(0.86, 0.24, 0.36, 1.0))
	downstairs_bubble.add_child(downstairs_stage_label)

	downstairs_label = Label.new()
	downstairs_label.position = Vector2(28.0, 76.0)
	downstairs_label.size = Vector2(564.0, 82.0)
	downstairs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	downstairs_label.add_theme_font_size_override("font_size", 26)
	downstairs_label.add_theme_color_override("font_color", Color(0.16, 0.14, 0.22, 1.0))
	downstairs_bubble.add_child(downstairs_label)


func _trigger_miss_cutscene() -> void:
	if cutscene_active or finished:
		return
	cutscene_active = true
	var failed_round := current_round
	# 현재 라운드의 남은 노트를 즉시 강제 종료(4박자 끝까지 기다리지 않음)
	for note in response_notes:
		if int(note["round"]) == failed_round and not bool(note["judged"]):
			note["judged"] = true
			note["holding"] = false
			var m: FootprintPair = note["mark"]
			if is_instance_valid(m):
				m.set_status("miss")
	active_hold_note = {}
	stop_cue.hide()
	hold_bar.value = 0.0
	if is_instance_valid(next_key_badge):
		next_key_badge.visible = false
	if is_instance_valid(timeline_panel):
		timeline_panel.visible = false

	# 아랫집 아저씨 단계별 연출 초기 세팅
	var stage := clampi(neighbor_stage, 0, 3)
	if lives <= 0 or noise >= 100.0:
		stage = 3
	downstairs_root.visible = true
	downstairs_bg.scale = Vector2.ONE
	downstairs_thud.scale = Vector2(1.4, 1.4)
	downstairs_thud.modulate = Color(1, 1, 1, 1)
	downstairs_bubble.scale = Vector2(0.7, 0.7)
	downstairs_bubble.modulate = Color(1, 1, 1, 0)

	if stage == 3:
		downstairs_bg.modulate = Color(1.0, 0.92, 0.92, 1.0)
		downstairs_face.visible = false
		downstairs_thud.text = "쾅!!"
		downstairs_stage_label.text = "아랫집 · 폭발!!"
		downstairs_label.text = "도저히 못 참겠다! 당장 올라간다!!"
	else:
		downstairs_bg.modulate = Color(0.68, 0.65, 0.78, 1.0) if stage <= 1 else Color(0.88, 0.72, 0.76, 1.0)
		downstairs_face.visible = true
		# 시작 시 직전 단계 표정에서 새 단계 표정으로 애니메이션 전환!
		var prev_tex_idx := maxi(stage - 1, 0)
		downstairs_face.texture = UNCLE_TEXTURES[prev_tex_idx]
		downstairs_face.position = Vector2(575.0, 275.0)
		downstairs_face.rotation = 0.0
		downstairs_face.scale = Vector2.ONE
		downstairs_thud.text = "쿵!" if stage <= 1 else "쿵! 쿵!!"
		match stage:
			0:
				downstairs_stage_label.text = "아랫집 · 자다가 깸"
				downstairs_label.text = "쿨쿨... 어? 위에서 무슨 소리가..."
			1:
				downstairs_stage_label.text = "아랫집 · 눈을 부비적거림!"
				downstairs_label.text = "으음... 눈 비비며 일어나는 중... 시끄럽네..."
			_:
				downstairs_stage_label.text = "아랫집 · 벌떡 일어나 분노!"
				downstairs_label.text = "또 쿵쿵거리네!! 한 번만 더 소리 내봐!!"

	# 1) 아래층으로 스크롤 다운
	var down_t := create_tween()
	down_t.set_parallel(true)
	down_t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	down_t.tween_property(panorama, "position:y", -1080.0, 0.30)
	down_t.tween_property($Stage, "position:y", -1080.0, 0.30)
	down_t.tween_property(downstairs_root, "position:y", 0.0, 0.30)
	down_t.tween_property(downstairs_thud, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	await down_t.finished

	# 2) 천장 충격파 떨림 + 말풍선 팝업 + 아저씨 리액션 애니메이션!
	var react := create_tween()
	react.set_parallel(true)
	react.tween_property(downstairs_bubble, "modulate:a", 1.0, 0.14)
	react.tween_property(downstairs_bubble, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	react.tween_property(downstairs_thud, "modulate:a", 0.0, 0.45).set_delay(0.25)

	if stage == 3:
		# 폭발: 화면 줌인 + 격렬한 흔들림
		var boom := create_tween()
		boom.tween_property(downstairs_bg, "scale", Vector2(1.06, 1.06), 0.15).set_trans(Tween.TRANS_BACK)
		for i in 8:
			boom.tween_property(downstairs_bg, "position", Vector2(randf_range(-14.0, 14.0), randf_range(-10.0, 10.0)), 0.04)
		boom.tween_property(downstairs_bg, "position", Vector2.ZERO, 0.06)
		await get_tree().create_timer(1.25).timeout
		cutscene_active = false
		_finish(false)
		return

	# 단계별 아저씨 모션 애니메이션 (자다 뒤척임 -> 눈 부비적 -> 벌떡 점프!)
	if downstairs_face.visible:
		var anim := create_tween()
		if stage == 0:
			# 누워서 뒤척이며 살짝 찌푸림
			anim.tween_property(downstairs_face, "rotation", -0.06, 0.14)
			anim.tween_property(downstairs_face, "rotation", 0.06, 0.16)
			anim.tween_callback(func(): downstairs_face.texture = UNCLE_TEXTURES[0])
			anim.tween_property(downstairs_face, "rotation", 0.0, 0.15)
		elif stage == 1:
			# 잠결에 부비적거리다 눈 비비며 anger2로 전환!
			anim.tween_property(downstairs_face, "position:y", 292.0, 0.10)
			anim.tween_property(downstairs_face, "rotation", -0.08, 0.09)
			anim.tween_property(downstairs_face, "rotation", 0.08, 0.09)
			anim.tween_callback(func(): downstairs_face.texture = UNCLE_TEXTURES[1])
			anim.tween_property(downstairs_face, "scale", Vector2(1.14, 0.88), 0.08)
			anim.tween_property(downstairs_face, "scale", Vector2(1.06, 1.06), 0.14).set_trans(Tween.TRANS_BACK)
			anim.parallel().tween_property(downstairs_face, "position:y", 262.0, 0.14)
			anim.parallel().tween_property(downstairs_face, "rotation", 0.0, 0.14)
		else:
			# 벌떡 뛰어오르며 새빨개진 anger3로 폭발 직전 분노!
			anim.tween_property(downstairs_face, "scale", Vector2(1.18, 0.82), 0.08)
			anim.tween_callback(func(): downstairs_face.texture = UNCLE_TEXTURES[2])
			anim.tween_property(downstairs_face, "position:y", 225.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			anim.parallel().tween_property(downstairs_face, "scale", Vector2(1.12, 1.12), 0.14)
			for i in 5:
				anim.tween_property(downstairs_face, "position:x", 530.0 + randf_range(-14.0, 14.0), 0.04)
			anim.tween_property(downstairs_face, "position", Vector2(530.0, 275.0), 0.08)
			anim.parallel().tween_property(downstairs_face, "scale", Vector2.ONE, 0.10)

	await get_tree().create_timer(1.1).timeout

	# 3) 다시 위층으로 스크롤 업
	var up_t := create_tween()
	up_t.set_parallel(true)
	up_t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	up_t.tween_property(panorama, "position:y", 0.0, 0.32)
	up_t.tween_property($Stage, "position:y", 0.0, 0.32)
	up_t.tween_property(downstairs_root, "position:y", 1080.0, 0.32)
	await up_t.finished
	downstairs_root.visible = false

	# 다음 라운드 시작 시간으로 차트 시계 점프 & 캐릭터 복귀
	_stop_poise_wobble()
	player.play("idle")
	var next_round := failed_round + 1
	if next_round >= round_timings.size():
		cutscene_active = false
		_finish(true)
		return
	var next_start := float(round_timings[next_round]["start"])
	chart_clock = next_start
	song_time = next_start
	var expected_x := CAMERA_START + float(next_round * BEATS_PER_PATTERN) * BEAT_DIST
	_set_camera(expected_x)
	last_beat = -1
	cutscene_active = false


func _setup_beat_timeline() -> void:
	var ui := get_node("UI")
	timeline_panel = Panel.new()
	timeline_panel.position = Vector2(680.0, 96.0)
	timeline_panel.size = Vector2(560.0, 52.0)
	timeline_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.11, 0.20, 0.82)
	style.border_color = Color(0.88, 0.82, 0.96, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	timeline_panel.add_theme_stylebox_override("panel", style)
	timeline_panel.visible = false
	ui.add_child(timeline_panel)

	# 왼쪽 1.5칸(준비 1.5틱 빈 공간) + 오른쪽 4칸(실제 4박자 패턴) = 총 5.5칸
	var total_slots := LEADIN_BEATS + float(BEATS_PER_PATTERN)
	var span := 490.0 / total_slots
	# 대기 1.5틱 내 눈금(0.0, 0.75) + 패턴 시작선(1.5) + 패턴 눈금(1.5..4.5)
	for offset in [0.0, 0.75]:
		var tick_x := 35.0 + float(offset) * span
		var tick := ColorRect.new()
		tick.position = Vector2(tick_x - 1.0, 14.0)
		tick.size = Vector2(2.0, 24.0)
		tick.color = Color(0.95, 0.56, 0.72, 0.34)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		timeline_panel.add_child(tick)
	for i in BEATS_PER_PATTERN:
		var tick_x := 35.0 + (LEADIN_BEATS + float(i)) * span
		var tick := ColorRect.new()
		var is_pattern_start := (i == 0)
		tick.position = Vector2(tick_x - (1.5 if is_pattern_start else 1.0), 6.0 if is_pattern_start else 12.0)
		tick.size = Vector2(3.0 if is_pattern_start else 2.0, 40.0 if is_pattern_start else 28.0)
		tick.color = Color(1.0, 0.92, 0.72, 0.52) if is_pattern_start else Color(0.85, 0.80, 0.95, 0.26 if i % 2 == 0 else 0.14)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		timeline_panel.add_child(tick)

	timeline_cursor = ColorRect.new()
	timeline_cursor.position = Vector2(30.0, 6.0)
	timeline_cursor.size = Vector2(4.0, 40.0)
	timeline_cursor.color = Color(1.0, 0.92, 0.72, 0.92)
	timeline_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timeline_panel.add_child(timeline_cursor)

	# 타임라인 아래 다음 누를 키 배지 (← 왼발 / 오른발 → / Space 꾹!)
	next_key_badge = Panel.new()
	next_key_badge.position = Vector2(840.0, 156.0)
	next_key_badge.size = Vector2(240.0, 48.0)
	next_key_badge.pivot_offset = Vector2(120.0, 24.0)
	next_key_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.14, 0.12, 0.22, 0.90)
	badge_style.border_color = Color(0.50, 0.92, 0.98, 0.85)
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(14)
	next_key_badge.add_theme_stylebox_override("panel", badge_style)
	next_key_badge.visible = false
	ui.add_child(next_key_badge)

	next_key_label = Label.new()
	next_key_label.position = Vector2.ZERO
	next_key_label.size = Vector2(240.0, 48.0)
	next_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_key_label.add_theme_font_size_override("font_size", 24)
	next_key_label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.99, 1.0))
	next_key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_key_badge.add_child(next_key_label)


func _clear_timeline_dots() -> void:
	for dot in timeline_dots:
		if is_instance_valid(dot):
			dot.queue_free()
	timeline_dots.clear()


func _rebuild_timeline_dots(round_idx: int) -> void:
	_clear_timeline_dots()
	if round_idx < 0 or round_idx >= active_patterns.size():
		return
	var round_resp_notes: Array[Dictionary] = []
	for n in response_notes:
		if int(n["round"]) == round_idx:
			round_resp_notes.append(n)
	for step_order in round_resp_notes.size():
		var n: Dictionary = round_resp_notes[step_order]
		var beat_offset := float(n["beat"])
		var hold_beats := float(n["hold_beats"])
		var special_kind := String(n.get("special", ""))
		var is_left_step := bool(n.get("is_left", true))
		var span := 490.0 / (LEADIN_BEATS + float(BEATS_PER_PATTERN))
		var dot_x := 35.0 + (LEADIN_BEATS + beat_offset) * span
		var dot := Panel.new()
		if hold_beats > 0.0:
			var bar_w := maxf(34.0, hold_beats * span)
			dot.position = Vector2(dot_x - 10.0, 14.0)
			dot.size = Vector2(bar_w + 10.0, 24.0)
			dot.pivot_offset = dot.size / 2.0
		else:
			dot.position = Vector2(dot_x - 13.0, 13.0)
			dot.size = Vector2(26.0, 26.0)
			dot.pivot_offset = Vector2(13.0, 13.0)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ds := StyleBoxFlat.new()
		ds.bg_color = Color(0.95, 0.48, 0.66, 0.9) if hold_beats > 0.0 else Color(0.45, 0.88, 0.95, 0.9)
		ds.set_corner_radius_all(12 if hold_beats > 0.0 else 13)
		dot.add_theme_stylebox_override("panel", ds)

		var lbl := Label.new()
		if hold_beats > 0.0:
			lbl.text = "💧물 꾹!" if special_kind == "drink" else "꾹!"
		else:
			lbl.text = "←" if is_left_step else "→"
		lbl.size = dot.size
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 15 if hold_beats <= 0.0 else 14)
		lbl.add_theme_color_override("font_color", Color(0.08, 0.07, 0.14, 1.0))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(lbl)

		timeline_panel.add_child(dot)
		timeline_dots.append(dot)
	# 커서를 맨 위로 올림
	timeline_panel.move_child(timeline_cursor, timeline_panel.get_child_count() - 1)


func _update_beat_timeline() -> void:
	if not is_instance_valid(timeline_panel):
		return
	if current_round < 0 or current_round >= round_timings.size():
		timeline_panel.visible = false
		return
	timeline_panel.visible = true
	if timeline_round != current_round:
		timeline_round = current_round
		_rebuild_timeline_dots(current_round)
	var timing: Dictionary = round_timings[current_round]
	var beat_dur := float(timing["beat"])
	var total_slots := LEADIN_BEATS + float(BEATS_PER_PATTERN)
	var span := 490.0 / total_slots
	var beat_pos := 0.0
	if current_phase == "call":
		beat_pos = clampf((song_time - float(timing["start"])) / beat_dur, 0.0, float(BEATS_PER_PATTERN))
		timeline_cursor.position.x = 35.0 + (LEADIN_BEATS + beat_pos) * span - 2.0
		timeline_cursor.color = Color(0.50, 0.92, 0.98, 0.95)
	else:
		# 준비 1.5틱(0..1.5)을 지나 실제 따라 걷기(1.5..5.5)까지 커서가 끊김 없이 연속 이동!
		var leadin_pos := clampf((song_time - float(timing["leadin"])) / beat_dur, 0.0, total_slots)
		beat_pos = clampf(leadin_pos - LEADIN_BEATS, 0.0, float(BEATS_PER_PATTERN))
		timeline_cursor.position.x = 35.0 + leadin_pos * span - 2.0
		timeline_cursor.color = Color(1.0, 0.48, 0.68, 0.98) if current_phase == "leadin" else Color(1.0, 0.86, 0.42, 0.95)

	var round_notes: Array[Dictionary] = []
	for n in response_notes:
		if int(n["round"]) == current_round:
			round_notes.append(n)
	for i in mini(timeline_dots.size(), round_notes.size()):
		var dot := timeline_dots[i]
		var ds := dot.get_theme_stylebox("panel") as StyleBoxFlat
		var is_hold := bool(round_notes[i].get("is_hold", false))
		if current_phase == "call":
			var call_played := float(round_notes[i]["beat"]) <= beat_pos
			if is_hold:
				ds.bg_color = Color(0.95, 0.48, 0.66, 1.0) if call_played else Color(0.50, 0.32, 0.44, 0.45)
			else:
				ds.bg_color = Color(0.50, 0.92, 0.98, 1.0) if call_played else Color(0.35, 0.42, 0.56, 0.45)
		else:
			if bool(round_notes[i]["judged"]):
				var mark: FootprintPair = round_notes[i]["mark"]
				if is_instance_valid(mark) and mark.status == "miss":
					ds.bg_color = Color(0.96, 0.38, 0.52, 0.85)
				else:
					ds.bg_color = Color(1.0, 0.84, 0.42, 0.35)
			else:
				ds.bg_color = Color(1.0, 0.88, 0.42, 0.98)


	var next_note: Dictionary = {}
	for n in round_notes:
		if not bool(n["judged"]):
			next_note = n
			break
	if is_instance_valid(next_key_badge):
		if (current_phase != "response" and current_phase != "leadin") or next_note.is_empty():
			next_key_badge.visible = false
		else:
			next_key_badge.visible = true
			var bs := next_key_badge.get_theme_stylebox("panel") as StyleBoxFlat
			var txt := ""
			var sp := String(next_note.get("special", ""))
			if bool(next_note.get("is_hold", false)):
				txt = "💧 물 받기 (꾹!)" if sp == "drink" else "Space 꾹! 멈춤"
				bs.border_color = Color(0.96, 0.48, 0.66, 0.95)
				next_key_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.84, 1.0))
			elif sp == "drink_btn":
				var arrow := "←" if bool(next_note.get("is_left", false)) else "→"
				txt = "%s  버튼 콕!" % arrow
				bs.border_color = Color(1.0, 0.86, 0.42, 0.95)
				next_key_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.56, 1.0))
			elif sp == "drink_sip":
				var arrow := "←" if bool(next_note.get("is_left", true)) else "→"
				txt = "%s  꿀꺽!" % arrow
				bs.border_color = Color(0.50, 0.92, 0.98, 0.95)
				next_key_label.add_theme_color_override("font_color", Color(0.62, 0.95, 1.0, 1.0))
			elif bool(next_note.get("is_left", true)):
				txt = "←  왼발"
				bs.border_color = Color(0.50, 0.92, 0.98, 0.95)
				next_key_label.add_theme_color_override("font_color", Color(0.62, 0.95, 1.0, 1.0))
			else:
				txt = "오른발  →"
				bs.border_color = Color(1.0, 0.86, 0.42, 0.95)
				next_key_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.56, 1.0))
			next_key_label.text = txt
			if txt != last_next_key_text:
				last_next_key_text = txt
				next_key_badge.scale = Vector2(1.12, 1.12)
				var bt := create_tween()
				bt.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				bt.tween_property(next_key_badge, "scale", Vector2.ONE, 0.14)


func _highlight_next_footprint() -> void:
	if current_phase != "response":
		return
	var highlighted := false
	for note in response_notes:
		if note["judged"]:
			continue
		var mark: FootprintPair = note["mark"]
		if not is_instance_valid(mark):
			continue
		if not highlighted and int(note["round"]) == current_round:
			highlighted = true
			if mark.status != "active":
				mark.set_status("active")
				var p := create_tween()
				p.tween_property(mark, "scale", Vector2(1.16, 1.16), 0.08)
				p.tween_property(mark, "scale", Vector2(1.05, 1.05), 0.12)
		elif mark.status == "active":
			mark.set_status("preview")
			mark.scale = Vector2.ONE


func _update_response_notes() -> void:
	for note in response_notes:
		if note["judged"] or bool(note.get("holding", false)):
			continue
		if song_time > float(note["time"]) + RESPONSE_WINDOW:
			note["judged"] = true
			miss_count += 1
			combo = 0
			_add_noise(18.0)
			judgment.add_theme_color_override("font_color", Color(0.96, 0.42, 0.56, 1.0))
			_flash("MISS")
			_shake()
			sfx_miss.play()
			_play_surprise()
			if is_instance_valid(note["mark"]):
				note["mark"].set_status("miss")
				note["mark"].scale = Vector2.ONE
			_update_combo()
			_trigger_miss_cutscene()
			break


func _update_beat() -> void:
	# 따라 걷기 직전 1.5틱(leadin)은 0.0 / 0.75 지점 두 번에 걸쳐 짧고 경쾌하게 고조된다!
	if current_phase == "leadin" and current_round >= 0 and current_round < round_timings.size():
		var timing: Dictionary = round_timings[current_round]
		var lead_elapsed := song_time - float(timing["leadin"])
		var half_step := int(floor(lead_elapsed / (BEAT * 0.75)))
		var lead_key := current_round * 10 + clampi(half_step, 0, 1)
		if lead_key != last_beat:
			last_beat = lead_key
			if not get_tree().paused:
				music.pitch_scale = 1.28 if half_step == 0 else 1.48
				music.play(0.0)
				call_cue.pitch_scale = 1.15 if half_step == 0 else 1.35
				call_cue.play()
			phase_label.text = "준비!" if half_step == 0 else "시작!"
			phase_label.pivot_offset = phase_label.size / 2.0
			phase_label.scale = Vector2(1.16, 1.16) if half_step == 0 else Vector2(1.28, 1.28)
			var pt := create_tween()
			pt.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pt.tween_property(phase_label, "scale", Vector2.ONE, 0.16)
			beat_dot.visible = true
			beat_dot.pivot_offset = beat_dot.size / 2.0
			beat_dot.scale = Vector2(1.55, 1.55)
			var dt := create_tween()
			dt.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			dt.tween_property(beat_dot, "scale", Vector2.ONE, 0.16)
		return

	var beat_index := int(floor(song_time / BEAT))
	if beat_index == last_beat:
		return
	last_beat = beat_index
	if not get_tree().paused:
		music.pitch_scale = 1.18 if (beat_index % 4 == 0) else 0.96
		music.play(0.0)
	beat_dot.visible = true
	beat_dot.pivot_offset = beat_dot.size / 2.0
	beat_dot.scale = Vector2(1.55, 1.55)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(beat_dot, "scale", Vector2.ONE, 0.18)
	# 서 있을 때 비트에 맞춰 가볍게 리듬 바운스
	if player.animation == "idle":
		player.scale = Vector2(player_base_scale * 1.03, player_base_scale * 0.96)
		var b := create_tween()
		b.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		b.tween_property(player, "scale", Vector2.ONE * player_base_scale, 0.16)


func _press_step(key_kind: String = "any") -> void:
	if finished:
		return
	if current_phase != "response":
		if current_phase == "call":
			_add_noise(5.0)
			judgment.add_theme_color_override("font_color", Color(0.96, 0.42, 0.56, 1.0))
			_flash("쉿")
			sfx_miss.play()
			_play_surprise()
		else:
			judgment.add_theme_color_override("font_color", Color(0.98, 0.68, 0.78, 1.0))
			_flash("준비")
			_play_surprise()
		return

	var target: Dictionary = {}
	var best_err := 9.0
	for note in response_notes:
		if note["judged"] or bool(note.get("holding", false)):
			continue
		var err: float = song_time - float(note["time"])
		if absf(err) <= RESPONSE_WINDOW and absf(err) < absf(best_err):
			best_err = err
			target = note
	if target.is_empty():
		combo = 0
		_add_noise(12.0)
		judgment.add_theme_color_override("font_color", Color(0.96, 0.42, 0.56, 1.0))
		_flash("MISS")
		sfx_miss.play()
		_play_surprise()
		_update_combo()
		_trigger_miss_cutscene()
		return
	if bool(target.get("is_hold", false)):
		if key_kind != "hold" and key_kind != "any":
			judgment.add_theme_color_override("font_color", Color(0.98, 0.68, 0.78, 1.0))
			_flash("Space 꾹!")
			return
		_begin_hold(target, best_err)
	else:
		var expect_left := bool(target.get("is_left", step_foot_index % 2 == 0))
		if (key_kind == "left" and not expect_left) or (key_kind == "right" and expect_left):
			combo = 0
			_add_noise(12.0)
			judgment.add_theme_color_override("font_color", Color(0.96, 0.42, 0.56, 1.0))
			_flash("반대 발!")
			sfx_miss.play()
			_play_surprise()
			_update_combo()
			_trigger_miss_cutscene()
			return
		elif key_kind == "hold":
			judgment.add_theme_color_override("font_color", Color(0.98, 0.68, 0.78, 1.0))
			_flash("← / →!")
			return
		_judge_response(target, best_err)


func _release_step() -> void:
	space_held = false
	if active_hold_note.is_empty() or bool(active_hold_note.get("judged", true)):
		return
	var end_time := float(active_hold_note["end_time"])
	var remaining := end_time - song_time
	if remaining <= RESPONSE_WINDOW:
		_finish_hold(true)
	else:
		_finish_hold(false)


func _begin_hold(note: Dictionary, timing_error: float) -> void:
	if bool(note["judged"]) or bool(note["holding"]):
		return
	note["holding"] = true
	note["start_error"] = timing_error
	active_hold_note = note
	stop_cue.show()
	hold_bar.value = 0.0
	var is_drink := String(note.get("special", "")) == "drink"
	stop_label.text = "💧 물 마시기! 꾹!" if is_drink else "꾹!"
	var mark: FootprintPair = note["mark"]
	if is_instance_valid(mark):
		mark.set_status("active")
	if is_drink and player.sprite_frames.has_animation("drink"):
		player.offset.x = -210.0
		player.play("drink")
		player.pause()
		player.frame = 0
	else:
		# 멈춰 숨 죽일 때는 한 발을 들고 균형을 잡은 채 낮게 멈춘다
		player.play("poise_left" if step_foot_index % 2 == 0 else "poise_right")
		var crouch := create_tween()
		crouch.set_parallel(true)
		crouch.tween_property(player, "scale", Vector2(player_base_scale * 1.04, player_base_scale * 0.94), 0.1)
		crouch.tween_property(player, "position:y", PLAYER_Y + 8.0, 0.1)


func _update_active_hold() -> void:
	if active_hold_note.is_empty():
		return
	var start_t := float(active_hold_note["time"])
	var end_t := float(active_hold_note["end_time"])
	var progress := clampf((song_time - start_t) / maxf(end_t - start_t, 0.01), 0.0, 1.0)
	hold_bar.value = progress * 100.0
	if String(active_hold_note.get("special", "")) == "drink" and player.sprite_frames.has_animation("drink"):
		# 물 받기 홀드 중에는 1~4번 프레임(물이 컵에 차오르는 장면)을 진행도에 맞춰 표시
		player.frame = clampi(1 + int(floor(progress * 4.0)), 1, 4)
	if song_time >= end_t:
		_finish_hold(true)


func _finish_hold(success: bool) -> void:
	var note := active_hold_note
	active_hold_note = {}
	stop_cue.hide()
	stop_label.text = "꾹!"
	hold_bar.value = 0.0
	if character_variant != "kid":
		player.offset = Vector2(-192.0, -315.0)
	var recover := create_tween()
	recover.set_parallel(true)
	recover.tween_property(player, "scale", Vector2.ONE * player_base_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	recover.tween_property(player, "position:y", PLAYER_Y, 0.14)
	if note.is_empty() or bool(note["judged"]):
		return
	note["holding"] = false
	if success:
		_judge_response(note, float(note["start_error"]))
	else:
		note["judged"] = true
		miss_count += 1
		combo = 0
		_add_noise(18.0)
		sfx_miss.play()
		_play_surprise()
		judgment.add_theme_color_override("font_color", Color(0.96, 0.42, 0.56, 1.0))
		_flash("놓쳤다!")
		var footprint: FootprintPair = note["mark"]
		if is_instance_valid(footprint):
			footprint.set_status("miss")
			footprint.scale = Vector2.ONE
		_shake()
		_update_combo()
		_trigger_miss_cutscene()


func _judge_response(note: Dictionary, timing_error: float) -> void:
	if note["judged"]:
		return
	note["judged"] = true
	response_hit_count += 1
	var footprint: FootprintPair = note["mark"]
	var abs_error := absf(timing_error)
	var sp := String(note.get("special", ""))
	if abs_error <= PERFECT_WINDOW:
		perfect_count += 1
		combo += 1
		_add_noise(-5.5 if sp == "drink_sip" else -1.5)
		sfx_perfect.pitch_scale = 0.98 + minf(float(combo), 8.0) * 0.015
		sfx_perfect.play()
		judgment.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42, 1.0))
		_flash("꿀꺽! ♪" if sp == "drink_sip" else ("버튼 콕!" if sp == "drink_btn" else "PERFECT"))
		if is_instance_valid(footprint):
			footprint.set_status("hit")
			footprint.scale = Vector2.ONE
		_do_step(float(note["target_x"]), sp)
	elif abs_error <= GOOD_WINDOW:
		good_count += 1
		combo += 1
		if sp == "drink_sip":
			_add_noise(-3.0)
		sfx_good.play()
		judgment.add_theme_color_override("font_color", Color(0.56, 0.90, 0.94, 1.0))
		_flash("꿀꺽!" if sp == "drink_sip" else ("버튼 콕!" if sp == "drink_btn" else "GOOD"))
		if is_instance_valid(footprint):
			footprint.set_status("hit")
			footprint.scale = Vector2.ONE
		_do_step(float(note["target_x"]), sp)
	else:
		miss_count += 1
		combo = 0
		_add_noise(18.0)
		sfx_miss.play()
		_play_surprise()
		judgment.add_theme_color_override("font_color", Color(0.96, 0.42, 0.56, 1.0))
		_flash("MISS")
		if is_instance_valid(footprint):
			footprint.set_status("miss")
			footprint.scale = Vector2.ONE
		_shake()
		_trigger_miss_cutscene()
	max_combo = maxi(max_combo, combo)
	_update_combo()


func _do_step(target_x: float, special_kind: String = "") -> void:
	_stop_poise_wobble()
	var step_time := clampf(_current_beat_duration() * 0.42, 0.14, 0.22)
	var is_left := (step_foot_index % 2 == 0)
	step_foot_index += 1
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_camera, camera_x, target_x, step_time)
	camera_x = target_x
	if (special_kind == "drink_btn" or special_kind == "drink_sip") and player.sprite_frames.has_animation("drink"):
		player.offset.x = -210.0
		player.play("drink")
		if special_kind == "drink_btn":
			player.pause()
			player.frame = 0
		else:
			player.frame = 5
		return
	if character_variant != "kid":
		player.offset = Vector2(-192.0, -315.0)
	# 한 걸음마다 왼발/오른발 애니메이션과 상하·앞뒤 탄성을 번갈아 적용해 역동감 부여
	player.position.x = 1024.0 if is_left else 1012.0
	player.position.y = PLAYER_Y - (18.0 if is_left else 8.0)
	player.scale = Vector2(player_base_scale * (1.08 if is_left else 1.12), player_base_scale * (0.92 if is_left else 0.86))
	var lunge := create_tween()
	lunge.set_parallel(true)
	lunge.tween_property(player, "position:x", 960.28, step_time * 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lunge.tween_property(player, "position:y", PLAYER_Y, step_time * 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var squash := create_tween()
	squash.tween_property(player, "scale", Vector2.ONE * player_base_scale, step_time * 0.92).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	player.play("sneak_left" if is_left else "sneak_right")


func _update_combo() -> void:
	combo_label.text = "" if combo < 2 else "COMBO %d" % combo


func _setup_life_dots() -> void:
	life_dots.clear()
	if not is_instance_valid(noise_card):
		return
	for i in MAX_LIVES:
		var dot := Panel.new()
		dot.position = Vector2(104.0 + float(i) * 24.0, 82.0)
		dot.size = Vector2(14.0, 14.0)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ds := StyleBoxFlat.new()
		ds.bg_color = Color(0.95, 0.48, 0.66, 1.0)
		ds.set_corner_radius_all(7)
		dot.add_theme_stylebox_override("panel", ds)
		noise_card.add_child(dot)
		life_dots.append(dot)


func _add_noise(amount: float) -> void:
	if amount > 0.0:
		lives = maxi(lives - 1, 0)
		noise = float(MAX_LIVES - lives) / float(MAX_LIVES) * 100.0
	_update_noise_ui()
	if amount > 0.0 and is_instance_valid(noise_card):
		var shake_t := create_tween()
		for i in 4:
			shake_t.tween_property(noise_card, "position:x", 1480.0 + randf_range(-7.0, 7.0), 0.03)
		shake_t.tween_property(noise_card, "position:x", 1480.0, 0.04)
	if lives <= 0 and not finished:
		noise = 100.0
		if not cutscene_active:
			_trigger_miss_cutscene()


func _update_noise_ui() -> void:
	for i in life_dots.size():
		var ds := life_dots[i].get_theme_stylebox("panel") as StyleBoxFlat
		ds.bg_color = Color(0.95, 0.48, 0.66, 1.0) if i < lives else Color(0.32, 0.28, 0.40, 0.55)
	var stage := 0
	if lives <= 0:
		stage = 3
	elif lives <= 2:
		stage = 2
	elif lives <= 4:
		stage = 1
	if stage < NEIGHBOR_TEXTURES.size():
		neighbor_portrait.texture = NEIGHBOR_TEXTURES[stage]
	match stage:
		0:
			neighbor_title.text = "아랫집 · 조용함"
			neighbor_title.add_theme_color_override("font_color", Color(0.95, 0.94, 0.99, 1.0))
			neighbor_speech.text = "쿨쿨 자는 중..."
		1:
			neighbor_title.text = "아랫집 · 거슬림"
			neighbor_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48, 1.0))
			neighbor_speech.text = "위에서 무슨 소리지...?"
		2:
			neighbor_title.text = "아랫집 · 화남"
			neighbor_title.add_theme_color_override("font_color", Color(0.98, 0.56, 0.40, 1.0))
			neighbor_speech.text = "시끄러워 죽겠네!"
		3:
			neighbor_title.text = "아랫집 · 폭발 직전!"
			neighbor_title.add_theme_color_override("font_color", Color(1.0, 0.36, 0.46, 1.0))
			neighbor_speech.text = "당장 올라간다!!"
	if is_instance_valid(noise_card):
		var card_style := noise_card.get_theme_stylebox("panel")
		if card_style is StyleBoxFlat:
			var box := card_style.duplicate() as StyleBoxFlat
			match stage:
				0:
					box.bg_color = Color(0.13, 0.11, 0.20, 0.84)
					box.border_color = Color(0.88, 0.82, 0.96, 0.22)
				1:
					box.bg_color = Color(0.18, 0.14, 0.22, 0.88)
					box.border_color = Color(1.0, 0.82, 0.42, 0.45)
				2:
					box.bg_color = Color(0.24, 0.12, 0.18, 0.92)
					box.border_color = Color(0.98, 0.52, 0.38, 0.70)
				3:
					box.bg_color = Color(0.32, 0.09, 0.14, 0.95)
					box.border_color = Color(1.0, 0.34, 0.44, 0.95)
			noise_card.add_theme_stylebox_override("panel", box)
		if stage > neighbor_stage and neighbor_stage >= 0:
			noise_card.scale = Vector2(1.08, 1.08)
			var pop := create_tween()
			pop.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pop.tween_property(noise_card, "scale", Vector2.ONE, 0.2)
	neighbor_stage = stage


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
	if is_instance_valid(timeline_panel):
		timeline_panel.visible = false
	if is_instance_valid(next_key_badge):
		next_key_badge.visible = false
	if is_instance_valid(next_key_badge):
		next_key_badge.visible = false
	last_next_key_text = ""
	result_overlay.show()
	player.play("relieved" if success else "caught")
	if success:
		var rank := "B"
		if miss_count == 0 and perfect_count == response_notes.size():
			rank = "S"
		elif miss_count == 0:
			rank = "A"
		result_title.text = "성공"
		rank_badge.texture = RANK_S if rank == "S" else (RANK_A if rank == "A" else RANK_B)
		result_desc.text = "PERFECT %d · GOOD %d · MISS %d\n콤보 %d · 아랫집 %s" % [perfect_count, good_count, miss_count, max_combo, "평온" if neighbor_stage == 0 else "안심"]
	else:
		result_title.text = "들켰다"
		rank_badge.texture = RANK_FAIL
		result_desc.text = "아랫집 폭발!\nPERFECT %d · GOOD %d · MISS %d" % [perfect_count, good_count, miss_count]


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
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			if event.pressed:
				_press_step("left")
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			if event.pressed:
				_press_step("right")
		elif event.keycode == KEY_SPACE:
			if event.pressed:
				space_held = true
				_press_step("hold")
			else:
				_release_step()


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


func _capture_rooms_flow() -> void:
	await get_tree().create_timer(0.4).timeout
	_start()
	await get_tree().create_timer(0.3).timeout
	for position in [2000, 2600, 3200, 3800, 4400, 5000, 5400]:
		_set_camera(float(position))
		await get_tree().create_timer(0.25).timeout
		_save_shot("room_%d.png" % position)
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


func _capture_cutscene_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	_start()
	# 1라운드 따라 걷기 시작 직후 일부러 미스 발생시켜 아래층 스크롤 연출 확인
	await get_tree().create_timer(3.6).timeout
	_press_step("right")
	await get_tree().create_timer(0.7).timeout
	_save_shot("cutscene_downstairs.png")
	await get_tree().create_timer(1.2).timeout
	_save_shot("cutscene_returned.png")
	get_tree().quit()


func _capture_audit_flow() -> void:
	await get_tree().create_timer(0.3).timeout
	_start()
	# R1 response, R3 call/response, R5 response, R6 response, final result
	var checkpoints := [
		{"t": 8.0, "name": "audit_r1.png"},
		{"t": 21.5, "name": "audit_r3_call.png"},
		{"t": 25.0, "name": "audit_r3_resp.png"},
		{"t": 37.5, "name": "audit_r5_resp.png"},
		{"t": 44.5, "name": "audit_r6_resp.png"},
		{"t": 47.5, "name": "audit_result.png"},
	]
	var prev := 0.0
	for cp in checkpoints:
		await get_tree().create_timer(float(cp["t"]) - prev).timeout
		prev = float(cp["t"])
		_save_shot(String(cp["name"]))
		print("AUDIT ", cp["name"], " round=", current_round, " phase=", current_phase, " cam=", camera_x, " P=", perfect_count, " G=", good_count, " M=", miss_count)
	get_tree().quit()


func _save_shot(file_name: String) -> void:
	var dir := "res://Design/shots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var image := get_viewport().get_texture().get_image()
	image.save_png(dir + "/" + file_name)
