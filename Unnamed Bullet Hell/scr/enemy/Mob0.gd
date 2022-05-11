extends Enemy


func _process(_delta):
	if $ShootCooldown.is_stopped(): 
		$AnimationPlayer2.play_backwards("shoot")
		$AnimationPlayer.queue("default")
