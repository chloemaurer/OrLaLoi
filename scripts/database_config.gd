extends Node

signal db_ready
var db_ref : FirebaseDatabaseReference = null
var is_ready : bool = false

# Variables locales
var money_local : int = 0
var munition_local : int = 0
var life_local : int = 0
var drink_local : int = 0
var food_local : int = 0
var actual_Gun : int = 0
var current_profil_id : String = "0"
var cible_don_id : String = "" # Contiendra l'ID du joueur sélectionné dans GiveCard
var zone = ""
var manches : int = 0
var cible_duel_id : String = ""
var mini_jeu_en_cours = ""
var recompenses_distribuees = false
var scores_accumules = {"0": 0.0, "1": 0.0, "2": 0.0, "3": 0.0}
# --- RÉFÉRENCES DES SCRIPTS (Assignées par le Main/Général) ---
var script_general = null 
var script_saloon = null 
var script_restaurant = null 
var script_bank = null
var script_armory = null
var script_duel = null
var script_don = null
var cache_cartes = null
#------- Actions par Tour ----------------------------------
var actions_faites : int = 0
const MAX_ACTIONS : int = 2

func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(_on_FirebaseAuth_login_succeeded)
	Firebase.Auth.login_with_email_and_password("chloe29.maurer@gmail.com", "Yeraci_8")
	
func _on_FirebaseAuth_login_succeeded(_auth):
	print("Firebase Connecté. Initialisation du Dispatcher Global...")
	db_ref = Firebase.Database.get_database_reference("", {})
	db_ref.new_data_update.connect(_on_db_data_update)
	db_ref.patch_data_update.connect(_on_db_data_update)
	is_ready = true
	db_ready.emit()

# --- LE DISPATCHER CENTRAL -------------------------------------------

func _on_db_data_update(resource: FirebaseResource):
	var chemin = resource.key
	var data = resource.data
	
	if chemin == null: return

#---- 1. PROFILS--------------------------------
	if chemin.begins_with("profils") or chemin == "profils":
		if script_general:
			# On envoie TOUT le dictionnaire au script général
			script_general.distribuer_donnees(chemin, data)
			
		_trier_donnees_locales(chemin, data)
		
		if script_bank and script_bank.has_method("mettre_a_jour_interface"):
			script_bank.mettre_a_jour_interface()
			
		if script_armory and script_armory.has_method("mettre_a_jour_interface"):
			script_armory.mettre_a_jour_interface()
#---- 2. SALOON-------------------------------
	if chemin.begins_with("saloon"):
		if script_saloon and typeof(script_saloon) == TYPE_OBJECT:
			var sub_key = chemin.replace("saloon/", "")
			script_saloon.mettre_a_jour_catalogue(sub_key, data)
		else:
			print("Erreur : script_saloon n'est pas un nœud valide !")

#----- 3. RESTAURANT (Indépendant)-----------
	if chemin.begins_with("restaurant"):
		if script_restaurant and typeof(script_restaurant) == TYPE_OBJECT:
			var sub_key = chemin.replace("restaurant/", "")
			script_restaurant.mettre_a_jour_catalogue(sub_key, data)
		else:
			print("Erreur : script_restaurant n'est pas un nœud valide !")
#----- 4. CARTES -----------
	if chemin.begins_with("cartes"):
		cache_cartes = data # On garde une copie pour le Main
		print("[DB] Données Cartes reçues !")
	
		if script_general and script_general.keypad.size() > 0:
			# On prépare la clé pour les scripts
			var sub_key = chemin.replace("cartes/", "")
			
			for kp in script_general.keypad:
				if is_instance_valid(kp):
					# LA SÉCURITÉ : On vérifie si le script est bien là
					if kp.has_method("mettre_a_jour_catalogue"):
						kp.mettre_a_jour_catalogue(sub_key, data)
					else:
						# Si ce print apparaît, le script Keypad.gd n'est pas sur le nœud !
						print("[DB] ERREUR : Le nœud ", kp.name, " n'a pas le script Keypad.gd")
		else:
			print("[DB] En attente du script_general pour envoyer les cartes.")
			
	#---- 2. Mini jeux-------------------------------
	if chemin.begins_with("mini_jeu"):
		_verifier_scores_minijeux(data)
		
# --- LOGIQUE DE TRIAGE DES VARIABLES ----------------------------------

func _trier_donnees_locales(chemin: String, data):
	var tag_actif = "ID" + current_profil_id
	
	# Cas A : C'est une valeur unique pour le profil actif (ex: profils/ID0/Vie)
	if chemin.contains(tag_actif):
		_update_local_vars(chemin, data)
	
	# Cas B : C'est le dictionnaire complet "profils" qui arrive
	elif chemin == "profils" and typeof(data) == TYPE_DICTIONARY:
		if data.has(tag_actif):
			_update_local_vars("", data[tag_actif])

