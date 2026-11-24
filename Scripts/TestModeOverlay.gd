extends Control
## 테스트 모드 일시정지 오버레이.
##
## 게임 화면 위에 "일시정지" 버튼을 띄우고, 누르면 SceneTree를 멈춰
## 게임 로직과 음악을 그 자리에서 정지시킨다. 다시 누르거나
## Space / ESC / P 로 재개한다. 일시정지 중에는 테스트용 상태 값을 보여준다.

signal pause_changed(paused: bool)

const SCENE_MENU := "res://Scenes/StartScreen.tscn"
const PAUSE_ICON := preload("res://Assets/Art/UI/icon_pause.png")
const FONT_TITLE := preload("res://Assets/Fonts/BlackHanSans-Regular.ttf")
const FONT_BOLD := preload("res://Assets/Fonts/GothicA1-Bold.ttf")
const FONT_REGULAR := preload("res://Assets/Fonts/GothicA1-Regular.ttf")

const PINK := Color(0.878, 0.416, 0.561, 1)
const PINK_DEEP := Color(0.776, 0.322, 0.463, 1)
const INK := Color(0.23, 0.21, 0.26, 1)
const SUB := Color(0.45, 0.41, 0.48, 1)
const CREAM := Color(1, 0.996, 0.984, 1)
const LINE := Color(0.909, 0.882, 0.918, 1)

var active := false
var paused := false

var _pause_button: Button
var _panel: Control
var _info_label: Label


func _ready() -> void:
	# 트리가 멈춰 있어도 이 노드는 입력과 표시를 계속 처리해야 한다.
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_pause_button()
	_build_panel()
	set_active(false)


func _build_pause_button() -> void:
	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = ""
	_pause_button.tooltip_text = "일시정지 (P)"
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.anchor_left = 1.0
	_pause_button.anchor_right = 1.0
	_pause_button.offset_left = -104.0
	_pause_button.offset_right = -32.0
	_pause_button.offset_top = 140.0
	_pause_button.offset_bottom = 212.0
	_pause_button.add_theme_stylebox_override("normal", _pill(PINK, 36))
	_pause_button.add_theme_stylebox_override("hover", _pill(PINK_DEEP, 36))
	_pause_button.add_theme_stylebox_override("pressed", _pill(PINK_DEEP, 36))
	_pause_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_pause_button.pressed.connect(toggle_pause)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = PAUSE_ICON
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -18.0
	icon.offset_right = 18.0
	icon.offset_top = -18.0
	icon.offset_bottom = 18.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pause_button.add_child(icon)

	add_child(_pause_button)


func _build_panel() -> void:
	_panel = Control.new()
	_panel.name = "PausePanel"
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.08, 0.06, 0.1, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(900, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _card_style())
	center.add_child(card)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(box)

	var title := Label.new()
	title.text = "테스트 모드"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", INK)
	box.add_child(title)

	_info_label = Label.new()
	_info_label.name = "Info"
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.add_theme_font_override("font", FONT_BOLD)
	_info_label.add_theme_font_size_override("font_size", 28)
	_info_label.add_theme_color_override("font_color", PINK)
	box.add_child(_info_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	buttons.add_child(_make_button("계속", true, func() -> void: set_paused(false)))
	buttons.add_child(_make_button("다시", false, _restart))
	buttons.add_child(_make_button("메뉴", false, _leave_to_menu))

	_panel.hide()


func _make_button(label: String, filled: bool, action: Callable) -> Button:
	var button := Button.new()
	button.name = label
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(228, 64)
	button.add_theme_font_override("font", FONT_BOLD)
	button.add_theme_font_size_override("font_size", 26)
	if filled:
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(state, CREAM)
		button.add_theme_stylebox_override("normal", _pill(PINK, 18))
		button.add_theme_stylebox_override("hover", _pill(PINK_DEEP, 18))
		button.add_theme_stylebox_override("pressed", _pill(PINK_DEEP, 18))
	else:
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(state, INK)
		button.add_theme_stylebox_override("normal", _outline(INK))
		button.add_theme_stylebox_override("hover", _outline(PINK))
		button.add_theme_stylebox_override("pressed", _outline(PINK_DEEP))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(action)
	return button


func _pill(color: Color, radius: int = 29) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


func _outline(color: Color) -> StyleBoxFlat:
	var style := _pill(Color(color.r, color.g, color.b, 0.08), 18)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = color
	return style


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.set_corner_radius_all(28)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = LINE
	style.shadow_color = Color(0.15, 0.1, 0.15, 0.25)
	style.shadow_size = 30
	return style


func is_pause_button_visible() -> bool:
	return _pause_button.visible


func is_panel_visible() -> bool:
	return _panel.visible


func set_active(value: bool) -> void:
	active = value
	if not active and paused:
		set_paused(false)
	if _pause_button != null:
		_pause_button.visible = active and not paused
	if not active and _panel != null:
		_panel.hide()


func toggle_pause() -> void:
	if not active:
		return
	set_paused(not paused)


func set_paused(value: bool) -> void:
	if value == paused:
		return
	paused = value
	get_tree().paused = value
	_panel.visible = value
	_pause_button.visible = active and not value
	if value:
		_refresh_info()
	pause_changed.emit(value)


func _refresh_info() -> void:
	var source := get_parent()
	var text := "테스트 모드에서 게임을 멈췄습니다."
	if source != null and source.has_method("test_mode_info"):
		text = source.test_mode_info()
	_info_label.text = text


func _restart() -> void:
	_resume_tree()
	get_tree().reload_current_scene()


func _leave_to_menu() -> void:
	_resume_tree()
	get_tree().change_scene_to_file(SCENE_MENU)


func _resume_tree() -> void:
	if paused:
		set_paused(false)
	else:
		get_tree().paused = false


func _process(_delta: float) -> void:
	if paused:
		_refresh_info()


func _input(event: InputEvent) -> void:
	if not active:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_P:
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if paused and (event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE):
		set_paused(false)
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	# 일시정지 상태로 씬을 떠나면 다음 씬까지 멈춰 있지 않게 정리한다.
	if get_tree() != null:
		get_tree().paused = false
