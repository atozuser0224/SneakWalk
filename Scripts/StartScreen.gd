extends Control

enum Mode { MENU, CHAPTER }

const SCENE_MAIN := "res://Scenes/Main.tscn"
const SCENE_ECHO := "res://Scenes/EchoStep.tscn"
const SLIDE := 1920.0
const PINK := Color(0.878, 0.416, 0.561, 1)

const CHAPTERS := [
	{"label": "챕터 1", "title": "내가 물 마시러 가기", "desc": "내 방 → 거실 → 부엌 → 물 마시기 → 부엌 → 거실 → 내 방\n부엌 이후 속도 증가 · 느리면 어머니에게 들킴", "locked": false},
	{"label": "챕터 2", "title": "아빠가 라면 끓여 먹기", "desc": "안방 → 복도 → 거실 → 부엌 → 라면 조리 → 거실 → 복도 → 안방\n요리 과정 자체를 리듬 게임으로 구성", "locked": false},
]

@onready var panorama: Node2D = %Panorama
@onready var rt_overlay: ColorRect = %RtOverlay
@onready var menu_ui: Control = %MenuUI
@onready var chapter_ui: Control = %ChapterUI
@onready var logo: Control = %Logo
@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton
@onready var settings_overlay: Control = %SettingsOverlay
@onready var dim: ColorRect = %Dim
@onready var bgm_slider: HSlider = %BgmSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var bgm_value: Label = %BgmValue
@onready var sfx_value: Label = %SfxValue
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var shake_check: CheckButton = %ShakeCheck
@onready var close_button: Button = %CloseButton
@onready var back_button: Button = %BackButton
@onready var left_arrow: TextureButton = %LeftArrow
@onready var right_arrow: TextureButton = %RightArrow
@onready var card: PanelContainer = %ChapterCard
@onready var chapter_label: Label = %ChapterLabel
@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var chapter_start_button: Button = %ChapterStartButton
@onready var dots: HBoxContainer = %Dots
@onready var fade: ColorRect = %Fade

var mode := Mode.MENU
var index := 0
var selected_difficulty := 1
var difficulty_buttons: Array[Button] = []
var busy := false
var _card_base_x := 0.0
var _dot_panels: Array[Panel] = []


func _ready() -> void:
	_card_base_x = card.position.x

	start_button.pressed.connect(_enter_chapters)
	settings_button.pressed.connect(_open_settings)
	exit_button.pressed.connect(_on_exit_pressed)
	back_button.pressed.connect(_exit_chapters)
	left_arrow.pressed.connect(func() -> void: _change_index(-1))
	right_arrow.pressed.connect(func() -> void: _change_index(1))
	chapter_start_button.pressed.connect(_start_chapter)
	close_button.pressed.connect(_close_settings)
	dim.gui_input.connect(_on_dim_input)

	bgm_slider.value_changed.connect(_on_bgm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	shake_check.toggled.connect(_on_shake_toggled)

	for button in [start_button, settings_button, exit_button]:
		_setup_hover(button)
	left_arrow.mouse_entered.connect(func() -> void: _tween_arrow(left_arrow, 1.06))
	left_arrow.mouse_exited.connect(func() -> void: _tween_arrow(left_arrow, 1.0))
	right_arrow.mouse_entered.connect(func() -> void: _tween_arrow(right_arrow, 1.06))
	right_arrow.mouse_exited.connect(func() -> void: _tween_arrow(right_arrow, 1.0))

	_start_logo_float()
	_build_dots()
	_build_difficulty_selector()
	_sync_settings_ui()

	chapter_ui.hide()
	settings_overlay.hide()
	_setup_rt_overlay()
	rt_overlay.hide()

	var flags := _flags()
	for flag in flags:
		if flag.begins_with("chapter") and flag.substr(7).is_valid_int():
			_setup_chapter_mode(int(flag.substr(7)) - 1)

	if "capture" in flags:
		_capture_and_quit()
	else:
		fade.color = Color(0, 0, 0, 1)
		var tween := create_tween()
		tween.tween_property(fade, "color", Color(0, 0, 0, 0), 0.3)


func _setup_rt_overlay() -> void:
	var material := rt_overlay.material as ShaderMaterial
	if material == null:
		return
	var rig := panorama.get_node("LightRig")
	var sun_world: Vector2 = rig.get_sun_screen_pos() - panorama.position
	material.set_shader_parameter("light_pos", PackedVector2Array([sun_world]))
	material.set_shader_parameter("light_energy", PackedFloat32Array([rig.get_sun_energy()]))
	material.set_shader_parameter("viewport_size", Vector2(1920, 1080))
	material.set_shader_parameter("pano_size", Vector2(7680, 1080))


func _process(_delta: float) -> void:
	if rt_overlay == null or rt_overlay.material == null:
		return
	var material := rt_overlay.material as ShaderMaterial
	var rig := panorama.get_node("LightRig")
	var sun_world: Vector2 = rig.get_sun_screen_pos() - panorama.position
	material.set_shader_parameter("light_pos", PackedVector2Array([sun_world]))
	material.set_shader_parameter("pano_offset", panorama.position)


func _flags() -> Array[String]:
	var result: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		result.append(arg.lstrip("-"))
	return result


func _sync_settings_ui() -> void:
	bgm_slider.value = Settings.bgm_volume
	sfx_slider.value = Settings.sfx_volume
	bgm_value.text = _percent(Settings.bgm_volume)
	sfx_value.text = _percent(Settings.sfx_volume)
	fullscreen_check.button_pressed = Settings.fullscreen
	shake_check.button_pressed = Settings.screen_shake


func _percent(value: int) -> String:
	return str(value) + "%"


func _setup_hover(button: Button) -> void:
	button.pivot_offset = button.size / 2.0
	button.mouse_entered.connect(func() -> void: _tween_scale(button, 1.02))
	button.mouse_exited.connect(func() -> void: _tween_scale(button, 1.0))
	button.button_down.connect(func() -> void: _tween_scale(button, 0.985))
	button.button_up.connect(func() -> void: _tween_scale(button, 1.02))


func _tween_scale(button: Control, target: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * target, 0.09)


func _tween_arrow(button: Control, target: float) -> void:
	button.pivot_offset = button.size / 2.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * target, 0.09)


