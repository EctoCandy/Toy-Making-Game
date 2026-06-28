class_name WindUpKey
extends Node2D

# TODO: Fix collision shape somehow changing to a circle when instantiated

signal cranked(distance: float)

@export var max_rotation_speed_degrees: float = 1150.0

var following_mouse: bool = false
var max_rotation_speed_rad: float = 0.0
var active: bool = false
var area_2_hover : bool = false


func _ready() -> void:
	max_rotation_speed_rad = deg_to_rad(max_rotation_speed_degrees)

	_connect_clickable_area("ClickableArea1")
	_connect_clickable_area("ClickableArea2")
	# Signals used to track which handle is selected
	$ClickableArea2.mouse_entered.connect(clickable_area_2_entered)
	$ClickableArea2.mouse_exited.connect(clickable_area_2_exited)

	# The key should always start hidden until RobotBuilder turns it on.
	set_enabled(false)


# Connects one clickable area to the wind-up input.
func _connect_clickable_area(area_name: String) -> void:
	var area_node: Node = get_node_or_null(area_name)

	if area_node == null:
		push_warning("WindUpKey is missing: " + area_name)
		return

	var area: Area2D = area_node as Area2D

	if area == null:
		push_warning(area_name + " is not an Area2D.")
		return

	var input_callable: Callable = Callable(self, "_on_clickable_area_input")

	if not area.input_event.is_connected(input_callable):
		area.input_event.connect(input_callable)


# Turns the wind-up key on or off.
func set_enabled(value: bool) -> void:
	active = value
	visible = value
	following_mouse = false
	set_physics_process(value)

	z_index = 100
	z_as_relative = false

	_set_area_enabled("ClickableArea1", value)
	_set_area_enabled("ClickableArea2", value)


# Enables or disables clicking on one Area2D.
func _set_area_enabled(area_name: String, value: bool) -> void:
	var area_node: Node = get_node_or_null(area_name)

	if area_node == null:
		return

	var area: Area2D = area_node as Area2D

	if area == null:
		return

	area.input_pickable = value
	area.monitoring = value
	area.monitorable = value


# Starts following the mouse when the key is clicked.
func _on_clickable_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not active:
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton

	

		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			# Sweep rotation bugs under the rug
			if area_2_hover:
				rotation -= deg_to_rad(180)
			following_mouse = true


# Rotates the key toward the mouse while the player holds left click.
func _physics_process(delta: float) -> void:
	if not active:
		return

	if not following_mouse:
		return

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		following_mouse = false
		return

	var max_frame_rotation: float = max_rotation_speed_rad * delta
	var frame_rotation: float = clampf(
		get_angle_to(get_global_mouse_position()),
		-max_frame_rotation,
		max_frame_rotation
	)

	rotation += frame_rotation

	cranked.emit(frame_rotation)

func clickable_area_2_entered()  -> void:
	area_2_hover = true

func clickable_area_2_exited() -> void:
	area_2_hover = false
