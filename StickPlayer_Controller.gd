extends CharacterBody2D

@onready var _animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var _hurtbox : Area2D = $HurtBox
@onready var _hurtbox_collider : CollisionPolygon2D = $HurtBox/HurtBox_Collider
@onready var _timer : Timer = $Timers/HurtTimer
@onready var _on_top_box = $OnTopBox

var coyote_timed_out = false #flag that checks whether the coyote timer ran out
var is_movement_disabled = false
var recent_direction_array = []
var zoom = Vector2(1,1)
#----------- Movement Flags -------------#
var is_sprintJumping = false
var is_sprinting = false
var is_horizontalJumping = false
var is_jumping = false
var is_drifting = false
#----------- Player Variables -------------#
#---- SPEED
const SPEED = 25.0
const SPEED_CAP_NORMAL = 250
const SPEED_CAP_SPRINT = 450

#---- JUMP VARIABLES
const JUMP_VELOCITY = -500.0
const JUMP_VELOCITY_SPRINT_JUMP = JUMP_VELOCITY + 175
const JUMP_VELOCITY_HORIZONTAL_JUMP = JUMP_VELOCITY - 175
const KNOCKBACK_VELOCITY = 200
const DAMAGE_JUMP_VELOCITY = JUMP_VELOCITY / 1.5

#---- GRAVITY
const GRAVITY_MULTIPLIER: float = 1.65
var enemy_velocity = 0
var SPEED_CAP = SPEED_CAP_NORMAL
var hor_jump_counter = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	PlayerData.health = 3
	$Camera2D.set_zoom(zoom)

func _physics_process(delta):
	print(velocity)
	print(enemy_velocity)

	var platform_found = false;

	for body in _on_top_box.get_overlapping_bodies():
		if body.has_method("get_enemy_velocity"):
			platform_found = true;
			enemy_velocity = body.get_enemy_velocity()

	if !platform_found:
		enemy_velocity = 0
		
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if PlayerData.health <= 0:
		zoom = zoom.move_toward(Vector2(2,2), 0.0155)
		$Camera2D.set_zoom(zoom)
	
	if direction_bias() != null:
		direction = direction_bias()
		
	if not is_on_floor():
		velocity.y += gravity*GRAVITY_MULTIPLIER * delta
		jump_buffer()
		
	if is_on_floor() and $Timers/JumpTimer.time_left > 0:
		is_horizontalJumping = false
		is_jumping = false
		is_sprintJumping = false
		player_jump(direction)
			
	if $Timers/JumpTimer.is_stopped() and is_on_floor():
		is_jumping = false
		is_horizontalJumping = false
		is_sprintJumping = false
		
	if is_on_floor() and velocity.y == 0:
		$Timers/JumpTimer.stop()
		is_horizontalJumping = false
		is_sprintJumping = false
		coyote_timed_out = false
		is_jumping = false
	
	if velocity.y == 0 and is_on_floor() and PlayerData.health > 0:
		is_movement_disabled = false
		
	if is_horizontalJumping:
		SPEED_CAP = SPEED_CAP_NORMAL
	
	if !is_movement_disabled:
		player_movement(direction)
		if is_on_floor():
			player_drift(direction)
			if Input.is_action_just_pressed("Jump"):
				player_jump(direction)
				
		if Input.is_action_just_released("Jump") and velocity.y < 0 and !is_sprinting:
			velocity.y = JUMP_VELOCITY/4
		
		if not coyote_timed_out:
			coyote_timing()
		
		player_sprint()
		
	player_death()
		
	move_and_slide()
	
	if not $Timers/CoyoteTimer.is_stopped() and not is_on_floor() and not is_jumping :
		if Input.is_action_just_pressed("Jump"):
			player_jump(direction)
	
		
func direction_bias():
	if Input.is_action_pressed("ui_left") and Input.is_action_pressed("ui_right"):
		if Input.is_action_just_pressed("ui_left"):
			recent_direction_array.append(-1)
		elif Input.is_action_just_pressed("ui_right"):
			recent_direction_array.append(1)
		if len(recent_direction_array) > 0:
			return recent_direction_array[-1]
		recent_direction_array = []
		
