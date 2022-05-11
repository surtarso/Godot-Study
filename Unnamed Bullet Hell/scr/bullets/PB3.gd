extends PlayerBullet

func _ready():
	kill_count = 0
	$CPUParticles2D.emitting = true
	$Sprite/Light2D.enabled = true
	self.scale = Vector2.ZERO

func _physics_process(_delta):
	position += transform.x * bullet_speed
	self.scale += Vector2(0.1,0.1) if self.scale <= Vector2(2,2) else Vector2(0,0)

func _on_body_entered(body): #if hits an enemy
	self.scale += Vector2(0.1,0.1) if self.scale <= Vector2(3,3) else Vector2(0,0)
	damage += 0.025
	if body.is_in_group("enemies"):
		PlayerData.shots_hit += 1 #for accuracy calcs
		body._got_hit(damage) #mob queues himself free on Enemy.gd
		if !body.is_in_group("boss"): ## if not a boss:
			_kill_count()
			PlayerData.score += body.mob_score #adds mob value to the player score

func _on_Bullet_area_entered(area): #if hits another enemy bullet
	self.scale += Vector2(0.1,0.1)
	if area.is_in_group("enemy_bullet") and !area.is_in_group("boss_laser"):
		PlayerData.shots_hit += 1 #for accuracy calcs
		PlayerData.tec_shot = true #flash on interface
		PlayerData.score += area.bullet_score #adds bullet value to player score
		area.queue_free() #destroy bullet, no need to destroy in EnemyBullet.gd

	if area.is_in_group("enemy_laser"):
		queue_free()
	if area.is_in_group("bullet"): area.queue_free()
