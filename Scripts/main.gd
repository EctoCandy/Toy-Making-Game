extends Node2D

signal health_changed
signal lane_selected

@export var player_unit_scene: PackedScene = preload("uid://dt3wdlwjtddbi")
@export var enemy_unit_scene: PackedScene = preload("uid://daib08ro8i7su")
@export var robot_builder_scene: PackedScene = preload("res://Scenes/Minigames/RobotBuilder.tscn")

@export var max_health := 1000.0

const RAYCAST_COLLISION_MASK = 4

@export var left_screen_percent := 0.5
@export var hud_height_percent := 0.17

@export var lane_prototype_size := Vector2(1280, 720)
@export var lane_extra_shrink := 0.9

@export var enemies_per_wave := 10
@export var enemies_added_per_wave := 3
@export var seconds_between_waves := 2.0
@export var score_per_enemy := 10

var robot_builder: Node2D = null
var minigame_host: Control = null

var lane_defense_area: Node2D = null
var lane_1: Node = null
var lane_2: Node = null
var lane_3: Node = null
var spawn_timer: Timer = null

var screen_ui: CanvasLayer = null
var right_hud: Control = null
var score_label: Label = null
var wave_label: Label = null
var selected_lane_label: Label = null
var wave_progress: ProgressBar = null
var health_bar :TextureProgressBar = null

var lane_dict := {}

var selected_lane := 1
var score := 0
var wave_number := 1

var wave_in_progress := false
var enemies_this_wave := 0
var enemies_spawned_this_wave := 0
var enemies_defeated_this_wave := 0
var enemies_alive_this_wave := 0

var left_width := 472.0
var hud_left_width := 640.0
var right_width := 640.0
var hud_height := 120.0

var health : float


func _ready() -> void:
	randomize()

	_find_or_create_robot_builder()
	_find_or_create_lane_defense_area()
	_find_or_create_hud_nodes()

	lane_dict = {
		1: lane_1,
		2: lane_2,
		3: lane_3,
	}

	_apply_screen_layout()
	_connect_signals()
	_start_wave()
	
	health = max_health


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		if is_inside_tree():
			_apply_screen_layout()
			_update_hud()


# Finds the robot builder in the scene, or creates it if it is missing.
func _find_or_create_robot_builder() -> void:
	robot_builder = get_node_or_null("RobotBuilder")

	if robot_builder == null:
		robot_builder = robot_builder_scene.instantiate()
		robot_builder.name = "RobotBuilder"
		add_child(robot_builder)

	minigame_host = robot_builder.get_node_or_null("MinigameHost")

	if minigame_host == null:
		push_warning("RobotBuilder is missing MinigameHost.")


# Finds the lane defense parent, or creates it and moves the lanes into it.
func _find_or_create_lane_defense_area() -> void:
	lane_defense_area = get_node_or_null("LaneDefenseArea")

	if lane_defense_area == null:
		lane_defense_area = Node2D.new()
		lane_defense_area.name = "LaneDefenseArea"
		add_child(lane_defense_area)

	lane_1 = get_node_or_null("LaneDefenseArea/Lane1")
	lane_2 = get_node_or_null("LaneDefenseArea/Lane2")
	lane_3 = get_node_or_null("LaneDefenseArea/Lane3")
	spawn_timer = get_node_or_null("LaneDefenseArea/SpawnTimer")

	if lane_1 == null:
		lane_1 = get_node_or_null("Lane1")

	if lane_2 == null:
		lane_2 = get_node_or_null("Lane2")

	if lane_3 == null:
		lane_3 = get_node_or_null("Lane3")

	if spawn_timer == null:
		spawn_timer = get_node_or_null("SpawnTimer")

	_reparent_to_lane_area(lane_1)
	_reparent_to_lane_area(lane_2)
	_reparent_to_lane_area(lane_3)
	_reparent_to_lane_area(spawn_timer)


