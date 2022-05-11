extends EnemyBullet

func _physics_process(_delta):
	position += transform.x * bullet_speed
