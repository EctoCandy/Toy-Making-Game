extends BaseMinigame

class_name ConnectPointsMinigame

@export var max_mistakes := 3
@export var drop_distance := 55.0
@export var line_thickness := 6.0

var panel: Panel
var title_label: Label
var feedback_label: Label
var cancel_button: Button

var left_buttons: Array[Button] = []
var right_buttons: Array[Button] = []

var point_ids := ["A", "B", "C"]

var selected_point_id := ""
var selected_point_button: Button = null
var current_drag_line: Line2D = null

var completed_connections := {}
var permanent_lines := {}

var mistakes := 0


func _ready() -> void:
	_build_ui()
	hide()


# Creates the minigame window, point buttons, target buttons, and cancel button.
func _build_ui() -> void:
	panel = Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(50, 150)
	panel.size = Vector2(430, 370)
	add_child(panel)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Connect Matching Points"
	title_label.position = Vector2(40, 20)
	title_label.size = Vector2(330, 40)
	panel.add_child(title_label)

	feedback_label = Label.new()
	feedback_label.name = "FeedbackLabel"
	feedback_label.text = "Drag each point to its matching target."
	feedback_label.position = Vector2(40, 295)
	feedback_label.size = Vector2(240, 60)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(feedback_label)

	var left_point_1 := _make_button("LeftPoint1", Vector2(40, 85))
	var left_point_2 := _make_button("LeftPoint2", Vector2(40, 155))
	var left_point_3 := _make_button("LeftPoint3", Vector2(40, 225))

	var right_target_1 := _make_button("RightTarget1", Vector2(265, 85))
	var right_target_2 := _make_button("RightTarget2", Vector2(235, 155))
	var right_target_3 := _make_button("RightTarget3", Vector2(280, 225))

	left_buttons = [
		left_point_1,
		left_point_2,
		left_point_3
	]

	right_buttons = [
		right_target_1,
		right_target_2,
		right_target_3
	]

	for button in left_buttons:
		button.button_down.connect(_on_left_point_button_down.bind(button))

	cancel_button = _make_button("CancelButton", Vector2(315, 315))
	cancel_button.size = Vector2(90, 35)
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(func(): end_minigame(false))


func _make_button(button_name: String, button_position: Vector2) -> Button:
	var button := Button.new()
	button.name = button_name
	button.position = button_position
	button.size = Vector2(130, 40)
	button.text = button_name
	panel.add_child(button)
	return button


# Resets the challenge and shuffles the targets so the matches are not straight across.
func start_minigame(new_context: Dictionary = {}) -> void:
	super.start_minigame(new_context)

	_clear_all_lines()

	selected_point_id = ""
	selected_point_button = null
	completed_connections.clear()
	permanent_lines.clear()
	mistakes = 0

	title_label.text = "Connect Matching Points"
	feedback_label.text = "Drag each point to its matching target."

	var right_order := _get_non_straight_target_order()

	for i in range(left_buttons.size()):
		var point_id: String = point_ids[i]
		var button := left_buttons[i]

		button.disabled = false
		button.show()
		button.text = "Point " + point_id
		button.set_meta("point_id", point_id)

	for i in range(right_buttons.size()):
		var point_id: String = right_order[i]
		var button := right_buttons[i]

		button.disabled = false
		button.show()
		button.text = "Target " + point_id
		button.set_meta("point_id", point_id)


# Updates the drag line while the player is dragging a point.
func _input(event: InputEvent) -> void:
	if not active:
		return

	if selected_point_id == "":
		return

	if event is InputEventMouseMotion:
		_update_drag_line(event.position)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_finish_drag(event.position)


# Starts dragging a point when the player clicks one on the left.
func _on_left_point_button_down(button: Button) -> void:
	if button.disabled:
		return

	var point_id := str(button.get_meta("point_id"))

	if completed_connections.has(point_id):
		return

	selected_point_id = point_id
	selected_point_button = button

	feedback_label.text = "Dragging Point " + selected_point_id

	_create_drag_line()


