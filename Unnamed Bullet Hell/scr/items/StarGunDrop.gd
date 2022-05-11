extends Item


func _ready():
	value = true
	$AnimationPlayer.play("default")
