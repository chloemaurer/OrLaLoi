extends Control

var foods = [
	preload("uid://uquodl1cy3my"), preload("uid://03gr4lta6i66"),
	preload("uid://fcengsh4b1qa"), preload("uid://qiism03hwew0"), 
	preload("uid://b3wf0jsr51id"), preload("uid://wvsewo06pnvq")
]

@onready var food_roller: TextureRect = $VBoxContainer/FoodRoller
@onready var food_name: Label = $VBoxContainer/FoodName
@onready var food_description: Label = $VBoxContainer/FoodDescription
@onready var restaurant: Control = $"../Restaurant"

var catalogue = {}  
var current_id = 0  

func _ready() -> void:
	random_food()

func mettre_a_jour_catalogue(cle: String, valeur):
	if cle == "restaurant" and typeof(valeur) == TYPE_DICTIONARY:
		catalogue = valeur
	else:
		catalogue[cle] = valeur
	
	print("Restaurant mis à jour pour : ", cle)
	actualiser_interface()

func random_food() -> void:
	current_id = randi() % foods.size()
	food_roller.texture = foods[current_id]
	actualiser_interface()

func actualiser_interface() -> void:
	var key = "ID" + str(current_id)
	if catalogue.has(key):
		var data = catalogue[key]
		food_name.text = str(data.get("nom", "Inconnu"))
		food_description.text = "Effet : " + str(data.get("effet", 0)) + " Nourriture"

func update_food():
	var key = "ID" + str(current_id)
	if catalogue.has(key):
		var data = catalogue[key] 
		var food_effect = data.get("effet", 0)
		var id_joueur = DatabaseConfig.current_profil_id
		
		# On définit le prix ici (1 pièce)
		var prix_food = 1
		
		print("Achat nourriture : Essai pour Profil ", id_joueur)
		
		# 1. On demande au Singleton de dépenser l'argent
		var succes = DatabaseConfig.spend_money(prix_food, id_joueur)

		if succes:
			print("Achat validé. Application de l'effet : ", food_effect)
			# 2. Si l'argent est retiré, on donne la nourriture
			DatabaseConfig.get_food(food_effect, id_joueur)

		else:
			DatabaseConfig.notifier_erreur("Achat échoué : Pas assez d'argent")
			print("Achat échoué : Fonds insuffisants")

func _on_food_buy_card_pressed() -> void:
	update_food()



func _on_get_food_receive_pressed() -> void:
	DatabaseConfig.actions_faites += 1
	self.hide()
	random_food()
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.verifier_limite_actions()
	if DatabaseConfig.actions_faites < 2:
		restaurant.show()
