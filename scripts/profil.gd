extends Control

@onready var liste_des_coeurs: HBoxContainer = $Resources/Life
@onready var liste_drink: HBoxContainer = $Resources/Drink
@onready var liste_food: HBoxContainer = $Resources/Food
@onready var money: Label = $Items/Items/Money
@onready var nom_joueur: Label = $NomJoueur
@onready var keypad: Node2D = $Keypad

@export var actual_profil ="0"
@onready var profils: Node = $".."

func _ready():
	DatabaseConfig.db_ready.connect(preparer_la_synchronisation)


func preparer_la_synchronisation():
	var link = "profils/ID" + actual_profil
	print(link)
	var db_profil = Firebase.Database.get_database_reference(link)
	
	db_profil.new_data_update.connect(_on_donnees_recues)
	db_profil.patch_data_update.connect(_on_donnees_modifier)

	
func _on_donnees_recues(donnees):
	_traiter_donnees(donnees)

func _on_donnees_modifier(donnees):
	_traiter_donnees(donnees)

# Une seule fonction pour tout gérer proprement
func _traiter_donnees(donnees):
	var resultat = donnees.data if donnees is FirebaseResource else donnees
	var cle_recue = donnees.key if donnees is FirebaseResource else ""

	# CAS 1 : On reçoit tout le profil d'un coup (Dictionnaire)
	if typeof(resultat) == TYPE_DICTIONARY:
		if resultat.has("Vie"): update_coeurs(resultat["Vie"])
		if resultat.has("Nourriture"): update_food(resultat["Nourriture"])
		if resultat.has("Boisson"): update_drink(resultat["Boisson"])
		if resultat.has("Argent"): update_money(resultat["Argent"])
		if resultat.has("Nom"): nom_joueur.text = str(resultat["Nom"])
	
	# CAS 2 : On reçoit juste une seule variable modifiée
	else:
		match cle_recue:
			"Vie": update_coeurs(resultat)
			"Nourriture": update_food(resultat)
			"Boisson": update_drink(resultat)
			"Argent": update_money(resultat)
			"Nom": nom_joueur.text = str(resultat)
	
	
func update_coeurs(nombre_de_vie):
	var tous_les_coeurs = liste_des_coeurs.get_children()
	var numero_du_coeur = 0
	
	for coeur in tous_les_coeurs:
		if numero_du_coeur < nombre_de_vie:
			coeur.modulate = Color(1, 0, 0.3) # Rose actif
		else:
			coeur.modulate = Color(0, 0, 0) # Noir vide
		
		numero_du_coeur += 1

	print("Affichage mis à jour : ", nombre_de_vie, " coeurs restants.")

func update_food(nombrefood):
	var quantite = int(nombrefood)
	
	var all_food = liste_food.get_children()

	for i in range(all_food.size()):
		var icone = all_food[i] # On récupère l'objet à l'index i
		if i < quantite:
			icone.modulate = Color(1, 0, 0.3) # Rose
		else:
			icone.modulate = Color(0, 0, 0) # Noir
			
	print("Affichage mis à jour : ", quantite, " Nourriture restants.")

func update_drink(nomberdrink):
	DatabaseConfig.drink_local = int(nomberdrink)
	var all_drink = liste_drink.get_children()
	
	for i in range(all_drink.size()):
		var icone = all_drink[i]
		
		# i est un int, quantite est un int. La comparaison fonctionne !
		if i < nomberdrink:
			icone.modulate = Color(1, 0, 0.3)
		else:
			icone.modulate = Color(0, 0, 0)

	print("Affichage mis à jour : ", nomberdrink, " Boisson restants.")


func update_money(gold):
	money.text = str(gold)
	DatabaseConfig.money_local = int(gold)
	
func _on_keypad_open_pressed() -> void:
	keypad.show()
