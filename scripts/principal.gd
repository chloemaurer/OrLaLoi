extends Control

@onready var profils_noeuds = [
	$Profils/Profil,
	$Profils/Profil2,
	$Profils/Profil3,
	$Profils/Profil4
]

@onready var boutons_fin_tour = [
	$Profils/Profil/EndTurn1, 
	$Profils/Profil2/EndTurn2, 
	$Profils/Profil3/EndTurn3, 
	$Profils/Profil4/EndTurn4
]

@onready var keypad = [
	$Profils/Profil/Keypad, 
	$Profils/Profil2/Keypad, 
	$Profils/Profil3/Keypad,
	$Profils/Profil4/Keypad
]

@onready var duel_ui = $Duel
@onready var duel_slots = [
	{"rect": $Duel/VBoxContainer/Joueurs/Joueurs/Joueur1, "label": $Duel/VBoxContainer/Joueurs/Joueurs/Joueur1/Nomjoueur1},
	{"rect": $Duel/VBoxContainer/Joueurs/Joueurs/Joueur2, "label": $Duel/VBoxContainer/Joueurs/Joueurs/Joueur2/Nomjoueur2},
	{"rect": $Duel/VBoxContainer/Joueurs/Joueurs/Joueur3, "label": $Duel/VBoxContainer/Joueurs/Joueurs/Joueur3/Nomjoueur3}
]

var cible_duel_id : String = ""
@onready var places: Node2D = $Places
@onready var restaurant_shop: Control = $RestaurantShop
@onready var saloon_shop: Control = $SaloonShop
@onready var armory: Control = $Armory
@onready var bank: Control = $Bank
@onready var duel: Control = $Duel
@onready var give_card: Control = $GiveCard


func _ready() -> void:
	# 1. On donne les accès au singleton immédiatement
	DatabaseConfig.script_general = self
	# 2. Branchement des autres boutiques
	DatabaseConfig.script_saloon = $SaloonShop
	DatabaseConfig.script_restaurant = $RestaurantShop
	DatabaseConfig.script_bank = $Bank
	DatabaseConfig.script_armory = $Armory
	DatabaseConfig.script_duel = $Duel
	DatabaseConfig.script_don = $GiveCard
	give_card.hide()
	
	if DatabaseConfig.cache_cartes != null:
		for kp in keypad:
			if is_instance_valid(kp) and kp.has_method("mettre_a_jour_catalogue"):
				kp.mettre_a_jour_catalogue("cartes", DatabaseConfig.cache_cartes)
	# 4. Connexion des signaux UI
	for i in range(profils_noeuds.size()):
		profils_noeuds[i].gui_input.connect(_on_profil_clique.bind(i))
		boutons_fin_tour[i].pressed.connect(_on_end_turn_pressed.bind(i))

	# 5. Initialisation Firebase
	if DatabaseConfig.is_ready:
		_initialisation_depart()
	else:
		DatabaseConfig.db_ready.connect(_initialisation_depart)

func _initialisation_depart():
	selectionner_profil(0)
	print("Initialisation terminée : Données profils récupérées.")

func distribuer_donnees(chemin: String, data):
	if chemin == "profils" and typeof(data) == TYPE_DICTIONARY:
		for profil_id in data.keys(): # profil_id sera "ID0", "ID1", etc.
			var index = int(profil_id.replace("ID", ""))
			if index < profils_noeuds.size():
				var cible = profils_noeuds[index]
				var stats = data[profil_id] # Le dictionnaire de stats du profil
				if typeof(stats) == TYPE_DICTIONARY:
					for cle in stats.keys():
						cible.update_visuel(cle, stats[cle])

	# CAS 2 : Mise à jour précise (ex: "profils/ID0/Vie")
	else:
		for i in range(profils_noeuds.size()):
			var tag = "ID" + str(i)
			if tag in chemin:
				var cible = profils_noeuds[i]
				if typeof(data) == TYPE_DICTIONARY:
					for cle in data.keys():
						cible.update_visuel(cle, data[cle])
				else:
					var parties = chemin.split("/")
					var cle_finale = parties[-1] 
					cible.update_visuel(cle_finale, data)
				break

# --- LOGIQUE DE JEU ---

func selectionner_profil(index_choisi: int):
	print("Passage au profil : ", index_choisi)
	DatabaseConfig.current_profil_id = str(index_choisi)
	DatabaseConfig.actions_faites = 0 # On remet le compteur à zéro pour le nouveau joueur
	print("Nouveau tour pour ID", index_choisi, ". Actions : 0/2")
	
	# On force la mise à jour des variables globales pour le nouveau profil
	_synchroniser_stats_vers_global(index_choisi)
	
	for i in range(profils_noeuds.size()):
		if i == index_choisi:
			profils_noeuds[i].modulate = Color(1, 1, 1, 1) 
			boutons_fin_tour[i].disabled = false
			boutons_fin_tour[i].show()
		else:
			profils_noeuds[i].modulate = Color(0.3, 0.3, 0.3, 1)
			boutons_fin_tour[i].disabled = true
			boutons_fin_tour[i].hide()

		
