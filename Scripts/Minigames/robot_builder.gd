extends Node2D

signal robot_completed(unit_data: Dictionary)

@export var snap_distance: float = 28.0
@export var builder_area_width: float = 640.0

@export var body_head_socket_offset: Vector2 = Vector2(0, -48)
@export var head_neck_socket_offset: Vector2 = Vector2(0, 48)

@export var required_wind_amount: float = TAU * 3.0
@export var wind_key_position: Vector2 = Vector2(236, 324)
@export var wind_progress_position: Vector2 = Vector2(116, 444)
@export var wind_progress_size: Vector2 = Vector2(240, 28)

@export var auto_reset_after_success: bool = true
@export var success_reset_delay: float = 0.6

@onready var body_part: Sprite2D = $BodyPart
@onready var head_choices: Node2D = $HeadChoices
@onready var minigame_host: MinigameHost = $MinigameHost
@onready var label: Label = $Label

var wind_up_key: WindUpKey = null
var wind_progress_bar: ProgressBar = null
var wind_background: Sprite2D = null

var head_parts: Array[Sprite2D] = []
var starting_positions: Dictionary = {}

var dragging_head: Sprite2D = null
var drag_offset: Vector2 = Vector2.ZERO

var pending_head: Sprite2D = null
var builder_locked: bool = false

var wind_amount: float = 0.0
var is_winding: bool = false

var head_unit_database: Dictionary = {
	# To change a units speed, you need to fine tune both the move_speed and
	# guide_move_speed. Use Debug -> Visible collision shape to help.
	
	# This is a first attempt at balancing the game change it however you feel
	"Head1": {
		"display_name": "Unit 1",
		"unit_type": "unit_1",
		"health": 100,
		"damage": 2,
		"attack_speed": 0.05,
		"move_speed": 1,
		"guide_move_speed": 0.07,
		"encounter_mask": 2,
		"behavior": "speedy boi"
	},
	"Head2": {
		"display_name": "Unit 2",
		"unit_type": "unit_2",
		"health": 350,
		"damage": 30,
		"attack_speed": 0.5,
		"move_speed": 0.4,
		"guide_move_speed": 0.030,
		"encounter_mask": 2,
		"behavior": "balanced"
	},
	"Head3": {
		"display_name": "Unit 3",
		"unit_type": "unit_3",
		"health": 550,
		"damage": 50,
		"attack_speed": 2.5,
		"move_speed": 0.2,
		"guide_move_speed": 0.014,
		"encounter_mask": 2,
		"behavior": "tank"
	}
}


func _ready() -> void:
	label.text = "Attach Head!"

	body_part.centered = true
	body_part.z_index = 1

	head_choices.z_index = 2

	for child in head_choices.get_children():
		if child is Sprite2D:
			var head: Sprite2D = child as Sprite2D

			head.centered = true
			head.z_index = 2
			head_parts.append(head)
			starting_positions[head] = head.global_position

			var unit_data: Dictionary = _get_unit_data_for_head(head)
			
			head.set_meta("unit_data", unit_data)

	var minigame_finished_callable: Callable = Callable(self, "_on_minigame_finished")

	if not minigame_host.minigame_finished.is_connected(minigame_finished_callable):
		minigame_host.minigame_finished.connect(minigame_finished_callable)
	
	if not minigame_host.update_splash_text.is_connected(minigame_finished_callable):
		minigame_host.update_splash_text.connect(_on_update_splash_text)

	_setup_wind_up_nodes()


func _on_update_splash_text(text: String):
	label.text = text


