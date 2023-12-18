extends Node3D

#Exits the game if quit button pressed
func _unhandled_input(event):
	if Input.is_action_just_pressed("Quit"):
		get_tree().quit()
