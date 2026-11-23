extends Node2D

const LIGHT_TEXTURE := preload("res://Assets/Art/UI/window_light.svg")
const BEAM_SHADER := preload("res://Scripts/window_beam.gdshader")
const PANORAMA_TEXTURE := preload("res://Assets/Art/Backgrounds/home_panorama.png")
const PANORAMA_NORMAL := preload("res://Assets/Art/Backgrounds/home_panorama_normal.png")
const PANEL_WIDTH := 1920.0

const SUN_SCREEN := Vector2(300.0, 150.0)
const SUN := {
	"energy": 0.42,
	"scale": 6.8,
	"beam_size": Vector2(1500, 3200),
	"beam_angle": -0.5,
	"beam_intensity": 0.09,
}

var _sun_light: PointLight2D
var _sun_beam: ColorRect


func _ready() -> void:
	_build_panels()
	_add_sun()
	_add_fill_light()


func _process(_delta: float) -> void:
	var offset := (get_parent() as Node2D).position
	if _sun_light != null:
		_sun_light.position = SUN_SCREEN - offset
	if _sun_beam != null:
		var size: Vector2 = SUN.beam_size
		_sun_beam.position = SUN_SCREEN - offset - Vector2(size.x * 0.5, 0.0)


func get_sun_screen_pos() -> Vector2:
	return SUN_SCREEN


func get_sun_energy() -> float:
	return SUN.energy


func _build_panels() -> void:
	var canvas_texture := CanvasTexture.new()
	canvas_texture.diffuse_texture = PANORAMA_TEXTURE
	canvas_texture.normal_texture = PANORAMA_NORMAL

	for panel in 4:
		var sprite := Sprite2D.new()
		sprite.texture = canvas_texture
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(panel * PANEL_WIDTH, 0.0, PANEL_WIDTH, 1080.0)
		sprite.position = Vector2(panel * PANEL_WIDTH, 0.0)
		sprite.light_mask = 1 << panel
		sprite.modulate = Color(0.9, 0.87, 0.84, 1)
		add_child(sprite)


func _add_sun() -> void:
	var offset := (get_parent() as Node2D).position

	var sun := PointLight2D.new()
	sun.texture = LIGHT_TEXTURE
	sun.texture_scale = SUN.scale
	sun.energy = SUN.energy
	sun.color = Color(1.0, 0.9, 0.76)
	sun.position = SUN_SCREEN - offset
	sun.height = 300.0
	sun.range_item_cull_mask = 15
	sun.shadow_enabled = false
	add_child(sun)
	_sun_light = sun

	var beam := ColorRect.new()
	var size: Vector2 = SUN.beam_size
	beam.size = size
	beam.pivot_offset = Vector2(size.x * 0.5, 0.0)
	beam.position = SUN_SCREEN - offset - Vector2(size.x * 0.5, 0.0)
	beam.rotation = SUN.beam_angle
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var material := ShaderMaterial.new()
	material.shader = BEAM_SHADER
	material.set_shader_parameter("beam_color", Color(1.0, 0.9, 0.7))
	material.set_shader_parameter("intensity", SUN.beam_intensity)
	material.set_shader_parameter("softness", 0.85)
	beam.material = material
	add_child(beam)
	_sun_beam = beam


func _add_fill_light() -> void:
	var fill := DirectionalLight2D.new()
	fill.energy = 0.09
	fill.color = Color(0.8, 0.86, 1.0)
	fill.range_item_cull_mask = 15
	fill.rotation = 0.55
	add_child(fill)
