extends Node
class_name Lighting2D
## 네이티브 2D 조명 리그.
##
## 실제 PointLight2D 광원과 LightOccluder2D 그림자를 만들고, 빛을 움직인다.
## UI는 빛의 영향을 받지 않게 light_mask를 0으로 만든다.

var _panorama: Node2D
var _stage: CanvasItem
var _rig: Node2D
var _lights: Array[PointLight2D] = []
var _bases: Array[Vector2] = []
var _energies: Array[float] = []
var _kinds: Array[String] = []
var _phases: Array[float] = []
var _fill: PointLight2D
var _time := 0.0
var _flicker_at := 0.0
var focus := Vector2.ZERO
var has_focus := false


static func apply(
	scene: Node,
	panorama: Node2D,
	stage: CanvasItem,
	unlit_roots: Array,
	light_specs: Array,
	with_occluders: bool = true,
) -> Lighting2D:
	var rig := Lighting2D.new()
	rig.name = "Lighting2D"
	scene.add_child(rig)
	rig._setup(scene, panorama, stage, unlit_roots, light_specs, with_occluders)
	return rig


func _setup(
	scene: Node,
	panorama: Node2D,
	stage: CanvasItem,
	unlit_roots: Array,
	light_specs: Array,
	with_occluders: bool,
) -> void:
	_panorama = panorama
	_stage = stage
	panorama.modulate = Color(0.68, 0.66, 0.78)
	if stage != null:
		stage.modulate = Color(0.84, 0.82, 0.90)
	for root in unlit_roots:
		if root != null:
			_unlight(root)

	_rig = Node2D.new()
	_rig.name = "LightRig2D"
	scene.add_child(_rig)

	var texture := _make_light_texture()
	for spec in light_specs:
		var light := PointLight2D.new()
		light.texture = texture
		light.color = spec["color"]
		light.energy = float(spec["energy"])
		light.texture_scale = float(spec["scale"])
		light.position = Vector2(float(spec["x"]), float(spec["y"]))
		light.shadow_enabled = true
		light.shadow_color = Color(0.02, 0.02, 0.05, 0.62)
		light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		_rig.add_child(light)
		_lights.append(light)
		_bases.append(light.position)
		_energies.append(light.energy)
		_kinds.append(String(spec.get("kind", "static")))
		_phases.append(float(spec.get("phase", 0.0)))

	_fill = PointLight2D.new()
	_fill.texture = texture
	_fill.color = Color(1.0, 0.92, 0.8)
	_fill.energy = 0.32
	_fill.texture_scale = 1.7
	_fill.shadow_enabled = false
	_rig.add_child(_fill)

	if with_occluders:
		_add_occluders(panorama)


func _make_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.42, Color(1, 1, 1, 0.86))
	gradient.add_point(0.74, Color(1, 1, 1, 0.28))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _unlight(node: Node) -> void:
	if node is CanvasItem:
		(node as CanvasItem).light_mask = 0
	for child in node.get_children():
		_unlight(child)


func _add_occluders(panorama: Node2D) -> void:
	for child in panorama.get_children():
		if not (child is Sprite2D):
			continue
		var sprite := child as Sprite2D
		var node_name := String(sprite.name)
		if (
			node_name.contains("Background")
			or node_name.contains("Pictures")
			or node_name.contains("Calendar")
			or node_name.contains("Clock")
			or node_name.contains("Hood")
			or node_name.contains("Bed")
			or node_name.contains("Sofa")
			or node_name.contains("Table")
			or node_name.contains("Desk")
			or node_name.contains("Plants")
			or node_name.contains("Sink")
			or node_name.contains("Cabinet")
			or node_name.contains("Divider")
		):
			continue
		if sprite.texture == null:
			continue
		var rect := Rect2(Vector2.ZERO, sprite.texture.get_size())
		var image := sprite.texture.get_image()
		if image != null:
			if image.is_compressed():
				image.decompress()
			var used := image.get_used_rect()
			if used.size.x > 8 and used.size.y > 8:
				rect = Rect2(used.position, used.size)
		var polygon := OccluderPolygon2D.new()
		polygon.polygon = PackedVector2Array([
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y),
		])
		var occluder := LightOccluder2D.new()
		occluder.occluder = polygon
		occluder.light_mask = 1
		sprite.add_child(occluder)


func _process(delta: float) -> void:
	_time += delta
	if _rig != null and _panorama != null:
		_rig.position = _panorama.position

	for index in _lights.size():
		var light := _lights[index]
		match _kinds[index]:
			"window":
				light.position.x = _bases[index].x + sin(_time * 0.22 + _phases[index]) * 54.0
				light.position.y = _bases[index].y + sin(_time * 0.31 + _phases[index]) * 14.0
				light.energy = _energies[index] + sin(_time * 0.85 + _phases[index]) * 0.07
			"lamp":
				light.energy = _energies[index] + sin(_time * 2.4 + _phases[index]) * 0.03
			"tv":
				if _time >= _flicker_at:
					light.energy = _energies[index] * randf_range(0.55, 1.05)
					_flicker_at = _time + randf_range(0.05, 0.2)
			_:
				light.energy = _energies[index] + sin(_time * 0.5 + _phases[index]) * 0.03

	if _fill != null and has_focus:
		_fill.position = focus
