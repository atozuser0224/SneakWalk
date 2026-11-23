extends Node

const CONFIG_PATH := "user://settings.cfg"

var bgm_volume: int = 80
var sfx_volume: int = 60
var fullscreen: bool = false
var screen_shake: bool = true
var current_chapter: int = 1


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	load_settings()
	apply_all()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func set_bgm_volume(value: float) -> void:
	bgm_volume = clampi(int(value), 0, 100)
	_apply_bus("Music", bgm_volume)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampi(int(value), 0, 100)
	_apply_bus("SFX", sfx_volume)


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	save_settings()


func set_screen_shake(enabled: bool) -> void:
	screen_shake = enabled
	save_settings()


func apply_all() -> void:
	_apply_bus("Music", bgm_volume)
	_apply_bus("SFX", sfx_volume)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _apply_bus(bus_name: String, volume: int) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_mute(index, volume <= 0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume / 100.0, 0.0001)))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("game", "screen_shake", screen_shake)
	config.save(CONFIG_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	bgm_volume = int(config.get_value("audio", "bgm_volume", bgm_volume))
	sfx_volume = int(config.get_value("audio", "sfx_volume", sfx_volume))
	fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
	screen_shake = bool(config.get_value("game", "screen_shake", screen_shake))
