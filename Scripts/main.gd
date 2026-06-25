extends Node2D

## Handles inputs and enemy spawn cooldown
## Should probably be divided between level/unit_manager script and main script later

# TODO: Make it so units are attracted to an enemy in range during combat
# TODO: Change sprite
# TODO: Combine with building minigame

const BASIC_PLAYER_UNIT = preload("uid://dt3wdlwjtddbi")
const BASIC_ENEMY = preload("uid://daib08ro8i7su")
const RAYCAST_COLLISION_MASK = 4

@onready var lane_1: Node2D = $Lane1
@onready var lane_2: Node2D = $Lane2
@onready var lane_3: Node2D = $Lane3
@onready var robot_builder: Node2D = $RobotBuilder

var lane_dict := {}
var selected_lane := 1


func _ready() -> void:
	lane_dict = {
		1 : lane_1,
		2 : lane_2,
		3 : lane_3,
	}

	robot_builder.robot_completed.connect(_on_robot_completed)

	print("Selected lane: ", selected_lane)

func _input(event: InputEvent) -> void:
	if has_node("RobotBuilder/MinigameHost"):
		if $RobotBuilder/MinigameHost.visible:
			return
	
	if event.is_action_pressed("left_click"):
		var clicked_lane = raycast_check_for_interractibles()
		
		if clicked_lane != null:
			print("test")
			selected_lane = _get_lane_number(clicked_lane.get_parent())
			print("Selected lane: ", selected_lane)
	
	## DEV FEATURE (SPAWNS UNIT INSTANTLY)
	elif event.is_action_pressed("right_click (debug)"):
		var lane = lane_dict[selected_lane]
		lane.spawn_unit(BASIC_PLAYER_UNIT, "PlayerUnitPath", Dictionary({}))
	
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("1_key"):
			selected_lane = 1
			print("Selected Lane: 1" )
		elif event.is_action_pressed("2_key"):
			selected_lane = 2
			print("Selected Lane: 2" )
		elif event.is_action_pressed("3_key"):
			selected_lane = 3
			print("Selected Lane: 3" )

func raycast_check_for_interractibles():
	## This function returns the node that mouse hovers over and its
	## collision layer in an array
	
	var space_state = get_world_2d().direct_space_state
	var parameters  = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collision_mask = RAYCAST_COLLISION_MASK
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)
	
	if result.size() > 0:
		return result[0].collider
	return null

func _get_lane_number(lane: Node2D) -> int:
	if lane == lane_1:
		return 1
	elif lane == lane_2:
		return 2
	elif lane == lane_3:
		return 3

	return selected_lane


func _on_robot_completed(unit_data: Dictionary) -> void:
	print("Robot finished from builder:")
	print(unit_data)

	var lane = lane_dict[selected_lane]

	# For now, every built robot uses the same basic player unit scene.
	# The unit_data controls its stats.
	lane.spawn_unit(BASIC_PLAYER_UNIT, "PlayerUnitPath", unit_data)

func _on_spawn_timer_timeout() -> void:
	var rand_lane = randi_range(1, 3) # temporary
	lane_dict[rand_lane].spawn_unit(BASIC_ENEMY,"EnemyPath")
