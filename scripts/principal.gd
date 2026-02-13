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

var joueurs_prets = [false, false, false, false]
var jeu_demarre = false
var cible_duel_id : String = ""
@onready var places: Node2D = $Map/Places
@onready var restaurant_shop: Control = $Map/RestaurantShop
@onready var saloon_shop: Control = $Map/SaloonShop
@onready var armory: Control = $Map/Armory
@onready var bank: Control = $Map/Bank
@onready var duel: Control = $Map/Duel
@onready var give_card: Control = $Map/GiveCard
@onready var map: Control = $Map
@onready var start_action: Control = $Map/StartAction



func _ready() -> void:
	# 1. On donne les accès au singleton immédiatement
	DatabaseConfig.script_general = self
	# 2. Branchement des autres boutiques
	DatabaseConfig.script_saloon = $Map/SaloonShop
	DatabaseConfig.script_restaurant = $Map/RestaurantShop
	DatabaseConfig.script_bank = $Map/Bank
	DatabaseConfig.script_armory = $Map/Armory
	DatabaseConfig.script_duel = $Map/Duel
	DatabaseConfig.script_don = $Map/GiveCard
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
	print("En attente des joueurs... Cliquez sur vos profils pour commencer.")
	places.hide()
	start_action.hide()
	for p in profils_noeuds:
		p.modulate = Color(0.2, 0.2, 0.2, 1)

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
	start_action.show()
	DatabaseConfig.current_profil_id = str(index_choisi)
	DatabaseConfig.actions_faites = 0 # On remet le compteur à zéro pour le nouveau joueur
	print("Nouveau tour pour ID", index_choisi, ". Actions : 0/2")
	
	# Si c'est le tour du joueur 3 (index 2) ou joueur 4 (index 3)
	if index_choisi == 2 or index_choisi == 3:
		map.rotation_degrees = 180
	else:
		map.rotation_degrees = 0
		
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
	check_resources(index_actuel)
	var prochain_profil = (index_actuel + 1) % profils_noeuds.size()
	
	var tentative = 0
	while profils_noeuds[prochain_profil].get_life() <= 0 and tentative < profils_noeuds.size():
		print("Joueur ID", prochain_profil, " est mort, on passe au suivant...")
		prochain_profil = (prochain_profil + 1) % profils_noeuds.size()
		tentative += 1
		DatabaseConfig.manches += 1
		print("--- TOUS LES JOUEURS ONT JOUÉ ---")
		print("DÉBUT DE LA MANCHE : ", DatabaseConfig.manches)
		$Manches.fill_wagon()
		$Manches2.fill_wagon()
		
	if prochain_profil == 0:
		DatabaseConfig.manches += 1
		print("--- TOUS LES JOUEURS ONT JOUÉ ---")
		print("DÉBUT DE LA MANCHE : ", DatabaseConfig.manches)
		$Manches.fill_wagon()
		$Manches2.fill_wagon()
		
	selectionner_profil(prochain_profil)
	places.show()
	places.close_all()
	restaurant_shop.random_food()
	saloon_shop.random_drink()

func check_resources(index_actuel: int):
	var joueur = profils_noeuds[index_actuel]
	var id_str = str(index_actuel)
	
	var boisson = joueur.get_drink()
	var nourriture = joueur.get_food()

	# Si l'un ou l'autre manque, le joueur perd 1 PV
	if boisson <= 0 or nourriture <= 0:
		var raison = "soif" if boisson <= 0 else "faim"
		if boisson <= 0 and nourriture <= 0: raison = "faim et soif"
		
		print("Ressources épuisées (", raison, ") pour ID", id_str, " ! -1 PV")
		DatabaseConfig.lose_life(1, id_str)
		
	if joueur.get_life() <= 0:
		Kill_player(index_actuel)

# Cette fonction gère l'apparence
func Kill_player(index: int):
	print("Le joueur ", index, " est éliminé.")
	var cible = profils_noeuds[index]
	cible.modulate = Color(0.2, 0.2, 0.2, 0.8) # Le gris
	
	# Optionnel : On cache son bouton pour qu'il ne puisse plus cliquer
	boutons_fin_tour[index].hide()

func revive_player():
	# On remet la couleur normale (blanc = pas de filtre)
	self.modulate = Color(1, 1, 1, 1)
	# On s'assure que le bouton de fin de tour est à nouveau cliquable
	if has_node("EndTurn1"):
		get_node("EndTurn1").disabled = false
	print("Le joueur ", name, " est revenu à la vie !")
	
func _synchroniser_stats_vers_global(index: int):
	var cible = profils_noeuds[index]
	
	# Si la cible n'existe pas ou n'a pas le script Profil attaché
	if not is_instance_valid(cible) or not cible.has_method("get_life"):
		print("Attente du script Profil sur le noeud : ", index)
		await get_tree().process_frame # On attend une frame
		_synchroniser_stats_vers_global(index) # On recommence
		return # On arrête l'exécution ici pour ne pas lire la suite


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
	# Si le jeu est déjà lancé, on ignore les clics sur les profils
	if jeu_demarre:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not joueurs_prets[index]:
			joueurs_prets[index] = true
			profils_noeuds[index].modulate = Color(1, 1, 1, 1) # On allume le profil
			print("Joueur ", index, " est prêt !")
			
			# On vérifie si tout le monde est prêt
			verifier_tous_les_joueurs_prets()

func verifier_tous_les_joueurs_prets():
	if not joueurs_prets.has(false): # Si plus aucun 'false' dans le tableau
		jeu_demarre = true
		print("TOUS LES JOUEURS SONT PRÊTS ! Lancement de la partie...")
		
		# On déconnecte les clics sur les profils pour le reste de la partie
		for i in range(profils_noeuds.size()):
			if profils_noeuds[i].gui_input.is_connected(_on_profil_clique):
				profils_noeuds[i].gui_input.disconnect(_on_profil_clique)
		
		# On lance enfin le premier tour
		selectionner_profil(0)

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
	
	
#--------------------------------------------------------------------------------
