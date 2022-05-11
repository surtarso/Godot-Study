class_name EnemyBullet

extends Area2D

export var bullet_score:int = 1
export var damage:float = 1
export var bullet_speed:float = 7

func _on_viewport_exited(_viewport):
	queue_free()
	
func _on_body_entered(body):
	if body.is_in_group("player") and !body.immune:
		body._got_hit(damage)
		if self.is_in_group("boss_iceshard") and !body.god_mode:
			PlayerData.shoot_rate += 0.0125
		$AnimationPlayer.play("blow") #queue_free on anim
	if body.name == "EnemyLimitMap":
		return
	else:
		$AnimationPlayer.play("blow") #queue_free on anim
	
func _on_Bullet_area_entered(area):
	if area.is_in_group("bullet"):
		$AnimationPlayer.play("blow") #queue_free on anim
