extends Control

@onready var liste_des_coeurs: HBoxContainer = $Resources/Life
@onready var liste_drink: HBoxContainer = $Resources/Drink
@onready var liste_food: HBoxContainer = $Resources/Food
@onready var money: Label = $Items/Items/Money
@onready var nom_joueur: Label = $NomJoueur
@onready var keypad: Node2D = $Keypad

@export var actual_profil = "1"

func _ready():
	DatabaseConfig.db_ready.connect(preparer_la_synchronisation)

func preparer_la_synchronisation():
	var link = "profils/ID" + actual_profil
	print(link)
	var db_profil = Firebase.Database.get_database_reference(link)
	
	db_profil.new_data_update.connect(_on_donnees_recues)
	db_profil.patch_data_update.connect(_on_donnees_patch)

func _on_donnees_recues(donnees):
	var resultat = donnees.data if donnees is FirebaseResource else donnees
	var cle_recue = donnees.key if donnees is FirebaseResource else ""

	# Gestion si dictionnaire (chargement complet)
	if typeof(resultat) == TYPE_DICTIONARY:
		if resultat.has("Vie"): update_coeurs(int(resultat["Vie"]))
		if resultat.has("Nourriture"): update_food(int(resultat["Nourriture"]))
		if resultat.has("Boisson"): update_drink(int(resultat["Boisson"]))
		if resultat.has("Argent"): update_money(int(resultat["Argent"]))
		if resultat.has("Nom"): nom_joueur.text = str(resultat["Nom"])
	
	# Gestion si valeur seule (comportement observé dans tes logs)
	else:
		_appliquer_donnee(cle_recue, resultat)
	
func _on_donnees_patch(donnees):
	_appliquer_donnee(donnees.key, donnees.data)

# Fonction interne pour éviter de répéter le match dans patch et recues
func _appliquer_donnee(cle: String, valeur):
	match cle:
		"Vie": update_coeurs(int(valeur))
		"Nourriture": update_food(int(valeur))
		"Boisson": update_drink(int(valeur))
		"Argent": update_money(int(valeur))
		"Nom": nom_joueur.text = str(valeur)

# --- FONCTIONS DE MISE À JOUR VISUELLE ---

func update_coeurs(nombre):
	DatabaseConfig.life_local = int(nombre)
	var enfants = liste_des_coeurs.get_children()
	for i in range(enfants.size()):
		enfants[i].modulate = Color(1, 0, 0.3) if i < int(nombre) else Color(0, 0, 0)

func update_food(nombre):
	DatabaseConfig.food_local = int(nombre)
	var enfants = liste_food.get_children()
	for i in range(enfants.size()):
		enfants[i].modulate = Color(1, 0, 0.3) if i < int(nombre) else Color(0, 0, 0)

func update_drink(nombre):
	var n = int(nombre)
	DatabaseConfig.drink_local = n 

	var enfants = liste_drink.get_children()
	for i in range(enfants.size()):
		enfants[i].modulate = Color(1, 0, 0.3) if i < n else Color(0, 0, 0)
	print("Synchro DatabaseConfig effectuée. Nouvelle base : ", n)
	
func update_money(gold):
	money.text = str(gold)
	DatabaseConfig.money_local = int(gold)

func _on_keypad_open_pressed() -> void:
	keypad.show()
