extends Control

var joueur_actuel := 0

func lancer_evenement_mine():
	joueur_actuel = 0
	print("[LIEU : MINE] L'explosion est imminente ! Début du sacrifice.")
	_passer_au_joueur_suivant()

func _passer_au_joueur_suivant():
	if joueur_actuel >= 4:
		print("[MINE] Tous les joueurs ont passé l'épreuve.")
		# Optionnel : masquer l'interface de la mine ici
		return

	# On configure la borne pour le joueur qui est devant
	DatabaseConfig.current_profil_id = str(joueur_actuel)
	DatabaseConfig.zone = "mine"
	
	print("[MINE] Joueur ", joueur_actuel, ", scannez vos 2 cartes Mine !")

	# On accède au keypad via le script général
	if DatabaseConfig.script_general and DatabaseConfig.script_general.keypad.size() > 0:
		var keypad = DatabaseConfig.script_general.keypad[0]
		
		# On connecte le signal de fin s'il ne l'est pas déjà
		if not keypad.is_connected("mine_terminee", _on_joueur_a_fini):
			keypad.connect("mine_terminee", _on_joueur_a_fini)
		
		keypad.preparer_pour_mine()

func _on_joueur_a_fini():
	joueur_actuel += 1
	# On peut ajouter un petit délai ou un écran "JOUEUR SUIVANT" ici
	_passer_au_joueur_suivant()

func _on_button_pressed() -> void:
	lancer_evenement_mine()