# Moves a node under LaneDefenseArea without changing its local lane layout.
func _reparent_to_lane_area(node: Node) -> void:
	if node == null:
		return

	if node.get_parent() != lane_defense_area:
		node.reparent(lane_defense_area, false)


# Finds your asset-based HUD, or creates simple fallback HUD nodes.
func _find_or_create_hud_nodes() -> void:
	var found_screen_ui := get_node_or_null("ScreenUI")

	if found_screen_ui is CanvasLayer:
		screen_ui = found_screen_ui as CanvasLayer
	else:
		screen_ui = CanvasLayer.new()
		screen_ui.name = "ScreenUI"
		add_child(screen_ui)

	var found_right_hud := screen_ui.get_node_or_null("RightHUD")

	if found_right_hud is Control:
		right_hud = found_right_hud as Control
	else:
		right_hud = Panel.new()
		right_hud.name = "RightHUD"
		screen_ui.add_child(right_hud)
	
	score_label = _get_or_create_label(right_hud, "ScoreLabel")
	wave_label = _get_or_create_label(right_hud, "WaveLabel")
	selected_lane_label = _get_or_create_label(right_hud, "SelectedLaneLabel")
	wave_progress = _get_or_create_progress_bar(right_hud, "WaveProgress")
	health_bar = _get_or_create_health_bar(right_hud, "PlayerHealthBar")


# Uses an existing Label if it exists, otherwise creates one.
func _get_or_create_label(parent: Control, node_name: String) -> Label:
	var found_node := parent.get_node_or_null(node_name)

	if found_node is Label:
		return found_node as Label

	var new_label := Label.new()
	new_label.name = node_name
	parent.add_child(new_label)
	return new_label


# Uses an existing ProgressBar if it exists, otherwise creates one.
func _get_or_create_progress_bar(parent: Control, node_name: String) -> ProgressBar:
	var found_node := parent.get_node_or_null(node_name)

	if found_node is ProgressBar:
		return found_node as ProgressBar

	var new_progress_bar := ProgressBar.new()
	new_progress_bar.name = node_name
	parent.add_child(new_progress_bar)
	return new_progress_bar


func _get_or_create_health_bar(parent: Control, node_name: String) -> TextureProgressBar:
	var found_node := parent.get_node_or_null(node_name)

	if found_node is TextureProgressBar:
		return found_node as TextureProgressBar
	
	var new_progress_bar := TextureProgressBar.new()
	new_progress_bar.name = node_name
	parent.add_child(new_progress_bar)
	return new_progress_bar


# Positions the HUD.
func _apply_screen_layout() -> void:
	# Lanes are now scaled correctly directly in editor to avoid strange
	# rigidbody behaviour
	
	screen_ui.layer = 10
	
	right_hud.position = Vector2(hud_left_width, 0)
	right_hud.size = Vector2(right_width, hud_height)
	right_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_layout_hud_nodes(right_width, hud_height)


# Sizes HUD labels and the progress bar so they fit inside the top-right HUD.
func _layout_hud_nodes(hud_width: float, hud_height_value: float) -> void:
	var margin := 12.0
	var label_width := hud_width * 0.46
	var progress_x := label_width + margin * 2.0
	var progress_width := hud_width - progress_x - margin
	
	score_label.position = Vector2(margin, 8)
	score_label.size = Vector2(label_width, 24)
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	wave_label.position = Vector2(margin, 36)
	wave_label.size = Vector2(label_width, 24)
	wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	selected_lane_label.position = Vector2(margin, 64)
	selected_lane_label.size = Vector2(label_width, 24)
	selected_lane_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	wave_progress.position = Vector2(hud_width * 0.31, hud_height_value * 0.29)
	wave_progress.size = Vector2(progress_width, 28)
	wave_progress.min_value = 0
	wave_progress.max_value = 100
	wave_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var hud_background := right_hud.get_node_or_null("HudBackground")
	
	if hud_background is Control:
		hud_background.position = Vector2.ZERO
		hud_background.size = Vector2(hud_width, hud_height_value)
		hud_background.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Connects the robot builder and enemy timer.
