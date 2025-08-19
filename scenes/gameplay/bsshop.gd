extends BoxContainer

@onready var p_1: TextureButton = $tiers/t1panel/t1/p1
@onready var p_2: TextureButton = $tiers/t2panel/t2/p2
@onready var p_3: TextureButton = $tiers/t2panel/t2/p3
@onready var p_4: TextureButton = $tiers/t3panel/t3/p4

func _ready():
	# Disable if already purchased, or if prerequisites not met
	p_1.disabled = Global.bs_perk1
	p_2.disabled = Global.bs_perk2 or Global.bs_perk3
	p_3.disabled = Global.bs_perk3 or Global.bs_perk2
	p_4.disabled = Global.bs_perk4 or not (Global.bs_perk2 or Global.bs_perk3)

func _on_p_1_pressed() -> void:
	if Global.bloodline_strength >= 1 and not Global.bs_perk1:
		Global.bloodline_strength -= 1
		Global.bs_perk1 = true
		p_1.disabled = true
		SaveManager.save()

func _on_p_2_pressed() -> void:
	if Global.bloodline_strength >= 10 and not Global.bs_perk2 and not Global.bs_perk3:
		Global.bloodline_strength -= 10
		Global.bs_perk2 = true
		p_2.disabled = true
		p_3.disabled = true
		# If p4 prereq met and not yet purchased, enable it
		if not Global.bs_perk4:
			p_4.disabled = false
		SaveManager.save()

func _on_p_3_pressed() -> void:
	if Global.bloodline_strength >= 10 and not Global.bs_perk3 and not Global.bs_perk2:
		Global.bloodline_strength -= 10
		Global.bs_perk3 = true
		p_3.disabled = true
		p_2.disabled = true
		# If p4 prereq met and not yet purchased, enable it
		if not Global.bs_perk4:
			p_4.disabled = false
		SaveManager.save()

func _on_p_4_pressed() -> void:
	# Require 100 bloodline, prereq perk2 OR perk3, and not already owned
	if Global.bloodline_strength >= 100 and (Global.bs_perk2 or Global.bs_perk3) and not Global.bs_perk4:
		Global.bloodline_strength -= 100
		Global.bs_perk4 = true
		p_4.disabled = true
		# At this point you can enable your expansion functionality
		# Global.expansion_enabled = true
		SaveManager.save()
