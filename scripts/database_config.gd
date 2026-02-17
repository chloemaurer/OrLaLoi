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
var players_alive : int = 4
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
			

	#---- 2. Mini jeux & Duel -------------------------------
	# 2. MINI JEUX & DUEL
	if chemin.begins_with("mini_jeu"):
		_extraire_score(chemin, data)
		
		# On regarde si la data contient le flag "duel"
		var est_un_duel = false
		if typeof(data) == TYPE_DICTIONARY and data.get("duel") == true:
			est_un_duel = true

		if cible_duel_id != "" or est_un_duel:
			if verifier_pret_pour_duel():
				terminer_le_duel()
		else:
			# On ne distribue l'argent QUE si ce n'est pas un duel
			valider_et_distribuer()

# --- HELPER SCORES ---

func _extraire_score(chemin: String, data):
	var parties = chemin.split("/")
	if parties.size() > 1:
		var id_key = parties[1].replace("ID","")
		if typeof(data) == TYPE_DICTIONARY:
			# On check temps (mini-jeu) ou temps_duel (duel)
			if data.has("temps_duel"):
				scores_accumules[id_key] = float(data["temps_duel"])
			elif data.has("temps"):
				scores_accumules[id_key] = float(data["temps"])
		elif typeof(data) in [TYPE_INT, TYPE_FLOAT]:
			scores_accumules[id_key] = float(data)
			
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
	var index = int(profil_id)
	
	if script_general and script_general.profils_noeuds.size() > index:
		var cible_node = script_general.profils_noeuds[index]
		
		# 1. On calcule le nouveau total en prenant ce qui est déjà affiché
		var nouveau_total = cible_node.get_money() + montant
		
		# 2. ACTION CRUCIALE : On force l'UI à changer tout de suite
		if cible_node.has_method("update_visuel"):
			cible_node.update_visuel("Argent", nouveau_total)
		
		# 3. On synchronise la variable locale si c'est le joueur qui a le tour
		if profil_id == current_profil_id:
			money_local = nouveau_total
		
		# 4. On envoie à Firebase (pour que les autres joueurs reçoivent l'info)
		Firebase.Database.get_database_reference("profils/ID" + profil_id).update("", {"Argent": nouveau_total})
		print("[SUCCÈS] ID", profil_id, " gagne ", montant, ". Nouveau total affiché: ", nouveau_total)
		
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

#func winner_money(montant: int, profil_id: String):
	#var index = int(profil_id)
	#if script_general and script_general.profils_noeuds.size() > index:
		#var cible_node = script_general.profils_noeuds[index]
		#var argent_actuel_cible = cible_node.get_money()
		#var nouveau_total = argent_actuel_cible + montant
		#
		## 1. Envoi à Firebase
		#Firebase.Database.get_database_reference("profils/ID" + profil_id).update("", {"Argent": nouveau_total})
		#
		## 2. LA CORRECTION : Si le joueur qui gagne est le joueur ACTUEL, on met à jour money_local DIRECTEMENT
		#if profil_id == current_profil_id:
			#money_local = nouveau_total
			#print("[LOCAL] Argent mis à jour immédiatement pour le joueur actif.")
			#
		#print("[DB] Argent ajouté à ID", profil_id, " : ", nouveau_total)
		
		
#---- Mini jeux ----------------------------

func play_minijeux(id_minijeux: String):
	
	recompenses_distribuees = false
	scores_accumules = {"0": 0.0, "1": 0.0, "2": 0.0, "3": 0.0}
	
	# 1. Activer le mini-jeu
	var chemin = "MiniJeux/" + id_minijeux
	Firebase.Database.get_database_reference(chemin).update("", {"play": true})
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
	
	# Log pour déboguer le format exact
	print("[DEBUG MINI-JEU] Data reçue : ", data)

	if data.has("temps"):

		pass 

	# Cas 2 (Le plus probable selon tes logs) :
	# On boucle pour voir si les clés ID0, ID1... sont PRÉSENTES dans le dictionnaire
	for i in range(4):
		var key = "ID" + str(i)
		
		# Si la mise à jour contient l'ID
		if data.has(key):
			var p_data = data[key]
			if typeof(p_data) == TYPE_DICTIONARY and p_data.has("temps"):
				var t = float(p_data["temps"])
				if t > 0:
					scores_accumules[str(i)] = t
					print("-> Score mis en mémoire pour ID", i, " : ", t)
		
		# NOUVEAU : Si la data est DIRECTEMENT le dictionnaire d'un ID 
		# (C'est ce qui arrive quand le chemin est "mini_jeu/ID0")
		elif data.has("temps") and not data.has("ID0"): 
			# On ne peut pas savoir l'ID juste avec 'data', 
			# il faut regarder le 'chemin' passé au dispatcher !
			pass
				
				
