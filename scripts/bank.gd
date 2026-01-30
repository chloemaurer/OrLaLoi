extends Control

@onready var moins: Button = $VBoxContainer/HBoxContainer/moins
@onready var count: Label = $VBoxContainer/HBoxContainer/Count
@onready var plus: Button = $VBoxContainer/HBoxContainer/plus
@onready var prix: Label = $VBoxContainer/HBoxContainer/Prix

var num := 1
var nb_prix := 2

func _on_moins_pressed() -> void:
	prix.modulate = Color(1.0, 0.647, 0.0)
	if num >= 2  :
		num -= 1
		nb_prix -= 1
		count.text = str(num)
		prix.text = str(nb_prix)
	

func _on_plus_pressed() -> void:
	if num <= 2 && nb_prix <= DatabaseConfig.money_local :
		prix.modulate = Color(1.0, 0.647, 0.0)
		num += 1
		nb_prix += 1
		count.text = str(num)
		prix.text = str(nb_prix)
	else :
		prix.modulate = Color.RED


func _on_bank_buy_card_pressed() -> void:
	print("Essai d'acheter pour : ", nb_prix, " gold")

	if nb_prix <= DatabaseConfig.money_local :
		var succes = DatabaseConfig.spend_money(nb_prix, "0")
		if succes:
			print("L'achat a été validé !")
