extends RigidBody3D

var isPowered = false
@onready var lightSource = $SpotLight3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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
