extends Node

#player stats
var lifetime_authority = 0
var authority = 0
var auth_per_click = 1
var passive_income = 0
var passive_mult = 1
var crit_chance = .05
var crit_mult = 3
var first_time: bool = true


#bloodline
var bloodline_strength = 0
var total_bloodline_strength = 0

#upgrade levels and cost
var upgrade_passive_level = 0
var upgrade_passive_cost = 50

var upgrade_passive_2_level = 0
var upgrade_passive_2_cost = 500

var upgrade_click_level = 0
var upgrade_click_cost = 10

var upgrade_click_2_level = 0
var upgrade_click_2_cost = 250

var upgrade_crit_chance_level = 0
var upgrade_crit_chance_cost = 500

var upgrade_crit_mult_level = 0
var upgrade_crit_mult_cost = 1000

#times for away income
var last_active_time = 0
var now = 0
var elapsed = 0


#options
var number_format: int = 0  # 0 = Words, 1 = Scientific
var music_volume: float = 1.0
var sfx_volume: float = 1.0




#puts stats in a saveable format
func to_dict() -> Dictionary:
	return {
		"lifetime_authority": lifetime_authority, "authority": authority, "auth_per_click": auth_per_click,
		"passive_income": passive_income, "passive_mult": passive_mult, "crit_chance": crit_chance, "crit_mult": crit_mult,
		"bloodline_strength": bloodline_strength, "total_bloodline_strength": total_bloodline_strength,
		"upgrade_passive_level": upgrade_passive_level, "upgrade_passive_cost": upgrade_passive_cost,
		"upgrade_passive_2_level": upgrade_passive_2_level, "upgrade_passive_2_cost": upgrade_passive_2_cost,
		"upgrade_click_level": upgrade_click_level, "upgrade_click_cost": upgrade_click_cost,
		"upgrade_click_2_level": upgrade_click_2_level, "upgrade_click_2_cost": upgrade_click_2_cost,
		"upgrade_crit_chance_level": upgrade_crit_chance_level, "upgrade_crit_chance_cost": upgrade_crit_chance_cost,
		"upgrade_crit_mult_level": upgrade_crit_mult_level, "upgrade_crit_mult_cost": upgrade_crit_mult_cost,
		"last_active_time": last_active_time, "music_volume": music_volume,
		"sfx_volume": sfx_volume, "number_format": int(Numberformatter.number_format), "first_time": (first_time),
		"bs_perk1": bs_perk1, "bs_perk2": bs_perk2, "bs_perk3": bs_perk3, "bs_perk4": (bs_perk4), "stats": stats,
		"troops": troops, "conquered": conquered, "regions": regions
	}


#turns stats back to useable
func from_dict(data: Dictionary) -> void:
	lifetime_authority = data.get("lifetime_authority", 0); authority = data.get("authority", 0); auth_per_click = data.get("auth_per_click", 1)
	passive_income = data.get("passive_income", 0); passive_mult = data.get("passive_mult", 1); 
	crit_chance = data.get("crit_chance", 0.05); crit_mult = data.get("crit_mult", 3)
	bloodline_strength = data.get("bloodline_strength", 0); total_bloodline_strength = data.get("total_bloodline_strength", 0);
	upgrade_passive_level = data.get("upgrade_passive_level", 0); upgrade_passive_cost = data.get("upgrade_passive_cost", 50)
	upgrade_passive_2_level = data.get("upgrade_passive_2_level", 0); upgrade_passive_2_cost = data.get("upgrade_passive_2_cost", 500)
	upgrade_click_level = data.get("upgrade_click_level", 0); upgrade_click_cost = data.get("upgrade_click_cost", 10)
	upgrade_click_2_level = data.get("upgrade_click_2_level", 0); upgrade_click_2_cost = data.get("upgrade_click_2_cost", 250)
	upgrade_crit_chance_level = data.get("upgrade_crit_chance_level", 0); upgrade_crit_chance_cost = data.get("upgrade_crit_chance_cost", 500)
	upgrade_crit_mult_level = data.get("upgrade_crit_mult_level", 0); upgrade_crit_mult_cost = data.get("upgrade_crit_mult_cost", 1000)
	last_active_time = data.get("last_active_time", 0); music_volume = data.get("music_volume", 1.0)
	sfx_volume = data.get("sfx_volume", 1.0); first_time = data.get("first_time", true); number_format = data.get("number_format", 0)
	bs_perk1 = data.get("bs_perk1", false); bs_perk2 = data.get("bs_perk2", false); bs_perk3 = data.get("bs_perk3", false);
	bs_perk4 = data.get("bs_perk4", false); stats = data.get("stats", stats); troops = data.get("troops", 0); conquered = data.get("conquered", {}); regions = data.get("regions", regions)
	@warning_ignore("int_as_enum_without_cast")
	Numberformatter.number_format = number_format

var save_path := "user://save.json"


