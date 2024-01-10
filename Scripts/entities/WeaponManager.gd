extends Node3D

@onready var animPlayer = $"../TorsoModel/AnimationPlayer"
@onready var itemGrabber = $"../playerCamera/itemGrabber"
@onready var lab = $"../../CanvasLayer/Label"

var currWeapon 
var currWeaponSlot = 0

var isItemOnCrosshair = false

var WeaponSlotsIndex = { 
	0 : "slot0",
	1 : "slot1",
	2 : "slot2",
	3 : "slot3"
}

var WeaponSlots = {
	"slot0" : null,
	"slot1" : null,
	"slot2" : null,
	"slot3" : null
}


var changing_weapon = false
var unequipped_weapon = false

var weapon_index = 0 #for switching weapons using the mouse wheel



var weaponNum = 0
var Next_Weapon: String

# Called when the node enters the scene tree for the first time.
func _ready():
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	print(itemGrabber.get_collider())
	print(WeaponSlots)
	var teststring = "The weapon slot is %s"
	var teststring2 = teststring % weaponNum
	#lab.settext( teststring2) 
	

func scrollWeaponSlot(dir):
	#Function only takes +1 or -1
	currWeaponSlot = (currWeaponSlot + dir) % WeaponSlots.size()

func pickup_Item():
	if itemGrabber.is_colliding():
		#Checks pickup raycast, if it's there, add ownership to the item  and add to item inventory
		var itemStore = itemGrabber.get_collider()
		WeaponSlots[WeaponSlotsIndex[currWeaponSlot]]  = itemStore
		itemStore.updateOwnership($self)
	
func drop_Item():
	#Removes the ownership on the item, then removes the item from inventory.
	WeaponSlots[WeaponSlotsIndex[currWeaponSlot]].removeOwnership($self)
	WeaponSlots[WeaponSlotsIndex[currWeaponSlot]] = null


func prim_fire():
	pass
	
func sec_fire():
	pass
	
func prim_fire_stop():
	pass
	
func sec_fire_stop():
	pass
	
func reload():
	pass
	
func drop_weapon():
	pass
	
	
