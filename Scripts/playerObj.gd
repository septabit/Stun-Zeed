extends CharacterBody3D

#This is the code for the player object, built off the default CharacterBody3D code.

#======================================
# Node Definitions
#======================================
@onready var playerView = $playerView
@onready var playerViewCamera = $playerView/playerCamera
@onready var pcap = $CollisionShape #player capsule.
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
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		#Jump is now multplied by floor normal so that the jump is directly off the plane.
		#NOTE may want to update this to occur over a period of time (longer button press = higher jump)
		velocity = velocity + (playerJumpVel * get_floor_normal())
		#velocity.y = playerJumpVel
	
	
	if Input.is_action_pressed("Crouch"):
		playerSpeed = playerRun * playerCrouchSpeedMult
		isPlayerCrouch = true
		pcap.shape.height -= playerCrouchSpeed * delta
	elif not headBonk:
		playerSpeed = playerRun
		isPlayerCrouch = false
		pcap.shape.height += playerCrouchSpeed * delta
		
	pcap.shape.height = clamp(pcap.shape.height, playerHeightCrouch, playerHeight)
	
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
		pass
		#primary_fire()
		
	if Input.is_action_pressed("SecondaryFire"):
		pass
		#secondary_fire()
		
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
	# MOVE AND SLIDE!!!
	#======================================
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

func take_damage(damage):
	currHP -= damage
	if currHP <= 0:
		die()
		
func die():
	pass
	
func add_health(amount):
	currHP = clamp(currHP + amount, 0, maxHP)
