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
	DatabaseConfig.db_ready.connect(ecouter_le_saloon)

func ecouter_le_saloon() -> void:
	print("Connexion au dossier Saloon...")
	var db_saloon = Firebase.Database.get_database_reference("saloon")
	
	db_saloon.new_data_update.connect(_on_saloon_data)
	db_saloon.patch_data_update.connect(_on_saloon_data)
	
	# Au lieu de get_data() qui crash, on attend un tout petit peu
	await get_tree().create_timer(1.0).timeout
	db_saloon.get_data() 

func _on_saloon_data(resource: FirebaseResource) -> void:
	# Si c'est le dictionnaire complet
	if resource.key == "saloon":
		catalogue = resource.data
	else:
		catalogue[resource.key] = resource.data
	
	print("Données Saloon reçues !")
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
		drink_description.text = "Effet : " + str(data.get("effet", 0)) + " PV"

func update_drink():
	var key = "ID" + str(current_id)
	if catalogue.has(key):
		var data = catalogue[key] 
		var drink_effect = data.get("effet", 0)
		print("Boisson effet: ", drink_effect)
		var succes = DatabaseConfig.get_drink(drink_effect, "0") 
		if succes:
			print("Achat réussi : +", drink_effect, " boisson(s)")


func _on_buy_card_pressed() -> void:
	update_drink()