func _connect_signals() -> void:
	if robot_builder != null and robot_builder.has_signal("robot_completed"):
		var robot_completed_callable := Callable(self, "_on_robot_completed")

		if not robot_builder.is_connected("robot_completed", robot_completed_callable):
			robot_builder.connect("robot_completed", robot_completed_callable)

	if spawn_timer != null:
		var timer_callable := Callable(self, "_on_spawn_timer_timeout")

		if not spawn_timer.timeout.is_connected(timer_callable):
			spawn_timer.timeout.connect(timer_callable)


# Starts a new enemy-based wave.
func _start_wave() -> void:
	wave_in_progress = true
	
	enemies_this_wave = enemies_per_wave
	enemies_spawned_this_wave = 0
	enemies_defeated_this_wave = 0
	enemies_alive_this_wave = 0
	
	if spawn_timer != null:
		if spawn_timer.wait_time <= 0.0:
			spawn_timer.wait_time = 1.0
		
		spawn_timer.stop()
		spawn_timer.start()

	_update_hud()


# Handles lane selection and blocks lane clicks while a minigame is open.
func _input(event: InputEvent) -> void:
	if minigame_host != null and minigame_host.visible:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_select_lane_from_mouse()

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_spawn_debug_player_unit()

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_select_lane(1)
		elif event.keycode == KEY_2:
			_select_lane(2)
		elif event.keycode == KEY_3:
			_select_lane(3)


# Selects the closest lane when the player clicks in the lane defense area.
func _try_select_lane_from_mouse() -> void:
	var mouse_pos := get_global_mouse_position()

	if mouse_pos.x < left_width:
		return

	if mouse_pos.y < hud_height:
		return

	var clicked_node = raycast_check_for_interactibles()

	if clicked_node != null:
		var lane_number_from_click := _get_lane_number_from_node(clicked_node)
		_select_lane(lane_number_from_click)
		return

	_select_lane(_get_nearest_lane_number_to_y(mouse_pos.y))


# Checks whether the mouse is over one of the lane Area2D nodes or its children.
func raycast_check_for_interactibles():
	var space_state = get_world_2d().direct_space_state

	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collision_mask = RAYCAST_COLLISION_MASK
	parameters.collide_with_areas = true
	parameters.collide_with_bodies = true

	var result = space_state.intersect_point(parameters)

	if result.size() > 0:
		return result[0].collider

	return null


# Converts a clicked node, child node, or unit into a lane number.
func _get_lane_number_from_node(node: Node) -> int:
	if _node_belongs_to_lane(node, lane_1):
		return 1

	if _node_belongs_to_lane(node, lane_2):
		return 2

	if _node_belongs_to_lane(node, lane_3):
		return 3

	return _get_nearest_lane_number_to_y(get_global_mouse_position().y)


# Checks whether a clicked node is inside a specific lane branch.
func _node_belongs_to_lane(node: Node, lane: Node) -> bool:
	var current_node := node

	while current_node != null:
		if current_node == lane:
			return true

		current_node = current_node.get_parent()

	return false


# Picks the lane whose global y position is closest to the mouse.
func _get_nearest_lane_number_to_y(mouse_y: float) -> int:
	var lane_y_values := {
		1: lane_1.global_position.y,
		2: lane_2.global_position.y,
		3: lane_3.global_position.y,
	}

	var closest_lane := selected_lane
	var closest_distance := INF

	for lane_number in lane_y_values.keys():
		var distance = abs(mouse_y - lane_y_values[lane_number])

		if distance < closest_distance:
			closest_distance = distance
			closest_lane = lane_number

	return closest_lane


# Changes which lane built robots will spawn into.
func _select_lane(lane_number: int) -> void:
	selected_lane = clamp(lane_number, 1, 3)

	print("Selected Lane: ", selected_lane)
	lane_selected.emit()

	_update_hud()