func _start_logo_float() -> void:
	var base_y := logo.position.y
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo, "position:y", base_y - 6.0, 3.0)
	tween.tween_property(logo, "position:y", base_y, 2.0)


func _build_dots() -> void:
	for i in CHAPTERS.size():
		var dot := Panel.new()
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.custom_minimum_size = Vector2(10, 10)
		dots.add_child(dot)
		_dot_panels.append(dot)


func _update_dots() -> void:
	for i in _dot_panels.size():
		var dot := _dot_panels[i]
		var style := StyleBoxFlat.new()
		style.bg_color = PINK if i == index else Color(0.8, 0.77, 0.82, 0.65)
		style.set_corner_radius_all(5)
		dot.add_theme_stylebox_override("panel", style)
		dot.custom_minimum_size = Vector2(26 if i == index else 10, 10)


func _enter_chapters() -> void:
	if busy or mode == Mode.CHAPTER:
		return
	busy = true
	index = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(panorama, "position:x", -SLIDE, 0.9)
	tween.tween_property(menu_ui, "modulate:a", 0.0, 0.3)
	await tween.finished

	menu_ui.hide()
	mode = Mode.CHAPTER
	_apply_chapter(false)
	chapter_ui.show()
	chapter_ui.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(chapter_ui, "modulate:a", 1.0, 0.2)
	await fade_in.finished
	busy = false


func _exit_chapters() -> void:
	if busy or mode != Mode.CHAPTER:
		return
	busy = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(panorama, "position:x", 0.0, 0.9)
	tween.tween_property(chapter_ui, "modulate:a", 0.0, 0.25)
	await tween.finished

	chapter_ui.hide()
	mode = Mode.MENU
	menu_ui.show()
	menu_ui.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(menu_ui, "modulate:a", 1.0, 0.25)
	await fade_in.finished
	busy = false


func _setup_chapter_mode(chapter_index: int) -> void:
	mode = Mode.CHAPTER
	index = clampi(chapter_index, 0, CHAPTERS.size() - 1)
	menu_ui.hide()
	chapter_ui.show()
	chapter_ui.modulate.a = 1.0
	_apply_chapter(false)


