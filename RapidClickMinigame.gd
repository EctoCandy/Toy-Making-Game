extends BaseMinigame

class_name RapidClickMinigame

@export var target_clicks := 18
@export var time_limit := 4.0

var panel: Panel
var title_label: Label
var feedback_label: Label
var timer_label: Label
var progress_bar: ProgressBar
var click_button: Button
var cancel_button: Button

var clicks := 0
var time_left := 0.0


func _ready() -> void:
	_build_ui()
	hide()
	set_process(false)


# Creates the minigame window, timer, progress bar, click button, and cancel button.
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
	timer_label.position = Vector2(40, 65)
	timer_label.size = Vector2(330, 30)
	panel.add_child(timer_label)

	feedback_label = Label.new()
	feedback_label.name = "FeedbackLabel"
	feedback_label.position = Vector2(40, 100)
	feedback_label.size = Vector2(330, 50)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(feedback_label)

	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.position = Vector2(40, 165)
	progress_bar.size = Vector2(350, 30)
	panel.add_child(progress_bar)

	click_button = Button.new()
	click_button.name = "ClickButton"
	click_button.position = Vector2(115, 220)
	click_button.size = Vector2(200, 60)
	click_button.text = "CLICK!"
	click_button.pressed.connect(_on_click_pressed)
	panel.add_child(click_button)

	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.position = Vector2(315, 315)
	cancel_button.size = Vector2(90, 35)
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(func(): end_minigame(false))
	panel.add_child(cancel_button)


# Resets the timer and click count when the challenge begins.
func start_minigame(new_context: Dictionary = {}) -> void:
	super.start_minigame(new_context)

	clicks = 0
	time_left = time_limit

	progress_bar.max_value = target_clicks
	progress_bar.value = 0

	click_button.disabled = false

	title_label.text = "Rapid Click"
	feedback_label.text = "Click fast enough before time runs out."

	_update_ui()


# Counts down and fails the player if time runs out.
func _process(delta: float) -> void:
	if not active:
		return

	time_left -= delta
	_update_ui()

	if time_left <= 0.0:
		end_minigame(false)


# Counts each click and checks whether the player clicked enough times.
func _on_click_pressed() -> void:
	if not active:
		return

	clicks += 1
	progress_bar.value = clicks

	if clicks >= target_clicks:
		click_button.disabled = true
		end_minigame(true)
	else:
		_update_ui()


# Updates the timer and click counter text.
func _update_ui() -> void:
	timer_label.text = "Time left: " + str(snapped(max(time_left, 0.0), 0.1))
	feedback_label.text = "Clicks: " + str(clicks) + "/" + str(target_clicks)