func winner_miniJeux(resultats: Array):
	# Tri du plus rapide au plus lent
	resultats.sort_custom(func(a, b): return a["temps"] < b["temps"])
	
	print("--- ATTRIBUTION DES RÉCOMPENSES ---")
	for i in range(resultats.size()):
		var id_joueur = resultats[i]["id"] # "0", "1", etc.
		
		match i:
			0: # 1er
				get_money(5, id_joueur)
			1: # 2ème
				get_money(3, id_joueur)
			2: # 3ème
				get_money(2, id_joueur)
			3: # 4ème
				print("Joueur ", id_joueur, " est dernier. Pas de pièces.")
				
var peut_distribuer_recompenses : bool = false

func valider_et_distribuer():
	if not peut_distribuer_recompenses:
		print("[INFO] Scores reçus, mais j'attends le clic sur le bouton pour payer.")
		return
	var resultats_temp = []
	var survivants_ids = []

	# 1. Identifier qui est encore en vie
	for i in range(4):
		if script_general.profils_noeuds[i].get_life() > 0:
			survivants_ids.append(str(i))

	# 2. Récupérer les scores de ces survivants
	for id_key in survivants_ids:
		if scores_accumules.has(id_key):
			var t = float(scores_accumules[id_key])
			if t > 0:
				resultats_temp.append({"id": id_key, "temps": t})

	print("Scores reçus: ", resultats_temp.size(), " / Attendus (survivants): ", survivants_ids.size())

	# 3. On distribue si tous les survivants ont fini
	if resultats_temp.size() >= survivants_ids.size() and survivants_ids.size() > 0:
		print("[DISTRIBUTION] Tout le monde a fini. Calcul des prix...")
		
		# ON VIDE LES SCORES LOCAUX AVANT DE DISTRIBUER
		# Cela empêche le dispatcher de boucler si Firebase répond trop vite
		var copie_resultats = resultats_temp.duplicate()
		scores_accumules = {"0": 0.0, "1": 0.0, "2": 0.0, "3": 0.0} 
		
		winner_miniJeux(copie_resultats)
		
	else:
		print("Attente des joueurs : ", resultats_temp.size(), "/", survivants_ids.size())
		
						
#---- Duel ----------------------------
func duel_versus(id_attaquant: String, id_cible: String):
	# On définit les chemins pour les deux joueurs dans le dossier MiniJeux
	var chemin_attaquant = "mini_jeu/ID" + id_attaquant
	var chemin_cible = "mini_jeu/ID" + id_cible
	var updates = {
	"ID0/temps": 0,
	"ID1/temps": 0,
	"ID2/temps": 0,
	"ID3/temps": 0
	}
	if current_profil_id == id_attaquant:
		cible_duel_id = id_cible
	elif current_profil_id == id_cible:
		cible_duel_id = id_attaquant
		
	Firebase.Database.get_database_reference("mini_jeu").update("", updates)
	Firebase.Database.get_database_reference(chemin_attaquant).update("", {"duel": true})
	Firebase.Database.get_database_reference(chemin_cible).update("", {"duel": true})
	
	print("[DB] Duel activé pour ID", id_attaquant, " et ID", id_cible)
	
