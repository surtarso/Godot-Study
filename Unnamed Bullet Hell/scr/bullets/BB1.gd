extends EnemyBullet

"""------ BOSS ICE SHARD ------"""

func _ready():
	self.scale = Vector2.ZERO
	$Sprite/Light2D.enabled = true

func _physics_process(delta):
	position += transform.x * bullet_speed
	self.scale += Vector2(1.5,1.5) * delta if self.scale <= Vector2(1,1) else Vector2(0,0)
