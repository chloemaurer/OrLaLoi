extends Node2D
@onready var saloon: Control = $"../Saloon"
@onready var saloon_shop: Control = $"../SaloonShop"
@onready var restaurant_shop: Control = $"../RestaurantShop"
@onready var restaurant: Control = $"../Restaurant"
@onready var bank: Control = $"../Bank"


func _ready():
	saloon.hide()
	saloon_shop.hide()
	restaurant.hide()
	restaurant_shop.hide()
	bank.hide()

func _on_saloon_pressed() -> void:
	saloon.show()


func _on_buy_card_pressed() -> void:
	saloon_shop.show()

func _on_restaurant_pressed() -> void:
	restaurant.show()

func _on_food_buy_card_pressed() -> void:
	restaurant_shop.show()


func _on_bank_pressed() -> void:
	bank.show()
