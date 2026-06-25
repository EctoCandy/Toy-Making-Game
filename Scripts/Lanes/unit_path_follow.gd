extends PathFollow2D

## Handles the movement of the unit "Guide"

@export var speed = 0.02

var is_stopped := false
var unit : RigidBody2D


func _process(delta: float) -> void:
	if is_stopped == false:
		self.progress_ratio += speed * delta
	else:
		self.modulate = Color(0.242, 0.242, 0.242, 1.0)
		
