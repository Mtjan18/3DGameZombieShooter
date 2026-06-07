extends Node3D

var speed = 50
var lifetime: float = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position+= transform.basis * Vector3(0,0,-speed) * delta
	lifetime -= delta
	
	if lifetime <= 0:
		queue_free()
	
	pass
