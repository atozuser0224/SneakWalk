extends Control

const TITLE_FONT := preload("res://Assets/Fonts/BlackHanSans-Regular.ttf")
const BOLD_FONT := preload("res://Assets/Fonts/GothicA1-Bold.ttf")
const BODY_FONT := preload("res://Assets/Fonts/GothicA1-Regular.ttf")
const INK := Color(0.23, 0.21, 0.26, 1.0)
const MUTED := Color(0.48, 0.44, 0.51, 1.0)
const PINK := Color(0.878, 0.416, 0.561, 1.0)
const CREAM := Color(1.0, 0.996, 0.984, 0.94)
const SOFT_PINK := Color(1.0, 0.91, 0.94, 1.0)
const SOFT_GRAY := Color(0.94, 0.92, 0.94, 1.0)


func _ready() -> void:
	var gameplay: Control = $Gameplay
	gameplay.set_process(false)
	gameplay.set_process_input(false)
	gameplay.set_process_unhandled_input(false)
	gameplay.get_node("UI").hide()
	gameplay.get_node("StartOverlay").hide()
	gameplay.get_node("ResultOverlay").hide()
	gameplay.get_node("TestMode").hide()
	gameplay.get_node("Music").stop()
	_build_mockup()

	if "mockup_capture" in _flags():
		await get_tree().create_timer(0.6).timeout
		var path := "res://Design/rhythm_response_proposal.png"
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(path)
		if error == OK:
			print("RHYTHM_PROPOSAL_CAPTURED: " + path)
		else:
			printerr("RHYTHM_PROPOSAL_CAPTURE_FAILED: " + error_string(error))
		get_tree().quit(error)


func _flags() -> Array[String]:
	var result: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		result.append(arg.lstrip("-"))
	return result


func _build_mockup() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)

	_add_panel(ui, Rect2(32, 28, 770, 122), CREAM, Color(0.91, 0.87, 0.9, 1), 22)
	_add_label(ui, "챕터 1  ·  살금 스텝", Rect2(66, 43, 700, 52), 38, INK, TITLE_FONT)
	_add_label(ui, "먼저 듣고, 같은 박자로 조용히 따라 걸어요", Rect2(70, 99, 700, 34), 23, MUTED, BODY_FONT)

	_add_panel(ui, Rect2(1430, 28, 458, 112), CREAM, Color(0.91, 0.87, 0.9, 1), 22)
	_add_label(ui, "층간소음", Rect2(1460, 39, 120, 32), 24, INK, BOLD_FONT)
	_add_panel(ui, Rect2(1584, 48, 274, 24), SOFT_GRAY, SOFT_GRAY, 12)
	_add_panel(ui, Rect2(1584, 48, 82, 24), PINK, PINK, 12)
	_add_label(ui, "14%", Rect2(1790, 82, 66, 30), 21, MUTED, BODY_FONT, HORIZONTAL_ALIGNMENT_RIGHT)
	_add_label(ui, "콤보  04", Rect2(1460, 85, 180, 28), 20, PINK, BOLD_FONT)

	_add_panel(ui, Rect2(680, 166, 560, 70), CREAM, Color(0.91, 0.87, 0.9, 1), 34)
	_add_label(ui, "따라 걷기  ·  3 / 4", Rect2(700, 178, 520, 44), 28, PINK, BOLD_FONT, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(ui, "사박!  정확해요", Rect2(650, 358, 620, 72), 50, PINK, TITLE_FONT, HORIZONTAL_ALIGNMENT_CENTER)

	_add_panel(ui, Rect2(96, 708, 1728, 320), Color(1.0, 0.996, 0.984, 0.96), Color(0.91, 0.87, 0.9, 1), 28)
	_add_label(ui, "리듬을 듣고 그대로 따라 걸어요", Rect2(144, 730, 790, 43), 30, INK, TITLE_FONT)
	_add_label(ui, "SPACE  ·  한 박자에 한 걸음", Rect2(1270, 736, 500, 34), 21, MUTED, BOLD_FONT, HORIZONTAL_ALIGNMENT_RIGHT)
	_add_label(ui, "들려준 걸음", Rect2(150, 805, 260, 40), 24, MUTED, BOLD_FONT)
	_add_label(ui, "내가 따라 걷기", Rect2(150, 916, 280, 40), 24, INK, BOLD_FONT)
	_add_label(ui, "똑   똑   ·   똑   ·   똑", Rect2(1450, 806, 300, 32), 20, MUTED, BODY_FONT, HORIZONTAL_ALIGNMENT_RIGHT)

	var heard_beats := [0, 1, 4, 6]
	var answered_beats := [0, 1, 4]
	for beat in 8:
		var x := 432.0 + float(beat) * 166.0
		var heard := beat in heard_beats
		_add_beat(ui, x, 790, beat + 1, heard, false)
		var answered := beat in answered_beats
		var active := beat == 6
		_add_beat(ui, x, 901, beat + 1, answered or active, active)

	_add_label(ui, "박자를 기억하고 Space로 한 걸음씩", Rect2(144, 980, 800, 28), 19, MUTED, BODY_FONT)


func _add_beat(parent: Control, x: float, y: float, number: int, active: bool, current: bool) -> void:
	var fill := SOFT_PINK if active else SOFT_GRAY
	var outline := PINK if current else Color(0.91, 0.87, 0.9, 1)
	var width := 88.0 if current else 78.0
	var height := 66.0 if current else 58.0
	var offset := Vector2(0, 0) if current else Vector2(5, 4)
	_add_panel(parent, Rect2(Vector2(x, y) - offset, Vector2(width, height)), fill, outline, 24 if current else 20)
	_add_label(parent, "●" if active else "·", Rect2(x + 13, y + 5, width - 26, 34), 26 if active else 30, PINK if active else Color(0.77, 0.73, 0.79, 1), BOLD_FONT, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(parent, str(number), Rect2(x + 13, y + 34, width - 26, 22), 16, MUTED, BODY_FONT, HORIZONTAL_ALIGNMENT_CENTER)


func _add_panel(parent: Control, rect: Rect2, fill: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.15, 0.1, 0.15, 0.12)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _add_label(
	parent: Control,
	text: String,
	rect: Rect2,
	font_size: int,
	color: Color,
	font: Font,
	h_align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = h_align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label
