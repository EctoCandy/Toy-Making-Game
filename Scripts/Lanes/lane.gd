extends Node2D

const UNIT_PATH_FOLLOW = preload("uid://dtulup478vp38")
const SPAWN_RANGE = 80.0

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

	_apply_unit_data_to_unit(new_unit, unit_data)

	path_node.add_child(new_path_follow)
	path_node.add_child(new_unit)

	_apply_random_color(new_unit, new_path_follow)
	_place_unit_at_spawn(new_unit, new_path_follow)

	return new_unit


# Converts builder unit data into the variables used by the lane unit scripts.
func _apply_unit_data_to_unit(unit: Node, unit_data: Dictionary) -> void:
	if unit_data.is_empty():
		return

	if unit_data.has("damage") and _has_property(unit, "attack_strength"):
		unit.set("attack_strength", unit_data["damage"])

	if unit_data.has("move_speed") and _has_property(unit, "mov_speed"):
		unit.set("mov_speed", float(unit_data["move_speed"]) / 100.0)

	if unit_data.has("health") and _has_property(unit, "max_health"):
		unit.set("max_health", unit_data["health"])


# Gives spawned units a temporary random color.
func _apply_random_color(unit: Node, path_follow: Node) -> void:
	var rand_color = colors[randi() % colors.size()]

	var unit_polygon = unit.find_child("Polygon2D", true, false)

	if unit_polygon != null:
		unit_polygon.color = rand_color

	var guide_polygon = path_follow.get_node_or_null("Guide/Polygon2D")

	if guide_polygon != null:
		guide_polygon.color = rand_color


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
