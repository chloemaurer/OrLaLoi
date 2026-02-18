extends Control

var drinks = [
	preload("uid://defnlcal2s16u"), preload("uid://duq0qpxicvgwe"),
	preload("uid://dbk7n00v8a0jk"), preload("uid://bmbrqc2cdl5cj"), 
	preload("uid://yntx2g58parc"), preload("uid://djpm3liihmd0r")
]

@onready var saloon: Control = $"../Saloon"
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
		var id_joueur = DatabaseConfig.current_profil_id
		
		# On définit le prix ici (1 pièce)
		var prix_boisson = 1
		
		print("Achat boisson : Essai pour Profil ", id_joueur)
		
		# 1. On demande au Singleton de dépenser l'argent
		var succes = DatabaseConfig.spend_money(prix_boisson, id_joueur)

		if succes:
			print("Achat validé. Application de l'effet : ", drink_effect)
			# 2. Si l'argent est retiré, on donne la boisson
			DatabaseConfig.get_drink(drink_effect, id_joueur)
			
		else:
			DatabaseConfig.notifier_erreur("Achat échoué : Pas assez d'argent")
			print("Achat échoué : Fonds insuffisants")

func _on_drink_buy_card_pressed() -> void:
	update_drink()

		

func _on_get_drink_receive_pressed() -> void:
	DatabaseConfig.actions_faites += 1
	self.hide()
	random_drink()
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.verifier_limite_actions()
	if DatabaseConfig.actions_faites < 2:
		saloon.show()
