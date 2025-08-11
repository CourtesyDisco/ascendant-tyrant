extends Control


#audio links
const SFX_CLICK := preload("res://assets/audio/click.ogg")
const SFX_AUTH  := preload("res://assets/audio/authorityclick.wav")

#player stats
var lifetime_authority = 0
var authority = 0
var auth_per_click = 1
var passive_income = 0
var passive_mult = 1
var crit_chance = .05
var crit_mult = 3
var first_time: bool = true
var time_idle: float = 0.0


#bloodline
var bloodline_strength = 0
var total_bloodline_strength = 0

#upgrade levels and cost
var upgrade_passive_level = 0
var upgrade_passive_cost = 50

var upgrade_passive_2_level = 0
var upgrade_passive_2_cost = 750

var upgrade_click_level = 0
var upgrade_click_cost = 10

var upgrade_click_2_level = 0
var upgrade_click_2_cost = 500

var upgrade_crit_chance_level = 0
var upgrade_crit_chance_cost = 2000

var upgrade_crit_mult_level = 0
var upgrade_crit_mult_cost = 5000

#rumours.txt scroller on bottom of screen
var rumours = []
var current_rumour = 0
var typewriter_text = ""
var typewriter_index = 0


@onready var rumourslabel: RichTextLabel = $rumours/rumourslabel
@onready var authoritylabel: Label = $clicker/authoritylabel
@onready var passivetimer: Timer = $idleincome/passivetimer
@onready var passivelabel: RichTextLabel = $idleincome/passivedisplay/passivelabel
@onready var passivebar: ProgressBar = $idleincome/passivedisplay/passivebar
@onready var upgradeclick: Button = $upgrades/upgradeclick
@onready var upgradepassive: Button = $upgrades/upgradepassive
@onready var upgradeclick_2: Button = $upgrades/upgradeclick2
@onready var upgradepassive_2: Button = $upgrades/upgradepassive2
@onready var upgradecritchance: Button = $upgrades/upgradecritchance
@onready var upgradecritmult: Button = $upgrades/upgradecritmult
@onready var away_popup = $idleincome/awaypopup
@onready var away_label = $idleincome/awaypopup/awaylabel
@onready var holdtoclick: Timer = $clicker/getauthority/holdtoclick
@onready var bsbutton: Button = $bloodline/bsbutton
@onready var abdicate: Button = $bloodline/abdicate
@onready var bsstrength: Label = $bloodline/bsstrength
@onready var bsshoppanel: PopupPanel = $bloodline/bsshoppanel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicManager.play_music(preload("res://assets/audio/gamebgm.wav"))
	SaveManager.load()

	# load locals from Global
	first_time = Global.first_time
	lifetime_authority = Global.lifetime_authority
	authority = Global.authority
	auth_per_click = Global.auth_per_click
	passive_income = Global.passive_income
	passive_mult = Global.passive_mult
	crit_chance = Global.crit_chance
	crit_mult = Global.crit_mult
	bloodline_strength = Global.bloodline_strength
	total_bloodline_strength = Global.total_bloodline_strength
	upgrade_passive_level = Global.upgrade_passive_level
	upgrade_passive_cost = Global.upgrade_passive_cost
	upgrade_passive_2_level = Global.upgrade_passive_2_level
	upgrade_passive_2_cost = Global.upgrade_passive_2_cost
	upgrade_click_level = Global.upgrade_click_level
	upgrade_click_cost = Global.upgrade_click_cost
	upgrade_click_2_level = Global.upgrade_click_2_level
	upgrade_click_2_cost = Global.upgrade_click_2_cost
	upgrade_crit_chance_level = Global.upgrade_crit_chance_level
	upgrade_crit_chance_cost = Global.upgrade_crit_chance_cost
	upgrade_crit_mult_level = Global.upgrade_crit_mult_level
	upgrade_crit_mult_cost = Global.upgrade_crit_mult_cost

	load_rumours()
	cycle_rumour()
	$rumours/rumourstimer.start()

	# first run ever? start the clock and clear the flag (both global and local)
	if Global.first_time:
		Global.first_time = false
		first_time = false
		Global.last_active_time = Time.get_unix_time_from_system()
		SaveManager.save_soon()
	else:
		away()	# away() will show/hide the popup itself
	update_ui()











# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_idle += delta
	Global.stat_add_time_played(delta)
	if time_idle > 0.0:
		Global.stat_add_time_idle(delta)
	if passive_income > 0:
		var elapsed = passivetimer.time_left
		passivebar.value = passivebar.max_value - elapsed
	else:
		passivebar.value = 0




func update_ui():
	# example: authority_label.text = "Authority: %d" % authority
	# also use this for showing hidden upgrades e.g.;
		#if upgrade_passive_level >=10:
			#upgrade_passive_2.visible = true
			#upgrade_passive_2.text = "Effigy (big passive) - Lv %d (Cost: %d)" %d [var, var2]

	authoritylabel.text = "Authority: " + Numberformatter.format(authority)
	#passivelabel.text = "Passive Authority: %d" % passive_income
	upgradeclick.text = "Tighten Grip - Lv. %d (Cost: %d)" % [upgrade_click_level, upgrade_click_cost]
	upgradepassive.text = "Hire Enforcers - Lv. %d (Cost: %d)" % [upgrade_passive_level, upgrade_passive_cost]
	bsstrength.text = "Bloodline Strength: %d" % Global.bloodline_strength
	update_stats_display()
	
	#shows hidden upgrades on level requirement
	if upgrade_click_level >= 10:
		upgradeclick_2.visible = true
		upgradeclick_2.text = "Break Their Will - Lv. %d (Cost: %d)" % [upgrade_click_2_level, upgrade_click_2_cost]
	else:
		upgradeclick_2.visible = false
	if upgrade_passive_level >= 10:
		upgradepassive_2.visible = true
		upgradepassive_2.text = "Mandate Loyalty - Lv. %d (Cost: %d)" % [upgrade_passive_2_level, upgrade_passive_2_cost]
	else:
		upgradepassive_2.visible = false
	if upgrade_click_2_level >= 5:
		upgradecritchance.visible = true
		upgradecritchance.text = "Exploit Fear - Lv. %d (Cost: %d)" % [upgrade_crit_chance_level, upgrade_crit_chance_cost]
	else:
		upgradecritchance.visible = false
	if upgrade_crit_chance_level >= 2:
		upgradecritmult.visible = true
		upgradecritmult.text = "Hammer The Point - Lv. %d (Cost: %d)" % [upgrade_crit_mult_level, upgrade_crit_mult_cost]
	else:
		upgradecritmult.visible = false
	if total_bloodline_strength >= 1:
		bsbutton.visible = true
		bsstrength.visible = true
	if lifetime_authority >= 100000:
		abdicate.visible = true
		
	_refresh_button_states()
		
		
		
func update_stats_display():
	var display_click = auth_per_click
	if Global.bs_perk3:
		display_click += 100
	if Global.bs_perk1:
		display_click *= Global.total_bloodline_strength
	
	var display_passive = passive_income * passive_mult
	if Global.bs_perk1:
		display_passive *= Global.total_bloodline_strength
	if Global.bs_perk2:
		display_passive *= 4
		
	var passive_text = "Passive Authority: %d" % display_passive
	if Global.bs_perk2 and time_idle >= 30.0:
		passive_text += " (Idle)"
	$statdisplay/margin/statslabel.text = """
[b]Stats:[/b]
Authority per click: [color=yellow]%d[/color]
Crit Chance: [color=yellow]%.2f%%[/color]
Crit Multiplier: [color=yellow]%d[/color]
Lifetime Authority: [color=yellow]%d[/color]
""" % [display_click, crit_chance * 100.0, crit_mult, lifetime_authority]

	authoritylabel.text = "Authority: " + Numberformatter.format(authority)
	passivelabel.text = passive_text
	upgradeclick.text = "Tighten Grip - Lv. %d (Cost: %d)" % [upgrade_click_level, upgrade_click_cost]
	upgradepassive.text = "Hire Enforcers - Lv. %d (Cost: %d)" % [upgrade_passive_level, upgrade_passive_cost]
	
	

#floating text on click showing income

@onready var floating_text_scene = preload("res://scenes/misc/FloatingText.tscn")
func show_floating_text(amount_text: String, is_crit: bool):
	var text = floating_text_scene.instantiate()
	text.text = amount_text 
	text.position = get_viewport().get_mouse_position()

	if is_crit:
		text.modulate = Color(1, 0.4, 0.2) 
		text.scale = Vector2(1.3, 1.3)

	add_child(text)


