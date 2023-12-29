extends Node3D

var BULLET_SPEED = 70
var BULLET_DAMAGE = 15

const KILL_TIMER = 4
var timer = 0

var hit_something = false




# Called when the node enters the scene tree for the first time.
func _ready():
	$Area.connect("body_entered", self, "collided")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	position += dir * speed * delta
