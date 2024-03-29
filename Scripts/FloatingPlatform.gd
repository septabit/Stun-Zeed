extends Node3D

@export var offset = Vector3(0, 5, 0)
@export var duration = 5.0

# Called when the node enters the scene tree for the first time.
func _ready():
	start_tween()

func start_tween():
	var tween = get_tree().create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_loops().set_parallel(false)
	tween.tween_property(self, "position", offset, duration / 2)
	tween.tween_property(self, "position", Vector3(), duration / 2)
	#tween.tween_property(self, "position", self.position + offset, duration / 2)
	#tween.tween_property(self, "position", self.position, duration / 2)
	
	
