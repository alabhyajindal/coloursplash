# The entire code here is copied from https://godotengine.org/asset-library/asset/2719. We can understand parts of it and modify it to change abilties. I'm thinking an if condition here and there to update variables.

# Add class name so script can be referenced by other scripts
class_name PlayerScript

extends CharacterBody2D

# Create new "Settings" subgroup
# Variables created with the @export tag can then be edited more conveniently
# in the Godot editor, in this case under the Player node's Inspector window
# This group is used for variables affecting player behaviour, such as movement
# speeds or jump heights
@export_subgroup("Settings")
@export var walk_force: int = 600		# Movement speed
@export var walk_max_speed: int = 200	# Maximum movement speed
@export var stop_force: int = 1300		# Friction
@export var jump_speed: int = 200		# Jump power

# Create new "Nodes" subgroup
@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2D		# Player sprite, assigned in Inspector

var is_falling: bool = false

@onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float):
	# Horizontal movement code.
	# Pass in self to access CharacterBody2D's velocity, and delta for physics stuff
	handle_horizontal_movement(self, delta)
	
	# Vertical movement code. 
	# Pass in self to access CharacterBody2D's velocity, and delta for physics stuff
	handle_vertical_movement(self, delta)

	# Move based on the velocity and snap to the ground.
	# TODO: This information should be set to the CharacterBody properties instead of arguments: snap, Vector2.DOWN, Vector2.UP
	# TODO: Rename velocity to linear_velocity in the rest of the script.
	move_and_slide()
	
	# Handle jump. Note that this must be after the movement code.
	handle_jump(self, delta)

func handle_horizontal_movement(body: CharacterBody2D, delta: float) -> void:
	# Horizontal movement code. First, get the player's input.
	var walk = walk_force * (Input.get_axis(&"move_left", &"move_right"))
	
	# Slow down the player if they're not trying to move.
	if abs(walk) < walk_force * 0.2:
		# The velocity, slowed down a bit, and then reassigned.
		body.velocity.x = move_toward(body.velocity.x, 0, stop_force * delta)
	else:
		body.velocity.x += walk * delta
	
	# Clamp to the maximum horizontal movement speed.
	velocity.x = clamp(velocity.x, -walk_max_speed, walk_max_speed)


func handle_vertical_movement(body: CharacterBody2D, delta: float) -> void:
	# Apply gravity.
	body.velocity.y += gravity * delta
	
	# Check if player is falling. Used to trigger falling animation.
	is_falling = body.velocity.y > 0 and not body.is_on_floor()


func handle_jump(body: CharacterBody2D, delta: float) -> void:
	# Check for jumping. is_on_floor() must be called after movement code.
	if body.is_on_floor() and Input.is_action_just_pressed(&"jump"):
		body.velocity.y = -jump_speed


func handle_move_animation(move_direction: float) -> void:
	# If the player is moving, set the sprite's horizontal flip accordingly
	if move_direction != 0:
		sprite.flip_h = move_direction <= 0
	
	# Play animations depending on movement
	if move_direction != 0:
		sprite.play("PlayerRun")
	else:
		sprite.play("PlayerIdle")


func handle_jump_animation(is_jumping: bool, is_falling: bool) -> void:
	# Play animations depending on jump.
	if is_jumping:
		sprite.play("PlayerJump")
	elif is_falling:
		sprite.play("PlayerFall")
