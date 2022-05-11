extends Area2D
"""
Drops coke on the floor, signals PlayerData.gd that there is coke on the floor for 3 seconds
Also signals PlayerData.gd player current position (coke position)
After 3 seconds it becomes unusable  and the respwn timer starts for 10 seconds
"""
func _ready():
	$drop_coke.frame = 0 #resets animation

func _process(_delta):
	if $RespawnTimer.is_stopped():
		self.modulate.r = 0  #original color would be better...(sets it green)
		self.set_deferred("monitoring",true) #enables monitoring of hitboxes

func _on_CokeBag_body_entered(_body):
	if $UseTimer.is_stopped():
		PlayerData.current_position = $drop_coke.global_position #save current coke position for enemy to follow
		PlayerData.dropped_coke = true #timer in which the enemy will persue the coke and ignore player
		$drop_coke.play("drop_coke")
		
		$UseTimer.start() ## 3 secs PM cop will follow coke on the floor
		
		yield($UseTimer,"timeout")
		$drop_coke.stop()
		$drop_coke.frame = 0 #removes coke from the floor
		PlayerData.dropped_coke = false #cop will stop chasing coke
		
		$RespawnTimer.start() ## 10 secs disabled
		#self.visible = false
		self.modulate.r = 255 #sets it red
		self.set_deferred("monitoring",false) #disable monitoring of hitboxes
