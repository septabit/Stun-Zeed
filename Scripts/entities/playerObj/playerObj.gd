extends CharacterBody3D

#This is the code for the player object, built off the default CharacterBody3D code.

#======================================
# Node Definitions
#======================================
@onready var playerView = $playerView
@onready var playerViewCamera = $playerView/playerCamera
@onready var pcap = $StandCol #player capsule.
@onready var headBonker = $headBonker
@onready var weaponManager = $playerView/WeaponManager

#Player States

#Head States
var torsoStates =  {
	"torsoIDLE":["torsoSTOW", "torsoATTACK", "torsoRELOAD", "torsoSTUN", "torsoSPRINT", "torsoCAST"],
	"torsoSTOW":["torsoREADY"],
	"torsoREADY":["torsoIDLE"],
	"torsoRELOAD":["torsoIDLE"],
	"torsoATTACK":["torsoATTACK", "torsoIDLE", "torsoSTUN"],
	"torsoSPRINT":["torsoIDLE"],
	"torsoCAST":["torsoIDLE"],
}

enum {
	legIDLE,
	legRUN,
	legSPRINT,
	legJUMP,
	legCROUCH,
	legCROUCHWALK,
	legCROUCHJUMP,
}

var playerTorsoState = "torsoIDLE"
var playerLegState = legIDLE
#======================================
# Body Variables
#======================================
var playerHeight = 1.5
var playerHeightCrouch = 0.5

#======================================
# Movement Variables
#======================================
@export_group("Movement Variables")
@export var playerJumpVel = 7 #4.5 #Jump Velocity
@export var playerRun = 5.0
@export var playerSprintSpeedMult = 1.5 #The multiplier for sprinting
@export var playerCrouchSpeedMult = 0.6 #The multplier for crouching
@export var playerAcc = 10.0 #the ground acc
@export var playerDeAcc = 10.0 #ground deacceleration
@export var playerAirAcc = 2 #Controls the amount of air control you have. Less = more commitment to jumps.
@export var maxSpeed = 100 #maximum possible speed due to physics and hwatnot
var playerSpeed = playerRun #Speed of the player.
var isPlayerSprint = false
var isPlayerCrouch = false
var headBonk = false #this checks if you can uncrouch 
var gravity = 9.8

var velocityIN = Vector3(0, 0 ,0)

# Coyote Physics Specific stuff.
var coyote_physics = true
var isPlayerGrounded = true #this is the grounded variable for coyote physics
var isPlayerGroundedLeeway = 1
var isPlayerGroundedLeewayCount = 0

var playerCrouchSpeed = 5 #This is the SPEED TO CROUCH not the SPEED FROM CROUCHING
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
#Default Gravity set in the game.

var input_dir = Vector2()
var direction = Vector3()

#======================================
# Control Variables
#======================================
@export_group("Control Variables")
@export var playerSens = 0.003 #Sensitivity for the mouselook.

#======================================
# Player Stats
#======================================
@export_group("Player Stats")
@export var maxHP = 100
@export var currHP = 100

