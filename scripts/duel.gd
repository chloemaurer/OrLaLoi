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
			var profil_data = tous_les_profils[i] # Référence au script Profil.gd
			
			# NOM : Récupéré directement du label du profil
			slot.label.text = profil_data.nom_joueur.text
			
			# IMAGE : Récupérée du TextureRect "personnage" du profil
			if profil_data.player_icone and profil_data.player_icone.texture:
				slot.rect.texture = profil_data.player_icone.texture
			else:
				# Sécurité si le visuel n'est pas encore prêt
				slot.rect.texture = profil_data.personnages[i]["sprite"]

			# COULEUR/VIE : Si le joueur est mort (gris), il apparaît gris ici aussi
			slot.rect.modulate = profil_data.modulate

			# SIGNAL : Nettoyage avant connexion pour éviter les doubles clics
			if slot.rect.gui_input.is_connected(_on_adversaire_clique):
				slot.rect.gui_input.disconnect(_on_adversaire_clique)
			slot.rect.gui_input.connect(_on_adversaire_clique.bind(index_slot))
			
			# META & AFFICHAGE
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
					texture_rect.material.set("shader_parameter/thickness", 5.0)
		
			print("[Duel] SUCCÈS : Cible choisie = ", cible_choisie_id)
		else:
			print("[Duel] ERREUR : Le Slot ", index, " n'a pas de Meta joueur_id au moment du clic !")

func _on_versus_pressed() -> void:
	if cible_choisie_id == "":
		DatabaseConfig.notifier_erreur("Aucun adversaire sélectionné !")
		print("Erreur : Aucune cible sélectionnée !")
		return
	
	var mon_id = DatabaseConfig.current_profil_id

	DatabaseConfig.duel_versus(mon_id, cible_choisie_id)
	self.hide()
	cible_choisie_id = ""
