extends Control

@onready var map: Control = $MarginContainer/VBoxContainer/HSplitContainer/map_wrap/map
@onready var tabs: TabContainer = $MarginContainer/VBoxContainer/HSplitContainer/side/tabs
@onready var troops_label: Label = $MarginContainer/VBoxContainer/HSplitContainer/side/tabs/Troops/troops_label
@onready var troops_desc: RichTextLabel = $MarginContainer/VBoxContainer/HSplitContainer/side/tabs/Troops/troops_desc
@onready var buffs_list: RichTextLabel = $MarginContainer/VBoxContainer/HSplitContainer/side/tabs/Buffs/buffs_list
@onready var btn_menu: Button = $bottom_bar/btn_menu
@onready var btn_game: Button = $bottom_bar/btn_game

var _size_small := Vector2(96, 48)
var _size_large := Vector2(150, 64)
var _size_cap := Vector2(120, 56)

func _ready() -> void:
	# DEBUG: force unlock + sample troops for testing
	Global.bs_perk4 = true
	if Global.troops <= 0:
		Global.total_bloodline_strength = max(Global.total_bloodline_strength, 10)
		if typeof(Global.stats) != TYPE_DICTIONARY:
			Global.stats = {}
			
			
			
	Global.stats["upgrades_bought"] = max(int(Global.stats.get("upgrades_bought", 0)), 20)
	Global.refresh_troops()
	btn_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://main_menu.tscn"))
	btn_game.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/game/clicker_ui.tscn"))

	if Global.bs_perk4:
		Global.refresh_troops()
	SaveManager.save()

	_build_map()
	_refresh_right_panel()

func _build_map() -> void:
	for c in map.get_children():
		c.queue_free()

	var center := map.size * 0.5

	for id in Global.regions.keys():
		var R: Dictionary = Global.regions[id] as Dictionary
		var tier := String(R.get("tier", "small"))
		var btn := Button.new()
		btn.text = String(R.get("name", id))
		btn.focus_mode = Control.FOCUS_NONE
		btn.disabled = Global.conquered.get(id, false)

		match tier:
			"capital":
				btn.custom_minimum_size = _size_cap
			"small":
				btn.custom_minimum_size = _size_small
			"large":
				btn.custom_minimum_size = _size_large
			_:
				btn.custom_minimum_size = _size_small

		var pos := center
		if tier != "capital":
			var radius := float(R.get("radius", 140))
			var ang := deg_to_rad(float(R.get("angle", 0)))
			pos = center + Vector2(cos(ang), sin(ang)) * radius
		btn.position = pos - btn.custom_minimum_size * 0.5

		var cost := int(R.get("cost", 0))
		var time_s := int(R.get("time", 0))
		var time_str := "\nTime: %ds" % time_s if time_s > 0 else ""
		btn.tooltip_text = "%s\nCost: %d troops%s" % [btn.text, cost, time_str]


		btn.pressed.connect(func(): _attempt_conquer(id))
		map.add_child(btn)

func _attempt_conquer(id: String) -> void:
	if Global.conquered.get(id, false):
		return
	var R: Dictionary = Global.regions[id] as Dictionary
	var cost := int(R.get("cost", 0))
	if Global.troops < cost:
		# TODO: play error/beep
		return

	# MVP: instant resolve (timer/progress can come later)
	Global.troops -= cost
	Global.conquered[id] = true
	_apply_bonus(R.get("bonus", {}) as Dictionary)

	SaveManager.save()
	_build_map()
	_refresh_right_panel()

func _apply_bonus(b: Dictionary) -> void:
	if b.has("passive_mult"):
		Global.passive_mult *= float(b["passive_mult"])
	if b.has("auth_per_click"):
		Global.auth_per_click += int(b["auth_per_click"])
	if b.has("crit_chance"):
		Global.crit_chance += float(b["crit_chance"])
	if b.has("passive_income"):
		Global.passive_income += int(b["passive_income"])
	if b.has("crit_mult"):
		Global.crit_mult += int(b["crit_mult"])

func _refresh_right_panel() -> void:
	troops_label.text = "Troops: %d" % Global.troops
	troops_desc.text = "[b]How to get troops[/b]\n• Bloodline Strength (heavy)\n• Upgrades bought (heavy)\n• Lifetime authority (light)"
	buffs_list.text = _format_bonuses()

func _format_bonuses() -> String:
	var out := PackedStringArray()
	for id in Global.conquered.keys():
		if not Global.conquered[id]:
			continue
		var R: Dictionary = Global.regions.get(id, {}) as Dictionary
		var bonus: Dictionary = R.get("bonus", {}) as Dictionary
		out.append("%s — %s" % [String(R.get("name", id)), _bonus_to_text(bonus)])
	return "\n".join(out) if out.size() > 0 else "No buffs yet."

func _bonus_to_text(b: Dictionary) -> String:
	var parts: Array[String] = []
	if b.has("passive_mult"):
		parts.append("+%d%% Passive Mult" % int((float(b["passive_mult"]) - 1.0) * 100.0))
	if b.has("auth_per_click"):
		parts.append("+%d Click" % int(b["auth_per_click"]))
	if b.has("crit_chance"):
		parts.append("+%.1f%% Crit Chance" % (float(b["crit_chance"]) * 100.0))
	if b.has("passive_income"):
		parts.append("+%d Passive" % int(b["passive_income"]))
	if b.has("crit_mult"):
		parts.append("+%d Crit Mult" % int(b["crit_mult"]))
	return ", ".join(parts)
