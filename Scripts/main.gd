extends Node2D

## Handles inputs and enemy spawn cooldown
## Should probably be divided between level/unit_manager script and main script later

# TODO: Make it so units are attracted to an enemy in range during combat
# TODO: Change sprite
# TODO: Combine with building minigame

const BASIC_PLAYER_UNIT = preload("uid://dt3wdlwjtddbi")
const BASIC_ENEMY = preload("uid://daib08ro8i7su")
const RAYCAST_COLLISION_MASK = 4

@onready var lane_1: Area2D = $Lane1
@onready var lane_2: Area2D = $Lane2
@onready var lane_3: Area2D = $Lane3

var lane_dict := {}


func _ready() -> void:
	lane_dict = {
		1 : lane_1,
		2 : lane_2,
		3 : lane_3,
	}


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		var interactible_element = raycast_check_for_interractibles()
		
		if not interactible_element == null:
			interactible_element.spawn_unit(BASIC_PLAYER_UNIT,"PlayerUnitPath")


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


func _on_spawn_timer_timeout() -> void:
	var rand_lane = randi_range(1, 3) # temporary
	lane_dict[rand_lane].spawn_unit(BASIC_ENEMY,"EnemyPath")
