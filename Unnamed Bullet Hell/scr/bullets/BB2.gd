extends EnemyBullet

"""---- BOSS LASER ----"""

func _ready():
	$Sprite/Light2D.enabled = true
	$AnimationPlayer.play("default")
	$Duration.start()

func _process(_delta):
	yield($Duration,"timeout")
	queue_free()

func _on_viewport_exited(_viewport):
	pass


func _on_Bullet_area_entered(area):
	if not area.is_in_group("boss_laser"): area.queue_free()
