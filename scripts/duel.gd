extends Control

@onready var emplacements = [
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur1, "label": $VBoxContainer/Joueurs/Joueurs/Joueur1/Nomjoueur1},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur2, "label": $VBoxContainer/Joueurs/Joueurs/Joueur2/Nomjoueur2},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur3, "label": $VBoxContainer/Joueurs/Joueurs/Joueur3/Nomjoueur3}
]

var cible_choisie_id : String = ""

func _ready() -> void:
	print("[Duel] Ready. Mouse filter set to STOP.")
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	for i in range(emplacements.size()):
		emplacements[i].rect.gui_input.connect(_on_adversaire_clique.bind(i))
		emplacements[i].rect.mouse_filter = Control.MOUSE_FILTER_STOP

func remplir_selection(tous_les_profils: Array, mon_id_actuel: String) -> void:
	print("[Duel] Tentative de remplissage. Mon ID actuel: ", mon_id_actuel)
	
	# Sécurité Timing
	if tous_les_profils.size() == 0:
		print("[Duel] ERREUR: La liste des profils est vide !")
		return
	
	if not tous_les_profils[0].has_method("get_life"):
		print("[Duel] Scripts pas encore prêts, attente d'une frame...")
		await get_tree().process_frame
		remplir_selection(tous_les_profils, mon_id_actuel)
		return

	var index_affichage = 0
	cible_choisie_id = "" 
	
	# Reset propre
	for slot in emplacements:
		slot.rect.hide()
		if slot.rect.has_meta("joueur_id"): 
			slot.rect.remove_meta("joueur_id")

	# Boucle de triage
	for i in range(tous_les_profils.size()):
		var id_boucle = str(i)
		
		if id_boucle == mon_id_actuel:
			print("[Duel] Skip ID ", i, " (C'est moi)")
			continue
			
		if index_affichage >= emplacements.size():
			print("[Duel] Plus de slots disponibles pour l'ID ", i)
			break

		var slot = emplacements[index_affichage]
		var source = tous_les_profils[i]
		
		# Debug check des propriétés
		if not is_instance_valid(source):
			print("[Duel] Source ID ", i, " est invalide !")
			continue

		print("[Duel] Remplissage Slot ", index_affichage, " avec ID ", i)
		
		# On tente de récupérer le nom
		if "nom_joueur" in source and source.nom_joueur != null:
			slot.label.text = source.nom_joueur.text
		else:
			slot.label.text = "ID " + id_boucle
			print("[Duel] ATTENTION: nom_joueur introuvable pour ID ", i)

		# Texture
		var img = source.get_node_or_null("TextureRect")
		if img: 
			slot.rect.texture = img.texture
		
		# ÉCRITURE DE LA META (L'étape qui échoue chez toi)
		slot.rect.set_meta("joueur_id", id_boucle)
		slot.rect.show()
		slot.rect.self_modulate = Color.WHITE
		
		print("[Duel] Slot ", index_affichage, " prêt pour ID ", id_boucle)
		index_affichage += 1

func _on_adversaire_clique(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var slot_clique = emplacements[index]
		
		print("[Duel] Clic détecté sur Slot ", index)
		
		if slot_clique.rect.has_meta("joueur_id"):
			cible_choisie_id = str(slot_clique.rect.get_meta("joueur_id"))
			for slot in emplacements: slot.rect.self_modulate = Color.WHITE
			slot_clique.rect.self_modulate = Color(1, 0.65, 0)
			print("[Duel] SUCCÈS : Cible choisie = ", cible_choisie_id)
		else:
			print("[Duel] ERREUR : Le Slot ", index, " n'a pas de Meta joueur_id au moment du clic !")
