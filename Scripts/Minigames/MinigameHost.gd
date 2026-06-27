extends Control

class_name MinigameHost

signal minigame_finished(success: bool)
signal update_splash_text(text: String)

@export var host_size := Vector2(640, 720)
@export var minigame_scenes: Array[PackedScene] = []
@export var use_random_minigames := false

var current_minigame: BaseMinigame = null
var next_minigame_index := 0


func _ready() -> void:
	position = Vector2.ZERO
	size = host_size

	z_index = 1000
	z_as_relative = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	hide()


# Chooses which action minigame the player has to complete.
func start_random_minigame(context: Dictionary = {}) -> void:
	if minigame_scenes.is_empty():
		push_warning("No minigame scenes assigned to MinigameHost.")
		minigame_finished.emit(false)
		return

	var scene: PackedScene = null

	if use_random_minigames:
		scene = minigame_scenes.pick_random()
	else:
		scene = minigame_scenes[next_minigame_index]
		next_minigame_index += 1

		if next_minigame_index >= minigame_scenes.size():
			next_minigame_index = 0

	if scene == null:
		push_warning("Chosen minigame scene is empty.")
		minigame_finished.emit(false)
		return

	_start_minigame_scene(scene, context)


# Lets you force a specific minigame instead of picking randomly.
func start_minigame_by_index(index: int, context: Dictionary = {}) -> void:
	if index < 0 or index >= minigame_scenes.size():
		push_warning("Invalid minigame index.")
		minigame_finished.emit(false)
		return

	_start_minigame_scene(minigame_scenes[index], context)


# Spawns the chosen minigame and starts the challenge.
func _start_minigame_scene(scene: PackedScene, context: Dictionary) -> void:
	_clear_current_minigame()

	show()

	var instance := scene.instantiate()
	current_minigame = instance as BaseMinigame
	update_splash_text.emit(instance.splash_text)

	if current_minigame == null:
		push_warning("Selected scene does not extend BaseMinigame.")
		instance.queue_free()
		hide()
		minigame_finished.emit(false)
		return

	add_child(current_minigame)

	current_minigame.position = Vector2.ZERO
	current_minigame.size = size
	current_minigame.z_index = 1001
	current_minigame.z_as_relative = false
	current_minigame.mouse_filter = Control.MOUSE_FILTER_STOP

	current_minigame.minigame_completed.connect(_on_current_minigame_completed)
	current_minigame.start_minigame(context)


# Receives the minigame result and sends it back to the robot builder.
func _on_current_minigame_completed(success: bool) -> void:
	_clear_current_minigame()
	hide()
	minigame_finished.emit(success)


# Removes the old minigame so the next one starts clean.
func _clear_current_minigame() -> void:
	if current_minigame != null and is_instance_valid(current_minigame):
		current_minigame.queue_free()

	current_minigame = null
