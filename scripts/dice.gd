extends BaseButton


@onready var roll_dice_animation: AnimationPlayer = $"../SubViewportContainer/SubViewport/Node3D/RollDiceAnimation"
@onready var roll_dice_animation_2: AnimationPlayer = $"../SubViewportContainer/SubViewport/Node3D2/RollDiceAnimation2"

const Getdice = preload("uid://fd3fwqw0llor")
@onready var d_6: Getdice = $"../SubViewportContainer/SubViewport/Node3D/D6"
@onready var d_2: Getdice = $"../SubViewportContainer/SubViewport/Node3D2/D2"
@onready var dice_result_label: Label = $"../DiceResultLabel"
var totalnumber := 0
@onready var places: Node2D = $"../../Places"

	
func roll_dice():
	rerolled()
	d_6.rotate_x(deg_to_rad(randi_range(0, 5) * 90))
	d_6.rotate_z(deg_to_rad(randi_range(0, 5) * 90))
	d_6.rotate_y(deg_to_rad(randi_range(0, 5) * 90))
	
	d_2.rotate_x(deg_to_rad(randi_range(0, 5) * 90))
	d_2.rotate_z(deg_to_rad(randi_range(0, 5) * 90))
	d_2.rotate_y(deg_to_rad(randi_range(0, 5) * 90))
	
	roll_dice_animation_2.play("dice_2")
	roll_dice_animation.play("dice_6")
	
	d_6.get_number()
	d_2.get_number()
	totalnumber = d_2.get_number() + d_6.get_number()


func afficher_resultat(valeur: int):
	# Conversion en texte et affichage
	dice_result_label.text = str(valeur)


#---------------------------------------------------------------------------------
@onready var saloon: Button = $"../../Places/Saloon"
@onready var mine: Button = $"../../Places/Mine"
@onready var restaurant: Button = $"../../Places/Restaurant"
@onready var armory: Button = $"../../Places/Armory"
@onready var bank: Button = $"../../Places/Bank"
@onready var duel: Button = $"../../Places/Duel"

func rerolled() -> void:
	bank.hide()
	saloon.hide()
	mine.hide()
	restaurant.hide()
	duel.hide()
	armory.hide()

func enable_place():
	var manche_actuelle = DatabaseConfig.manches
	match totalnumber:
		2:
			bank.show()
			duel.show()
			if manche_actuelle >= 6:
				mine.show()
				print("Mine débloquée (Manche ", manche_actuelle, ")")
		3:
			bank.show()
			duel.show()
		4:
			duel.show()
			restaurant.show()
		5:
			duel.show()
			restaurant.show()
			saloon.show()
		6:
			duel.show()
			restaurant.show()
			saloon.show()
		7:
			saloon.show()
			restaurant.show()
		8:
			saloon.show()
			restaurant.show()
			armory.show()
		9:
			saloon.show()
			armory.show()
		10:
			armory.show()
		11:
			armory.show()
			bank.show()
		12:
			armory.show()
			bank.show()
			if manche_actuelle >= 6:
				mine.show()
				print("Mine débloquée (Manche ", manche_actuelle, ")")
		_:
			print("unknown DICE NUMBER")

func _on_roll_dice_animation_animation_finished(_anim_name: StringName) -> void:
	places.show()
	afficher_resultat(totalnumber)	
	enable_place()
