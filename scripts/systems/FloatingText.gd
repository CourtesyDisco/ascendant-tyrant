extends Label

var velocity := Vector2(0, -150)  # Start by going up
var gravity := 300                # Pull down
var lifetime := 1.2               # Total duration
var fade_time := 0.5              # Fade out at end

func _ready():
	set_as_top_level(true)  # Ignore parent transform for proper positioning

func _process(delta):
	# Apply movement
	velocity.y += gravity * delta
	position += velocity * delta

	# Handle fading
	lifetime -= delta
	if lifetime < fade_time:
		modulate.a = lifetime / fade_time

	# Destroy self
	if lifetime <= 0:
		queue_free()
