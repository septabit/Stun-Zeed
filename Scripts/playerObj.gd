extends CharacterBody3D

#This is the code for the player object, built off the default CharacterBody3D code.

#======================================
# Node Definitions
#======================================
@onready var playerView = $playerView
@onready var playerViewCamera = $playerView/playerCamera

#Player States

var playerTorsoState = torsoIDLE
var playerLegState = legIDLE

#Head States
enum {
	torsoIDLE,
	torsoSPRINT,
	torsoWEAPON,
	torsoCAST,
	torsoHOLDITEM,
	torsoHOLDBIG,
	torsoSTUN
}

enum {
	legIDLE,
	legRUN,
	legSPRINT,
	legJUMP
}


#======================================
# Movement Variables
#======================================
@export_group("Movement Variables")
@export var playerJumpVel = 7 #4.5 #Jump Velocity
@export var playerRun = 5.0
@export var playerSprint = 1.5 #The multiplier for sprinting
@export var playerAirAcc = 1 #Controls the amount of air control you have. Less = more commitment to jumps.
var playerSpeed = playerRun #Speed of the player.
var isPlayerSprint = false
var gravity = 9.8
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
#Default Gravity set in the game.

#======================================
# Control Variables
#======================================
@export_group("Control Variables")
@export var playerSens = 0.003 #Sensitivity for the mouselook.

#======================================
# Player Stats
#======================================
@export_group("Player Stats")
@export var playerHealth = 100

#======================================
# Head bob & FOV Settings
#======================================
#Head bob values
const bobFreq = 2.0
const bobAmp = 0.08
var tbob = 0.0
#FOV
const fovBase = 90.0
const fovChange = 1.5

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
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		#Jump is now multplied by floor normal so that the jump is directly off the plane.
		velocity = velocity + (playerJumpVel * get_floor_normal())
		#velocity.y = playerJumpVel
		
	if Input.is_action_pressed("Sprint") and is_on_floor():
		playerSpeed = playerRun * playerSprint
		isPlayerSprint = true
	else:
		playerSpeed = playerRun
		isPlayerSprint = false
		
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction = (playerView.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			#If you're moving, then set movement to SPEED.
			velocity.x = direction.x * playerSpeed
			velocity.z = direction.z * playerSpeed
			#Set state for if running or sprinting.
			if isPlayerSprint:
				playerLegState = legSPRINT
			else:
				playerLegState = legRUN 
		else:
			#This part sets the speed to 0 if not holding direction.
			velocity.x = move_toward(velocity.x, 0, playerSpeed) 
			velocity.z = move_toward(velocity.z, 0, playerSpeed)
			playerLegState = legIDLE 
	else:
		velocity.x = lerp(velocity.x, direction.x * playerSpeed, delta * playerAirAcc)
		velocity.z = lerp(velocity.z, direction.z * playerSpeed, delta * playerAirAcc)
		playerLegState = legJUMP
	
	print(playerLegState)
	
	#======================================
	# FOV & Head Bob Code
	#======================================
	tbob += delta * velocity.length() * float(is_on_floor())
	playerViewCamera.transform.origin = _headbob(tbob)
	#var velocity_clamped = clamp(velocity.length(), 0.5, (playerSpeed * playerSprint) * 2)
	var target_fov = fovBase + fovChange# * velocity_clamped
	playerViewCamera.fov = lerp(playerViewCamera.fov, target_fov, delta * 8.0)

	#======================================
	# MOVE AND SLIDE!!!
	#======================================
	move_and_slide()
	


func _headbob(time) -> Vector3:
	#This function just gives a headbob to the character.
	var pos = Vector3.ZERO
	pos.y = sin(time * bobFreq) * bobAmp
	return pos