# Finds and prepares the wind-up key and progress bar.
func _setup_wind_up_nodes() -> void:
	var found_key: Node = get_node_or_null("WindUpKey")
	var found_bar: Node = get_node_or_null("WindProgressBar")
	var found_bg: Node = get_node_or_null("WindUpKeyBG")

	wind_up_key = found_key as WindUpKey
	wind_progress_bar = found_bar as ProgressBar
	wind_background = found_bg as Sprite2D

	if wind_up_key != null:
		var crank_callable: Callable = Callable(self, "_on_wind_up_key_cranked")

		if not wind_up_key.cranked.is_connected(crank_callable):
			wind_up_key.cranked.connect(crank_callable)

		wind_up_key.position = wind_key_position
		wind_up_key.rotation = 0.0
		wind_up_key.z_index = 100
		wind_up_key.z_as_relative = false

		# The key starts hidden and disabled.
		wind_up_key.set_enabled(false)
	else:
		push_warning("RobotBuilder is missing a direct child named WindUpKey.")

	if wind_progress_bar != null:
		wind_progress_bar.position = wind_progress_position
		wind_progress_bar.size = wind_progress_size
		wind_progress_bar.z_index = 101
		wind_progress_bar.z_as_relative = false
		wind_progress_bar.min_value = 0
		wind_progress_bar.max_value = required_wind_amount
		wind_progress_bar.value = 0
		wind_progress_bar.mouse_filter = Control.MOUSE_FILTER_STOP
		wind_progress_bar.hide()
	else:
		push_warning("RobotBuilder is missing a direct child named WindProgressBar.")


# Handles dragging heads only when the builder is usable.
func _unhandled_input(event: InputEvent) -> void:
	if builder_locked:
		return

	if is_winding:
		return

	if minigame_host.visible:
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_start_drag()
			else:
				_stop_drag()

	if event is InputEventMouseMotion:
		if dragging_head != null:
			dragging_head.global_position = get_global_mouse_position() + drag_offset


# Starts dragging whichever head the player clicked.
func _start_drag() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()

	if mouse_pos.x > builder_area_width:
		return

	dragging_head = _get_head_under_mouse(mouse_pos)

	if dragging_head != null:
		drag_offset = dragging_head.global_position - mouse_pos
		dragging_head.z_index = 10

		var unit_data: Dictionary = _get_stored_unit_data(dragging_head)
		# label.text = "Selected: " + str(unit_data.get("display_name", "Unknown Unit"))


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

	var local_mouse_pos: Vector2 = sprite.to_local(mouse_pos)
	var texture_size: Vector2 = sprite.texture.get_size()

	var sprite_rect: Rect2 = Rect2(
		-texture_size / 2.0,
		texture_size
	)

	return sprite_rect.has_point(local_mouse_pos)


# Checks whether the selected head is close enough to snap onto the body.
func _try_connect_head(head: Sprite2D) -> void:
	var body_socket_global: Vector2 = body_part.to_global(body_head_socket_offset)
	var head_socket_global: Vector2 = head.to_global(head_neck_socket_offset)

	var distance: float = body_socket_global.distance_to(head_socket_global)

	if distance <= snap_distance:
		_snap_head_to_body(head)

		pending_head = head
		builder_locked = true

		var unit_data: Dictionary = _get_stored_unit_data(pending_head)
		# label.text = "Building: " + str(unit_data.get("display_name", "Unknown Unit"))

		head_choices.hide()
		body_part.hide()
		minigame_host.start_random_minigame({
			"part_name": pending_head.name,
			"unit_data": unit_data
		})
	#else:
		#label.text = "That head is not lined up with the body yet."


# Snaps the head into the correct position on top of the body.
func _snap_head_to_body(head: Sprite2D) -> void:
	var body_socket_global: Vector2 = body_part.to_global(body_head_socket_offset)
	var head_socket_global: Vector2 = head.to_global(head_neck_socket_offset)

	var movement_needed: Vector2 = body_socket_global - head_socket_global
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
		reset_builder()
		return

	# IMPORTANT: do not complete the robot here.
	# The robot only completes after wind-up.
	_start_wind_up_step()


# Starts the final wind-up step after the minigame succeeds.
func _start_wind_up_step() -> void:
	is_winding = true
	builder_locked = true
	wind_amount = 0.0

	label.text = "Spin!!!"

	if wind_up_key == null:
		label.text = "ERROR: WindUpKey missing."
		push_warning("Cannot start wind-up because WindUpKey is missing.")
		return

	wind_background.show()

	wind_up_key.position = wind_key_position
	wind_up_key.rotation = 0.0
	wind_up_key.z_index = 100
	wind_up_key.z_as_relative = false
	wind_up_key.set_enabled(true)

	if wind_progress_bar != null:
		wind_progress_bar.position = wind_progress_position
		wind_progress_bar.size = wind_progress_size
		wind_progress_bar.max_value = required_wind_amount
		wind_progress_bar.value = 0
		wind_progress_bar.z_index = 101
		wind_progress_bar.z_as_relative = false
		wind_progress_bar.show()


