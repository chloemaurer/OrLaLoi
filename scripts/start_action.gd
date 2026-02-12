extends Control

@onready var dés: Control = $"../Dés"
@onready var places: Node2D = $"../Places"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dés.hide()
	



func _on_piocher_pressed() -> void:
	self.hide()



func _on_lancer_les_dé_pressed() -> void:
	self.hide()
	if dés.has_method("rerolled"):
		dés.rerolled()
	dés.show()