#runs rumours at bottom of screen
func load_rumours():
	if not FileAccess.file_exists("res://data/rumours.txt"):
		push_warning("rumours.txt not found!")
		return
	var file = FileAccess.open("res://data/rumours.txt", FileAccess.READ)
	while file.get_position() < file.get_length():
		var line = file.get_line()
		if line.strip_edges() != "":
			rumours.append(line.strip_edges())
	file.close()
func cycle_rumour():
	if rumours.size() > 0:
		# Pick a random index, different from the current one
		var new_index = randi() % rumours.size()
		while new_index == current_rumour and rumours.size() > 1:
			new_index = randi() % rumours.size()

		current_rumour = new_index
		typewriter_text = rumours[current_rumour]
		typewriter_index = 0
		rumourslabel.text = ""
		$rumours/typewritertimer.start()
#makes rumours appear gradually
func _on_typewriter_timer_timeout():
	if typewriter_index < typewriter_text.length():
		rumourslabel.text += typewriter_text[typewriter_index]
		typewriter_index += 1
	else:
		$rumours/typewritertimer.stop()
	


#navigation
func _on_backtomenu_pressed() -> void:
	MusicManager.play_sfx(SFX_CLICK)
	_stamp_last_active()
	get_tree().change_scene_to_file("res://main_menu.tscn")
	
func _on_gotooptions_pressed() -> void:
	MusicManager.play_sfx(SFX_CLICK)
	_stamp_last_active()
	get_tree().change_scene_to_file("res://scenes/misc/options.tscn")








#rounds floats to int (for upgrade costs)
func _bump_cost(cost: int, mult: float) -> int:
	return int(ceil(cost * mult))

#these sync stats to global when called
func _sync_core() -> void:
	Global.lifetime_authority = lifetime_authority
	Global.authority = authority
	Global.auth_per_click = auth_per_click
	Global.passive_income = passive_income
	Global.passive_mult = passive_mult
	Global.crit_chance = crit_chance
	Global.crit_mult = crit_mult

func _sync_upgrades() -> void:
	Global.upgrade_passive_level = upgrade_passive_level
	Global.upgrade_passive_cost = upgrade_passive_cost
	Global.upgrade_passive_2_level = upgrade_passive_2_level
	Global.upgrade_passive_2_cost = upgrade_passive_2_cost
	Global.upgrade_click_level = upgrade_click_level
	Global.upgrade_click_cost = upgrade_click_cost
	Global.upgrade_click_2_level = upgrade_click_2_level
	Global.upgrade_click_2_cost = upgrade_click_2_cost
	Global.upgrade_crit_chance_level = upgrade_crit_chance_level
	Global.upgrade_crit_chance_cost = upgrade_crit_chance_cost
	Global.upgrade_crit_mult_level = upgrade_crit_mult_level
	Global.upgrade_crit_mult_cost = upgrade_crit_mult_cost
#away / afk income
func _stamp_last_active() -> void:
	Global.last_active_time = Time.get_unix_time_from_system()
	SaveManager.save_soon()
	
func calculate_away_income(elapsed: int):
	var income = elapsed * passive_income * passive_mult * 0.5
	if Global.bs_perk1:
		income *= Global.total_bloodline_strength
	if Global.bs_perk2:
		income *= 4
	return int(income)

func away() -> void:
	var now_i: int = int(Time.get_unix_time_from_system())
	var last_i: int = Global.last_active_time
	var elapsed_i: int = max(0, now_i - last_i)

	Global.last_active_time = now_i
	SaveManager.save()  

	if elapsed_i <= 0:
		away_popup.hide()
		away_label.hide()
		return

	var income: int = calculate_away_income(elapsed_i)
	authority += income
	lifetime_authority += income
	_sync_core()
	SaveManager.save_soon()

	away_label.text = "While away (%ds), you earned %d Authority." % [elapsed_i, income]
	away_popup.show()
	away_label.show()

		
func _on_awaypopup_close_requested() -> void:
	away_popup.hide()
	away_label.hide()
	