func _on_end_turn_pressed(index_actuel: int):
	var prochain_profil = (index_actuel + 1) % profils_noeuds.size()
	selectionner_profil(prochain_profil)
	places.show()
	places.close_all()
	restaurant_shop.random_food()
	saloon_shop.random_drink()


func _synchroniser_stats_vers_global(index: int):
	var cible = profils_noeuds[index]
	
	# Si la cible n'existe pas ou n'a pas le script Profil attaché
	if not is_instance_valid(cible) or not cible.has_method("get_life"):
		print("Attente du script Profil sur le noeud : ", index)
		await get_tree().process_frame # On attend une frame
		_synchroniser_stats_vers_global(index) # On recommence
		return # On arrête l'exécution ici pour ne pas lire la suite

	# Si on arrive ici, c'est que get_life EXISTE forcément
	DatabaseConfig.life_local = cible.get_life()
	DatabaseConfig.food_local = cible.get_food()
	DatabaseConfig.drink_local = cible.get_drink()
	DatabaseConfig.money_local = cible.get_money()
	DatabaseConfig.munition_local = cible.get_munition()
	DatabaseConfig.actual_Gun = cible.get_gun()
	
#---- Tour -------------------------------------------------------------------------
func verifier_limite_actions():
	if DatabaseConfig.actions_faites >= 2:
		print("[Tour] Limite atteinte, fermeture des lieux.")
		places.close_all() # Ferme visuellement les accès aux boutiques
		places.hide()
		
		
#----------------------------------------

func _on_profil_clique(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selectionner_profil(index)

func ouvrir_menu_duel():
	# 1. On identifie qui est le joueur actif (ex: "0")
	var mon_id = DatabaseConfig.current_profil_id
	print("[Principal] Tentative d'ouverture du Duel pour l'ID : ", mon_id)
	
	# 2. Sécurité : on vérifie que le nœud Duel et sa méthode existent
	if is_instance_valid(duel) and duel.has_method("remplir_selection"):
		duel.remplir_selection(profils_noeuds, mon_id)
		duel.show()
		print("[Principal] Menu Duel affiché avec succès.")
	else:
		print("[Principal] ERREUR : Le menu Duel n'est pas prêt ou la méthode est absente.")

		
# La fonction liée au signal "pressed" de ton bouton Duel sur l'interface
func _on_duel_pressed() -> void:
	ouvrir_menu_duel()
	
func open_current_keypad():
	# 1. On vérifie d'abord si le joueur a déjà fait ses 2 actions
	if DatabaseConfig.actions_faites >= 2:
		print("[Sécurité] Action refusée : Limite de 2 actions atteinte !")
		return # On arrête tout ici, le keypad ne s'ouvrira pas
		
	var mon_id = int(DatabaseConfig.current_profil_id)
	if mon_id < keypad.size():
		var keypad_actuel = keypad[mon_id]
		if is_instance_valid(keypad_actuel):
			keypad_actuel.show()
			print("[Principal] Ouverture du Keypad pour le joueur : ", mon_id)
	else:
		print("[Principal] ERREUR : ID de profil hors limites pour le Keypad")

#----------------------------------------------------------------------------------------
func _on_saloon_use_card_pressed() -> void:
	DatabaseConfig.zone = "saloon"
	open_current_keypad()

func _on_restaurant_use_card_pressed() -> void:
	DatabaseConfig.zone = "restaurant"
	open_current_keypad()

func _on_armory_use_card_pressed() -> void:
	DatabaseConfig.zone = "armurerie"
	open_current_keypad()

#func _on_mine_use_card_pressed() -> void:
	#DatabaseConfig.zone = "mine"
	#open_current_keypad()
#----------------------------------------------------------------------------

#func _on_give_card_pressed() -> void:
	#open_current_keypad()
	
func _on_saloon_give_card_pressed() -> void:
	DatabaseConfig.zone = "saloon"
	var mon_id = DatabaseConfig.current_profil_id
	give_card.remplir_selection(profils_noeuds, mon_id)
	give_card.show()

func _on_restaurant_give_card_pressed() -> void:
	DatabaseConfig.zone = "restaurant" # On définit la zone avant
	var mon_id = DatabaseConfig.current_profil_id
	give_card.remplir_selection(profils_noeuds, mon_id)
	give_card.show()
