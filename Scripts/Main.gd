extends Control

const CHAPTER_TITLES := [
	"물 마시러 가기",
	"아빠의 라면",
	"??? (추후 기획)",
]

@onready var title_label: Label = $Center/Title
@onready var desc_label: Label = $Center/Desc


func _ready() -> void:
	var flags := _flags()
	for flag in flags:
		if flag.begins_with("chapter") and flag.substr(7).is_valid_int():
			Settings.current_chapter = int(flag.substr(7))

	var chapter := clampi(Settings.current_chapter, 1, CHAPTER_TITLES.size())
	title_label.text = "챕터 %d" % chapter
	desc_label.text = CHAPTER_TITLES[chapter - 1]

	if "capture" in flags:
		_capture_and_quit()


func _flags() -> Array[String]:
	var result: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		result.append(arg.lstrip("-"))
	return result


func _capture_and_quit() -> void:
	await get_tree().create_timer(1.0).timeout
	var dir := "res://Design/shots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var image := get_viewport().get_texture().get_image()
	image.save_png(dir + "/main_chapter_%d.png" % Settings.current_chapter)
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/StartScreen.tscn")
