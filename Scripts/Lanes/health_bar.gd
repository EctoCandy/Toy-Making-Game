extends TextureProgressBar

@export var unit : Node2D


func _ready():
	unit.health_changed.connect(update_health_bar)
	update_health_bar()

func update_health_bar():
	value = unit.health * 100 / unit.max_health
