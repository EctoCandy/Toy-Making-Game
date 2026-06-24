extends Unit

@export var attack_strength = 10

func set_up_encounter_mask():
	encounter_collision_mask = 2


func _on_attack_cooldown_timeout():
	attack_cooldown.wait_time = randf_range(1.5, 2.0)
	for i in enemies_in_range.size():
		if is_instance_valid(enemies_in_range[i]):
			enemies_in_range[i].take_damage(attack_strength)