func _on_getauthority_pressed() -> void:
	MusicManager.play_sfx(SFX_AUTH)
	time_idle = 0.0

	var gain: int = auth_per_click
	var crit: bool = false
	var crit_mult_eff: int = crit_mult * (3 if Global.bs_perk3 else 1)

	# Perk 3 adds flat +100 to click
	if Global.bs_perk3:
		gain += 100

	# Crit roll
	if randf() < crit_chance:
		gain *= crit_mult_eff
		crit = true

	# Perk 1 global mult
	if Global.bs_perk1:
		gain *= Global.total_bloodline_strength

	authority += gain
	lifetime_authority += gain

	# stats
	Global.stat_add("clicks", 1)
	if crit:
		Global.stat_add("crit_clicks", 1)
	Global.stat_add("authority_total", gain)
	Global.stat_add("authority_from_clicks", gain)
	Global.stat_set_max("highest_click", gain)

	show_floating_text("%d" % gain, crit)
	update_ui()
	_sync_core()
	SaveManager.save_soon()



#hold to click income
func _on_getauthority_button_down():
	holdtoclick.start()
func _on_getauthority_button_up():
	holdtoclick.stop()
func _on_holdtoclick_timeout():
	_on_getauthority_pressed()



func _on_passivetimer_timeout():
	if passive_income > 0:
		var income: float = passive_income * passive_mult
		var crit: bool = false

		# Perk 1: global multiplier
		if Global.bs_perk1:
			income *= Global.total_bloodline_strength

		# Perk 2: 4x passive; can crit if idle >= 30s
		if Global.bs_perk2:
			income *= 4
			if time_idle >= 30.0 and randf() < crit_chance:
				income *= crit_mult
				crit = true

		# Perk 3: halves passive
		if Global.bs_perk3:
			income *= 0.5

		var income_i: int = int(income)

		authority += income_i
		lifetime_authority += income_i

		# stats
		Global.stat_add("authority_total", income_i)
		Global.stat_add("authority_from_passive", income_i)
		if crit:
			Global.stat_add("passive_crits", 1)
		Global.stat_set_max("highest_passive", income_i)

		if crit:
			# Floating text
			show_floating_text("%d (Crit!)" % income_i, true)

			# Flash label
			var original_label := passivelabel.modulate
			passivelabel.modulate = Color(1, 0.4, 0.2)
			await get_tree().create_timer(0.2).timeout
			passivelabel.modulate = original_label

			# Pulse bar
			var original_scale := passivebar.scale
			passivebar.scale = original_scale * 1.2
			await get_tree().create_timer(0.15).timeout
			passivebar.scale = original_scale

		update_ui()
		_sync_core()
		SaveManager.save_soon()


#disables buttons if unaffordable (ran in update_ui)
func _refresh_button_states() -> void:
	upgradeclick.disabled       = authority < upgrade_click_cost
	upgradepassive.disabled     = authority < upgrade_passive_cost
	upgradeclick_2.disabled     = authority < upgrade_click_2_cost
	upgradepassive_2.disabled   = authority < upgrade_passive_2_cost
	upgradecritchance.disabled  = authority < upgrade_crit_chance_cost
	upgradecritmult.disabled    = authority < upgrade_crit_mult_cost

#upgrades
func _on_upgradeclick_pressed() -> void:
	MusicManager.play_sfx(SFX_CLICK)
	if authority >= upgrade_click_cost:
		authority -= upgrade_click_cost
		auth_per_click += 1
		upgrade_click_level += 1
		upgrade_click_cost = _bump_cost(upgrade_click_cost, 1.30)
		Global.stat_add("upgrades_bought", 1)
		update_ui()
		_sync_upgrades()
		_sync_core()
		SaveManager.save_soon()

func _on_upgradepassive_pressed() -> void:
	MusicManager.play_sfx(SFX_CLICK)
	if authority >= upgrade_passive_cost:
		authority -= upgrade_passive_cost
		passive_income += 3
		upgrade_passive_level += 1
		upgrade_passive_cost    = _bump_cost(upgrade_passive_cost, 1.30)
		Global.stat_add("upgrades_bought", 1)
		update_ui()
		_sync_upgrades()
		_sync_core()
		SaveManager.save_soon()
		

