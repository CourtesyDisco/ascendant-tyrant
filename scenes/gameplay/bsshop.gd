extends BoxContainer

@onready var p_1: TextureButton = $tiers/t1panel/t1/p1
@onready var p_2: TextureButton = $tiers/t2panel/t2/p2
@onready var p_3: TextureButton = $tiers/t2panel/t2/p3
@onready var p_4: TextureButton = $tiers/t3panel/t3/p4

func _ready():
	p_1.disabled = Global.bs_perk1
	p_2.disabled = Global.bs_perk2 or Global.bs_perk3
	p_3.disabled = Global.bs_perk3 or Global.bs_perk2

func _on_p_1_pressed() -> void:
	if Global.bloodline_strength >= 1 and not Global.bs_perk1:
		Global.bloodline_strength -= 1
		Global.bs_perk1 = true
		p_1.disabled = true
		Global.save()

func _on_p_2_pressed() -> void:
	if Global.bloodline_strength >= 10 and not Global.bs_perk2 and not Global.bs_perk3:
		Global.bloodline_strength -= 10
		Global.bs_perk2 = true
		p_2.disabled = true
		p_3.disabled = true
		Global.save()

func _on_p_3_pressed() -> void:
	if Global.bloodline_strength >= 10 and not Global.bs_perk3 and not Global.bs_perk2:
		Global.bloodline_strength -= 10
		Global.bs_perk3 = true
		p_2.disabled = true
		p_3.disabled = true
		Global.save()