func delete_save():
	@warning_ignore("unused_variable", "shadowed_variable")
	var save_path = ProjectSettings.globalize_path("user://save.json")
	if FileAccess.file_exists("user://save.json"):
		var dir = DirAccess.open("user://")
		if dir:
			var err = dir.remove("save.json")
			if err == OK:
				print("Save deleted.")
			else:
				print("Failed to delete save file. Error code:", err)
		else:
			print("Failed to open user directory.")
	else:
		print("No save file to delete.")


func reset_stats_abdicate():
	# Player stats
	lifetime_authority = 0
	authority = 0
	auth_per_click = 1
	passive_income = 0
	passive_mult = 1
	crit_chance = 0.05
	crit_mult = 3


	# Upgrade levels and cost
	upgrade_passive_level = 0
	upgrade_passive_cost = 50

	upgrade_passive_2_level = 0
	upgrade_passive_2_cost = 750

	upgrade_click_level = 0
	upgrade_click_cost = 10

	upgrade_click_2_level = 0
	upgrade_click_2_cost = 500

	upgrade_crit_chance_level = 0
	upgrade_crit_chance_cost = 2000

	upgrade_crit_mult_level = 0
	upgrade_crit_mult_cost = 5000

	# Times for away income
	last_active_time = 0
	now = 0
	elapsed = 0



# bloodline strength perk bools
var bs_perk1: bool = false
var bs_perk2: bool = false
var bs_perk3: bool = false
var bs_perk4: bool = false # ← Expansion unlock


# --- Stats ---
var stats := {
	"clicks": 0,
	"crit_clicks": 0,
	"passive_crits": 0,
	"time_played": 0.0,
	"time_idle": 0.0,
	"upgrades_bought": 0,
	"abdications": 0,
	"authority_total": 0,			# across runs
	"authority_from_clicks": 0,
	"authority_from_passive": 0,
	"highest_click": 0,
	"highest_passive": 0
}

# helpers
func stat_add(key: String, amount) -> void:
	stats[key] = stats.get(key, 0) + amount

func stat_add_time_played(dt: float) -> void:
	stats["time_played"] += dt

func stat_add_time_idle(dt: float) -> void:
	stats["time_idle"] += dt

func stat_set_max(key: String, value) -> void:
	if value > stats.get(key, 0):
		stats[key] = value




#expansion stuff
# --- Expansion (persist across abdications) ---


var troops: int = 0
var conquered: Dictionary = {}	# "region_id": true

# Weight troops toward Bloodline + Upgrades (auth is a light kicker)
const TROOP_W_AUTH := 0.00001	# ~1 per 100k lifetime
const TROOP_W_BS := 8
const TROOP_W_UPG := 2

# Example regions (inner = small, outer = big). Tweak freely.
var regions := {
	"capital": {"name":"Capital","tier":"capital","angle":0,"radius":0,"cost":0,"time":0,"bonus":{}},

	"inner_1": {"name":"Outskirts","tier":"small","angle":-90,"radius":140,"cost":10,"time":5,"bonus":{"passive_mult":1.05}},
	"inner_2": {"name":"Canals","tier":"small","angle":-30,"radius":140,"cost":12,"time":5,"bonus":{"auth_per_click":2}},
	"inner_3": {"name":"Workshops","tier":"small","angle":30,"radius":140,"cost":14,"time":6,"bonus":{"passive_income":2}},
	"inner_4": {"name":"Old Quarter","tier":"small","angle":90,"radius":140,"cost":16,"time":6,"bonus":{"crit_chance":0.005}},
	"inner_5": {"name":"Granary","tier":"small","angle":150,"radius":140,"cost":18,"time":6,"bonus":{"passive_mult":1.05}},
	"inner_6": {"name":"Gate Ward","tier":"small","angle":210,"radius":140,"cost":20,"time":7,"bonus":{"auth_per_click":3}},

	"outer_1": {"name":"Northern League","tier":"large","angle":-60,"radius":240,"cost":120,"time":30,"bonus":{"passive_mult":1.15}},
	"outer_2": {"name":"River Principality","tier":"large","angle":0,"radius":240,"cost":140,"time":35,"bonus":{"auth_per_click":15}},
	"outer_3": {"name":"Salt Empire","tier":"large","angle":60,"radius":240,"cost":160,"time":40,"bonus":{"crit_mult":1}},
	"outer_4": {"name":"Ash Dominion","tier":"large","angle":180,"radius":240,"cost":180,"time":45,"bonus":{"passive_income":8}}
}

func calc_troops() -> int:
	var upgrades_bought := 0
	if typeof(stats) == TYPE_DICTIONARY:
		upgrades_bought = int(stats.get("upgrades_bought", 0))
	return int(lifetime_authority * TROOP_W_AUTH
		+ total_bloodline_strength * TROOP_W_BS
		+ upgrades_bought * TROOP_W_UPG)

func refresh_troops() -> void:
	troops = calc_troops()







func _stamp_last_active() -> void:
	Global.last_active_time = Time.get_unix_time_from_system()
	SaveManager.save()
#on alt+f4 or close
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_stamp_last_active() #this also saves