#---- Reset ----------------------------
var etait_en_reset : bool = false # AJOUTÉ : Pour automatiser le redémarrage
# --- RESET ET RELOAD ---
func reset_game_start():
	print("[DB] Lancement du Reset complet...")
	etait_en_reset = true
	for i in range(4):
		var path = "profils/ID" + str(i)
		var data = {"Vie": 5, "Boisson": 5, "Nourriture": 5, "Munition": 0, "Argent": 10, "Arme": 1}
		Firebase.Database.get_database_reference(path).update("", data)
	
	_reset_all_cards()
	Firebase.Database.get_database_reference("mini_jeu").update("", {"ID0/temps":0,"ID1/temps":0,"ID2/temps":0,"ID3/temps":0})
	
	manches = 0
	actions_faites = 0
	current_profil_id = "0"
	
	script_general = null
	script_saloon = null
	script_restaurant = null
	
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

func _reset_all_cards():
	var big_update = {}
	for i in range(100): big_update["ID" + str(i) + "/disponible"] = true
	Firebase.Database.get_database_reference("cartes").update("", big_update)
	

# --- LOGIQUE DUEL ---

func verifier_pret_pour_duel() -> bool:
	if cible_duel_id == "": return false
	
	# Sécurité : on s'assure que les clés existent
	if not scores_accumules.has(current_profil_id) or not scores_accumules.has(cible_duel_id):
		return false
		
	var t_attaquant = float(scores_accumules[current_profil_id])
	var t_cible = float(scores_accumules[cible_duel_id])
	
	# Debug pour voir les valeurs en temps réel
	print("[CHECK] Moi(ID", current_profil_id, "): ", t_attaquant, " | Lui(ID", cible_duel_id, "): ", t_cible)
	
	return t_attaquant > 0.001 and t_cible > 0.001
	

func terminer_le_duel():
	var id_a = current_profil_id
	var id_b = cible_duel_id
	
	var t_a = float(scores_accumules.get(id_a, 0))
	var t_b = float(scores_accumules.get(id_b, 0))

	if t_a <= 0 or t_b <= 0:
		print("[ERREUR] Duel incomplet")
		return

	# 1. On récupère les munitions actuelles des deux duellistes
	var m_a = script_general.profils_noeuds[int(id_a)].get_munition()
	var m_b = script_general.profils_noeuds[int(id_b)].get_munition()
	
	# 2. Déterminer le gagnant "théorique" (le plus rapide)
	var rapide = id_a if t_a < t_b else id_b
	var lent = id_b if t_a < t_b else id_a
	
	var gagnant_final = ""
	var perdant_final = ""
	
	# 3. LOGIQUE DES MUNITIONS
	# Si le plus rapide a des munitions, il gagne normalement
	if (rapide == id_a and m_a > 0) or (rapide == id_b and m_b > 0):
		gagnant_final = rapide
		perdant_final = lent
		print("[DUEL] Le plus rapide (ID", rapide, ") a tiré !")
	# Si le plus rapide n'a PAS de munitions mais que le plus lent en a
	elif (rapide == id_a and m_a <= 0 and m_b > 0) or (rapide == id_b and m_b <= 0 and m_a > 0):
		gagnant_final = lent
		perdant_final = rapide
		print("[DUEL] ID", rapide, " était plus rapide mais n'avait pas de balles ! ID", lent, " riposte !")
	else:
		print("[DUEL] Personne n'a de munitions... Match nul !")
		return

	# 4. Consommation d'une munition pour le gagnant
	get_munition(-1, gagnant_final)
	get_munition(-1, perdant_final)

	# 5. Calcul des dégâts selon l'arme du gagnant
	var degats = script_general.profils_noeuds[int(gagnant_final)].get_gun()

	print("[VICTOIRE FINALE] ID", gagnant_final, " inflige ", degats, " dégâts à ID", perdant_final)
	
	# 6. Application des dégâts
	lose_life(degats, perdant_final)
	
	scores_accumules = {"0": 0.0, "1": 0.0, "2": 0.0, "3": 0.0}
	cible_duel_id = ""


func _nettoyer_duel(id_joueur: String):
	scores_accumules[id_joueur] = 0.0
	Firebase.Database.get_database_reference("mini_jeu/ID" + id_joueur).update("", {"duel": false, "temps": 0})
