extends BaseMinigame

class_name PrecisionClickMinigame

@export var target_points := 6
@export var time_limit := 6.0
@export var point_size := Vector2(48, 48)

var panel: Panel
var title_label: Label
var feedback_label: Label
var timer_label: Label
var point_button: Button
var cancel_button: Button

var points_hit := 0
var time_left := 0.0


func _ready() -> void:
	randomize()
	_build_ui()
	hide()
	set_process(false)


# Creates the minigame window, timer, moving target button, and cancel button.
func _build_ui() -> void:
	panel = Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(50, 150)
	panel.size = Vector2(430, 370)
	add_child(panel)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.position = Vector2(40, 20)
	title_label.size = Vector2(330, 40)
	panel.add_child(title_label)

	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.position = Vector2(40, 60)
	timer_label.size = Vector2(330, 30)
	panel.add_child(timer_label)

	feedback_label = Label.new()
	feedback_label.name = "FeedbackLabel"
	feedback_label.position = Vector2(40, 95)
	feedback_label.size = Vector2(330, 50)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(feedback_label)

	point_button = Button.new()
	point_button.name = "PointButton"
	point_button.size = point_size
	point_button.text = "●"
	point_button.pressed.connect(_on_point_pressed)
	panel.add_child(point_button)

	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.position = Vector2(315, 315)
	cancel_button.size = Vector2(90, 35)
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(func(): end_minigame(false))
	panel.add_child(cancel_button)


# Resets the target count and spawns the first target.
func start_minigame(new_context: Dictionary = {}) -> void:
	super.start_minigame(new_context)

	points_hit = 0
	time_left = time_limit

	title_label.text = "Precision Click"
	feedback_label.text = "Click each target as it appears."

	point_button.disabled = false
	point_button.show()

	_spawn_point()
	_update_ui()


# Counts down and fails the player if time runs out.
func _process(delta: float) -> void:
	if not active:
		return

	time_left -= delta
	_update_ui()

	if time_left <= 0.0:
		end_minigame(false)


# Counts a successful target click and spawns the next target.
func _on_point_pressed() -> void:
	if not active:
		return

	points_hit += 1

	if points_hit >= target_points:
		point_button.hide()
		end_minigame(true)
	else:
		_spawn_point()
		_update_ui()


# Moves the target to a random spot inside the panel.
func _spawn_point() -> void:
	var min_x := 40.0
	var max_x := panel.size.x - point_size.x - 40.0

	var min_y := 145.0
	var max_y := panel.size.y - point_size.y - 65.0

	point_button.position = Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y)
	)

	point_button.show()


# Updates the timer and target counter text.
func _update_ui() -> void:
	timer_label.text = "Time left: " + str(snapped(max(time_left, 0.0), 0.1))
	feedback_label.text = "Targets hit: " + str(points_hit) + "/" + str(target_points)
