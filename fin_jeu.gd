extends Control

@onready var message_fin: Label = $MessageFin



func _ready():
	hide() # Caché par défaut

# Cette fonction sera appelée par le script Mine ou le script Général
func afficher_resultat(victoire: bool):
	show()
	
	if victoire:
		message_fin.text = "Bravo vous êtes tous rentrés dans la mine et vous repartez avec le trésor"
		# On peut ajouter un petit son de pièces ou une couleur verte
		message_fin.modulate = Color.GREEN
	else:
		message_fin.text = "OH non vous ne ressortez jamais de la mine par manque d'équipement"
		# Couleur rouge pour l'échec
		message_fin.modulate = Color.RED

func _on_button_pressed() -> void:
	# Logique pour redémarrer le jeu si tu as une fonction reset
	DatabaseConfig.reset_game_start()
	get_tree().reload_current_scene()
