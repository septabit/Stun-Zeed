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
	
	jump()
	
	
	
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
	#_rotate_step_up_seperation_ray()
	$floorSeperationRayF.disabled = 1
	$floorSeperationRayL.disabled = 1
	$floorSeperationRayR.disabled = 1
	move_and_slide()
	#_snap_down_to_stairs_check()

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


#Jump Function
var _cur_frame = 0
@export var _jump_frame_grace = 50
var _last_frame_was_on_floor = -_jump_frame_grace - 1
func jump():
	#Jump is now multplied by floor normal so that the jump is directly off the plane.
	#NOTE may want to update this to occur over a period of time (longer button press = higher jump)
	#This first part fixes jumping on planes a little bit
	_cur_frame += 1
	if is_on_floor():
		_last_frame_was_on_floor = _cur_frame
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or (_cur_frame - _last_frame_was_on_floor <= _jump_frame_grace)):
		velocity = velocity + (playerJumpVel * get_floor_normal())
	#velocity.y = playerJumpVel

#code that handles down stairs (currently sort of broken near ramps as they snap to parts of the ramp under the floor...:
var _was_on_floor_last_frame = false
var _snapped_to_stairs_last_frame = false
func _snap_down_to_stairs_check():
	var did_snap = false
	$floorSnapBelow.position.y = self.global_position.y + (playerHeight/2 - pcap.shape.height) #Move the floorSnapBelow raycast w. crouch.
	if not is_on_floor() and velocity.y <= 0 and (_was_on_floor_last_frame or _snapped_to_stairs_last_frame) and $floorSnapBelow.is_colliding():
		var body_test_result = PhysicsTestMotionResult3D.new()
		var params = PhysicsTestMotionParameters3D.new()
		var max_step_down = -0.5
		params.from = self.global_transform
		params.motion = Vector3(0,max_step_down,0)
		if PhysicsServer3D.body_test_motion(self.get_rid(), params, body_test_result):
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			print("Snap!")
			did_snap = true
			
	_was_on_floor_last_frame = is_on_floor()
	_snapped_to_stairs_last_frame = did_snap

#code that handles going up stairs
@onready var initial_seperation_ray_dist = abs($floorSeperationRayF.position.z)
var _last_xz_vel : Vector3 = Vector3(0, 0, 0)
func _rotate_step_up_seperation_ray():
	var xz_vel = velocity * Vector3(1,0,1)
	
	if xz_vel.length() < 0.1:
		xz_vel = _last_xz_vel
	else:
		_last_xz_vel = xz_vel
	
	
		#This code rotates the step up detectors around the character so that you can walk up steps
	#no matter the direction. There are three of the nodes so that it can detect walking diagonal up stairs.
	var xz_f_ray_pos = xz_vel.normalized() * initial_seperation_ray_dist
	$floorSeperationRayF.global_position.x = self.global_position.x + xz_f_ray_pos.x
	$floorSeperationRayF.global_position.z = self.global_position.z + xz_f_ray_pos.z
	$floorSeperationRayF.global_position.y = self.global_position.y + (playerHeight/2 - pcap.shape.height)
	
	var xz_l_ray_pos = xz_f_ray_pos.rotated(Vector3(0,1.0,0), deg_to_rad(-50))
	$floorSeperationRayL.global_position.x = self.global_position.x + xz_l_ray_pos.x
	$floorSeperationRayL.global_position.z = self.global_position.z + xz_l_ray_pos.z
	$floorSeperationRayL.global_position.y = self.global_position.y + (playerHeight/2 - pcap.shape.height)
	
	var xz_r_ray_pos = xz_f_ray_pos.rotated(Vector3(0,1.0,0), deg_to_rad(50))
	$floorSeperationRayR.global_position.x = self.global_position.x + xz_r_ray_pos.x
	$floorSeperationRayR.global_position.z = self.global_position.z + xz_r_ray_pos.z
	$floorSeperationRayR.global_position.y = self.global_position.y + (playerHeight/2 - pcap.shape.height)
	
	
	$floorSeperationRayF/RayCast3D.force_raycast_update()
	$floorSeperationRayR/RayCast3D.force_raycast_update()
	$floorSeperationRayL/RayCast3D.force_raycast_update()
	
	#This code determines whether the slope is too steep.
	var max_slope_ang_dot = Vector3(0, 1, 0).rotated(Vector3(1.0, 0, 0), self.floor_max_angle).dot(Vector3(0,1,0))
	var any_too_steep = false
	if $floorSeperationRayF/RayCast3D.is_colliding() and $floorSeperationRayF/RayCast3D.get_collision_normal().dot(Vector3(0,1,0)) < max_slope_ang_dot:
		any_too_steep = true
	if $floorSeperationRayL/RayCast3D.is_colliding() and $floorSeperationRayL/RayCast3D.get_collision_normal().dot(Vector3(0,1,0)) < max_slope_ang_dot:
		any_too_steep = true
	if $floorSeperationRayR/RayCast3D.is_colliding() and $floorSeperationRayR/RayCast3D.get_collision_normal().dot(Vector3(0,1,0)) < max_slope_ang_dot:
		any_too_steep = true
	
	print("focal dot is: " + str($floorSeperationRayF/RayCast3D.get_collision_normal().dot(Vector3(0,1,0))))
	
	if !is_on_floor():
		any_too_steep = 1
		
	
	#This stops any of the step up/step down if the slope is too steep.
	$floorSeperationRayF.disabled = any_too_steep
	$floorSeperationRayL.disabled = any_too_steep
	$floorSeperationRayR.disabled = any_too_steep

	$floorSnapBelow.enabled = !any_too_steep
	