# Adds wind-up progress whenever the key is turned.
func _on_wind_up_key_cranked(distance: float) -> void:
	if not is_winding:
		return

	wind_amount += abs(distance)

	if wind_progress_bar != null:
		wind_progress_bar.value = wind_amount

	var safe_required_amount: float = max(required_wind_amount, 0.001)
	var percent: int = int(round((wind_amount / safe_required_amount) * 100.0))

	# label.text = "Winding: " + str(percent) + "%"

	if wind_amount >= required_wind_amount:
		_finish_wind_up_step()


# Finishes the wind-up step and completes the robot.
func _finish_wind_up_step() -> void:
	if not is_winding:
		return

	is_winding = false

	if wind_up_key != null:
		wind_up_key.set_enabled(false)

	if wind_progress_bar != null:
		wind_progress_bar.hide()
	
	if wind_background != null:
		wind_background.hide()

	_complete_robot_from_head(pending_head)


# Creates the completed unit data based on which head was attached.
func _complete_robot_from_head(head: Sprite2D) -> void:
	if head == null:
		reset_builder()
		return

	var unit_data: Dictionary = _get_stored_unit_data(head).duplicate(true)
	print(unit_data)
	unit_data["head_node_name"] = head.name
	unit_data["wind_up_power"] = wind_amount
	unit_data["is_wound_up"] = true

	label.text = "Place!"
	# label.text = "Completed: " + str(unit_data.get("display_name", "Unknown Unit"))

	# This is the only place the robot should emit as completed.
	robot_completed.emit(unit_data)

	#if auto_reset_after_success:
		#await get_tree().create_timer(success_reset_delay).timeout
		#reset_builder()
	#else:
		#builder_locked = false


# Resets the builder so the player can build another robot.
func reset_builder() -> void:
	for head in head_parts:
		head.visible = true
		head.z_index = 2
		_return_head_to_start(head)

	pending_head = null
	dragging_head = null
	builder_locked = false
	is_winding = false
	wind_amount = 0.0

	if wind_up_key != null:
		wind_up_key.set_enabled(false)
		wind_up_key.position = wind_key_position
		wind_up_key.rotation = 0.0

	if wind_progress_bar != null:
		wind_progress_bar.value = 0
		wind_progress_bar.hide()
	
	if wind_background != null:
		wind_background.hide()

	head_choices.show()
	body_part.show()
	label.text = "Attach!"


# Sends a head back to its original choice position.
func _return_head_to_start(head: Sprite2D) -> void:
	if starting_positions.has(head):
		head.global_position = starting_positions[head]


# Gets the unit data saved on a head.
func _get_stored_unit_data(head: Sprite2D) -> Dictionary:
	var stored_data: Variant = head.get_meta("unit_data", {})

	if stored_data is Dictionary:
		return stored_data as Dictionary

	return {
		"display_name": "Unknown Unit",
		"unit_type": "unknown_unit",
		"damage": 1,
		"move_speed": 50,
		"lane_cost": 1,
		"behavior": "basic"
	}


# Looks up what unit a specific numbered head should create.
func _get_unit_data_for_head(head: Sprite2D) -> Dictionary:
	var head_name: String = str(head.name)

	if head_unit_database.has(head_name):
		var raw_data: Variant = head_unit_database[head_name]

		if raw_data is Dictionary:
			var copied_data: Dictionary = (raw_data as Dictionary).duplicate(true)
			return copied_data

	push_warning("No unit data found for head named: " + head_name)

	return {
		"display_name": "Unknown Unit",
		"unit_type": "unknown_unit",
		"damage": 1,
		"move_speed": 50,
		"lane_cost": 1,
		"behavior": "basic"
	}
