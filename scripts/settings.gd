extends Control

@onready var panel_settings: Panel = $Panel2


func _on_button_pressed() -> void:
	panel_settings.visible = !panel_settings.visible


func _on_reset_pressed() -> void:
	DatabaseConfig.reset_game_start()
