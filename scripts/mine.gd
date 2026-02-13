extends Control

var joueur_actuel := 0
@onready var dés: Control = $"../Dés"


func lancer_evenement_mine():
	joueur_actuel = 0
	print("[LIEU : MINE] L'explosion est imminente ! Début du sacrifice.")
	_passer_au_joueur_suivant()

func _passer_au_joueur_suivant():
	if joueur_actuel >= 4:
		print("[MINE] Tous les joueurs ont passé l'épreuve.")
		DatabaseConfig.zone = "" # On libère la zone
		return

	# 1. On définit l'ID pour la base de données
	DatabaseConfig.current_profil_id = str(joueur_actuel)
	DatabaseConfig.zone = "mine"
	
	# 2. On va chercher le noeud du profil (ID0, ID1, etc.) dans script_general
	# On suppose que script_general.profils_noeuds contient les instances de Profil.gd
	if DatabaseConfig.script_general and DatabaseConfig.script_general.profils_noeuds.size() > joueur_actuel:
		var profil_du_joueur = DatabaseConfig.script_general.profils_noeuds[joueur_actuel]
		
		# 3. On récupère le keypad qui est DANS ce profil
		var keypad_local = profil_du_joueur.keypad
		
		if is_instance_valid(keypad_local):
			# On connecte le signal pour passer au suivant
			if not keypad_local.mine_terminee.is_connected(_on_joueur_a_fini):
				keypad_local.mine_terminee.connect(_on_joueur_a_fini)
			
			# On l'ouvre !
			print("[MINE] Ouverture du Keypad pour ID", joueur_actuel)
			keypad_local.preparer_pour_mine()
		else:
			print("ERREUR : Keypad introuvable pour le joueur ", joueur_actuel)
	else:
		print("ERREUR : Impossible de trouver le profil du joueur ", joueur_actuel)

func _on_joueur_a_fini():
	# On déconnecte le signal de l'ancien keypad pour éviter les bugs au prochain tour
	var profil_precedent = DatabaseConfig.script_general.profils_noeuds[joueur_actuel]
	if profil_precedent.keypad.mine_terminee.is_connected(_on_joueur_a_fini):
		profil_precedent.keypad.mine_terminee.disconnect(_on_joueur_a_fini)

	joueur_actuel += 1
	_passer_au_joueur_suivant()

func _on_button_pressed() -> void:
	dés.hide()
	lancer_evenement_mine()
