extends Node

signal troops_changed(new_total: int)

# ---------------- CONFIG ----------------
const GREEN_REGIONS: Dictionary = {
	"g1":  {"troops": 100,  "time": 120.0,  "buff": "idle_5"},
	"g2":  {"troops": 150,  "time": 180.0,  "buff": "click_5"},
	"g3":  {"troops": 200,  "time": 240.0,  "buff": "troops_10"},
	"g4":  {"troops": 250,  "time": 300.0,  "buff": "all_auth_5"},
	"g5":  {"troops": 300,  "time": 360.0,  "buff": "crit_chance_1"},
	"g6":  {"troops": 350,  "time": 420.0,  "buff": "crit_mult_0_5"},
	"g7":  {"troops": 400,  "time": 480.0,  "buff": "crit_chance_cost_down_5"},
	"g8":  {"troops": 450,  "time": 540.0,  "buff": "crit_mult_cost_down_5"},
	"g9":  {"troops": 500,  "time": 600.0,  "buff": "lucky_hit_1"},
	"g10": {"troops": 600,  "time": 660.0,  "buff": "autoclicker"},
	"g11": {"troops": 700,  "time": 720.0,  "buff": "bls_req_reduce"},
	"g12": {"troops": 800,  "time": 780.0,  "buff": "all_upgrade_cost_down_3"},
	"g13": {"troops": 900,  "time": 840.0,  "buff": "idle_5_b"},
	"g14": {"troops": 1000, "time": 900.0,  "buff": "troops_10_b"},
	"g15": {"troops": 1100, "time": 960.0,  "buff": "click_5_b"},
	"g16": {"troops": 1200, "time": 1020.0, "buff": "all_auth_5_b"},
}

const BLUE_REGIONS: Dictionary = {
	"b1": {"troops": 20000, "time": 7200.0,  "buff": "click_stack"},
	"b2": {"troops": 30000, "time": 10800.0, "buff": "idle_double"},
	"b3": {"troops": 40000, "time": 14400.0, "buff": "bloodline_perks"},
	"b4": {"troops": 50000, "time": 18000.0, "buff": "imperial_conquest"}, # merged mist+edict
	"b5": {"troops": 60000, "time": 21600.0, "buff": "war_economy"},
}

const CAPITAL_REGION: Dictionary = {"capital": {"troops": 0, "time": 0.0, "buff": ""}}

# ---------------- STATE ----------------
var _computed_total: int = 0			# from formula (read-only, recalculated)
var _troops_spent: int = 0				# spent this abdication
var troops: int = 0						# available = computed - spent

var conquered: Dictionary = {}			# region_id -> bool
var active_region: String = ""
var conquest_timer: float = 0.0
var conquest_target_time: float = 0.0

var _recalc_cooldown: float = 0.0
var _last_computed_total: int = 0
func _ready() -> void:
	reset_state()
	set_process(true)

func _process(delta: float) -> void:
	# Recompute a few times/sec so UI reflects Global changes quickly
	_recalc_cooldown -= delta
	if _recalc_cooldown <= 0.0:
		_recalc_cooldown = 0.25
		_recompute_available_troops()
	update_conquest(delta)

# ---------------- TROOPS (FORMULA) ----------------
func _compute_formula_total() -> int:
	# 1) +1 per total bloodline strength
	var from_bloodline: int = int(Global.total_bloodline_strength)

	# 2) +1 per 10 total upgrade levels (this abdication)
	var levels: int = 0
	levels += Global.upgrade_passive_level
	levels += Global.upgrade_passive_2_level
	levels += Global.upgrade_click_level
	levels += Global.upgrade_click_2_level
	levels += Global.upgrade_crit_chance_level
	levels += Global.upgrade_crit_mult_level
	var from_levels: int = levels / 10

	# 3) +1 per 10,000 authority (this abdication)
	var from_auth: int = int(Global.authority / 10000)

	return from_bloodline + from_levels + from_auth

func _recompute_available_troops() -> void:
	_computed_total = _compute_formula_total()
	if _computed_total > _last_computed_total:
		Global.stat_add("troops_trained", _computed_total - _last_computed_total)
	_last_computed_total = _computed_total
	# Prevent spent from exceeding computed (edge cases)
	if _troops_spent > _computed_total:
		_troops_spent = _computed_total
	var new_available: int = max(0, _computed_total - _troops_spent)
	if new_available != troops:
		troops = new_available
		troops_changed.emit(troops)

func get_available_troops() -> int:
	return troops

func get_spent_troops() -> int:
	return _troops_spent

func add_spent_troops(amount: int) -> void:
	if amount <= 0: return
	_troops_spent = min(_computed_total, _troops_spent + amount)
	_recompute_available_troops()

