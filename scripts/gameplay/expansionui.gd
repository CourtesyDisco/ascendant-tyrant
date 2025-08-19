extends Control

# bottom bar (if already connected in editor, the handlers below will be called)
@onready var btn_menu: Button = $bottom_bar/btn_menu
@onready var btn_game: Button = $bottom_bar/btn_game

# map (TextureRect with the click-mask script that emits `region_clicked(String)`)
@onready var map_tex: TextureRect = $"mapview/Map"

# troops tab widgets (match your tree exactly)
@onready var lbl_troops: Label = $TabContainer/Troops/TroopsPanel/HBoxContainer0/lbl_troops
@onready var lbl_region: Label     = $TabContainer/Troops/TroopsPanel/lbl_region
@onready var lbl_cost: Label       = $TabContainer/Troops/TroopsPanel/HBoxContainer/lbl_cost
@onready var lbl_time: Label       = $TabContainer/Troops/TroopsPanel/HBoxContainer2/lbl_time
@onready var lbl_status: Label     = $TabContainer/Troops/TroopsPanel/HBoxContainer3/lbl_status
@onready var progress: ProgressBar = $TabContainer/Troops/TroopsPanel/progress
@onready var btn_conquer: Button   = $TabContainer/Troops/TroopsPanel/btn_conquer
@onready var btn_add_troops: Button = $TabContainer/Troops/TroopsPanel/btn_add_troops	# create this button

var _selected_region: String = ""

func _on_btn_menu_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
	
func _on_btn_game_pressed():
	get_tree().change_scene_to_file("res://scenes/gameplay/clicker_ui.tscn")



func _ready() -> void:
	# Map click signal
	if is_instance_valid(map_tex) and map_tex.has_signal("region_clicked"):
		map_tex.connect("region_clicked", Callable(self, "_on_region_clicked"))
	else:
		push_warning("Map TextureRect missing or has no 'region_clicked' signal (path: mapview/Map)")

	# Conquer / Dev buttons
	if not btn_conquer.pressed.is_connected(_on_btn_conquer_pressed):
		btn_conquer.pressed.connect(_on_btn_conquer_pressed)
	if is_instance_valid(btn_add_troops) and not btn_add_troops.pressed.is_connected(_on_btn_add_troops_pressed):
		btn_add_troops.pressed.connect(_on_btn_add_troops_pressed)

	# Refresh when troops change
	if not Expansion.troops_changed.is_connected(_on_troops_changed):
		Expansion.troops_changed.connect(_on_troops_changed)

	_refresh_troops_label()
	_refresh_panel()

func _process(delta: float) -> void:
	# Autoload also ticks, but this keeps UI responsive if Expansion scene is open.
	Expansion.update_conquest(delta)
	if Expansion.active_region != "":
		_update_progress_ui()
	_refresh_troops_label()

# -------- handlers --------
func _on_region_clicked(region_id: String) -> void:
	_selected_region = region_id
	_refresh_panel()

func _on_btn_conquer_pressed() -> void:
	if _selected_region == "":
		return
	if Expansion.can_start_conquest(_selected_region):
		Expansion.start_conquest(_selected_region)
		_update_progress_ui()
	else:
		_refresh_panel()

func _on_btn_add_troops_pressed() -> void:
	Expansion.grant_troops(1000)	# dev button

func _on_troops_changed(new_total: int) -> void:
	_refresh_troops_label()
	# selected region may become affordable → update status
	_refresh_panel()

# -------- UI helpers --------
func _refresh_troops_label() -> void:
	if is_instance_valid(lbl_troops):
		lbl_troops.text = "Troops: " + _fmt_int(Expansion.troops)

func _refresh_panel() -> void:
	var info: Dictionary = _get_region_info(_selected_region)
	if info.is_empty():
		_set_panel("-", "-", "-", "Click a region", 0.0, false)
		return

	var state: String = _get_region_state(_selected_region)
	var cost_text: String = _fmt_int(int(info.troops))
	var time_text: String = _fmt_secs(float(info.time))

	match state:
		"CONQUERED":
			_set_panel(_selected_region, cost_text, time_text, "Conquered", 100.0, false)
		"IN_PROGRESS":
			_update_progress_ui()
		"LOCKED":
			var can: bool = Expansion.can_start_conquest(_selected_region)
			var need: int = max(0, int(info.troops) - Expansion.troops)
			var status: String = "Ready" if can else "Need " + _fmt_int(need) + " troops"
			_set_panel(_selected_region, cost_text, time_text, status, 0.0, can)

func _update_progress_ui() -> void:
	if Expansion.active_region == "":
		return
	var id: String = Expansion.active_region
	var info: Dictionary = _get_region_info(id)
	if info.is_empty():
		return

	var total: float = max(0.001, float(info.time))
	var pct: float = clamp((Expansion.conquest_timer / total) * 100.0, 0.0, 100.0)
	var remaining: float = max(0.0, total - Expansion.conquest_timer)

	_set_panel(id, _fmt_int(int(info.troops)), _fmt_secs(total), "In progress • " + _fmt_secs(remaining) + " left", pct, false)

	if pct >= 100.0 and Expansion.active_region == "":
		_set_panel(id, _fmt_int(int(info.troops)), _fmt_secs(total), "Conquered", 100.0, false)

func _get_region_info(id: String) -> Dictionary:
	if id == "": return {}
	if Expansion.GREEN_REGIONS.has(id): return Expansion.GREEN_REGIONS[id]
	if Expansion.BLUE_REGIONS.has(id): return Expansion.BLUE_REGIONS[id]
	if Expansion.CAPITAL_REGION.has(id): return Expansion.CAPITAL_REGION[id]
	return {}

func _get_region_state(id: String) -> String:
	if id == "": return "-"
	if id == "capital": return "CONQUERED"
	var is_conq: bool = bool(Expansion.conquered.get(id, false))
	if is_conq: return "CONQUERED"
	if Expansion.active_region == id: return "IN_PROGRESS"
	return "LOCKED"

func _fmt_secs(s: float) -> String:
	var t: int = int(round(s))
	var h: int = t / 3600
	var m: int = (t % 3600) / 60
	var sec: int = t % 60
	if h > 0:
		return "%dh %02dm %02ds" % [h, m, sec]
	elif m > 0:
		return "%dm %02ds" % [m, sec]
	return "%ds" % sec

func _fmt_int(n: int) -> String:
	return String.num_int64(n)

func _set_panel(region: String, cost: String, time_str: String, status: String, pct: float, can_conquer: bool) -> void:
	lbl_region.text = region
	lbl_cost.text = cost
	lbl_time.text = time_str
	lbl_status.text = status
	progress.value = pct
	progress.tooltip_text = str(int(round(pct))) + "%"
	btn_conquer.disabled = not can_conquer
