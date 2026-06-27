extends Node2D

const UNIT_PATH_FOLLOW = preload("uid://dtulup478vp38")
const SPAWN_RANGE = 67.0

const UNIT_1_HEAD = preload("uid://c2jhfthnp0nuw")
const UNIT_2_HEAD = preload("uid://44w1wci3rfad")
const UNIT_3_HEAD = preload("uid://cpvvyhm5pd78n")


var colors = [
	Color(0.842, 0.319, 0.232, 1.0),
	Color(0.0, 0.728, 0.0, 1.0),
	Color(0.0, 0.632, 0.632, 1.0)
]


# Spawns a unit into this lane and optionally applies robot-builder stats to it.
func spawn_unit(unit_type: PackedScene, path: String, unit_data: Dictionary = {}) -> Node2D:
	
	var path_node := find_child(path, true, false)
	
	if path_node == null:
		push_warning("Could not find path named: " + path)
		return null

	var new_path_follow = UNIT_PATH_FOLLOW.instantiate()
	var new_unit = unit_type.instantiate()

	new_unit.path_follow = new_path_follow
	new_path_follow.unit = new_unit
	
	if not unit_data.is_empty():
		_apply_unit_data_to_unit(new_unit, new_path_follow, unit_data)

	path_node.add_child(new_path_follow)
	path_node.add_child(new_unit)

	#_apply_random_color(new_unit, new_path_follow)
	_place_unit_at_spawn(new_unit, new_path_follow)


	return new_unit


# Converts builder unit data into the variables used by the lane unit scripts.
func _apply_unit_data_to_unit(unit: Node, path_follow: Node, unit_data: Dictionary) -> void:

	if unit_data.has("damage") and _has_property(unit, "attack_strength"):
		unit.set("attack_strength", unit_data["damage"])

	if unit_data.has("move_speed") and _has_property(unit, "mov_speed"):
		unit.set("mov_speed", unit_data["move_speed"])

	if unit_data.has("health") and _has_property(unit, "max_health"):
		unit.set("max_health", unit_data["health"])
	
	if unit_data.has("attack_speed") and _has_property(unit, "attack_speed"):
		unit.find_child("AttackCooldown").wait_time = unit_data["attack_speed"]
	
	if unit_data.has("guide_move_speed") and _has_property(path_follow, "move_speed"):
		path_follow.set("move_speed", unit_data["guide_move_speed"])
	
	if unit_data.has("encounter_mask") and _has_property(path_follow, "encounter_mask"):
		path_follow.set("encounter_mask", unit_data["encounter_mask"])
	
	
	## HEAD SPRITE
	if unit_data["unit_type"] == "unit_1":
		unit.find_child("HeadSprite").texture = UNIT_1_HEAD
	if unit_data["unit_type"] == "unit_2":
		unit.find_child("HeadSprite").texture = UNIT_2_HEAD
	if unit_data["unit_type"] == "unit_3":
		unit.find_child("HeadSprite").texture = UNIT_3_HEAD


# Gives spawned units a temporary random color.
#func _apply_random_color(unit: Node, path_follow: Node) -> void:
	#var rand_color = colors[randi() % colors.size()]
#
	#var unit_polygon = unit.find_child("Polygon2D", true, false)
#
	#if unit_polygon != null:
		#unit_polygon.color = rand_color
#
	#var guide_polygon = path_follow.get_node_or_null("Guide/Polygon2D")
#
	#if guide_polygon != null:
		#guide_polygon.color = rand_color


# Places the unit near the path guide.
func _place_unit_at_spawn(unit: Node2D, path_follow: Node) -> void:
	var guide = path_follow.find_child("Guide", true, false)

	if guide == null:
		return

	var spawn_position = guide.global_position
	spawn_position.y += randf_range(-SPAWN_RANGE, SPAWN_RANGE)

	unit.global_position = spawn_position


# Checks whether a script/property exists before setting it.
func _has_property(object: Object, property_name: String) -> bool:
	for property_info in object.get_property_list():
		if str(property_info.name) == property_name:
			return true

	return false


func _on_enemy_end_lane_body_entered(body: Node2D) -> void:
	print("enemy ended line")
	var has_been_defeated = false
	body.death(has_been_defeated)


func _on_player_end_lane_body_entered(body: Node2D) -> void:
	print("player ended line")
	var has_been_defeated = false
	self.owner.add_score(body.health / 2)
	body.death(has_been_defeated)
