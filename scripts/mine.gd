extends Control

var joueur_actuel := 0
@onready var dés: Control = $"../Dés"
@onready var fin_jeu: Control = $"../../FinJeu"
@onready var passturn: Button = $Passturn


func lancer_evenement_mine():
	joueur_actuel = 0
	print("[LIEU : MINE] L'explosion est imminente ! Début du sacrifice.")
	_passer_au_joueur_suivant()

func _passer_au_joueur_suivant():
	# 1. Vérifier si on a dépassé le nombre de joueurs
	if joueur_actuel >= 4:
		print("[MINE] Tous les survivants ont passé l'épreuve.")
		DatabaseConfig.zone = "" # On libère la zone
		var survivants = 0
		for p in DatabaseConfig.script_general.profils_noeuds:
			if p.get_life() > 2 && p.get_drink() > 1 && p.get_food() > 1:
				survivants += 1
		
		# Si au moins un joueur est vivant à la fin de la mine
		if survivants == 4:
			fin_jeu.afficher_resultat(true)
			
		return

	# 2. Récupérer le profil
	var profil_du_joueur = DatabaseConfig.script_general.profils_noeuds[joueur_actuel]

	# 3. LOGIQUE DES MORTS : Si le joueur est mort, on l'ignore et on passe au suivant
	if profil_du_joueur.get_life() <= 0:
		print("[MINE] Joueur ID", joueur_actuel, " est mort, on saute.")
		joueur_actuel += 1
		_passer_au_joueur_suivant()
		return

	# 4. GESTION VISUELLE : On active ce profil et on grise les autres
	_actualiser_visuel_profils(joueur_actuel)

	# 5. CONFIGURATION DU KEYPAD
	DatabaseConfig.current_profil_id = str(joueur_actuel)
	DatabaseConfig.zone = "mine"
	
	var keypad_local = profil_du_joueur.keypad
	if is_instance_valid(keypad_local):
		if not keypad_local.mine_terminee.is_connected(_on_joueur_a_fini):
			keypad_local.mine_terminee.connect(_on_joueur_a_fini)
		
		print("[MINE] Ouverture du Keypad pour ID", joueur_actuel)
		keypad_local.preparer_pour_mine()
	else:
		print("ERREUR : Keypad introuvable pour le joueur ", joueur_actuel)

func _actualiser_visuel_profils(id_actif: int):
	# On parcourt tous les profils pour les griser, sauf celui qui doit jouer
	for i in range(4):
		var p = DatabaseConfig.script_general.profils_noeuds[i]
		if i == id_actif:
			p.modulate = Color(1, 1, 1, 1) # Allumé
		else:
			# On le grise (plus sombre s'il est mort, un peu moins s'il attend juste son tour)
			if p.get_life() <= 0:
				p.modulate = Color(0.2, 0.2, 0.2, 0.8) # Mort
			else:
				p.modulate = Color(0.3, 0.3, 0.3, 1) # En attente

func _on_joueur_a_fini():
	# déconnexion signal ancien joueur
	var profil_precedent = DatabaseConfig.script_general.profils_noeuds[joueur_actuel]
	if profil_precedent.keypad.mine_terminee.is_connected(_on_joueur_a_fini):
		profil_precedent.keypad.mine_terminee.disconnect(_on_joueur_a_fini)

	joueur_actuel += 1
	_passer_au_joueur_suivant()

func _on_button_pressed() -> void:
	dés.hide()
	lancer_evenement_mine()
	passturn.show()
	
	


func _on_passturn_pressed() -> void:
	fin_jeu.afficher_resultat(false)
