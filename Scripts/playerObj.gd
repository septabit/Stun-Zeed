extends CharacterBody3D

#This is the code for the player object, built off the default CharacterBody3D code.

#Player States

var playerTorsoState = torsoIDLE
var playerLegState = legIDLE

#Head States
enum {
	torsoIDLE,
	torsoWEAPON,
	torsoCAST,
	torsoHOLDITEM,
	torsoHOLDBIG,
	torsoSTUN
}

enum {
	legIDLE,
	legRUN,
	legSPRINT
}

#Player Variables
const playerJumpVel = 4.5 #Jump Velocity
const playerSens = 0.003 #Sensitivity for the mouselook.
var playerSpeed = 5.0 #Speed of the player.
var playerSprint = 1.25 #The multiplier for sprinting
var playerHealth = 100

#Head bob values
const bobFreq = 2.0
const bobAmp = 0.08
var tbob = 0.0

#FOV
const fovBase = 75.0
const fovChange = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
#Default Gravity set in the game.

@onready var playerView = $playerView
@onready var playerViewCamera = $playerView/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		playerView.rotate_y(-event.relative.x * playerSens)
		playerViewCamera.rotate_x(-event.relative.y * playerSens)
		playerViewCamera.rotation.x = clamp(playerViewCamera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = playerJumpVel

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (playerView.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			#If you're moving, then set movement to SPEED.
			velocity.x = direction.x * playerSpeed
			velocity.z = direction.z * playerSpeed
		else:
			#This part sets the speed to 0 if not holding direction.
			velocity.x = move_toward(velocity.x, 0, playerSpeed) 
			velocity.z = move_toward(velocity.z, 0, playerSpeed)
	else:
		velocity.x = lerp(velocity.x, direction.x * playerSpeed, delta * 2.0)

	#Head Bob Code
	tbob += delta * velocity.length() * float(is_on_floor())
	playerViewCamera.transform.origin = _headbob(tbob)

	# FOV
	#var velocity_clamped = clamp(velocity.length(), 0.5, (playerSpeed * playerSprint) * 2)
	var target_fov = fovBase + fovChange# * velocity_clamped
	playerViewCamera.fov = lerp(playerViewCamera.fov, target_fov, delta * 8.0)

	move_and_slide()
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bobFreq) * bobAmp
	return pos
