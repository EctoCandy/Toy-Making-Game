extends RigidBody2D
class_name Unit

## /!\ The unit movement is divided between this script and unit_path_follow.gd
## Handles the physics part of all unit movement and detection of adversary units
##
## The rigidbody tries it's best to follow its path "guide" and stops when it
## has collided with adversary or the "guide" has gotten too far away

# TODO: Lock rotation without changing the way units interact with each other

signal health_changed
signal defeated(unit: Unit)

@export var max_health := 100.0 # temporary
@export var mov_speed := 0.6 # temporary
@export var follow_strength := 10
@export var max_follow_range := 70.0
@export var reconnecting_range := 50.0

var path_follow : Node2D
var path_guide : Node2D

var target_pos : Vector2
var enemies_in_range: Array
var health : float
var encounter_collision_mask : int

var is_away_from_guide := false
var is_in_combat := false
var is_defeated := false

@onready var attack_cooldown: Timer = $AttackCooldown
@onready var pivot: Node2D = $Pivot
@onready var health_bar: TextureProgressBar = $Pivot/HealthBar


func _ready() -> void:
	health = max_health
	health_changed.emit()
	
	path_guide = path_follow.find_child("Guide")
	target_pos = path_guide.global_position
	
	path_follow.find_child("FrontlineArea").collision_mask = encounter_collision_mask
	attack_cooldown.wait_time = randf_range(1.5, 2.0)


func _process(_delta: float) -> void:
	# Reversing rigidbody rotation to keep interesting physics behaviour
	# but also have upright sprites >:)
	pivot.rotation = -rotation
	print(pivot.rotation)
	
	if enemies_in_range.size() == 0:
		target_pos = path_guide.global_position
	
	## CHECKING GUIDE/UNIT DISTANCE (not used anymore)
	#
	# Stopping unit when too far from guide on x axis
	# to stop units "sneaking" behind lines
	#var dist_from_target = abs(target_pos.x - global_position.x)
	#
	#if dist_from_target > max_follow_range:
		#is_away_from_guide = true
	#elif dist_from_target < reconnecting_range:
		#is_away_from_guide = false
	#
	
	## CHECKING COLLISION WITH ADVERSARY
	if (
			enemies_in_range.size() > 0
			and is_in_combat == false
	):
		is_in_combat = true
		unit_encounter(enemies_in_range)
	
	elif (
			enemies_in_range.is_empty()
			and is_in_combat == true
	):
		is_in_combat = false


func _physics_process(_delta: float) -> void:
	var bodies_intersecting = get_colliding_bodies()
	enemies_in_range.clear()
	
	for i in bodies_intersecting.size():
		if bodies_intersecting[i].collision_layer == encounter_collision_mask:
			enemies_in_range.append(bodies_intersecting[i])

# known bug : if rigidbody very far from "guide", starts spinning healthbar
func get_target_force(state :PhysicsDirectBodyState2D, origin, target):
	var norm_direction = origin.direction_to(target)
	var local_mov_speed = minf(mov_speed, origin.distance_to(target))
	var velocity = local_mov_speed * norm_direction / state.step
	
	# Decreasing y axis vel so the unit is pulled more towards the end than 
	# the center of the lane
	velocity.y = velocity.y / 2
	
	state.linear_velocity = velocity


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	get_target_force(state, global_position, target_pos)


func unit_encounter(enemies: Array):
	health_bar.visible = true
	
	## Changes target from "guide" to an enemy in range
	for i in range(enemies.size()-1, -1, - 1): # iterating backwards
		if not is_instance_valid(enemies[i]):
			pass
		else:
			break
			
	attack_cooldown.start()


func take_damage(damage):
	health -= damage
	health_changed.emit()
	
	if health <= 0:
		defeat()


func defeat():
	if is_defeated:
		return

	is_defeated = true

	defeated.emit(self)

	if path_follow != null and is_instance_valid(path_follow):
		path_follow.queue_free()

	queue_free()