# Receives finished robot data and spawns the unit in the selected lane.
func _on_robot_completed(unit_data: Dictionary) -> void:
	await(lane_selected)
	var lane = lane_dict[selected_lane]

	if lane != null and lane.has_method("spawn_unit"):
		lane.spawn_unit(player_unit_scene, "PlayerUnitPath", unit_data)
		robot_builder.reset_builder()


# Spawns enemies until the wave has spawned all enemies.
func _on_spawn_timer_timeout() -> void:
	if not wave_in_progress:
		return

	if enemies_spawned_this_wave >= enemies_this_wave:
		if spawn_timer != null:
			spawn_timer.stop()

		_check_for_wave_complete()
		return

	var rand_lane := randi_range(1, 3)
	var lane = lane_dict[rand_lane]

	if lane != null and lane.has_method("spawn_unit"):
		var new_enemy = lane.spawn_unit(enemy_unit_scene, "EnemyPath")

		if new_enemy != null:
			_register_enemy_for_wave(new_enemy)

	enemies_spawned_this_wave += 1

	if enemies_spawned_this_wave >= enemies_this_wave:
		if spawn_timer != null:
			spawn_timer.stop()

	_update_hud()


# Connects an enemy's defeat signal so the wave knows when it has been killed.
func _register_enemy_for_wave(enemy: Node) -> void:
	enemies_alive_this_wave += 1
	
	if enemy.has_signal("died"):
		var defeated_callable := Callable(self, "_on_enemy_death")
		
		if not enemy.is_connected("died", defeated_callable):
			enemy.connect("died", defeated_callable)
	
	if enemy.has_signal("player_damaged"):
		var damage_callable := Callable(self, "_player_take_damage")

		if not enemy.is_connected("player_damaged", damage_callable):
			enemy.connect("player_damaged", damage_callable)


# Counts defeated enemies and checks whether the wave is complete.
func _on_enemy_death(_enemy: Node, has_been_defeated: bool) -> void:
	enemies_alive_this_wave = max(0, enemies_alive_this_wave - 1)
	enemies_defeated_this_wave += 1
	
	if has_been_defeated == true:
		add_score(score_per_enemy)
	
	_check_for_wave_complete()
	_update_hud()


func _player_take_damage(damage):
	health -= damage
	print(health)
	_update_hud()
	
	if health <= 0.0:
		_game_over()


func _game_over():
	get_tree().reload_current_scene.call_deferred()


# Ends the wave only after all enemies have spawned and all enemies are defeated.
func _check_for_wave_complete() -> void:
	if not wave_in_progress:
		return

	if enemies_spawned_this_wave < enemies_this_wave:
		return

	if enemies_alive_this_wave > 0:
		return

	wave_in_progress = false
	wave_label.text = "Wave Clear!"

	await get_tree().create_timer(seconds_between_waves).timeout

	wave_number += 1
	enemies_per_wave += enemies_added_per_wave

	_start_wave()


# Right-click debug spawn.
func _spawn_debug_player_unit() -> void:
	var lane = lane_dict[selected_lane]

	if lane != null and lane.has_method("spawn_unit"):
		lane.spawn_unit(player_unit_scene, "PlayerUnitPath", {})


# Adds points to the score.
func add_score(amount: int) -> void:
	score += amount
	_update_hud()


# Updates HUD values without replacing your HUD art.
func _update_hud() -> void:
	if score_label != null:
		score_label.text = "Score: " + str(score)

	if wave_label != null:
		wave_label.text = "Wave: " + str(wave_number) + "  Enemies: " + str(enemies_defeated_this_wave) + "/" + str(enemies_this_wave)

	if selected_lane_label != null:
		selected_lane_label.text = "Selected Lane: " + str(selected_lane)

	if wave_progress != null:
		var progress_percent := 0.0

		if enemies_this_wave > 0:
			progress_percent = float(enemies_defeated_this_wave) / float(enemies_this_wave) * 100.0

		wave_progress.value = clamp(progress_percent, 0.0, 100.0)
		
	health_changed.emit()
