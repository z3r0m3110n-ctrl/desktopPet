extends Node2D
var speed = 600
var direction = Vector2(1,0)
var screen_size = Vector2()
var window_size = Vector2(200, 200)

# idling
var idle_timer = 0.0
var is_idling = false

# dragging
var is_dragging = false
var drag_offset = Vector2()

# personaliyy
var happiness = 0
var bored_count = 0

# voices
var voices = DisplayServer.tts_get_voices_for_language("en")
var phrases_happy = ["Happy to see you, my friend!", "How is your day going?", "What's up?"]
var phrases_angry = ["Finally!", "Where were you?", "I was so bored!"]
var phrases_mid = ["Nice to see you!", "Thanks!", "Hello there!"]

@onready var animated_sprite = $AnimatedSprite2D
@onready var area = $Area2D

func _ready():
	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("walk")
	
	area.input_pickable = true
	area.input_event.connect(_on_area_input)
	get_viewport().physics_object_picking = true

	screen_size = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("walk")
	
func _physics_process(delta: float) -> void:
	if is_dragging:
		var mouse_pos = Vector2(DisplayServer.mouse_get_position())
		var new_win_pos = mouse_pos - drag_offset
		DisplayServer.window_set_position(Vector2i(new_win_pos))
		speed = randi_range(700, 1000) # set a random speed
		if is_idling:
			is_idling = false
			animated_sprite.play("walk")
			$CPUParticles2D.emitting = false
		return
	
	if is_idling:
		idle_timer -= delta
		if idle_timer <= 0:
			is_idling = false
			speed = randi_range(700, 1000) # set a random speed
			animated_sprite.play("walk")
			$CPUParticles2D.emitting = false
		return
			
	
	var window_position =  Vector2(DisplayServer.window_get_position())
	window_position.x = clamp(window_position.x,0,screen_size.x - window_size.x)
	window_position.y = clamp(window_position.y,0,screen_size.y - window_size.y)
	speed -= randi_range(0, 2) # slow down a random amount
	print("Happy:", happiness)
	print("Bored:", bored_count)
	if speed < 0:
		speed = 0
	#print(speed)
	window_position += direction * speed * delta 
	#print(window_position)
	DisplayServer.window_set_position(Vector2i(window_position))

	if window_position.x <= 0 or window_position.x >= screen_size.x - window_size.x:
		direction.x *= -1
		animated_sprite.flip_h = !animated_sprite.flip_h
		
	if window_position.y <= 0 or window_position.y >= screen_size.y - window_size.y:
		direction.y *= -1
		
	maybe_idle()
	
# is the pet idling
func maybe_idle():
	if speed < 5 and randf() < 0.3:
		is_idling = true
		idle_timer = randf_range(3.0, 5.0)
		animated_sprite.play("rest")
		bored_count += 1
		if bored_count > 3:
			happiness -= 1
			
		
		$CPUParticles2D.emitting = true
		
func _on_area_input(_viewport, event, _shape_idx):
	#print("input received: ", event)
	# drag the pet if it is pressed and dragged by the mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			bored_count = 0
			if happiness < 10:
				happiness += 1
			if happiness >= 5:
				DisplayServer.tts_speak(phrases_happy.pick_random(), voices[0],50,2,0)
			elif happiness < 1:
				DisplayServer.tts_speak(phrases_angry.pick_random(), voices[0],50,2,0)
			else:
				DisplayServer.tts_speak(phrases_mid.pick_random(), voices[0],50,1.2,0)
			is_dragging = true
			var mouse_pos = Vector2(DisplayServer.mouse_get_position())
			var win_pos = Vector2(DisplayServer.window_get_position())
			drag_offset = mouse_pos - win_pos
			
				
		else:
			is_dragging = false

	
