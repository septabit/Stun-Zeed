extends RigidBody3D

var objName = "flashlight"

var isPowered = false
@onready var lightSource = $SpotLight3D

# var pos = $self.position
var isHeld = false
var itemOwner = null
var itemSlot = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _physics_process(delta):
	updatePOS()
	print(itemOwner)

func updatePOS():
	if itemOwner != null:
		$self.position = itemOwner.weaponPOS
		

func updateOwnership(player):
	itemOwner = player
	isHeld = true

func removeOwnership(player):
	itemOwner = null
	isHeld = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if isPowered:
		lightSource.show()
	else:
		lightSource.hide()
		
	


func prim_fire():
	isPowered = true
	
func sec_fire():
	isPowered = false

func reload():
	pass

