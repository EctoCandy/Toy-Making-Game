extends RigidBody2D
class_name Unit

## /!\ The unit movement is divided between this script and unit_path_follow.gd
## Handles the physics part of all unit movement and detection of adversary units
##
## The rigidbody tries it's best to follow its path "guide" and stops when it
## has collided with adversary or the "guide" has gotten too far away


signal health_changed
signal died(unit: Unit, has_been_defeated: bool)
signal player_damaged(damage)

@export var max_health := 100.0 # temporary
@export var mov_speed := 0.6 # temporary
@export var follow_strength := 10.0
@export var max_follow_range := 70.0
@export var reconnecting_range := 50.0

var path_follow : Node2D
var path_guide : Node2D

var target_pos : Vector2
var enemies_in_range: Array
var health : float

var is_away_from_guide := false
var is_in_combat := false
var is_dead := false

@onready var attack_cooldown: Timer = $AttackCooldown
@onready var pivot: Node2D = $Pivot
@onready var health_bar: TextureProgressBar = $Pivot/HealthBar
@onready var attack_range: Area2D = $AttackRangeArea


func _ready() -> void:
	health = max_health
	health_changed.emit()
	
	path_guide = path_follow.find_child("Guide")
	target_pos = path_guide.global_position


func _process(_delta: float) -> void:
	# Reversing rigidbody rotation on pivot to keep interesting physics 
	# behaviour but also have upright sprites >:)
	pivot.rotation = -rotation
	
	target_pos = path_guide.global_position
	
	## CHECKING COLLISION WITH ADVERSARY
	enemies_in_range = attack_range.get_overlapping_bodies()
	
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


func unit_encounter(_enemies: Array):
	health_bar.visible = true
	attack_cooldown.start()


func take_damage(damage):
	health -= damage
	health_changed.emit()
	
	if health <= 0:
		var has_been_defeated = true
		death(has_been_defeated)


func death(has_been_defeated: bool):
	if is_dead:
		return
	
	is_dead = true
	died.emit(self, has_been_defeated)
	
	if has_been_defeated == false:
		print("test")
		player_damaged.emit(90)
	
	if path_follow != null and is_instance_valid(path_follow):
		path_follow.queue_free()
	
	queue_free()
