extends TextureProgressBar

@export var target : Node2D


func _ready():
	target.health_changed.connect(update_health_bar)
	update_health_bar()

func update_health_bar():
	value = target.health * 100 / target.max_health
