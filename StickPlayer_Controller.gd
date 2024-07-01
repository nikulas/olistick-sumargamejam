extends CharacterBody2D

@onready var _animated_sprite = $AnimatedSprite2D
@onready var _hurtbox = $HurtBox
@onready var _hurtbox_collider = $HurtBox/HurtBox_Collider
@onready var _timer = $HurtTimer



var coyote_timed_out = false #flag that checks whether the coyote time ran out
var is_movement_disabled = false
var recent_direction_array = []
#----------- Movement Flags -------------#
var is_sprintJumping = false
var is_sprinting = false
var is_vertJumping = false
var is_jumping = false
#----------------------------------------#
const SPEED = 25.0
var SPEED_CAP = 250
const JUMP_VELOCITY = -500.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if recent_direction() != null:
		direction = recent_direction()
		#print(direction)
	#print(direction_array)
	if not is_on_floor():
		velocity.y += gravity*1.65 * delta
	if is_on_floor():
		is_vertJumping = false
		coyote_timed_out = false
		is_jumping = false
	
	if velocity.y == 0 and is_on_floor():
		is_movement_disabled = false
		
	if !is_movement_disabled:
		player_movement(direction)
		
		if is_on_floor():
			player_jump(direction)
		if not coyote_timed_out:
			coyote_timing()
		
		player_sprint()
			
	move_and_slide()
	
	if not $CoyoteTimer.is_stopped() and not is_on_floor() and not is_jumping:
		player_jump(direction)
	
		
func recent_direction():
	if Input.is_action_pressed("ui_left") and Input.is_action_pressed("ui_right"):
		if Input.is_action_just_pressed("ui_left"):
			recent_direction_array.append(-1)
		elif Input.is_action_just_pressed("ui_right"):
			recent_direction_array.append(1)
		if len(recent_direction_array) >= 0:
			return recent_direction_array[-1]
		recent_direction_array = []
		
#function handling player movement
func player_movement(direction):
	if direction != 0:	
		if is_on_floor() and velocity.y == 0 :
			if !Input.is_action_pressed("Run"):
				if $SoundNode/Timer.time_left <= 0:
					$SoundNode/Walk.volume_db = -12
					$SoundNode/Walk.play()
					$SoundNode/Timer.start(0.365)
				_animated_sprite.play("Walk")
			else:
				if $SoundNode/Timer.time_left <= 0:
					$SoundNode/Walk.volume_db = -8
					$SoundNode/Walk.play()
					$SoundNode/Timer.start(0.165)
				_animated_sprite.play("Run")
		if not is_on_floor():
			velocity.x += direction * SPEED/4
		else:
			velocity.x += direction * SPEED
		velocity.x = clamp(velocity.x, -SPEED_CAP, SPEED_CAP)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED*3)
		if velocity.y == 0 and is_on_floor():
			if Input.is_action_pressed("Run"):
				_animated_sprite.play("Run")
			else:
				_animated_sprite.play("Idle")

#function handling jump mechanics
func player_jump(direction):
	if is_sprinting:
		if Input.is_action_just_pressed("Jump"):
			is_jumping = true
			is_sprintJumping = true
			if direction != 0 and abs(velocity.x) >= 100:
				velocity.y = JUMP_VELOCITY
				if direction == 1:
					velocity.x += 200
					_animated_sprite.play("SprintJump")
				elif direction == -1:
					velocity.x -= 200
					_animated_sprite.play_backwards("SprintJump")
			else:
				velocity.y = JUMP_VELOCITY-175
				is_vertJumping = true
				_animated_sprite.play("VertJump")
			$SoundNode/SprintJump.play()
				
	elif Input.is_action_just_pressed("Jump"):
		is_jumping = true
		$SoundNode/Jump.play()
		velocity.y = JUMP_VELOCITY
		_animated_sprite.play("Jump")
			
func coyote_timing():
	if not is_on_floor() and is_jumping == false and $CoyoteTimer.is_stopped():
		$CoyoteTimer.start(0.2)
		
#function handling player sprint
func player_sprint():
	if Input.is_action_pressed("Run"):
		is_sprinting = true
		if  is_on_floor():
				SPEED_CAP = 450
	else:
		is_sprinting = false
		SPEED_CAP = move_toward(SPEED_CAP, 250, SPEED/4)	

#function handling entities entering the HurtBox collider
func _on_area_2d_body_entered(body):#HurtBox Signal Function
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if body.is_in_group("Enemies"):
		$SoundNode/TakeDamage.play()
		if direction == 0:
			direction = rand_direction()
		is_movement_disabled = true
		velocity.x = -direction * 200
		velocity.y = JUMP_VELOCITY/1.5
		player_invincible_timer()

#when an enemy touches the player disable the HurtBox and start a timer
func player_invincible_timer():
	_animated_sprite.play("Damage")
	_hurtbox.set_deferred("monitoring", false)
	_hurtbox_collider.disabled = true
	
	_timer.wait_time = 1
	_timer.one_shot = true
	_timer.start()

#when the timer runs out this function is called
func _on_timer_timeout():
	_hurtbox.set_deferred("monitoring", true)
	_hurtbox_collider.disabled = false
	
#generating a random float that returns either 1 or -1. giving me a random 
#axis that i can knock the player back with. direction == 0 e.g not moving	
func rand_direction():
	var random_value = randf()
	if random_value > 0.5:
		return 1
	else:
		return -1


func _on_coyote_timer_timeout():
	coyote_timed_out = true

