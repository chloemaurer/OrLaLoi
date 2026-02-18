extends Control

@onready var moins: Button = $VBoxContainer/HBoxContainer/moins
@onready var count: Label = $VBoxContainer/HBoxContainer/Count
@onready var plus: Button = $VBoxContainer/HBoxContainer/plus
@onready var prix: Label = $VBoxContainer/HBoxContainer/Prix

var num := 1
var nb_prix := 2
var prix_pioche := 3
var munition

func _ready() -> void:
	count.text = str(num)
	prix.text = str(nb_prix)

func _on_moins_pressed() -> void:
	prix.modulate = Color(1.0, 0.647, 0.0) 
	if num >= 2:
		num -= 1
		nb_prix -= 1
		_actualiser_labels()

func _on_plus_pressed() -> void:
	# On vérifie si le joueur actif a assez d'argent via le Global
	if num <= 2 && nb_prix < DatabaseConfig.money_local:
		prix.modulate = Color(1.0, 0.647, 0.0) 
		num += 1
		nb_prix += 1
		_actualiser_labels()
	else:
		prix.modulate = Color.RED

func _actualiser_labels() -> void:
	count.text = str(num)
	prix.text = str(nb_prix)


func _on_armory_buy_card_pressed() -> void:
	var id_actuel = DatabaseConfig.current_profil_id
	print("Armurerie : Essai d'achat pour Profil ", id_actuel)
	var succes = DatabaseConfig.spend_money(nb_prix, id_actuel)
	
	if succes:
		print("Armurerie : Achat validé pour le profil ", id_actuel)
		DatabaseConfig.get_munition(num, id_actuel)
		DatabaseConfig.actions_faites += 1
	# On demande au script principal de vérifier si on doit fermer les places
		if DatabaseConfig.script_general:
			DatabaseConfig.script_general.verifier_limite_actions()
	else :
		DatabaseConfig.notifier_erreur("Achat échoué : Pas assez d'argent")