func _apply_chapter(animate: bool) -> void:
	index = clampi(index, 0, CHAPTERS.size() - 1)
	var data: Dictionary = CHAPTERS[index]
	chapter_label.text = data.label
	title_label.text = data.title
	desc_label.text = data.desc
	var locked: bool = data.locked
	chapter_start_button.disabled = locked
	chapter_start_button.text = "준비 중" if locked else "시작"

	left_arrow.disabled = false
	right_arrow.disabled = index == CHAPTERS.size() - 1
	left_arrow.modulate = Color(1, 1, 1, 1)
	right_arrow.modulate = Color(1, 1, 1, 0.25) if right_arrow.disabled else Color(1, 1, 1, 1)

	_update_dots()

	var target := -(index + 1) * SLIDE
	if animate:
		var move := create_tween()
		move.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
		move.tween_property(panorama, "position:x", target, 0.9)

		card.position.x = _card_base_x + 24.0
		card.modulate.a = 0.2
		var card_tween := create_tween()
		card_tween.set_parallel(true)
		card_tween.tween_property(card, "position:x", _card_base_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		card_tween.tween_property(card, "modulate:a", 1.0, 0.25)
	else:
		panorama.position.x = target
		card.position.x = _card_base_x



func _change_index(delta: int) -> void:
	if busy or mode != Mode.CHAPTER:
		return
	if delta < 0 and index == 0:
		_exit_chapters()
		return
	var next := clampi(index + delta, 0, CHAPTERS.size() - 1)
	if next == index:
		return
	index = next
	_apply_chapter(true)


func _build_difficulty_selector() -> void:
	var info := desc_label.get_parent()
	if not is_instance_valid(info):
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	info.add_child(row)
	var names := ["난이도 1 · 기본", "난이도 2 · 빽빽", "난이도 3 · 초고밀도"]
	for i in 3:
		var btn := Button.new()
		btn.text = names[i]
		btn.custom_minimum_size = Vector2(150, 38)
		btn.add_theme_font_size_override("font_size", 16)
		var diff := i + 1
		btn.pressed.connect(func() -> void: _select_difficulty(diff))
		row.add_child(btn)
		difficulty_buttons.append(btn)
	selected_difficulty = clampi(Settings.current_difficulty, 1, 3)
	_update_difficulty_buttons()


func _select_difficulty(diff: int) -> void:
	selected_difficulty = clampi(diff, 1, 3)
	Settings.current_difficulty = selected_difficulty
	_update_difficulty_buttons()


func _update_difficulty_buttons() -> void:
	for i in difficulty_buttons.size():
		var btn := difficulty_buttons[i]
		var active := (i + 1) == selected_difficulty
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.878, 0.416, 0.561, 1.0) if active else Color(0.18, 0.16, 0.26, 0.85)
		sb.border_color = Color(1.0, 0.85, 0.9, 1.0) if active else Color(0.45, 0.42, 0.58, 0.7)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1) if active else Color(0.82, 0.80, 0.92, 0.9))


func _start_chapter() -> void:
	if busy or mode != Mode.CHAPTER or CHAPTERS[index].locked:
		return
	busy = true
	Settings.current_chapter = index + 1
	Settings.current_difficulty = selected_difficulty
	var target := SCENE_ECHO
	var tween := create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), 0.25)
	await tween.finished
	get_tree().change_scene_to_file(target)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _open_settings() -> void:
	settings_overlay.show()
	settings_overlay.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(settings_overlay, "modulate", Color(1, 1, 1, 1), 0.15)


func _close_settings() -> void:
	settings_overlay.hide()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_settings()


func _on_bgm_changed(value: float) -> void:
	bgm_value.text = _percent(int(value))
	Settings.set_bgm_volume(value)


func _on_sfx_changed(value: float) -> void:
	sfx_value.text = _percent(int(value))
	Settings.set_sfx_volume(value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	Settings.set_fullscreen(enabled)


func _on_shake_toggled(enabled: bool) -> void:
	Settings.set_screen_shake(enabled)


func _capture_and_quit() -> void:
	await get_tree().create_timer(1.4).timeout

	var dir := "res://Design/shots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var image := get_viewport().get_texture().get_image()
	var file_name := "start_menu.png" if mode == Mode.MENU else "chapter_select_%d.png" % (index + 1)
	image.save_png(dir + "/" + file_name)
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if settings_overlay.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_settings()
		return

	if mode != Mode.CHAPTER or busy:
		return

	if event.is_action_pressed("ui_left"):
		_change_index(-1)
	elif event.is_action_pressed("ui_right"):
		_change_index(1)
	elif event.is_action_pressed("ui_accept"):
		_start_chapter()
	elif event.is_action_pressed("ui_cancel"):
		_exit_chapters()