func _update_local_vars(chemin: String, data):
	# Si data est une valeur seule
	if typeof(data) != TYPE_DICTIONARY:
		if "Argent" in chemin: money_local = int(data)
		elif "Vie" in chemin: life_local = int(data)
		elif "Nourriture" in chemin: food_local = int(data)
		elif "Boisson" in chemin: drink_local = int(data)
		elif "Munition" in chemin: munition_local = int(data)
		elif "Arme" in chemin: actual_Gun = int(data)
	# Si data est le dictionnaire du profil
	else:
		if data.has("Argent"): money_local = int(data["Argent"])
		if data.has("Vie"): life_local = int(data["Vie"])
		if data.has("Nourriture"): food_local = int(data["Nourriture"])
		if data.has("Boisson"): drink_local = int(data["Boisson"])
		if data.has("Munition"): munition_local = int(data["Munition"])
		if data.has("Arme"): actual_Gun = int(data["Arme"])


# ----- Tour ---------------------------------------------------------

func peut_agir() -> bool:
	return actions_faites < MAX_ACTIONS

func enregistrer_action():
	actions_faites += 1
	print("Action enregistrée. Total : ", actions_faites, "/", MAX_ACTIONS)
	if actions_faites >= MAX_ACTIONS:
		print("Plus d'actions disponibles !")

# --- FONCTIONS D'ÉCRITURE --------------------------------------------

func spend_money(montant: int, profil_id: String) -> bool:
	if money_local >= montant:
		var nouveau_solde = money_local - montant
		Firebase.Database.get_database_reference("profils/ID" + profil_id).update("", {"Argent": nouveau_solde})
		return true
	return false

func get_munition(montant_a_ajouter: int, profil_id: String):
	munition_local += montant_a_ajouter
	Firebase.Database.get_database_reference("profils/ID" + profil_id).update("", {"Munition": munition_local})

func get_money(montant: int, profil_id: String):
	var nouveau_total = money_local + montant
	Firebase.Database.get_database_reference("profils/ID" + profil_id).update("", {"Argent": nouveau_total})

func get_life(montant: int, profil_id: String):
	var nouveau_total = clampi(life_local + montant, 0, 5)
	Firebase.Database.get_database_reference("profils/ID" + profil_id).update("", {"Vie": nouveau_total})

func lose_life(montant: int, profil_id: String):
	var index = int(profil_id)
	if script_general and script_general.profils_noeuds.size() > index:
		var cible = script_general.profils_noeuds[index]
		var vie_actuelle = cible.get_life() 
		var nouveau_total = clampi(vie_actuelle - montant, 0, 5)
		Firebase.Database.get_database_reference("profils/ID" + profil_id).update("", {"Vie": nouveau_total})

		if nouveau_total <= 0:
			script_general.Kill_player(index)
			
func get_drink(val: int, profil_id: String):
	var cible_node = script_general.profils_noeuds[int(profil_id)]
	var valeur_actuelle_cible = cible_node.get_drink()
	var nouveau_total = clampi(valeur_actuelle_cible + val, 0, 5)
	var db_link = Firebase.Database.get_database_reference("profils/ID" + profil_id)
	db_link.update("", {"Boisson": nouveau_total})
	
	print("[DB] Don Boisson : ID", profil_id, " passe à ", nouveau_total)

func get_food(val: int, profil_id: String):
	# 1. On récupère la valeur actuelle de celui qui REÇOIT
	var cible_node = script_general.profils_noeuds[int(profil_id)]
	var valeur_actuelle_cible = cible_node.get_food()
	var nouveau_total = clampi(valeur_actuelle_cible + val, 0, 5)
	Firebase.Database.get_database_reference("profils/ID" + profil_id).update("", {"Nourriture": nouveau_total})
	print("[DB] Don Nourriture : ID", profil_id, " passe à ", nouveau_total)

func update_gun(val: int, profil_id: String):
	if val == 2 && actual_Gun == 1 :
		actual_Gun = val
	elif val == 3 && actual_Gun == 2 :
		actual_Gun = val
	elif val == 3 && actual_Gun == 3 :
		print("Arme déjà au max")
	elif val == 3 && actual_Gun == 1 :
		print("Veuillez d'abord augmenter au niveau 2")
	else :
		print("arme impossible a upgrader")
	Firebase.Database.get_database_reference("profils/ID" + profil_id).update("", {"Arme": actual_Gun})
	print (actual_Gun)

func disable_card(id_carte: String):
	# Le chemin sera "cartes/ID58"
	var chemin = "cartes/" + id_carte
	Firebase.Database.get_database_reference(chemin).update("", {"disponible": false})

