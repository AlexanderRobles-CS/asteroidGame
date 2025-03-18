extends Control

signal startGame

func _on_play_game_pressed() -> void:
	emit_signal("startGame")


func _on_quit_game_pressed() -> void:
	get_tree().quit()
