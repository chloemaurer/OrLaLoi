extends Control

var foods = [
	preload("uid://uquodl1cy3my"), preload("uid://03gr4lta6i66"),
	preload("uid://fcengsh4b1qa"), preload("uid://qiism03hwew0"), 
	preload("uid://b3wf0jsr51id"), preload("uid://wvsewo06pnvq")
]

@onready var food_roller: TextureRect = $VBoxContainer/FoodRoller
@onready var food_name: Label = $VBoxContainer/FoodName
@onready var food_description: Label = $VBoxContainer/FoodDescription
@onready var timer: Timer = $Timer

var catalogue = {}  
var current_id = 0  

func _ready() -> void:
	random_food()
	# Note: On ne se connecte plus ici, c'est le Dispatcher qui enverra les infos.

# Cette fonction est appelée par le Dispatcher dans DatabaseConfig
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
	else:
		food_name.text = "Chargement..."
		food_description.text = "Synchronisation..."

func update_food():
	var key = "ID" + str(current_id)
	if catalogue.has(key):
		var data = catalogue[key] 
		var food_effect = data.get("effet", 0)
		var id_joueur = DatabaseConfig.current_profil_id
		
		# On définit le prix (cohérent avec le saloon)
		var prix_food = 1
		
		print("Achat nourriture : Essai pour Profil ", id_joueur)
		
		# 1. On tente de retirer l'argent d'abord
		var succes = DatabaseConfig.spend_money(prix_food, id_joueur)

		if succes:
			print("Achat validé. Application de l'effet : ", food_effect)
			# 2. Si l'argent est débité, on donne la nourriture
			DatabaseConfig.get_food(food_effect, id_joueur)
			
			# 3. ON COMPTE L'ACTION ICI
			timer.start()
				
			# On change de nourriture pour le prochain achat
			random_food()
		else:
			print("Achat échoué : Pas assez d'argent")

func _on_food_buy_card_pressed() -> void:
	update_food()
	timer.start()
	#DatabaseConfig.actions_faites += 1
	## On demande au script principal de vérifier si on doit fermer les places
	#if DatabaseConfig.script_general:
		#DatabaseConfig.script_general.verifier_limite_actions()
		


func _on_timer_timeout() -> void:
	DatabaseConfig.actions_faites += 1
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.verifier_limite_actions()
