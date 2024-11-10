# The entire code here is copied from https://godotengine.org/asset-library/asset/2719. We can understand parts of it and modify it to change abilties. I'm thinking an if condition here and there to update variables.

# Add class name so script can be referenced by other scripts
class_name PlayerScript

extends CharacterBody2D

# Create new "Settings" subgroup
# Variables created with the @export tag can then be edited more conveniently
# in the Godot editor, in this case under the Player node's Inspector window.
# This group is used for variables affecting player behaviour, such as movement
# speeds or jump heights.
@export_subgroup("Settings")
@export var walk_force: int = 600		# Movement speed
@export var walk_max_speed: int = 200	# Maximum movement speed
@export var stop_force: int = 1300		# Friction
@export var jump_speed: int = 200		# Jump power

# Create new "Nodes" subgroup
@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2D		# Player sprite, assigned in Inspector
@export var jump_buffer_timer: Timer		# Timer node used for jump buffer
@export var coyote_timer: Timer			# Timer node used for coyote timer

var is_falling: bool = false 		# Used to trigger falling animation.
var is_jumping: bool = false			# Used to trigger jumping animation
var want_to_jump: bool = false		# Shorthand for Input...just_pressed
var jump_released: bool = false		# Shorthand for Input...just_released
var is_going_up: bool = false
var last_frame_on_floor: bool = false

var move_dir: float = 0

@onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# ##############
# # MAIN LOGIC #
# ##############

func _physics_process(delta: float):
	# Get the player's input.
	move_dir = walk_force * (Input.get_axis(&"move_left", &"move_right"))
	
	# Horizontal movement code.
	handle_horizontal_movement(self, delta, move_dir)
	
	# Vertical movement code. 
	# Pass in self to access CharacterBody2D's velocity, and delta for physics stuff
	handle_vertical_movement(self, delta)

	# Move based on the velocity and snap to the ground.
	# TODO: This information should be set to the CharacterBody properties instead of arguments: snap, Vector2.DOWN, Vector2.UP
	# TODO: Rename velocity to linear_velocity in the rest of the script.
	move_and_slide()
	
	# Check if player wants to jump (is pressing input)
	# Used multiple times, so I set this to a bool variable for a shorthand.
	var want_to_jump = Input.is_action_just_pressed(&"jump")
	
	# Handle jump. Note that this must be after the movement code.
	handle_jump(self)
	
	# Handle animations for movement and jumping.
	handle_move_animation()
	handle_jump_animation()

# #######################
# # HORIZONTAL MOVEMENT #
# #######################

# body: player's body, to access velocity and position
# delta: float from _physics_process for physics stuff
# walk: movement axis reading, with walk speed already applied
func handle_horizontal_movement(body: CharacterBody2D, delta: float, walk: float) -> void:
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
	
	# Check if player is falling.
	is_falling = body.velocity.y > 0 and not body.is_on_floor()

# ###########
# # JUMPING #
# ###########

# -- STATUS CHECKS --
# These are bool functions that return true/false when the player is in a certain
# state or condition.
# Scroll down to the Handlers for more context on why these are useful.

# Check if the player is in a condition where they can jump.
func is_allowed_to_jump(body: CharacterBody2D, want_to_jump: bool) -> bool:
	# 1. They should want to jump (initiated by pressing the Jump keybind).
	# 2. Either:
	# 		a. They are on the ground.
	# 		b. The coyote timer is still counting down.
	return want_to_jump and (body.is_on_floor() or not coyote_timer.is_stopped())


# Check if the player was on the floor last frame, but now isn't, without having jumped.
func has_just_stepped_off_ledge(body: CharacterBody2D) -> bool:
	# 1. The player should not be on the floor.
	# 2. The player should have been on the floor last frame.
	# 3. The player should not have triggered a jump; they should have walked off the edge.
	return not body.is_on_floor() and last_frame_on_floor and not is_jumping


# Check if the player was in the air last frame, but now has landed FROM A JUMP.
func has_just_landed(body: CharacterBody2D) -> bool:
	# 1. The player should be on the floor.
	# 2. The player should have been in the air last frame.
	# 3. The player should have been in a jump.
	return body.is_on_floor() and not last_frame_on_floor and is_jumping

# -- HANDLERS --
# Main logic for jumping.
# Three key features are added for more responsive platforming:

# -- What is coyote time? --
# Normally, the player can only jump if they are currently standing on the floor.
# The player might press the button a bit too late, right after they walk off the edge.
# The coyote timer adds a grace period; when the player leaves the ledge, the timer starts.
# If the player then presses jump while the timer is active, they are given the jump.
# It makes the platforming more forgiving.

# -- What is a jump buffer? --
# As the player is landing, they may pre-emptively press to jump again right when they land.
# They might press it too early, as they're still falling, so the jump won't be triggered.
# This can feel unresponsive.
# If they press the jump button before landing, the jump buffer timer is started.
# If they then land while the timer is still active, they will jump as they land.

# -- What is variable jump height? --
# If the player holds the jump button, they jump with full power.
# If the player lets go part-way through, they fall down immediately.
# Allows the player to make small jumps if they want.

# Main jump logic.
func handle_jump(body: CharacterBody2D) -> void:
	# If they just landed, they are no longer jumping.
	if has_just_landed(body):
		is_jumping = false
	
	# If the player wants to jump and is allowed to, then perform the jump
	if is_allowed_to_jump(body, want_to_jump):
		jump(body)
	
	handle_coyote_timer(body)
	handle_jump_buffer(body)
	handle_variable_jump_height(body)
	
	# Used for ...
	is_going_up = body.velocity.y < 0 and not body.is_on_floor()
	
	# Used for jump frame buffer.
	last_frame_on_floor = body.is_on_floor()


# Logic for coyote timer.
func handle_coyote_timer(body: CharacterBody2D) -> void:
	# If the player just stepped off the ledge, start the timer.
	if has_just_stepped_off_ledge(body):
		coyote_timer.start()
	
	# While timer hasn't stopped and the player isn't jumping, do not fall.
	# This means the player keeps moving horizontally and gravity does not affect them.
	# Makes coyote jumps more consistent with the player's memory of jump heights.
	if not coyote_timer.is_stopped() and not is_jumping:
		body.velocity.y = 0


# Logic for jump buffer.
func handle_jump_buffer(body: CharacterBody2D) -> void:
	# If the player jumps but isn't on the floor, start the buffer timer.
	if want_to_jump and not body.is_on_floor():
		jump_buffer_timer.start()
	
	# If the player then lands on the floor while the timer is still going, jump.
	if body.is_on_floor() and not jump_buffer_timer.is_stopped():
		jump(body)


# Logic for variable jump height.
func handle_variable_jump_height(body: CharacterBody2D) -> void:
	if jump_released and is_going_up:
		body.velocity.y = 0

func jump(body: CharacterBody2D) -> void:
	body.velocity.y = jump_speed
	jump_buffer_timer.stop()
	is_jumping = true
	coyote_timer.stop()

# ###########
# ANIMATION #
# ###########

func handle_move_animation() -> void:
	# If the player is moving, set the sprite's horizontal flip accordingly
	if move_dir != 0:
		sprite.flip_h = move_dir <= 0
	
	# Play animations depending on movement
	if move_dir != 0:
		sprite.play("PlayerRun")
	else:
		sprite.play("PlayerIdle")


func handle_jump_animation() -> void:
	# Play animations depending on jump.
	if is_jumping:
		sprite.play("PlayerJump")
	elif is_falling:
		sprite.play("PlayerFall")
