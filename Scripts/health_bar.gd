extends TextureProgressBar

@export var unit : Node2D

var pivot


func _ready():
	unit.health_changed.connect(update_health_bar)
	
	pivot = get_parent()
	update_health_bar()

func _process(_delta: float) -> void:
	pivot.rotation = -unit.rotation

func update_health_bar():
	value = unit.health * 100 / unit.max_health