func _on_upgradeclick_2_pressed() -> void:
	MusicManager.play_sfx(SFX_CLICK)
	if authority >= upgrade_click_2_cost:
		authority -= upgrade_click_2_cost
		auth_per_click += 10
		upgrade_click_2_level += 1
		upgrade_click_2_cost    = _bump_cost(upgrade_click_2_cost, 1.30)
		Global.stat_add("upgrades_bought", 1)
		update_ui()
		_sync_upgrades()
		_sync_core()
		SaveManager.save_soon()
		
func _on_upgradepassive_2_pressed() -> void:
	MusicManager.play_sfx(SFX_CLICK)
	if authority >= upgrade_passive_2_cost:
		authority -= upgrade_passive_2_cost
		passive_mult *= 2
		upgrade_passive_2_level += 1
		upgrade_passive_2_cost  = _bump_cost(upgrade_passive_2_cost, 5.00)
		Global.stat_add("upgrades_bought", 1)
		update_ui()
		_sync_upgrades()
		_sync_core()
		SaveManager.save_soon()

func _on_upgradecritchance_pressed() -> void:
	MusicManager.play_sfx(SFX_CLICK)
	if authority >= upgrade_crit_chance_cost:
		authority -= upgrade_crit_chance_cost
		crit_chance += .02
		upgrade_crit_chance_level += 1
		upgrade_crit_chance_cost= _bump_cost(upgrade_crit_chance_cost, 10.0)
		Global.stat_add("upgrades_bought", 1)
		update_ui()
		_sync_upgrades()
		_sync_core()
		SaveManager.save_soon()
		
func _on_upgradecritmult_pressed() -> void:
	MusicManager.play_sfx(SFX_CLICK)
	if authority >= upgrade_crit_mult_cost:
		authority -= upgrade_crit_mult_cost
		crit_mult += 1
		upgrade_crit_mult_level += 1
		upgrade_crit_mult_cost  = _bump_cost(upgrade_crit_mult_cost, 10.0)
		Global.stat_add("upgrades_bought", 1)
		update_ui()
		_sync_upgrades()
		_sync_core()
		SaveManager.save_soon()



#bloodline stuff

func can_prestige() -> bool:
	return lifetime_authority >= 100000 # requires this much lifetime authority to prestige.
	
func calculate_bloodline_strength() -> int:
	return int(lifetime_authority / 100000)  # 1 bloodline per 100k lifetime

func _on_abdicate_pressed() -> void:
	MusicManager.play_sfx(SFX_CLICK)
	if not can_prestige():
		print("Not enough lifetime authority to prestige.")
		return
	$bloodline/abdicateconfirm.popup_centered()
func _on_abdicateconfirm_confirmed():
	MusicManager.play_sfx(SFX_CLICK)
	var gained = calculate_bloodline_strength()
	Global.total_bloodline_strength += gained
	Global.bloodline_strength += gained
	total_bloodline_strength = Global.total_bloodline_strength
	bloodline_strength = Global.bloodline_strength
	Global.stat_add("abdications", 1)
	
	#reset global state
	Global.lifetime_authority = 0
	Global.authority = 0
	Global.auth_per_click = 1
	Global.passive_income = 0
	Global.passive_mult = 1
	Global.crit_chance = .05
	Global.crit_mult = 3
	Global.upgrade_passive_level = 0
	Global.upgrade_passive_cost = 50
	Global.upgrade_passive_2_level = 0
	Global.upgrade_passive_2_cost = 750
	Global.upgrade_click_level = 0
	Global.upgrade_click_cost = 10
	Global.upgrade_click_2_level = 0
	Global.upgrade_click_2_cost = 500
	Global.upgrade_crit_chance_level = 0
	Global.upgrade_crit_chance_cost = 2000
	Global.upgrade_crit_mult_level = 0
	Global.upgrade_crit_mult_cost = 5000
	var last_active_time = Time.get_unix_time_from_system()
	Global.last_active_time = last_active_time
	Global.elapsed = 0
	Global.now = 0
	#Global.first_time = true
	#reset current stats
	
	Global.reset_stats_abdicate()
	SaveManager.save_soon()
	get_tree().reload_current_scene()
	print(total_bloodline_strength)
	
func _on_bsbutton_pressed():
	bsshoppanel.show()
	
	
	
	
	
	
#debug/cheat
func _on_cheat_pressed() -> void:
	authority += 100000
	lifetime_authority += 100000
	update_ui()
	_sync_core()
	SaveManager.save_soon()