#======================================
# Head bob & FOV Settings
#======================================
var headBobFlag = true
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
		playerViewCamera.rotation.x = clamp(playerViewCamera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	
	#Do playerchecks
	process_flags()
	
	#Process Input
	process_input(delta)
	
	#Process State
	process_state()
	
	#Process Leg Movement
	process_movement(delta)
	
	process_weapons()
	
	#Debug related code.
	print(playerLegState)

func _headbob(time) -> Vector3:
	#This function just gives a headbob to the character.
	var pos = Vector3.ZERO
	pos.y = sin(time * bobFreq) * bobAmp
	return pos

func process_input(delta):
	#Jump function
	_jump()
	#crouch function
	crouch(delta)
	#Set sprint flag
	if isPlayerCrouch != true:
		if Input.is_action_pressed("Sprint") and is_on_floor():
			isPlayerSprint = true
		else:
			isPlayerSprint = false
	
	input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	direction = (playerView.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	

func process_state():
	if is_on_floor:
		if direction:
			if isPlayerSprint:
				playerLegState = legSPRINT
				playerSpeed = playerRun * playerSprintSpeedMult
			elif isPlayerCrouch:
				playerLegState = legCROUCHWALK
				playerSpeed = playerRun * playerCrouchSpeedMult
			else:
				playerLegState = legRUN
				playerSpeed = playerRun
		else:
			if isPlayerCrouch:
				playerLegState = legCROUCH
			else:
				playerLegState = legIDLE
	else:
		playerLegState = legJUMP
		
	print("state is: " + str(playerLegState))
	print("speed is: " + str(playerSpeed))

var velocityFLAT = Vector3()
var velocityGRAV = Vector3()
var velocityIMPULSE = Vector3()
var velocityEXTRA = Vector3()
var velFScalar = 0
func process_movement(delta):
	if is_on_floor():
		if direction: # This is the movement if on the ground + playerinput
			velFScalar += playerAcc * delta
			velFScalar = clamp(velFScalar, 0, playerSpeed)
			velocityFLAT = lerp(velocityFLAT, direction * velFScalar, playerAcc * delta) #!!!This might need to change.
		else: # This is the movement if on the ground w. no playerinput
			velFScalar -= playerDeAcc * delta
			velFScalar = clamp(velFScalar, 0, playerSpeed)
			velocityFLAT = lerp(velocityFLAT, direction * velFScalar, playerAcc * delta)
	else:
		if direction: # This is the movement if in the air + playerinput
			velFScalar += playerAirAcc * delta
			velFScalar = clamp(velFScalar, 0, playerSpeed)
			velocityFLAT = lerp(velocityFLAT, direction * velFScalar, playerAirAcc * delta)
		else: # This is the movement if in the air w. no playerinput
			velFScalar -= playerAirAcc * delta
			velFScalar = clamp(velFScalar, 0, playerSpeed)
			velocityFLAT = lerp(velocityFLAT, direction * velFScalar, playerAirAcc * delta)

	velocity = velocityFLAT + velocityGRAV + velocityEXTRA + velocityIMPULSE
	velocityIMPULSE = Vector3()
	velocityEXTRA = velocity - velocityFLAT - velocityGRAV
	
	if is_on_floor:
		velocityEXTRA = lerp(velocityEXTRA, Vector3(), delta)

	#print("FLAT: " + str(velocityFLAT) + ", GRAV: " + str(velocityGRAV) + ", IMPULSE" + str(velocityIMPULSE) + ", EXTRA: " + str(velocityEXTRA))
	#print("Total Velocity is: " + str(velocity))
	#print(direction)
	
	#======================================
	# FOV & Head Bob Code
	#======================================
	
	if headBobFlag == true:
		tbob += delta * velocity.length() * float(is_on_floor())
		playerViewCamera.transform.origin = _headbob(tbob)
		#var velocity_clamped = clamp(velocity.length(), 0.5, (playerSpeed * playerSprint) * 2)
		var target_fov = fovBase + fovChange# * velocity_clamped
		playerViewCamera.fov = lerp(playerViewCamera.fov, target_fov, delta * 8.0)

	#======================================
	# STAIRS AND MOVE AND SLIDE!!!
	#======================================
	_stepup()
	wallslidefix()
	move_and_slide()
	
	if not is_on_floor():
		velocityGRAV.y -= gravity * delta
	else: velocityGRAV.y = 0
	

func process_weapons():
	if Input.is_action_just_pressed("Pick Up"):
		weaponManager.pickup_Item()
	
	if Input.is_action_pressed("PrimaryFire"):
		weaponManager.prim_fire()
		
	if Input.is_action_pressed("SecondaryFire"):
		weaponManager.sec_fire()
		
	if Input.is_action_just_pressed("Drop"):
		weaponManager.drop_Item()
		
	if Input.is_action_just_pressed("WeaponListUp"):
		weaponManager.scrollWeaponSlot(1)
	if Input.is_action_just_pressed("WeaponListDown"):
		weaponManager.scrollWeaponSlot(-1)
	
	#weapon swap
	if Input.is_action_just_pressed("slot_0"):
		weaponManager.change_weapon(0)
	
	if Input.is_action_just_pressed("slot_1"):
		weaponManager.change_weapon(1)
		
	if Input.is_action_just_pressed("slot_2"):
		weaponManager.change_weapon(2)
		
	if Input.is_action_just_pressed("slot_3"):
		weaponManager.change_weapon(3)


func process_flags():
	headBonk = false
	if headBonker.is_colliding():
		headBonk = true
		
	#This is the code for coyote physics - the movement code generally doesn't use this unless it's for the stairs.
	if coyote_physics == true:
		if !is_on_floor():
			isPlayerGroundedLeewayCount += 1
			if isPlayerGroundedLeewayCount >= isPlayerGroundedLeeway:
				isPlayerGrounded = false
		else:
			isPlayerGroundedLeewayCount = 0
			isPlayerGrounded = true
	else:
		isPlayerGrounded = is_on_floor()

func take_damage(damage):
	currHP -= damage
	if currHP <= 0:
		die()

func die():
	pass

func add_health(amount):
	currHP = clamp(currHP + amount, 0, maxHP)

func crouch(delta):
	if Input.is_action_pressed("Crouch"):
		playerSpeed = playerRun * playerCrouchSpeedMult
		isPlayerCrouch = true
		pcap.shape.height -= playerCrouchSpeed * delta
	elif not headBonk:
		playerSpeed = playerRun
		isPlayerCrouch = false
		pcap.shape.height += playerCrouchSpeed * delta
		
	pcap.shape.height = clamp(pcap.shape.height, playerHeightCrouch, playerHeight)

#Jump Function
var _cur_frame = 0
@export var _jump_frame_grace = 50
var _last_frame_was_on_floor = -_jump_frame_grace - 1
func _jump():
	#Jump is now multplied by floor normal so that the jump is directly off the plane.
	#NOTE may want to update this to occur over a period of time (longer button press = higher jump)
	#This first part fixes jumping on planes a little bit
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		var velocityTEMP = (playerJumpVel * get_floor_normal())
		velocityGRAV = Vector3()
		print("vtemp = " + str(velocityTEMP))
		velocityGRAV.y += velocityTEMP.y
		velocityIMPULSE += velocityTEMP - Vector3(0, velocityTEMP.y, 0)
	else:
		pass

	#velocity.y = playerJumpVel


var max_step_up = 0.5
var step_up_speed = 0.1
var colP = Vector3()
var normP = Vector3()

#var initpos = $stepUpSeperation.position
func _stepup():
	var detectPOSF = Vector3(velocityFLAT.normalized().x * 0.6, 0, velocityFLAT.normalized().z * 0.6)
	#focal
	$stepUpSeperationF.position = detectPOSF
	$stepUpSeperationF.shape.length = pcap.shape.height/2
	$stepUpRayF.position = detectPOSF
	$stepUpRayF.target_position.y = -pcap.shape.height/2
	#left
	var detectPOSL = detectPOSF.rotated(Vector3(0,1.0,0), deg_to_rad(50))
	$stepUpSeperationL.position = detectPOSL
	$stepUpSeperationL.shape.length = pcap.shape.height/2
	$stepUpRayL.position = detectPOSL
	$stepUpRayL.target_position.y = -pcap.shape.height/2
	#right
	var detectPOSR = detectPOSF.rotated(Vector3(0,1.0,0), deg_to_rad(-50))
	$stepUpSeperationR.position = detectPOSR
	$stepUpSeperationR.shape.length = pcap.shape.height/2
	$stepUpRayR.position = detectPOSR
	$stepUpRayR.target_position.y = -pcap.shape.height/2
	
	#var max_slope_ang_dot = Vector3(0, 1, 0).rotated(Vector3(1.0, 0, 0), self.floor_max_angle).dot(Vector3(0,1,0))
	$stepUpSeperationF.disabled = true
	$stepUpSeperationL.disabled = true
	$stepUpSeperationR.disabled = true
	
	var colCheck = false
	if $stepUpRayF.is_colliding() or $stepUpRayL.is_colliding() or $stepUpRayR.is_colliding():
		colCheck = true
	
	var normCheck = false
	if $stepUpRayF.get_collision_normal() == Vector3(0, 1, 0) or $stepUpRayL.get_collision_normal() == Vector3(0, 1, 0) or $stepUpRayR.get_collision_normal() == Vector3(0, 1, 0):
		normCheck = true
	
	print("colCheck = " + str(colCheck))
	print("normCheck = " + str(normCheck))
	print(abs(velocityFLAT))
	
	if colCheck and direction != Vector3(0, 0, 0) and normCheck and isPlayerGrounded == true:
		$stepUpSeperationF.disabled = false
		$stepUpSeperationL.disabled = false
		$stepUpSeperationR.disabled = false

# please god, in the name of all that is holy, PLEASE let me slide along walls.
var undesiredMotion = Vector3()
func wallslidefix():
	if self.is_on_wall():
		undesiredMotion = self.get_wall_normal() * (velocity.dot(self.get_wall_normal()));
		if rad_to_deg(acos(velocity.normalized().dot(self.get_wall_normal()))) > 90:
			velocity = velocity - undesiredMotion;
	#if acos(velocity.normalized().dot(self.get_wall_normal())) < deg_to_rad(180):

