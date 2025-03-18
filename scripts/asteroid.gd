class_name Asteroid extends Area2D

signal exploded(pos, size, points)

var movement_vector := Vector2(0, -1)

enum AsteroidSize {LARGE, MEDIUM, SMALL}
@export var size := AsteroidSize.LARGE

var speed := 50.0

@onready var sprite = $Sprite2D
@onready var cshape = $CollisionShape2D

var points: int:
	get:
		match size:
			AsteroidSize.LARGE:
				return 25
			AsteroidSize.MEDIUM:
				return 50
			AsteroidSize.SMALL:
				return 100
			_:
				return 0

func _ready() -> void:
	rotation = randf_range(0, 2*PI)
	
	match size:
		AsteroidSize.LARGE:
			speed = randf_range(50, 100)
			sprite.texture = preload("res://assets/Meteors/meteorGrey_big4.png")
			cshape.set_deferred("shape", preload("res://resources/asteroid_cshape_large.tres"))
			pass
			
		AsteroidSize.MEDIUM:
			speed = randf_range(100, 150)
			sprite.texture = preload("res://assets/Meteors/meteorGrey_med2.png")
			cshape.set_deferred("shape", preload("res://resources/asteroid_cshape_med.tres"))
			pass
			
		AsteroidSize.SMALL:
			speed = randf_range(100, 200)
			sprite.texture = preload("res://assets/Meteors/meteorGrey_tiny1.png")
			cshape.set_deferred("shape", preload("res://resources/asteroid_cshape_small.tres"))
			pass

func _physics_process(delta: float) -> void:
	global_position += movement_vector.rotated(rotation) * speed * delta
	
	var screen_size = get_viewport_rect().size
	var radius = cshape.shape.radius
	
	if (global_position.y + radius) < 0:
		global_position.y = (screen_size.y - radius)
	elif (global_position.y - radius) > screen_size.y:
		global_position.y = -radius
		
	if (global_position.x + radius) < 0:
		global_position.x = (screen_size.x + radius)
	elif (global_position.x - radius) > screen_size.x:
		global_position.x = -radius
		
func explode():
	emit_signal("exploded", global_position, size, points)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player = body
		player.die()
