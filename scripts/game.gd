extends Node2D

@onready var lasers = $Lasers
@onready var player = $Player
@onready var asteroids = $Asteroids
@onready var hud = $UI/HUD
@onready var start_menu = $UI/StartScreen
@onready var game_over_screen = $UI/GameOverScreen
@onready var player_spawn_pos = $PlayerSpawnPos
@onready var player_spawn_area = $PlayerSpawnPos/PlayerSpawnArea

var asteroid_scene = preload("res://scenes/asteroid.tscn")
var game_started = false
var asteroid_count = 4
var max_asteroids = 15
var small_asteroids_destroyed = 0

var score := 0:
	set(value):
		score = value
		hud.score = score

var lives: int:
	set(value):
		lives = value
		hud.init_lives(lives)

func _ready() -> void:
	score = 0
	lives = 1
	player.connect("laser_shot", _on_player_laser_shot)
	player.connect("died", _on_player_died)
	
	start_menu.connect("startGame", _start_Game)
	game_over_screen.connect("restartGame", _restart_Game)
	
	for asteroid in asteroids.get_children():
		asteroid.connect("exploded", _on_asteroid_exploded)
		
	player.alive = false
	player.visible = false
	
	if !game_started: return
	
func _process(_delta):
	if !game_started:
		return
	
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
		
func _start_Game():
	game_started = true
	start_menu.visible = false
	hud.visible = true
	
	while !player_spawn_area.is_empty:
		await get_tree().create_timer(0.1).timeout
	
	player.alive = true
	player.visible = true
	
func _restart_Game():
	game_over_screen.visible = false
	score = 0
	lives = 3

	# Clear all existing asteroids
	for asteroid in asteroids.get_children():
		asteroid.queue_free()

	asteroid_count = 0

	# respawn asteroids
	respawn_asteroids()
	
func respawn_asteroids():
	# Spawn 4 large asteroids directly
	for i in range(4):
		var screen_size = get_viewport_rect().size
		var random_position = Vector2(
			randf_range(0, screen_size.x), 
			randf_range(0, screen_size.y)
		)
		spawn_asteroid(random_position, Asteroid.AsteroidSize.LARGE)
		asteroid_count += 1 

	while !player_spawn_area.is_empty:
		await get_tree().create_timer(0.1).timeout

	player.respawn(player_spawn_pos.global_position)

	while !player_spawn_area.is_empty:
		await get_tree().create_timer(0.1).timeout
		
	player.respawn(player_spawn_pos.global_position)
	
func _on_player_laser_shot(laser):
	$LaserSound.play()
	lasers.add_child(laser)

func _on_asteroid_exploded(position, size, points):
	$AsteroidHitSound.play()
	score += points
	asteroid_count -= 1
	for i in range(2):
		match size:
			Asteroid.AsteroidSize.LARGE:
				asteroid_count += 1
				spawn_asteroid(position, Asteroid.AsteroidSize.MEDIUM)
				pass
			Asteroid.AsteroidSize.MEDIUM:
				asteroid_count += 1
				spawn_asteroid(position, Asteroid.AsteroidSize.SMALL)
				pass
			Asteroid.AsteroidSize.SMALL:
				pass
				
	spawn_random_asteroid(size)

func spawn_asteroid(position, size):
	var a = asteroid_scene.instantiate()
	a.global_position = position
	a.size = size
	a.connect("exploded", _on_asteroid_exploded)
	asteroids.call_deferred("add_child", a)
	
func spawn_random_asteroid(size):
	if size == Asteroid.AsteroidSize.SMALL:
		small_asteroids_destroyed += 1
		if small_asteroids_destroyed % 2 == 0:
			var screen_size = get_viewport_rect().size

			# Randomly pick a side to spawn the object off-screen
			var side = randi_range(0, 3)  # 0: left, 1: right, 2: top, 3: bottom

			var random_position = Vector2()

			match side:
				0:  # Spawn off-screen on the left
					random_position.x = -50 
					random_position.y = randf_range(0, screen_size.y)
				1:  # Spawn off-screen on the right
					random_position.x = screen_size.x + 50
					random_position.y = randf_range(0, screen_size.y)
				2:  # Spawn off-screen at the top
					random_position.x = randf_range(0, screen_size.x)
					random_position.y = -50
				3:  # Spawn off-screen at the bottom
					random_position.x = randf_range(0, screen_size.x)
					random_position.y = screen_size.y + 50
					
				# Minimum distance to keep between spawned asteroids and screen edges
					var min_distance = 100
					if random_position.x < min_distance:
						random_position.x = min_distance
					if random_position.x > screen_size.x - min_distance:
						random_position.x = screen_size.x - min_distance

			# Spawn the object at the off-screen position
			if asteroid_count < max_asteroids:
				spawn_asteroid(random_position, Asteroid.AsteroidSize.LARGE)
				asteroid_count += 1
	
func _on_player_died():
	$PlayerDieSound.play()
	lives -= 1
	player.global_position = player_spawn_pos.global_position
	if lives <= 0:
		await get_tree().create_timer(2).timeout
		game_over_screen.visible = true
		
	else:
		await get_tree().create_timer(1).timeout
		while !player_spawn_area.is_empty:
			await get_tree().create_timer(0.1).timeout
		player.respawn(player_spawn_pos.global_position)
