extends CharacterBody3D

#This is the code for the player object, built off the default CharacterBody3D code.

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
# Object Definitions
#======================================
#Grabs the positions of the playerView object and Camera3D object.
@onready var playerView = $playerView
@onready var playerViewCamera = $playerView/playerCamera

#======================================
# Controller Variables
#======================================
@export_group("Control Variables")
@export var playerSens = 0.003 #Sensitivity for the mouselook.

#======================================
# Movement Variables
#======================================
@export_group("Movement Variables")
@export var playerJumpVel = 7 #4.5 #Jump Velocity
@export var playerAccel = 4.5
@export var playerDeaccel = 16
@export var playerRun = 7.0
@export var playerSprint = 1.5 #The multiplier for sprinting
var playerSpeed = playerRun #Speed of the player.
var isPlayerSprint = false
var vel = Vector3()
var dir = Vector3()

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = -9.8
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
#Default Gravity set in the game.

#======================================
# Player Stat Variables
#======================================
@export_group("Player Stat Variables")
@export var playerHealth = 100


#======================================
#Head Bob & FOV values
#======================================
#Head Bob
const bobFreq = 2.0
const bobAmp = 0.08
var tbob = 0.0
#FOV
const fovBase = 90.0
const fovChange = 1.5


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	#Call input function
	process_input(delta)
	#Call movement function
	process_movement(delta)
	
	#DEBUG - PRINT PLAYER LEG STATE
	print(playerLegState)
	
	#======================================
	# FOV & Head Bob Code
	#======================================
	#Head Bob Code
	tbob += delta * velocity.length() * float(is_on_floor())
	playerViewCamera.transform.origin = _headbob(tbob)
	#FOV
	var target_fov = fovBase + fovChange# * velocity_clamped
	playerViewCamera.fov = lerp(playerViewCamera.fov, target_fov, delta * 8.0)
	#===================
	
	#This code just gives a headbob to the character.
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bobFreq) * bobAmp
	return pos


func process_input(delta):
	dir = Vector3()
	var cam_xform = playerViewCamera.get_global_transform()
	var input_movement_vector = Vector2()
	
	#create the directional input
	if Input.is_action_pressed("Forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("Backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("Left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("Right"):
		input_movement_vector.x += 1
		
		#normalize the vector
	input_movement_vector = input_movement_vector.normalized()
	
	#modify movement vector based on the direction of the camera
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x
	
	#======================================
	# jumping & sprinting
	#======================================
	if is_on_floor():
		if Input.is_action_just_pressed("Jump"):
			#jump force is multiplied by floor normal so that the jump is directly off the plane.
			print(vel)
			vel.y = playerJumpVel
			print(vel)
			vel = vel + (playerJumpVel * get_floor_normal()) #CHANGING MOVEMENT BROKE THIS :(
			print(vel)
		if Input.is_action_pressed("Sprint"):
			playerSpeed = playerRun * playerSprint
			isPlayerSprint = true
			print(isPlayerSprint)
		else:
			playerSpeed = playerRun
			isPlayerSprint = false
	#Ouch! I hit my head :( (End jump early if hit roof)
	if is_on_ceiling():
		vel.y = 0
	#======================================
	
	#======================================
	# Cancel UI (Mouse Toggle)
	#======================================
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func process_movement(delta):
	
	#======================================
	# movement
	#======================================
	dir.y = 0
	dir = dir.normalized()
	
	vel.y += delta * gravity
	
	var hvel = vel
	hvel.y = 0
	
	var target = dir
	target *= playerSpeed
	
	var accel
	if dir.dot(hvel) > 0:
		accel = playerAccel
	else:
		accel = playerDeaccel
		
	hvel = hvel.lerp(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z 
	velocity = vel
	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		playerView.rotate_y(-event.relative.x * playerSens)
		playerViewCamera.rotate_x(-event.relative.y * playerSens)
		playerViewCamera.rotation.x = clamp(playerViewCamera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
