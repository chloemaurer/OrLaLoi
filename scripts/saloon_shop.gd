extends Control

var drinks = [
	preload("uid://defnlcal2s16u"), preload("uid://duq0qpxicvgwe"),
	preload("uid://dbk7n00v8a0jk"), preload("uid://bmbrqc2cdl5cj"), 
	preload("uid://yntx2g58parc"), preload("uid://djpm3liihmd0r")
]

@onready var drink_roller = $VBoxContainer/DrinkRoller
@onready var drink_name = $VBoxContainer/DrinkName
@onready var drink_description = $VBoxContainer/DrinkDescription

var catalogue = {}  
var current_id = 0  

func _ready() -> void:
	random_drink()

func mettre_a_jour_catalogue(cle: String, valeur):
	if cle == "saloon" and typeof(valeur) == TYPE_DICTIONARY:
		catalogue = valeur
	else:
		catalogue[cle] = valeur
	
	print("Saloon mis à jour pour : ", cle)
	actualiser_interface()

func random_drink() -> void:
	current_id = randi() % drinks.size()
	drink_roller.texture = drinks[current_id]
	actualiser_interface()

func actualiser_interface() -> void:
	var key = "ID" + str(current_id)
	if catalogue.has(key):
		var data = catalogue[key]
		drink_name.text = str(data.get("nom", "Inconnu"))
		drink_description.text = "Effet : " + str(data.get("effet", 0)) + " Boisson"

func update_drink():
	var key = "ID" + str(current_id)
	if catalogue.has(key):
		var data = catalogue[key] 
		var drink_effect = data.get("effet", 0)
		
		# Récupération du profil actif au lieu de "0"
		var id_joueur = DatabaseConfig.current_profil_id
		
		print("Achat boisson pour Profil ", id_joueur, " | Effet : ", drink_effect)
		
		# On envoie l'effet au DatabaseConfig
		var succes = DatabaseConfig.get_drink(drink_effect, id_joueur) 
		
		if succes:
			print("Achat validé en base de données.")

func _on_buy_card_pressed() -> void:
	update_drink()
