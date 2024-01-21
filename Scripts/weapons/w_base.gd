extends RigidBody3D
class_name w_base

var objName = "base"

var isHeld = false
var itemOwner = null
var itemSlot = null
var itemSlotPOS = null

# Called when the node enters the scene tree for the first time.
func _ready():
	#For children of this, you will want to reassign the objName variable to the
	#item name.
	pass # Replace with function body.

func _physics_process(delta):
	#One of the things about process and physics process when it comes to 
	#inheritence is that it will call the parent instance of physics process
	#and then the childs instance. For this, we only want to update POS.
	updatePOS()

func updatePOS():
	if itemOwner != null:
		position = itemSlotPOS.global_position
		basis = itemSlotPOS.global_basis

func updateOwnership(player, weaponPOSNode):
	itemOwner = player
	itemSlotPOS = weaponPOSNode
	isHeld = true

func removeOwnership(player):
	itemOwner = null
	isHeld = false
	itemSlotPOS = null
	

#DEFAULT WEAPON OPERATION
#If these functions are not changed within the child node, then they will pass which means they ain't do shit.

func prim_fire():
	#This is what happens when you click the primary fire button. Usually this would fire a weapon.
	pass
	
func sec_fire():
	#This is what happens when you click the secondary fire button. Usually this would aim a weapon or do a secondary fire.
	pass

func prim_fire_stop():
	#When you let go of the primary fire button. 
	#Usually you would let this pass unless you need to do something like weapon charging.
	pass
	
func sec_fire_stop():
	#Same as prim_fire_stop but for secondary fire. Un-ADS for example.
	pass
	
func reload():
	#for reloading, obviously...
	pass
	
