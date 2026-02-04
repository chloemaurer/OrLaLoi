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
	var id_extrait = cle.split("/")[0]
	
	# Utilitaire pour nettoyer les nombres (float -> int -> string)
	var clean_val = func(v): return str(int(float(v))) if typeof(v) in [TYPE_FLOAT, TYPE_INT] else str(v)

	if typeof(valeur) == TYPE_DICTIONARY:
		# Si on reçoit le dossier complet "cartes"
		for id_key in valeur.keys():
			var data = valeur[id_key]
			if typeof(data) == TYPE_DICTIONARY:
				tous_les_codes[id_key] = {
					"code": clean_val.call(data.get("code", "0")),
					"effet": data.get("effet", "Inconnu"),
					"categorie": data.get("categorie", "Inconnue")
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

func check_code():
	print("[Keypad] --- Vérification en cours ---")
	print("[Keypad] Tape: '", input_code, "'")
	
	var carte_trouvee = null
	
	# On parcourt chaque ID pour vérifier le code à l'intérieur
	for id_name in tous_les_codes:
		if tous_les_codes[id_name]["code"] == input_code:
			carte_trouvee = tous_les_codes[id_name]
			break

	if carte_trouvee:
		print("✅ SUCCÈS : Code valide !")
		var cat = carte_trouvee["categorie"]
		var eff = carte_trouvee["effet"]
		
		print("Détails -> Catégorie: ", cat, " | Effet: ", eff)
		
		# On appelle l'application de l'effet
		apply_card(cat, eff)
	else:
		print("❌ ÉCHEC : '", input_code, "' n'existe pas dans la base.")
	
	# On réinitialise l'affichage après la vérification
	reset_keypad()

func reset_keypad():
	while current_index > 0:
		_on_back_pressed()
	input_code = ""

func _on_check_pressed() -> void:
	check_code()
	reset_keypad()

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
		#"arme":
			
