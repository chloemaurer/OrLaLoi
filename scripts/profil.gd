class_name Profil
extends Control

@onready var liste_des_coeurs: HBoxContainer = $Resources/Life
@onready var liste_drink: HBoxContainer = $Resources/Drink
@onready var liste_food: HBoxContainer = $Resources/Food
@onready var money: Label = $Items/Items/Money
@onready var nom_joueur: Label = $NomJoueur
@onready var munition: Label = $Items/Items/Control/Munition
@onready var keypad: Node2D = $Keypad
@onready var gun: TextureRect = $Items/Items/Control/Gun

const NIV_1_ICON = preload("uid://dcsgy653c2i6b")
const NIV_2_ICON = preload("uid://c3kva8nrhjb2s")
const NIV_3_ICON = preload("uid://s1gbkxaaxbje")

# Variables internes pour mémoriser les stats (très important pour le Dispatcher)
var _vie: int = 0
var _food: int = 0
var _drink: int = 0
var _money: int = 0
var _munition: int = 0
var _arme: int = 0

func update_visuel(cle: String, valeur):
	match cle:
		"Vie":
			_vie = int(valeur)
			_update_hbox_icons(liste_des_coeurs, _vie)
		"Nourriture":
			_food = int(valeur)
			_update_hbox_icons(liste_food, _food)
		"Boisson":
			_drink = int(valeur)
			_update_hbox_icons(liste_drink, _drink)
		"Argent":
			_money = int(valeur)
			# SÉCURITÉ ICI : On vérifie si le Label est prêt
			if money: 
				money.text = str(_money)
		"Nom":
			nom_joueur.text = str(valeur)
		"Munition":
			_munition = int(valeur)
			# SÉCURITÉ ICI : On vérifie si le Label est prêt
			if munition: 
				munition.text = str(_munition)
		"Arme":
			_arme = int(valeur)
			show_gun()

# Fonction utilitaire pour éviter de répéter les boucles
func _update_hbox_icons(container: HBoxContainer, n: int):
	if not container: return
	var enfants = container.get_children()
	for i in range(enfants.size()):
		# Rose/Rouge si actif, noir si vide
		enfants[i].modulate = Color(1, 0, 0.3) if i < n else Color(0, 0, 0)

# --- FONCTIONS DE LECTURE (Appelées par le script Principal) ---
# Note : Les noms correspondent maintenant exactement à ton script Principal

func get_life(): 
	return _vie

func get_food(): 
	return _food

func get_drink(): 
	return _drink

func get_money(): 
	return _money
	
func get_munition(): 
	return _munition
	
func get_gun():
	return _arme

func show_gun():
	# On utilise la variable interne mise à jour par update_visuel
	match _arme:
		1:
			gun.texture = NIV_1_ICON
			print("Visuel : Arme Niveau 1")
		2:
			gun.texture = NIV_2_ICON
			print("Visuel : Arme Niveau 2")
		3:
			gun.texture = NIV_3_ICON
			print("Visuel : Arme Niveau 3")



func _on_keypad_open_pressed() -> void:
	keypad.show()
