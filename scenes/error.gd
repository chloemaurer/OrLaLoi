extends Control

@onready var error_text: Label = $ErrorText
@onready var timer: Timer = $Timer

func _ready():
	#self.hide()
	DatabaseConfig.demande_affichage_erreur.connect(_afficher_message)

func _afficher_message():
	error_text.text = DatabaseConfig.error_message
	
	self.show()
	timer.start()
	
	# Ton animation
	self.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
func _on_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	self.hide()
