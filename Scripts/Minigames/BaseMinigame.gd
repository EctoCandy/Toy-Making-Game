extends Control

class_name BaseMinigame

signal minigame_completed(success: bool)

var active := false
var context: Dictionary = {}


# Turns the minigame on and lets it receive update logic.
func start_minigame(new_context: Dictionary = {}) -> void:
	context = new_context
	active = true
	show()
	set_process(true)


# Turns the minigame off and tells the host whether the player won or failed.
func end_minigame(success: bool) -> void:
	if not active:
		return

	active = false
	hide()
	set_process(false)
	minigame_completed.emit(success)
