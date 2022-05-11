extends Enemy


onready var shoot_array:Array = [$Sprite/Position2D,$Sprite/Position2D2,$Sprite/Position2D3,$Sprite/Position2D4]


##- override
func _ready():
	bullet_type = 0
	$ShootCooldown.wait_time = rand_range(shoot_rate,shoot_rate+0.8) 
	$ShootCooldown.start()
	$AnimationPlayer2.play("default")
	$HealthBar.value = 100

func _shoot(): #shoot Bullets on interval
	$Sprite/aim/Light2D2.energy -= 0.1
	if $ShootCooldown.is_stopped(): #control speed with var shoot_rate
		for hole in shoot_array.size():
			can_shoot = false
			$Sprite/aim/Light2D2.enabled = true
			$Sprite/aim/Light2D2.energy = 3
			$ShootCooldown.wait_time = rand_range(shoot_rate,shoot_rate+0.5) 
			var bullet = bullets_array[bullet_type].instance()
			bullet.transform = shoot_array[hole].global_transform
			Globals.stage.add_child(bullet)
			$Sprite.frame = 1
			$DelayTimer.start()
			yield($DelayTimer,"timeout")
			$Sprite.frame = 0
			can_shoot = true
		$ShootCooldown.start()


## - killed with eye closed drops a meteor
func _on_tree_exiting():
	if $Sprite.frame == 1:
		bullet_type = 1
		var bullet = bullets_array[bullet_type].instance()
		bullet.position = self.global_position
		Globals.stage.call_deferred("add_child",bullet)
