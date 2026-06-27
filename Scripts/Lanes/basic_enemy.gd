extends Unit

@export var attack_strength = 10.0

func _ready() -> void:
	super._ready()



func _on_attack_cooldown_timeout():
	for i in enemies_in_range.size():
		if is_instance_valid(enemies_in_range[i]):
			enemies_in_range[i].take_damage(attack_strength)
