extends Control

var foods = [
	preload("uid://uquodl1cy3my"), preload("uid://03gr4lta6i66"),
	preload("uid://fcengsh4b1qa"), preload("uid://qiism03hwew0"), 
	preload("uid://b3wf0jsr51id"), preload("uid://wvsewo06pnvq")
]

@onready var food_roller: TextureRect = $VBoxContainer/FoodRoller
@onready var food_name: Label = $VBoxContainer/FoodName
@onready var food_description: Label = $VBoxContainer/FoodDescription


var catalogue = {}  
var current_id = 0  

func _ready() -> void:
	random_food()
	
	if DatabaseConfig.is_ready:
		ecouter_le_restaurant()
	else:
		DatabaseConfig.db_ready.connect(ecouter_le_restaurant)

func ecouter_le_restaurant() -> void:
	print("Connexion au dossier restaurant...")

	var db_restaurant = Firebase.Database.get_database_reference("restaurant")
	
	db_restaurant.new_data_update.connect(_on_restaurant_data)
	db_restaurant.patch_data_update.connect(_on_restaurant_data)
	
	# Au lieu de get_data() qui crash, on attend un tout petit peu
	await get_tree().create_timer(1.0).timeout
	db_restaurant.get_data() 

func _on_restaurant_data(resource: FirebaseResource) -> void:
	# Si c'est le dictionnaire complet
	if resource.key == "restaurant":
		catalogue = resource.data
	else:
		catalogue[resource.key] = resource.data
	
	print("Données restaurant reçues !")
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
		food_description.text = "Effet : " + str(data.get("effet", 0)) + " PV"
	else:
		food_name.text = "Chargement..."
		food_description.text = "Synchronisation..."

func update_food():
	var key = "ID" + str(current_id)
	if catalogue.has(key):
		var data = catalogue[key] 
		var food_effect = data.get("effet", 0)
		var succes = DatabaseConfig.get_food(food_effect, "0") 
		if succes:
			print("Achat réussi : +", food_effect, " boisson(s)")


func _on_food_buy_card_pressed() -> void:
	update_food()