func refund_spent_troops(amount: int) -> void:
	if amount <= 0: return
	_troops_spent = max(0, _troops_spent - amount)
	_recompute_available_troops()

# ---------------- CONQUEST ----------------
func reset_state() -> void:
	conquered.clear()
	for id in GREEN_REGIONS.keys():
		conquered[id] = false
	for id in BLUE_REGIONS.keys():
		conquered[id] = false
	for id in CAPITAL_REGION.keys():
		conquered[id] = true  # capital always owned

	active_region = ""
	conquest_timer = 0.0
	conquest_target_time = 0.0

	_troops_spent = 0

	# Seed last == current before the first recompute so we don't "train"
	# the entire computed pool on the first tick.
	_last_computed_total = _compute_formula_total()
	_computed_total = _last_computed_total
	troops = max(0, _computed_total - _troops_spent)
	troops_changed.emit(troops)


func _get_region_info(region_id: String) -> Dictionary:
	if GREEN_REGIONS.has(region_id):
		return GREEN_REGIONS[region_id]
	if BLUE_REGIONS.has(region_id):
		return BLUE_REGIONS[region_id]
	if CAPITAL_REGION.has(region_id):
		return CAPITAL_REGION[region_id]
	return {}

func can_start_conquest(region_id: String) -> bool:
	if conquered.get(region_id, false):
		return false
	if active_region != "":
		return false
	var info: Dictionary = _get_region_info(region_id)
	if info.is_empty():
		return false
	var cost: int = int(info.get("troops", 0))
	return get_available_troops() >= cost

func start_conquest(region_id: String) -> void:
	if not can_start_conquest(region_id):
		return
	var info: Dictionary = _get_region_info(region_id)
	var cost: int = int(info.get("troops", 0))

	# spend and recompute
	_troops_spent = min(_computed_total, _troops_spent + cost)
	_recompute_available_troops()

	active_region = region_id
	conquest_timer = 0.0
	conquest_target_time = float(info.get("time", 0.0))

func update_conquest(delta: float) -> void:
	if active_region == "":
		return
	conquest_timer += delta
	if conquest_timer >= conquest_target_time:
		conquered[active_region] = true
		Global.stat_add("territories_conquered", 1)
		var info: Dictionary = _get_region_info(active_region)
		var buff_id: String = str(info.get("buff", ""))
		active_region = ""
		conquest_timer = 0.0
		conquest_target_time = 0.0
		_apply_buff(buff_id)

func _apply_buff(buff_id: String) -> void:
	# Forward to other systems as needed; recompute in case formula inputs changed indirectly.
	if buff_id != "":
		print("Buff applied:", buff_id)
	_recompute_available_troops()

# ---------------- SAVE / LOAD ----------------
func to_dict() -> Dictionary:
	return {
		"troops_spent": _troops_spent,
		"conquered": conquered,                 # region_id -> bool
		"active_region": active_region,         # "" if none
		"conquest_timer": conquest_timer,       # seconds elapsed in current conquest
		"conquest_target_time": conquest_target_time, # seconds required for current conquest
		"__ver": 1,                             # optional: schema version for future-proofing
	}


func from_dict(data: Dictionary) -> void:
	# --- core fields ---
	_troops_spent = int(data.get("troops_spent", 0))
	conquered = data.get("conquered", {})
	active_region = str(data.get("active_region", ""))
	conquest_timer = float(data.get("conquest_timer", 0.0))
	conquest_target_time = float(data.get("conquest_target_time", 0.0))

	# --- normalize conquered map against current region lists ---
	for id in GREEN_REGIONS.keys():
		if not conquered.has(id):
			conquered[id] = false
	for id in BLUE_REGIONS.keys():
		if not conquered.has(id):
			conquered[id] = false
	for id in CAPITAL_REGION.keys():
		conquered[id] = true  # capital always owned

	# --- validate active conquest (clear if nonsense) ---
	var info: Dictionary = _get_region_info(active_region)
	if active_region != "" and info.is_empty():
		active_region = ""
		conquest_timer = 0.0
		conquest_target_time = 0.0
	elif active_region == "" or conquest_target_time <= 0.0:
		active_region = ""
		conquest_timer = 0.0
		conquest_target_time = 0.0
	else:
		conquest_timer = clampf(conquest_timer, 0.0, conquest_target_time)

	# Seed last == current before recompute so we don't double-count
	# a huge "trained troops" delta on load.
	_last_computed_total = _compute_formula_total()
	_computed_total = _last_computed_total
	troops = max(0, _computed_total - _troops_spent)

	# (Optional) notify UI even if total didn't change
	troops_changed.emit(troops)
