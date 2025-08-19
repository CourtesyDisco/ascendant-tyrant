# Map.gd  (attach to the TextureRect named "Map")
extends TextureRect

signal region_clicked(region_id: String)

var _mask_img: Image
var _color_to_region: Dictionary = {}
var _label_positions: Dictionary = {}
var debug_show_labels := true

func _ready() -> void:
	# important: this node should STOP, so it actually receives clicks
	mouse_filter = Control.MOUSE_FILTER_STOP

	# load mask
	var mask_tex: Texture2D = load("res://assets/art/expansionmap_mask.png")
	_mask_img = mask_tex.get_image()
	_mask_img.convert(Image.FORMAT_RGBA8)

	# color → region mapping (your scheme)
	for i in range(1, 17):
		_color_to_region[Color8(0, 255, i)] = "g%d" % i
	for i in range(1, 6):
		_color_to_region[Color8(0, i, 255)] = "b%d" % i
	_color_to_region[Color8(82, 0, 58)] = "capital"

	_build_label_positions()
	queue_redraw()
	print("Map ready size=", size)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local: Vector2 = (event as InputEventMouseButton).position
		print("Map got click:", local)
		var id := _region_id_from_local(local)
		print("Region:", id)
		if id != "":
			region_clicked.emit(id)

func _region_id_from_local(local: Vector2) -> String:
	var drawn: Rect2 = _get_drawn_rect_for_self()
	if not drawn.has_point(local):
		return ""
	var uv: Vector2 = (local - drawn.position) / drawn.size
	var w: int = _mask_img.get_width()
	var h: int = _mask_img.get_height()
	var px := Vector2i(
		clamp(int(floor(uv.x * float(w))), 0, w - 1),
		clamp(int(floor(uv.y * float(h))), 0, h - 1)
	)
	var c: Color = _mask_img.get_pixelv(px)
	var c8 := Color8(int(round(c.r*255.0)), int(round(c.g*255.0)), int(round(c.b*255.0)), 255)
	return String(_color_to_region.get(c8, ""))

func _get_drawn_rect_for_self() -> Rect2:
	if texture == null:
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var ctrl_rect: Rect2 = Rect2(Vector2.ZERO, size)
	var tex_size: Vector2 = texture.get_size()

	var sx: float = ctrl_rect.size.x / tex_size.x
	var sy: float = ctrl_rect.size.y / tex_size.y
	var scale: float = min(sx, sy)

	var draw_size: Vector2 = tex_size * scale
	var offset: Vector2 = (ctrl_rect.size - draw_size) * 0.5

	return Rect2(offset, draw_size)


# ---- centroid labels (debug) ----
func _build_label_positions() -> void:
	_label_positions.clear()
	var w := _mask_img.get_width()
	var h := _mask_img.get_height()
	var sum_xy := {}
	var counts := {}
	for y in range(h):
		for x in range(w):
			var c: Color = _mask_img.get_pixel(x, y)
			var c8 := Color8(int(round(c.r*255.0)), int(round(c.g*255.0)), int(round(c.b*255.0)), 255)
			if _color_to_region.has(c8):
				var id := String(_color_to_region[c8])
				sum_xy[id] = (sum_xy.get(id, Vector2.ZERO) as Vector2) + Vector2(x, y)
				counts[id] = int(counts.get(id, 0)) + 1
	for id in sum_xy.keys():
		_label_positions[id] = (sum_xy[id] as Vector2) / float(counts[id])

func _draw() -> void:
	if not debug_show_labels or _label_positions.is_empty():
		return
	var font: Font = get_theme_default_font()
	var drawn := _get_drawn_rect_for_self()
	var w := _mask_img.get_width()
	var h := _mask_img.get_height()
	for id in _label_positions.keys():
		var tex_pos: Vector2 = _label_positions[id]
		var local_pos := drawn.position + Vector2(
			(tex_pos.x / float(w)) * drawn.size.x,
			(tex_pos.y / float(h)) * drawn.size.y
		)
		var text_size := font.get_string_size(id)
		draw_string(font, local_pos - text_size * 0.5, id, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
