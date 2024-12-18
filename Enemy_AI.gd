extends CharacterBody2D

const SPEED = 100
var direction = -1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	$AnimatedSprite2D.play("Walk")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	if not is_on_floor():
		velocity.y += gravity*1.65 * delta
	
	enemy_walk(direction)
	
	sprite_flip(direction)
	move_and_slide()
	
func enemy_walk(direction):
	velocity.x = direction * SPEED


func _on_area_2d_body_entered(body):
	direction = -(direction)

func sprite_flip(direction):
	if direction == -1:
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = true
		
func get_velocity_x():
	return velocity.x
