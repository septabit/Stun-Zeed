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
var legStates =  {
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
@export var playerAirAcc = 1 #Controls the amount of air control you have. Less = more commitment to jumps.
var playerSpeed = playerRun #Speed of the player.
var isPlayerSprint = false
var isPlayerCrouch = false
var headBonk = false #this checks if you can uncrouch 
var gravity = 9.8

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
	
	#Process Leg Movement
	process_movement(delta)
	
	#Debug related code.
	print(playerLegState)

func _headbob(time) -> Vector3:
	#This function just gives a headbob to the character.
	var pos = Vector3.ZERO
	pos.y = sin(time * bobFreq) * bobAmp
	return pos

func process_input(delta):
	# Handle jump.
	
	_jump()
	
	crouch(delta)
	
	if isPlayerCrouch != true:
		if Input.is_action_pressed("Sprint") and is_on_floor():
			playerSpeed = playerRun * playerSprintSpeedMult
			isPlayerSprint = true
		else:
			playerSpeed = playerRun
			isPlayerSprint = false
			
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
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	direction = (playerView.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	

func process_movement(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	if is_on_floor():
		if direction:
			#If you're moving, then set movement to SPEED.
			velocity.x = direction.x * playerSpeed
			velocity.z = direction.z * playerSpeed
			#Set state for if running or sprinting.
			if isPlayerSprint:
				playerLegState = legSPRINT
			elif isPlayerCrouch:
				playerLegState = legCROUCHWALK
			else:
				playerLegState = legRUN
		else:
			#This part sets the speed to 0 if not holding direction.
			velocity.x = move_toward(velocity.x, 0, playerSpeed) 
			velocity.z = move_toward(velocity.z, 0, playerSpeed)
			if isPlayerCrouch:
				playerLegState = legCROUCH
			else:
				playerLegState = legIDLE 
	else:
		velocity.x = lerp(velocity.x, direction.x * playerSpeed, delta * playerAirAcc)
		velocity.z = lerp(velocity.z, direction.z * playerSpeed, delta * playerAirAcc)
		playerLegState = legJUMP
		
	#======================================
	# FOV & Head Bob Code
	#======================================
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

func process_weapons():
	
	#weapon swap
	if Input.is_action_just_pressed("slot_0"):
		weaponManager.change_weapon(0)
	
	if Input.is_action_just_pressed("slot_1"):
		weaponManager.change_weapon(1)
		
	if Input.is_action_just_pressed("slot_2"):
		weaponManager.change_weapon(2)
		
	if Input.is_action_just_pressed("slot_3"):
		weaponManager.change_weapon(3)
	
	#weapon firing
	if Input.is_action_just_pressed("PrimaryFire"):
		weaponManager.prim_fire()
	if Input.is_action_just_released("PrimaryFire"):
		weaponManager.prim_fire_stop()
	if Input.is_action_just_pressed("SecondaryFire"):
		weaponManager.sec_fire()
	if Input.is_action_just_released("SecondaryFire"):
		weaponManager.sec_fire_stop()
		
	#weapon reload
	if Input.is_action_just_pressed("reload"):
		weaponManager.reload()
	
	#weapon drop
	if Input.is_action_just_pressed("drop"):
		weaponManager.drop_weapon()
		
	#weapon pickup

func process_flags():
	headBonk = false
	if headBonker.is_colliding():
		headBonk = true
		
		
	if coyote_physics == true:
		if !is_on_floor():
			isPlayerGroundedLeewayCount += 1
			if isPlayerGroundedLeewayCount >= isPlayerGroundedLeeway:
				isPlayerGrounded = false
		else:
			isPlayerGroundedLeewayCount = 0
			isPlayerGrounded = true
			
		print(isPlayerGrounded)
		print(is_on_floor())
		print(isPlayerGroundedLeewayCount)
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
		velocity = velocity + (playerJumpVel * get_floor_normal())
	#velocity.y = playerJumpVel


var max_step_up = 0.5
var step_up_speed = 0.1
var colP = Vector3()
var normP = Vector3()
func _stepup():
	
	#$stepupRayObj/stepUpRay.position.x = self.position.x + velocity.normalized().x * 0.5
	#$stepupRayObj/stepUpRay.position.z = self.position.z + velocity.normalized().z * 0.5
	#$stepupRayObj/stepUpRay.position.y = self.position.y + (playerHeight/2 - pcap.shape.height)
	
	#$stepUpRay.position = Vector3(self.position.x + velocity.normalized().x * 0.5, self.position.z + velocity.normalized().z * 0.5, self.position.y + (playerHeight/2 - pcap.shape.height))
	
	#var max_slope_ang_dot = Vector3(0, 1, 0).rotated(Vector3(1.0, 0, 0), self.floor_max_angle).dot(Vector3(0,1,0))
	$stepUpSeperation.disabled = true
	if $stepUpRay.is_colliding() and velocity != Vector3(0, 0, 0) and $stepUpRay.get_collision_normal() == Vector3(0, 1, 0) and isPlayerGrounded == true:
		print("walking up stairs...")
		$stepUpSeperation.disabled = false


# please god, in the name of all that is holy, PLEASE let me slide along walls.
var undesiredMotion = Vector3()
func wallslidefix():
	if self.is_on_wall():
		undesiredMotion = self.get_wall_normal() * (velocity.dot(self.get_wall_normal()));
		if rad_to_deg(acos(velocity.normalized().dot(self.get_wall_normal()))) > 90:
			velocity = velocity - undesiredMotion;
	#if acos(velocity.normalized().dot(self.get_wall_normal())) < deg_to_rad(180):

