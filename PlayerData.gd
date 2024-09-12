extends Node

var health: int = 3
var stars: int = 0

signal health_changed(new_health)

func set_health(value):
	health = value
	emit_signal("health_changed", health)
