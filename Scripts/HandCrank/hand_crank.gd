class_name HandCrank
extends Node2D

# notifies listeners when this is cranked, and by how much
signal cranked(distance : float)

# how far the crank should be able to rotate in one second (deg)
@export var MAX_ROTATION_SPEED : float = 1080.0

# tracks whether the hand crank is currently following the mouse
var following_mouse : bool = false
# used to convert the max rotation speed to radians for godot's use
var max_rotation_speed_rad : float
var last_crank_pos : float

func _ready() -> void:
	max_rotation_speed_rad = deg_to_rad(MAX_ROTATION_SPEED)
	$HandCrankHandle/ClickableArea.input_event.connect(on_crank_handle_input)
	$HandCrankHandle/DraggableArea.mouse_exited.connect(on_mouse_exited_range)
	
	last_crank_pos = rotation


# begin following the mouse when the crank is clicked
func on_crank_handle_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("left_click"):
		following_mouse = true


# stop following the mouse when it gets too far from the crank handle
func on_mouse_exited_range() -> void:
	following_mouse = false


func _physics_process(delta: float) -> void:
	if following_mouse:
		# stop following the mouse when the mouse button is released
		if not Input.is_action_pressed("left_click"):
			following_mouse = false
			return
		# rotates the crank toward the mouse cursor, limited by the max rotation speed
			# Why are multiplying max rot by delta ?
		var max_frame_rotation = max_rotation_speed_rad * delta
		var frame_rotation = clamp(
				get_angle_to(get_global_mouse_position()),
				 -max_frame_rotation,
				 max_frame_rotation
			)
		rotation += frame_rotation
		# let listeners know the crank was cranked
		cranked.emit(frame_rotation)
		last_crank_pos = rotation
