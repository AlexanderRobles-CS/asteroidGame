class_name Player extends CharacterBody2D

signal laser_shot(laser)
signal died

@export var acceleration := 10.0
@export var max_speed := 350.0
@export var rotation_speed := 250.0

@onready var muzzle = $Muzzle
@onready var sprite = $Sprite2D
@onready var cshape = $CollisionShape2D

var laser_scene = preload("res://scenes/laser.tscn")

var shoot_cd = false
var rate_of_fire = 0.15

var alive = true

# shoot laser and give cooldown on laser rate of fire
func _process(_delta: float) -> void:
	if !alive: return
	 
	if Input.is_action_pressed("shoot"):
		if !shoot_cd:
			shoot_cd = true
			shoot_laser()
			await get_tree().create_timer(rate_of_fire).timeout
			shoot_cd = false

func _physics_process(delta: float) -> void:
	if !alive: return
	
	# Returns (0, 1): move_forward or (0, -1): move_backward
	var input_vector := Vector2(0, Input.get_axis("move_forward", "move_backward"))
	
	# apply accelaration to input vector
	velocity += input_vector.rotated(rotation) * acceleration
	
	# apply max speed
	velocity = velocity.limit_length(max_speed)
	
	# rotate ship right
	if Input.is_action_pressed("rotate_right"):
		rotate(deg_to_rad(rotation_speed * delta))
	
	# rotate ship left
	if Input.is_action_pressed("rotate_left"):
		rotate(deg_to_rad(- rotation_speed * delta))
	
	# set velocity to 0 when you let go of key
	if input_vector.y == 0:
		velocity = velocity.move_toward(Vector2.ZERO, 3)
	
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	
	# bring player back on screen (y axis)
	if global_position.y < 0:
		global_position.y = screen_size.y
	elif global_position.y > screen_size.y:
		global_position.y = 0
		
	# bring player back on screen (x axis)
	if global_position.x < 0:
		global_position.x = screen_size.x
	elif global_position.x > screen_size.x:
		global_position.x = 0
		
func shoot_laser():
	var l = laser_scene.instantiate()
	l.global_position = muzzle.global_position
	l.rotation = rotation
	emit_signal("laser_shot", l)
	
func die():
	if alive == true:
		alive = false
		sprite.visible = false
		cshape.set_deferred("disabled", true)
		emit_signal("died")

func respawn(pos):
	if alive == false:
		alive = true
		global_position = pos
		velocity = Vector2.ZERO
		sprite.visible = true
		cshape.set_deferred("disabled", false)
