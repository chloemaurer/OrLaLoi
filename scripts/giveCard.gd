extends Control

@onready var emplacements = [
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur1, "label": $VBoxContainer/Joueurs/Joueurs/Joueur1/Nomjoueur1},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur2, "label": $VBoxContainer/Joueurs/Joueurs/Joueur2/Nomjoueur2},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur3, "label": $VBoxContainer/Joueurs/Joueurs/Joueur3/Nomjoueur3}
]

var cible_choisie_id : String = ""


func remplir_selection(tous_les_profils: Array, mon_id_actuel: String) -> void:
	var index_slot = 0
	cible_choisie_id = "" # Reset de la sélection précédente

	# 1. On cache tous les slots au départ
	for s in emplacements:
		s.rect.hide()

	# 2. On boucle sur les 4 profils reçus
	for i in range(tous_les_profils.size()):
		var id_adversaire = str(i)
		
		# SI l'ID est celui du joueur actuel, on l'ignore (on ne se bat pas contre soi-même)
		if id_adversaire == mon_id_actuel:
			continue
		
		# Si on a encore de la place dans nos 3 slots d'affichage
		if index_slot < emplacements.size():
			var slot = emplacements[index_slot]
			var profil_data = tous_les_profils[i]
			
			# On remplit le nom et l'image depuis le script Profil
			slot.label.text = profil_data.nom_joueur.text
			
			# Récupération de l'image (TextureRect "Icone" ou autre dans ton Profil)
			var icone_source = profil_data.get_node_or_null("Icone") 
			if icone_source:
				slot.rect.texture = icone_source.texture
				
			slot.rect.gui_input.connect(_on_adversaire_clique.bind(index_slot))
			
			# On stocke l'ID dans la Meta pour savoir qui on frappe plus tard
			slot.rect.set_meta("joueur_id", id_adversaire)
			slot.rect.show()
			
			index_slot += 1
		

func _on_adversaire_clique(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var slot_clique = emplacements[index]
		
		print("[Duel] Clic détecté sur Slot ", index)
		
		if slot_clique.rect.has_meta("joueur_id"):
			var nouvelle_cible = str(slot_clique.rect.get_meta("joueur_id"))
	
	# 1. RÉINITIALISATION : On enlève le shader de TOUT LE MONDE
			for slot in emplacements:
				var tr : TextureRect = slot.rect
				if tr.material is ShaderMaterial:
					tr.material.set("shader_parameter/thickness", 0.0)

	# 2. LOGIQUE DE TOGGLE : 
	# Si on clique sur celui qui est déjà sélectionné, on le désactive (Toggle Off)
			if cible_choisie_id == nouvelle_cible:
				cible_choisie_id = "" # On vide la sélection
				print("[Duel] Sélection annulée.")
			else:
				# Sinon, on active le nouveau (Toggle On)
				cible_choisie_id = nouvelle_cible
				var texture_rect : TextureRect = slot_clique.rect
				if texture_rect.material is ShaderMaterial:
					texture_rect.material.set("shader_parameter/thickness", 30.0)
		
			print("[Duel] SUCCÈS : Cible choisie = ", cible_choisie_id)
		else:
			print("[Duel] ERREUR : Le Slot ", index, " n'a pas de Meta joueur_id au moment du clic !")

	

func _on_give_card_pressed() -> void:
	if cible_choisie_id == "":
		print("Erreur : Aucune cible sélectionnée !")
		return
	
	# 1. On enregistre enfin l'ID dans le Singleton
	DatabaseConfig.cible_don_id = cible_choisie_id
	print("[GiveCard] Cible enregistrée : ", DatabaseConfig.cible_don_id)
	
	# 2. On ferme le menu de sélection
	self.hide()
	
	var principal = DatabaseConfig.script_general
	principal.open_current_keypad() 

	# IMPORTANT : C'est ici qu'on prévient le keypad d'afficher la croix
	var id_joueur = int(DatabaseConfig.current_profil_id)
	principal.keypad[id_joueur].preparer_clavier_pour_don()
