extends Control

@onready var icon_winner = [
	$"VBoxContainer/1er/Icon", $"VBoxContainer/2eme/Icon", $"VBoxContainer/3eme/Icon", $"VBoxContainer/4eme/Icon"
]

@onready var time_winner = [
	$"VBoxContainer/1er/Time", $"VBoxContainer/2eme/Time", $"VBoxContainer/3eme/Time", $"VBoxContainer/4eme/Time"
]

func afficher_resultats(scores_bruts: Array):
	# 1. Trier les scores (du plus petit temps au plus grand)
	scores_bruts.sort_custom(func(a, b): return a.temps < b.temps)
	
	# 2. Parcourir les nodes d'affichage (VBoxContainer)
	for i in range(icon_winner.size()):
		if i < scores_bruts.size():
			var data = scores_bruts[i]
			var id_joueur = data.id
			var temps_joueur = data.temps
			
			# Affichage du temps arrondi à 2 décimales
			# %.2f permet de formater un float avec 2 chiffres après la virgule
			time_winner[i].text = str("%.2f" % temps_joueur) + "s"
			
			# Récupérer l'icône du joueur depuis ton script principal (script_general)
			# On suppose que tes profils ont une texture d'icône accessible
			var profil_source = DatabaseConfig.script_general.profils_noeuds[id_joueur]
			
			if is_instance_valid(profil_source) and profil_source.has_node("Icone"):
				icon_winner[i].texture = profil_source.get_node("Icone").texture
			
			# On montre la ligne si elle était cachée
			icon_winner[i].get_parent().show()
		else:
			# Si moins de 4 joueurs ont fini, on cache les lignes vides
			icon_winner[i].get_parent().hide()

	# On affiche enfin le menu de score lui-même
	self.show()
