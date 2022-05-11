extends EnemyBullet

"""------ BOSS BLACK HOLE --------"""

func _ready():
	self.scale = Vector2.ZERO
	$Sprite/Light2D.enabled = true

func _physics_process(_delta):
	position += transform.x * bullet_speed
	self.scale += Vector2(0.1,0.1) if self.scale <= Vector2(1,1) else Vector2(0,0)

## _____________ OVERIDES _________________

func _on_body_entered(body):
	if body.is_in_group("player") and !body.immune:
		body._got_hit(damage)

func _on_Bullet_area_entered(area):
	self.scale += Vector2(0.1,0.1)
	damage += 0.5
	if not area.is_in_group("boss_laser"): area.queue_free()
