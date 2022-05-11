extends Enemy


onready var shoot_array_purple:Array = [$Sprite/Position2D,$Sprite/Position2D2,$Sprite/Position2D3] ## PURPLE
onready var shoot_array_red:Array = [$Sprite/Position2DRed,$Sprite/Position2DRed2,$Sprite/Position2DRed3] ## RED
onready var shoot_array_green:Array = [$Sprite/Position2DGreen,$Sprite/Position2DGreen2,$Sprite/Position2DGreen3] ## GREEN
onready var shoot_array_blue:Array = [$Sprite/Position2DBlue,$Sprite/Position2DBlue2,$Sprite/Position2DBlue3] ## BLUE
onready var all_holes:Array = [shoot_array_purple,shoot_array_blue,shoot_array_green,shoot_array_red]


func _shoot(): #shoot 12 Bullets on interval
	if $ShootCooldown.is_stopped(): #control speed with var shoot_rate
		$AnimationPlayer2.play("default")
		$ShootCooldown.wait_time = rand_range(shoot_rate,shoot_rate+0.75)
		#can_shoot = false (removale option)
		
		for eye in all_holes.size():
			for hole in all_holes[eye].size():
				can_shoot = false
				
				var bullet = bullets_array[bullet_type].instance()
				bullet.transform = all_holes[eye][hole].global_transform
				Globals.stage.add_child(bullet)
				
				$DelayTimer.start()
				yield($DelayTimer,"timeout")
				can_shoot = true
			
			$ShootCooldown.start()
			
			#changes bullets per hole type: (removable option)
			if bullet_type < bullets_array.size() - 1: 
				bullet_type += 1
			else: bullet_type = 0
		
		#breath time: (removable option)
		$DelayTimer.start()
		yield($DelayTimer,"timeout")
		
		#cycles start bullet pseudo random: (removable option)
		if bullet_type < bullets_array.size() - 1:
			bullet_type += 1
		else: bullet_type = 0
