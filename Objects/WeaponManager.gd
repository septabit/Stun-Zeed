extends Node3D

@onready var animPlayer = $"../TorsoModel/AnimationPlayer"

var allWeapons = {}
var currWeapons = {}


var hud

var currWeaponSlot = 0
var currWeapon

var changing_weapon = false
var unequipped_weapon = false

var weapon_index = 0 #for switching weapons using the mouse wheel



var weaponNum = 0
var Next_Weapon: String

# Called when the node enters the scene tree for the first time.
func _ready():
	
	allWeapons = {
		"unarmed" : preload(""),
		"flashlight" : preload("res://Objects/weapons/w_flashlight.tscn"),
		#"shotgun" : preload("")
	}

	currWeapons = {
		"slot0" : $unarmed,
		"slot1" : $unarmed,
		"slot2" : $unarmed,
		"slot3" : $unarmed
	}


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func scrollWeaponSlot(dir):
	#Function only takes +1 or -1
	if currWeaponSlot == 3 and dir == 1:
		currWeaponSlot = 0
	elif currWeaponSlot == 0 and dir == -1:
		currWeaponSlot = 3
	else:
		currWeaponSlot += dir

func pickup(item):
	currslot = 

func prim_fire():
	return
	
func sec_fire():
	return
	
func prim_fire_stop():
	return
	
func sec_fire_stop():
	return
	
func reload():
	return
	
func drop_weapon():
	return
	
	
