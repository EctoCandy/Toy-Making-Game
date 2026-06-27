extends PathFollow2D

## Handles the movement of the unit "Guide"

@export var move_speed = 0.02

var is_stopped := false
var has_reached_frontline := false
var unit : RigidBody2D
var encounter_mask : int

@onready var guide: Node2D = $Guide
@onready var frontline_area: Area2D = $FrontlineArea

func _ready() -> void:
	frontline_area.collision_mask = encounter_mask
	print(encounter_mask)


func _process(delta: float) -> void:
	if (
		unit.is_away_from_guide == false
		and unit.is_in_combat == false
		and has_reached_frontline == false
	):
		self.progress_ratio += move_speed * delta
	else:
		pass
	
	## CHECKING FRONTLINE AREA
	if frontline_area.has_overlapping_bodies():
		has_reached_frontline = true
	else:
		has_reached_frontline = false
	
	if abs(to_local(unit.global_position).x) > 70.0:
		if to_local(unit.global_position).x < 0.0:
			self.progress_ratio -= 0.1 * delta
		else:
			self.progress_ratio += 0.1 * delta
	#guide.position.x = maxf(0.0, to_local(unit.global_position).x)
		
