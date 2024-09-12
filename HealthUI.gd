extends Control

var player_health
@onready var heart_sprite = get_node("CanvasLayer/AnimatedSprite2D")

func _process(delta):
		heart_ui(PlayerData.health)

func heart_ui(health):
	if health == 3:
		heart_sprite.play("FullHeart")
	elif health == 2:
		heart_sprite.play("TwoHeart")
	elif health == 1:
		heart_sprite.play("OneHeart")
	elif health < 1:
		heart_sprite.play("NoHeart")
	
