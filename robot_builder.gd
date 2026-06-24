extends Node2D

signal robot_completed(unit_data: Dictionary)

@export var snap_distance := 28.0

@export var body_head_socket_offset := Vector2(0, -48)
@export var head_neck_socket_offset := Vector2(0, 48)

@export var auto_reset_after_success := true
@export var success_reset_delay := 0.6

@onready var body_part: Sprite2D = $BodyPart
@onready var head_choices: Node2D = $HeadChoices
@onready var minigame_host: MinigameHost = $MinigameHost
@onready var label: Label = $Label

var head_parts: Array[Sprite2D] = []
var starting_positions := {}

var dragging_head: Sprite2D = null
var drag_offset := Vector2.ZERO

var pending_head: Sprite2D = null
var builder_locked := false

var head_unit_database := {
	"Head1": {
		"display_name": "Unit 1",
		"unit_type": "unit_1",
		"damage": 35,
		"move_speed": 70,
		"lane_cost": 1,
		"behavior": "explode_on_contact"
	},
	"Head2": {
		"display_name": "Unit 2",
		"unit_type": "unit_2",
		"damage": 20,
		"move_speed": 55,
		"lane_cost": 2,
		"behavior": "ranged_projectile"
	},
	"Head3": {
		"display_name": "Unit 3",
		"unit_type": "unit_3",
		"damage": 12,
		"move_speed": 95,
		"lane_cost": 1,
		"behavior": "fast_melee"
	}
}


func _ready() -> void:
	label.text = "Choose a head, attach it to the body, then complete the minigame."

	body_part.centered = true

	for child in head_choices.get_children():
		if child is Sprite2D:
			var head := child as Sprite2D

			head.centered = true
			head_parts.append(head)
			starting_positions[head] = head.global_position

			var unit_data := _get_unit_data_for_head(head)
			head.set_meta("unit_data", unit_data)

	minigame_host.minigame_finished.connect(_on_minigame_finished)


# Handles dragging heads around the builder area.
func _unhandled_input(event: InputEvent) -> void:
	if builder_locked:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag()
			else:
				_stop_drag()

	if event is InputEventMouseMotion:
		if dragging_head != null:
			dragging_head.global_position = get_global_mouse_position() + drag_offset


# Starts dragging whichever head the player clicked.
func _start_drag() -> void:
	var mouse_pos := get_global_mouse_position()

	dragging_head = _get_head_under_mouse(mouse_pos)

	if dragging_head != null:
		drag_offset = dragging_head.global_position - mouse_pos
		dragging_head.z_index = 10

		var unit_data: Dictionary = dragging_head.get_meta("unit_data", {})
		label.text = "Selected: " + str(unit_data.get("display_name", "Unknown Unit"))


# Stops dragging and checks whether the head was attached to the body.
func _stop_drag() -> void:
	if dragging_head == null:
		return

	dragging_head.z_index = 2
	_try_connect_head(dragging_head)
	dragging_head = null


# Finds which head the mouse is currently over.
func _get_head_under_mouse(mouse_pos: Vector2) -> Sprite2D:
	for head in head_parts:
		if head.visible and _mouse_is_over_sprite(head, mouse_pos):
			return head

	return null


# Checks whether the mouse is inside a sprite's rectangle.
func _mouse_is_over_sprite(sprite: Sprite2D, mouse_pos: Vector2) -> bool:
	if sprite.texture == null:
		return false

	var local_mouse_pos := sprite.to_local(mouse_pos)
	var texture_size := sprite.texture.get_size()

	var sprite_rect := Rect2(
		-texture_size / 2.0,
		texture_size
	)

	return sprite_rect.has_point(local_mouse_pos)


# Checks whether the selected head is close enough to snap onto the body.
func _try_connect_head(head: Sprite2D) -> void:
	var body_socket_global := body_part.to_global(body_head_socket_offset)
	var head_socket_global := head.to_global(head_neck_socket_offset)

	var distance := body_socket_global.distance_to(head_socket_global)

	if distance <= snap_distance:
		_snap_head_to_body(head)

		pending_head = head
		builder_locked = true

		var unit_data: Dictionary = pending_head.get_meta("unit_data", {})
		label.text = "Building: " + str(unit_data.get("display_name", "Unknown Unit"))

		minigame_host.start_random_minigame({
			"part_name": pending_head.name,
			"unit_data": unit_data
		})
	else:
		label.text = "That head is not lined up with the body yet."


# Snaps the head into the correct position on top of the body.
func _snap_head_to_body(head: Sprite2D) -> void:
	var body_socket_global := body_part.to_global(body_head_socket_offset)
	var head_socket_global := head.to_global(head_neck_socket_offset)

	var movement_needed := body_socket_global - head_socket_global
	head.global_position += movement_needed


# Handles success or failure from whichever minigame the host chose.
func _on_minigame_finished(success: bool) -> void:
	if pending_head == null:
		builder_locked = false
		return

	if not success:
		label.text = "Minigame failed. Try again."
		_return_head_to_start(pending_head)
		pending_head = null
		builder_locked = false
		return

	_complete_robot_from_head(pending_head)


# Creates the completed unit data based on which head was attached.
func _complete_robot_from_head(head: Sprite2D) -> void:
	var unit_data: Dictionary = head.get_meta("unit_data", {}).duplicate(true)

	unit_data["head_node_name"] = head.name

	label.text = "Completed: " + str(unit_data.get("display_name", "Unknown Unit"))

	print("Robot completed:")
	print(unit_data)

	robot_completed.emit(unit_data)

	if auto_reset_after_success:
		await get_tree().create_timer(success_reset_delay).timeout
		reset_builder()
	else:
		builder_locked = false


# Resets the builder so the player can build another robot.
func reset_builder() -> void:
	for head in head_parts:
		head.visible = true
		head.z_index = 2
		_return_head_to_start(head)

	pending_head = null
	dragging_head = null
	builder_locked = false

	label.text = "Choose a head, attach it to the body, then complete the minigame."


# Sends a head back to its original choice position.
func _return_head_to_start(head: Sprite2D) -> void:
	if starting_positions.has(head):
		head.global_position = starting_positions[head]


# Looks up what unit a specific numbered head should create.
func _get_unit_data_for_head(head: Sprite2D) -> Dictionary:
	var head_name := str(head.name)

	if head_unit_database.has(head_name):
		return head_unit_database[head_name].duplicate(true)

	push_warning("No unit data found for head named: " + head_name)

	return {
		"display_name": "Unknown Unit",
		"unit_type": "unknown_unit",
		"damage": 1,
		"move_speed": 50,
		"lane_cost": 1,
		"behavior": "basic"
	}
