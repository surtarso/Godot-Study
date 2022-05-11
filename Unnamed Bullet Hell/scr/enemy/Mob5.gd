extends Enemy


onready var eye_shoot_array:Array = [$Sprite/Position2DEyes,$Sprite/Position2DEyes2,$Sprite/Position2DEyes3,$Sprite/Position2DEyes4]


func _shoot(): #shoot Bullets on interval
	if $ShootCooldown.is_stopped(): #control speed with var shoot_rate
		$ShootCooldown.wait_time = rand_range(shoot_rate,shoot_rate+0.5) 
		for hole in eye_shoot_array.size():
			can_shoot = false
			var bullet = bullets_array[bullet_type].instance()
			bullet.transform = eye_shoot_array[hole].global_transform
			Globals.stage.add_child(bullet)
			$DelayTimer.start()
			yield($DelayTimer,"timeout")
			can_shoot = true
		$ShootCooldown.start()
