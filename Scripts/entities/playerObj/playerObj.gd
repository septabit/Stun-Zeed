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
	legSLIDE,
	legSTUN
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

#Run Variables
@export var playerRun = 5.0
@export var playerAcc = 10.0 #the ground acc
@export var playerDeAcc = 10.0 #ground deacceleration
@export var maxSpeed = 100 #maximum possible speed due to physics and hwatnot
var playerSpeed = playerRun #Speed of the player.

#Sprint Variables
@export var playerSprintSpeedMult = 1.5 #The multiplier for sprinting

#Crouch Variables
@export var playerCrouchSpeedMult = 0.6 #The multplier for crouching

#Slide Variables
var slideTime = 1
var slide_timer = slideTime

#Jump Variables
var gravity = 9.8
@export var playerJumpVel = 7 #4.5 #Jump Velocity
@export var playerAirAcc = 1 #Controls the amount of air control you have. Less = more commitment to jumps.

#State Variables
var isPlayerStun = false
var isPlayerSprint = false
var isPlayerCrouch = false
var isPlayerSliding = false
var headBonk = false #this checks if you can uncrouch 



# Coyote Physics Specific stuff.
var coyote_physics = true
var isPlayerGrounded = true #this is the grounded variable for coyote physics
var isPlayerGroundedLeeway = 0.2 #This is the timer in seconds. This is used for normal-aligned jumps.
var isPlayerGroundedLeewayCount = 0

var playerCrouchSpeed = 5 #This is the SPEED TO CROUCH not the SPEED FROM CROUCHING
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
#Default Gravity set in the game.

#Movement Vectors
var input_dir = Vector2()
var direction = Vector3()
var velocityIN = Vector3()
var velocityFLAT = Vector3()
var velocityGRAV = Vector3()
var velocityIMPULSE = Vector3()
var velocityEXTRA = Vector3()
var velocitySLIDE = Vector3()
var velFScalar = 0

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

#======================================
#TEST VARIABLES
#======================================
var velocityREAL = Vector3()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		playerView.rotate_y(-event.relative.x * playerSens)
		playerViewCamera.rotate_x(-event.relative.y * playerSens)
		playerViewCamera.rotation.x = clamp(playerViewCamera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	
	
	#Do playerchecks
	process_flags(delta)
	
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
	
	input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	direction = (playerView.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if isPlayerCrouch != true:
		if Input.is_action_pressed("Sprint") and is_on_floor():
			isPlayerSprint = true
		elif !Input.is_action_pressed("Sprint") and (direction.length() < 0.75):
			isPlayerSprint = false
	

func process_state():
	if isPlayerStun:
		playerLegState = legSTUN
		return
	if isPlayerSliding:
		playerLegState = legSLIDE
		return
	if is_on_floor():
		if direction:
			if isPlayerSprint:
				if isPlayerCrouch: #by all accounts i shouldn't
					isPlayerSliding = true
					velocitySLIDE = direction * playerRun * playerSprintSpeedMult
					playerLegState = legSLIDE
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
		if isPlayerCrouch:
			playerLegState = legCROUCHJUMP
		else:
			playerLegState = legJUMP


func process_movement(delta):
	print("Your currently velocity is: " + str(velocity.length()))
	#Stun Movement
	if isPlayerStun:
		return
	
	#Sliding Movement
	elif isPlayerSliding:
		slide_timer -= delta
		velocityFLAT = velocitySLIDE 
		if slide_timer <= 0:
			isPlayerSliding = false
			isPlayerSprint = false
			slide_timer = slideTime #Reset slide counter
		
	#Regular Movement
	else:
		velocityFLAT = lerp(velocityFLAT, direction * playerSpeed, playerAcc * delta * float(is_on_floor()) + playerAirAcc * delta * float(!is_on_floor()))

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
	
	velocityREAL = -position / delta
	moveFunc()
	velocityREAL += position / delta
	print("velocityREAL is: " + str(velocityREAL))
	
	
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

func process_flags(delta):
	headBonk = false
	if headBonker.is_colliding():
		headBonk = true
		
	#This is the code for coyote physics - the movement code generally doesn't use this unless it's for the stairs.
	if coyote_physics == true:
		print("is_on_floor()")
		print(is_on_floor())
		print("isPlayerGrounded")
		print(isPlayerGrounded)
		if is_on_floor() != isPlayerGrounded:
			isPlayerGroundedLeewayCount += delta
			if isPlayerGroundedLeewayCount >= isPlayerGroundedLeeway:
				isPlayerGrounded = is_on_floor()
				isPlayerGroundedLeewayCount = 0
		#if !is_on_floor():
			#isPlayerGroundedLeewayCount += delta
			#if isPlayerGroundedLeewayCount >= isPlayerGroundedLeeway:
				#isPlayerGrounded = false
		#else:
			#isPlayerGroundedLeewayCount = 0
			#isPlayerGrounded = true
	#else:
		#isPlayerGrounded = is_on_floor()

func take_damage(damage):
	currHP -= damage
	if currHP <= 0:
		die()

func die():
	pass

func add_health(amount):
	currHP = clamp(currHP + amount, 0, maxHP)

func crouch(delta):
	if Input.is_action_pressed("Crouch") or isPlayerSliding:
		playerSpeed = playerRun * playerCrouchSpeedMult
		isPlayerCrouch = true
		$StandCol.disabled = true
		$CrouchCol.disabled = false
		
		$playerView.position.y = lerp($playerView.position.y, 0.6 - 1, 0.1)

	elif not headBonk:
		playerSpeed = playerRun
		isPlayerCrouch = false
		$StandCol.disabled = false
		$CrouchCol.disabled = true
		$playerView.position.y = lerp($playerView.position.y, 0.6, 0.1)

#Jump Function
func _jump():
	#Jump is now multplied by floor normal so that the jump is directly off the plane.
	#NOTE may want to update this to occur over a period of time (longer button press = higher jump)
	#This first part fixes jumping on planes a little bit
	
	
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or isPlayerGrounded):
		if is_on_floor() and !isPlayerGrounded:
			var velocityTEMP = (playerJumpVel * get_floor_normal()) 
			velocityGRAV = Vector3()
			print("vtemp = " + str(velocityTEMP))
			velocityGRAV.y += velocityTEMP.y + velocityREAL.y #NOTE Remove the final term if don't want slope assisting jumps
			velocityIMPULSE += velocityTEMP - Vector3(0, velocityTEMP.y, 0)
		else:
			velocityGRAV.y += playerJumpVel + velocityREAL.y #NOTE Remove the final term if don't want slope assisting jumps

# please god, in the name of all that is holy, PLEASE let me slide along walls.
var undesiredMotion = Vector3()
func wallslidefix():
	if self.is_on_wall():
		undesiredMotion = self.get_wall_normal() * (velocity.dot(self.get_wall_normal()));
		if rad_to_deg(acos(velocity.normalized().dot(self.get_wall_normal()))) > 90:
			velocity = velocity - undesiredMotion;
	#if acos(velocity.normalized().dot(self.get_wall_normal())) < deg_to_rad(180):

func blink():
	pass

func moveFunc():
	wallslidefix()
	move_and_slide()