#function handling player movement
func player_movement(direction):
	if direction != 0:	
		if is_on_floor() and velocity.y == 0:
			if !Input.is_action_pressed("Run"):
				if $SoundNode/Timer.time_left <= 0:
					$SoundNode/Walk.volume_db = -12
					$SoundNode/Walk.play()
					$SoundNode/Timer.start(0.365)
				_animated_sprite.play("Walk")
			else:
				if $SoundNode/Timer.time_left <= 0:
					if !is_drifting: 
						$SoundNode/Walk.volume_db = -8
						$SoundNode/Walk.play()
						$SoundNode/Timer.start(0.165)
					else:
						$SoundNode/Drift.play()
						$SoundNode/Timer.start(0.05)
				_animated_sprite.play("Run")
		if !is_on_floor():
			velocity.x += direction * SPEED/4
		else:
			velocity.x += direction * SPEED/1.5
			
		velocity.x = clamp(velocity.x, -SPEED_CAP, SPEED_CAP)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0 and is_on_floor():
			if Input.is_action_pressed("Run"):
				_animated_sprite.play("Run")
			else:
				_animated_sprite.play("Idle")

#function handling player sprint
func player_sprint():
	if Input.is_action_pressed("Run"):
		is_sprinting = true
		if is_on_floor() and is_sprinting:
				SPEED_CAP = SPEED_CAP_SPRINT
	else:
		is_sprinting = false
		if is_on_floor():
			SPEED_CAP = move_toward(SPEED_CAP, SPEED_CAP_NORMAL, SPEED/2)	

func player_drift(direction):
	if is_sprinting:	
		if (direction * velocity.x) < -100:
			is_drifting = true
		else:
			is_drifting = false
	
#function handling jump mechanics
func player_jump(direction):
	is_jumping = true
	if is_sprinting:
		if direction != 0 and abs(velocity.x) > 100:
			is_sprintJumping = true
			velocity.y += JUMP_VELOCITY
			velocity.x += -(enemy_velocity)
			if velocity.x < 0:
				_animated_sprite.play_backwards("SprintJump")
			else:
				_animated_sprite.play("SprintJump")
		else:
			is_horizontalJumping = true
			velocity.y = JUMP_VELOCITY_HORIZONTAL_JUMP
			velocity.x += -(enemy_velocity)
			_animated_sprite.play("VertJump")
		$SoundNode/SprintJump.play()
		
	else:
		$SoundNode/Jump.play()
		velocity.y = JUMP_VELOCITY
		velocity.x += -(enemy_velocity)
		_animated_sprite.play("Jump")
			
func coyote_timing():
	if !is_on_floor() and !is_jumping and $Timers/CoyoteTimer.is_stopped():
		$Timers/CoyoteTimer.start(0.1)
		

func _on_coyote_timer_timeout():
	coyote_timed_out = true

#function handling entities entering the HurtBox collider
func _on_area_2d_body_entered(body):#HurtBox Signal Function
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if body.is_in_group("Enemies"):
		take_damage(direction)
	if body.is_in_group("OneWayPlatform"):
		print("Onewaygo")

func player_death():
	if PlayerData.health <= 0 and $Timers/DeathTimer.is_stopped():
		_hurtbox.set_deferred("monitoring", false)
		_hurtbox_collider.disabled = true
		_animated_sprite.play("Death")
		$SoundNode/Death.play()
		velocity.x = 0
		$Timers/DeathTimer.start(2)

func _on_death_timer_timeout():
	get_tree().reload_current_scene()

func take_damage(direction):
	$SoundNode/TakeDamage.play()
	PlayerData.set_health(PlayerData.health - 1)
	if direction == 0:
		direction = rand_direction()
	is_movement_disabled = true
	velocity.x = -KNOCKBACK_VELOCITY
	velocity.y = DAMAGE_JUMP_VELOCITY
	if PlayerData.health > 0:
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
	
func jump_buffer():
	if Input.is_action_just_pressed("Jump") and $Timers/JumpTimer.is_stopped() and $Timers/CoyoteTimer.is_stopped():
		$Timers/JumpTimer.start(0.1)
	
#generating a random float that returns either 1 or -1. giving me a random 
#axis that i can knock the player back with. direction == 0 e.g not moving	
func rand_direction() -> int:
	var random_value = randf()
	if random_value > 0.5:
		return 1
	else:
		return -1

func get_camera_loc():
	return $Camera2D.global_position
	

func _on_death_zone_area_entered(area:Area2D) -> void:
	PlayerData.health = 1;
	var direction = Input.get_axis("ui_left", "ui_right")
	take_damage(direction)
	$SoundNode/Oof.play()
	$Timers/ReloadTimer.start(1)
	
func _on_reload_timer_timeout() -> void:
	if($Timers/ReloadTimer.is_stopped()):
		get_tree().reload_current_scene()
