extends Node2D

var icons = [preload("uid://bh2fl2jexuv11"),preload("uid://bigj6xlc0devs"),preload("uid://b01lqf5jf531"),
preload("uid://cm7m7l86ey38f"),preload("uid://dmhx8f5xybayy"),preload("uid://dromh00wukg7r"),
preload("uid://by34fmmkfdae3"),preload("uid://civ1gsrq8j33m"),preload("uid://du742y314x7w0")]

@onready var screen: Node2D = $Screen
@onready var code: Node2D = $Code
@onready var back: Button = $Actions/Back

var current_index := 0
var input_code := "" 
var tous_les_codes := {} 


func _ready():
	for node in code.get_children():
		if node is Button:
			node.pressed.connect(_on_key_pressed.bind(node))
	back.pressed.connect(_on_back_pressed)


func mettre_a_jour_catalogue(cle: String, valeur):
	var _id_extrait = cle.split("/")[0]
	var clean_val = func(v): return str(int(float(v))) if typeof(v) in [TYPE_FLOAT, TYPE_INT] else str(v)

	if typeof(valeur) == TYPE_DICTIONARY:
		# Si on reçoit le dossier complet "cartes"
		for id_key in valeur.keys():
			var data = valeur[id_key]
			if typeof(data) == TYPE_DICTIONARY:
				tous_les_codes[id_key] = {
					"code": clean_val.call(data.get("code", "0")),
					"effet": data.get("effet", "Inconnu"),
					"categorie": data.get("categorie", "Inconnue"),
					"disponible": data.get("valeur", true) # On récupère le booléen
				}
	
	print("[Keypad] Catalogue mis à jour. Nombre de cartes : ", tous_les_codes.size())
		
func _on_key_pressed(button: Button):
	if current_index > 3: return
	
	var keypressed = int(button.name)
	input_code += str(keypressed)
	var keyicon = icons[keypressed - 1]
	screen.get_child(current_index).texture = keyicon
	current_index += 1
	print(input_code)

func _on_back_pressed():
	if current_index <= 0: return
	current_index -= 1
	input_code = input_code.substr(0, input_code.length() - 1)
	screen.get_child(current_index).texture = null


func reset_keypad():
	while current_index > 0:
		_on_back_pressed()
	input_code = ""

# Le bouton "Check" lance maintenant le processus complet
func _on_check_pressed() -> void:
	check_code()

func check_code():
	print("[Keypad] --- Vérification ---")
	
	var carte_trouvee = null
	for id_name in tous_les_codes:
		if tous_les_codes[id_name]["code"] == input_code:
			carte_trouvee = tous_les_codes[id_name]
			break

	if not carte_trouvee:
		print("❌ ÉCHEC : Code inconnu.")
		reset_keypad()
		return
		
	if carte_trouvee["disponible"] == false:
		print("🚫 ÉCHEC : Cette carte a déjà été utilisée !")
		_finaliser_utilisation_keypad()
		return
		
	# On a trouvé une carte, maintenant on vérifie la Zone
	var category = carte_trouvee["categorie"]
	
	if is_zone_valid(category):
		print("✅ SUCCÈS : Carte valide et zone correcte.")
		
		apply_card(category, carte_trouvee["effet"])
		DatabaseConfig.disable_card(carte_trouvee["id"])
		carte_trouvee["disponible"] = false 
	else:
		print("🚫 MAUVAISE ZONE.")
	_finaliser_utilisation_keypad()

func _finaliser_utilisation_keypad():
	DatabaseConfig.zone = "" # On reset la zone globale
	reset_keypad()          # On vide l'affichage et l'input_code
	self.hide()             # On ferme le keypad
	print("[Keypad] Zone reset et clavier fermé.")

func is_zone_valid(category: String) -> bool:
	# "vie", "argent" et "MiniJeux" sont utilisables partout
	if category in ["vie", "argent", "MiniJeux"]:
		return true
		
	# Pour les autres, on compare avec la zone actuelle dans DatabaseConfig
	var player_zone = DatabaseConfig.zone # Assure-toi que cette variable existe
	
	match category:
		"Mine": return player_zone == "mine"
		"saloon": return player_zone == "saloon"
		"restaurant": return player_zone == "restaurant"
		"arme": return player_zone == "armurerie"
	
	return false

func apply_card(category: String, effet_valeur):
	var id_joueur = DatabaseConfig.current_profil_id
	var effet = int(effet_valeur)
	
	match category:
		#"MiniJeux":
			#var succes = DatabaseConfig.spend_money(effet, id_joueur)
		#"Mine":
			#var succes = DatabaseConfig.spend_money(effet, id_joueur)
		"saloon":
			DatabaseConfig.get_drink(effet, id_joueur)
		"restaurant":
			DatabaseConfig.get_food(effet, id_joueur)
		"vie":
			DatabaseConfig.get_life(effet, id_joueur)
		"argent":
			DatabaseConfig.get_money(effet, id_joueur)
		"arme":
			DatabaseConfig.update_gun(effet, id_joueur)