#---- Mini jeux ----------------------------
func play_minijeux(id_minijeux: String):
	recompenses_distribuees = false
	scores_accumules = {"0": 0.0, "1": 0.0, "2": 0.0, "3": 0.0}
	
	# 1. Activer le mini-jeu
	var chemin_jeu = "MiniJeux/" + id_minijeux
	Firebase.Database.get_database_reference(chemin_jeu).update("", {"play": true})
	
	# 2. Reset UNIQUEMENT les scores sans supprimer le "status" ou les "autres trucs"
	# On crée un dictionnaire de chemins précis
	var updates = {
		"ID0/temps": 0,
		"ID1/temps": 0,
		"ID2/temps": 0,
		"ID3/temps": 0
	}
	
	Firebase.Database.get_database_reference("mini_jeu").update("", updates)
	print("[DB] Mini-jeu ", id_minijeux, " activé. Seuls les temps ont été réinitialisés.")


func _verifier_scores_minijeux(data):
	if typeof(data) != TYPE_DICTIONARY: return
	
	# 1. Mise à jour de la mémoire locale
	for i in range(4):
		var key = "ID" + str(i)
		if data.has(key) and data[key] != null:
			# On convertit en String puis en float pour éviter le crash de constructeur
			var value_as_string = str(data[key])
			scores_accumules[str(i)] = value_as_string.to_float()
	
	# 2. Vérification des scores
	var resultats_temp = []
	var joueurs_termines = 0
	
	for id_key in scores_accumules.keys():
		var temps = scores_accumules[id_key]
		if temps > 0.0:
			joueurs_termines += 1
			resultats_temp.append({"id": id_key, "temps": temps})
	
	# 3. Podium
	if joueurs_termines == 4 and not recompenses_distribuees:
		recompenses_distribuees = true
		print("[SYSTÈME] Les 4 scores sont là : ", scores_accumules)
		winner_miniJeux(resultats_temp)

func winner_miniJeux(resultats: Array):
	# 1. On trie le tableau du plus petit temps au plus grand
	# (Le plus rapide gagne)
	resultats.sort_custom(func(a, b): return a["temps"] < b["temps"])
	
	print("--- RÉSULTATS DU MINI-JEU ---")
	
	for i in range(resultats.size()):
		var id_joueur = resultats[i]["id"]
		var temps = resultats[i]["temps"]
		var nom_joueur = "Joueur " + str(int(id_joueur) + 1) # Pour l'affichage
		
		match i:
			0: # PREMIER
				print("1er: ", nom_joueur, " (", temps, "s) -> +5 pièces")
				get_money(5, id_joueur)
				
			1: # DEUXIÈME
				print("2ème: ", nom_joueur, " (", temps, "s) -> +3 pièces")
				get_money(3, id_joueur)
				
			2: # TROISIÈME
				print("3ème: ", nom_joueur, " (", temps, "s) -> +2 pièces")
				get_money(2, id_joueur)
				
			3: # DERNIER (Quatrième)
				# On récupère le nom du premier pour le print spécial
				var nom_premier = "Joueur " + str(int(resultats[0]["id"]) + 1)
				print("Dernier: ", nom_joueur, ". Action: Donner deux cartes à ", nom_premier)

#---- Duel ----------------------------
func duel_versus(id_attaquant: String, id_cible: String):
	# On définit les chemins pour les deux joueurs dans le dossier MiniJeux
	var chemin_attaquant = "mini_jeu/ID" + id_attaquant
	var chemin_cible = "mini_jeu/ID" + id_cible
	
	Firebase.Database.get_database_reference(chemin_attaquant).update("", {"duel": true})
	Firebase.Database.get_database_reference(chemin_cible).update("", {"duel": true})
	
	print("[DB] Duel activé pour ID", id_attaquant, " et ID", id_cible)
	
#---- Reset ----------------------------
func reset_game_start():
	print("[DB] Réinitialisation complète de la partie...")
	
	# 1. On réinitialise les 4 profils (ID0 à ID3)
	for i in range(4):
		var id_str = "ID" + str(i)
		var path = "profils/" + id_str
		
		var reset_data = {
			"Vie": 5,
			"Boisson": 5,
			"Nourriture": 5,
			"Munition": 0,
			"Argent": 10, 
			"Arme": 1
		}
		
		Firebase.Database.get_database_reference(path).update("", reset_data)
		script_general.revive_player()
	
	_reset_all_cards()
	
	manches = 0
	if script_general:
		var m1 = script_general.get_node_or_null("Manches")
		var m2 = script_general.get_node_or_null("Manches2")

		if m1: m1.fill_wagon() # Va maintenant remettre les textures vides
		if m2: m2.fill_wagon()
			
func _reset_all_cards():
	for i in range(100): 
		var id_carte = "ID" + str(i)
		Firebase.Database.get_database_reference("cartes/" + id_carte).update("", {"disponible": true})
	
	print("[DB] 100 Cartes réinitialisées à 'disponible: true'.")
	
