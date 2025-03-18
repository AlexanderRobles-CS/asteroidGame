extends Control

signal restartGame

func _on_restart_button_pressed() -> void:
	emit_signal("restartGame")

func _on_quit_pressed() -> void:
	get_tree().quit()
