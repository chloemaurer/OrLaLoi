extends Node
# Variables
signal db_ready
var db_ref : FirebaseDatabaseReference = null
var is_ready : bool = false
var money_local : int = 0
var life_local : int = 0
var drink_local : int = 0
var food_local : int = 0

func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(_on_FirebaseAuth_login_succeeded)
	Firebase.Auth.login_failed.connect(failed_login)
	Firebase.Auth.login_with_email_and_password("chloe29.maurer@gmail.com", "Yeraci_8")
	
func _on_FirebaseAuth_login_succeeded(_auth):
	print("Firebase est prêt et connecté.")
	db_ref = Firebase.Database.get_database_reference("", {})
	db_ref.new_data_update.connect(_on_db_data_update)
	db_ref.patch_data_update.connect(_on_db_data_update)
	db_ref.delete_data_update.connect(_on_db_data_update)
	db_ready.emit()
	is_ready = true


func failed_login():
	print("Connection failed")
	

func spend_money(montant: int, profil_id: String):
	if money_local >= montant:
		var nouveau_solde = money_local - montant
		var link = "profils/ID" + profil_id
		var db_link = Firebase.Database.get_database_reference(link)
		db_link.update("", {"Argent": nouveau_solde})
		print("Paiement accepté. Nouveau solde : ", nouveau_solde)
		return true
		
	else:
		print("Paiement refusé : fonds insuffisants (actuel:", money_local, ")")
		return false

func lose_life(life: int, profil_id: String):
	if life_local >= life:
		var nouveau_solde = life_local + life
		var link = "profils/ID" + profil_id
		var db_link = Firebase.Database.get_database_reference(link)
		db_link.update("", {"Vie": nouveau_solde})
		print("Vie accepté. Nouveau solde : ", nouveau_solde)
		return true
		
	else:
		print("Vie refusé : fonds insuffisants (actuel:", life_local, ")")
		return false


func get_food(food_a_ajouter: int, profil_id: String):

	var nouveau_total = food_local + food_a_ajouter
	if nouveau_total > 5:
		nouveau_total = 5

	var link = "profils/ID" + profil_id
	var db_link = Firebase.Database.get_database_reference(link)

	db_link.update("", {"Nourriture": nouveau_total})
	
	print("Nourriture acceptée. Ancien: ", food_local, " | Nouveau total: ", nouveau_total, "/5")
	return true


func get_drink(drink_a_ajouter: int, profil_id: String):
	var nouveau_total = drink_local + (drink_a_ajouter)
	
	if nouveau_total > 5:
		nouveau_total = 5
		
	var link = "profils/ID" + profil_id
	
	var db_link = Firebase.Database.get_database_reference(link)
	
	# Mise à jour Firebase
	db_link.update("", {"Boisson": nouveau_total})
	
	print("Ancien stock: ", drink_local, " | Ajout: ", drink_a_ajouter, " | Nouveau: ", nouveau_total)
	return true


func _on_db_data_update(resource):
	var data = resource.data if resource is FirebaseResource else resource

	if typeof(data) == TYPE_DICTIONARY:
		if data.has("profils") and data["profils"].has("ID0"):
			var profil = data["profils"]["ID0"]
			if profil.has("Argent"):
				money_local = int(profil["Argent"])
				print("Argent local mis à jour : ", money_local)
			if profil.has("Vie"):
				life_local = int(profil["Vie"])
				print("Vie local mis à jour : ", life_local)
			if profil.has("Nourriture"):
				food_local = int(profil["Nourriture"])
				print("Nourriture local mis à jour : ", food_local)
			if profil.has("Boisson"):
				drink_local = int(profil["Boisson"])
				print("Boisson local mis à jour : ", drink_local)
