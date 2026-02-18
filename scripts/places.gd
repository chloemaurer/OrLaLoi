extends Node2D

#----------POP UP (Les Menus qui s'ouvrent)---------------------------------------
@onready var saloon: Control = $"../Saloon"
@onready var saloon_shop: Control = $"../SaloonShop"
@onready var restaurant_shop: Control = $"../RestaurantShop"
@onready var restaurant: Control = $"../Restaurant"
@onready var bank: Control = $"../Bank"
@onready var armory: Control = $"../Armory"
@onready var duel: Control = $"../Duel"
@onready var dés: Control = $"../Dés"
@onready var mine: Control = $"../Mine"


#---------- Places (Les Boutons sur la Map) ---------------------------------------
@onready var saloon_button: Button = $Saloon
@onready var mine_button: Button = $Mine
@onready var restaurant_button: Button = $Restaurant
@onready var armory_button: Button = $Armory
@onready var bank_button: Button = $Bank
@onready var duel_button: Button = $Duel

func _ready():
	close_all()

# Ferme tous les menus/boutiques
func close_all():
	saloon.hide()
	saloon_shop.hide()
	restaurant.hide()
	restaurant_shop.hide()
	bank.hide()
	armory.hide()
	duel.hide()
	mine.hide()
# Cache tous les boutons de lieux sur la carte

func close_place():
	saloon_button.hide()
	mine_button.hide()
	restaurant_button.hide()
	armory_button.hide()
	bank_button.hide()
	duel_button.hide()

# --- LOGIQUE DES BOUTONS DE LIEUX ---

func _on_saloon_pressed() -> void:
	close_all()      # Ferme les boutiques ouvertes
	close_place()    # Cache les autres boutons
	saloon_button.show()
	saloon.show()
	dés.hide()	

func _on_restaurant_pressed() -> void:
	close_all()
	close_place()
	restaurant_button.show()
	restaurant.show()
	dés.hide()
	
func _on_bank_pressed() -> void:
	close_all()
	close_place()
	bank_button.show()
	bank.show()
	dés.hide()
	
func _on_armory_pressed() -> void:
	close_all()
	close_place()
	armory_button.show()
	armory.show()
	dés.hide()
	
func _on_duel_pressed() -> void:
	check_munition()

func check_munition():
	var munitions = DatabaseConfig.munition_local
	if munitions > 0:
		print("[OK] Munitions détectées : ", munitions)
		close_all()
		close_place()
		duel_button.show()
		duel.show()
		dés.hide()
	else:
		DatabaseConfig.notifier_erreur("Pas de munitions ! Vous ne pouvez pas lancer le duel")
		print("[REFUS] Pas de munitions ! Le joueur ne peut pas lancer de duel.")
		duel.hide() 
		
	
		
func _on_mine_pressed() -> void:
	close_all()
	close_place()
	mine_button.show()
	mine.show()
	dés.hide()
	
# --- LOGIQUE DES BOUTONS "ACHAT" (PASSAGE AU SHOP) ---

func _on_drink_buy_card_pressed() -> void:
	saloon_shop.show()
	saloon.hide() # On cache le petit menu pour voir la grande boutique

func _on_food_buy_card_pressed() -> void:
	restaurant_shop.show()
	restaurant.hide()