func _create_drag_line() -> void:
	if current_drag_line != null:
		current_drag_line.queue_free()

	current_drag_line = Line2D.new()
	current_drag_line.width = line_thickness
	current_drag_line.default_color = _get_point_color(selected_point_id)
	current_drag_line.z_index = 200

	add_child(current_drag_line)

	var start_pos := _get_left_anchor(selected_point_button)
	var mouse_pos := get_viewport().get_mouse_position()

	_set_line_points(current_drag_line, start_pos, mouse_pos)


func _update_drag_line(mouse_pos: Vector2) -> void:
	if current_drag_line == null:
		return

	if selected_point_button == null:
		return

	var start_pos := _get_left_anchor(selected_point_button)
	_set_line_points(current_drag_line, start_pos, mouse_pos)


# When the player releases the mouse, checks whether they dropped on the correct target.
func _finish_drag(mouse_pos: Vector2) -> void:
	var target := _get_target_at_position(mouse_pos)

	if target == null:
		feedback_label.text = "Dropped too far from a target. Try again."
		_clear_current_drag()
		return

	var target_point_id := str(target.get_meta("point_id"))

	if selected_point_id == target_point_id:
		_complete_connection(selected_point_id, selected_point_button, target)
	else:
		mistakes += 1
		feedback_label.text = "Wrong target. Mistakes: " + str(mistakes) + "/" + str(max_mistakes)
		_clear_current_drag()

		if mistakes >= max_mistakes:
			end_minigame(false)


func _get_target_at_position(mouse_pos: Vector2) -> Button:
	for target in right_buttons:
		if target.disabled:
			continue

		var target_anchor := _get_right_anchor(target)

		if mouse_pos.distance_to(target_anchor) <= drop_distance:
			return target

		if target.get_global_rect().has_point(mouse_pos):
			return target

	return null


# Locks in a correct connection and wins once all points are connected.
func _complete_connection(point_id: String, left_button: Button, right_button: Button) -> void:
	completed_connections[point_id] = true

	left_button.disabled = true
	right_button.disabled = true

	feedback_label.text = "Point " + point_id + " connected."

	if current_drag_line != null:
		_set_line_points(
			current_drag_line,
			_get_left_anchor(left_button),
			_get_right_anchor(right_button)
		)

		permanent_lines[point_id] = current_drag_line
		current_drag_line = null

	selected_point_id = ""
	selected_point_button = null

	if completed_connections.size() >= point_ids.size():
		end_minigame(true)


# Clears the active drag attempt.
func _clear_current_drag() -> void:
	if current_drag_line != null:
		current_drag_line.queue_free()
		current_drag_line = null

	selected_point_id = ""
	selected_point_button = null


# Clears all connection lines before a new attempt starts.
func _clear_all_lines() -> void:
	if current_drag_line != null:
		current_drag_line.queue_free()
		current_drag_line = null

	for line in permanent_lines.values():
		if is_instance_valid(line):
			line.queue_free()

	permanent_lines.clear()


func _set_line_points(line: Line2D, start_global: Vector2, end_global: Vector2) -> void:
	line.points = [
		line.to_local(start_global),
		line.to_local(end_global)
	]


func _get_left_anchor(button: Button) -> Vector2:
	return button.global_position + Vector2(button.size.x, button.size.y / 2.0)


func _get_right_anchor(button: Button) -> Vector2:
	return button.global_position + Vector2(0, button.size.y / 2.0)


func _get_non_straight_target_order() -> Array:
	var order := point_ids.duplicate()
	order.shuffle()

	while _order_has_straight_match(order):
		order.shuffle()

	return order


func _order_has_straight_match(order: Array) -> bool:
	for i in range(order.size()):
		if order[i] == point_ids[i]:
			return true

	return false


func _get_point_color(point_id: String) -> Color:
	match point_id:
		"A":
			return Color(1.0, 0.1, 0.1)
		"B":
			return Color(0.1, 0.9, 0.2)
		"C":
			return Color(0.2, 0.45, 1.0)
		_:
			return Color.WHITE
