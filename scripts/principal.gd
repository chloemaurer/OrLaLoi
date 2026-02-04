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

# Références pour le menu de duel (à ajuster selon tes chemins)
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


func _ready() -> void:
	# 1. On donne les accès au singleton immédiatement
	DatabaseConfig.script_general = self
	# 2. Branchement des autres boutiques
	DatabaseConfig.script_saloon = $SaloonShop
	DatabaseConfig.script_restaurant = $RestaurantShop
	DatabaseConfig.script_bank = $Bank
	DatabaseConfig.script_armory = $Armory
	DatabaseConfig.script_duel = $Duel

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

func _on_profil_clique(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selectionner_profil(index)

func ouvrir_menu_duel():
	print("[Principal] Ouverture Duel. ID Actuel: ", DatabaseConfig.current_profil_id)
	var index_affichage = 0
	cible_duel_id = ""
	
	# 1. On nettoie l'interface de duel
	for slot in duel_slots:
		slot.rect.hide()
		if slot.rect.has_meta("id_cible"): slot.rect.remove_meta("id_cible")
		# On connecte le clic une seule fois (sécurité)
		if not slot.rect.gui_input.is_connected(_on_duel_slot_clicked):
			slot.rect.gui_input.connect(_on_duel_slot_clicked.bind(index_affichage))
		index_affichage += 1

	# 2. On remplit avec les autres joueurs
	var slot_idx = 0
	for i in range(profils_noeuds.size()):
		var id_str = str(i)
		
		# Si c'est un adversaire
		if id_str != DatabaseConfig.current_profil_id:
			if slot_idx < duel_slots.size():
				var slot = duel_slots[slot_idx]
				var source = profils_noeuds[i]
				
				var nom_source = source.nom_joueur.text
				slot.label.text = nom_source if nom_source != "" else "Joueur " + id_str
				#slot.label.text = source.nom_joueur.text
				
				var img = source.get_node_or_null("TextureRect") # ou "Icone"
				if img: slot.rect.texture = img.texture
				
				# On stocke l'ID
				slot.rect.set_meta("id_cible", id_str)
				slot.rect.show()
				slot.rect.self_modulate = Color.WHITE
				slot_idx += 1
	
	duel_ui.show()
	
func _on_duel_slot_clicked(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Empêche le clic de traverser vers les cowboys en arrière-plan
		get_viewport().set_input_as_handled()
		
		var slot = duel_slots[slot_index]
		
		if slot.rect.has_meta("id_cible"):
			cible_duel_id = slot.rect.get_meta("id_cible")
			
			# Visuel : Tout le monde en blanc, le sélectionné en Orange
			for s in duel_slots:
				s.rect.self_modulate = Color.WHITE
			
			slot.rect.self_modulate = Color(1, 0.65, 0) # Orange
			print("[Duel] Cible sélectionnée : ID ", cible_duel_id)
		else:
			print("[Duel] Slot vide cliqué")
