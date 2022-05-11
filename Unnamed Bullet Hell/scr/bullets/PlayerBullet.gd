class_name PlayerBullet
extends Area2D

export var bullet_speed:float = 900
export var damage:float = 1

var kill_count:int

func _ready():
	kill_count = 0
	
func _process(delta):
	position += transform.x * bullet_speed * delta

func _on_viewport_exited(_viewport):
	queue_free() #if bullet leaves the screen
	
func _on_body_entered(body): #if hits ------------------------   AN ENEMY:
	if body.is_in_group("enemies"):
		PlayerData.shots_hit += 1 #for accuracy calcs
		var n = randi() % 101
		if n < PlayerData.crit_chance: damage *= PlayerData.crit_bonus
		body._got_hit(damage) #mob queues himself free on Enemy.gd
		if !body.is_in_group("boss"): ## if not a boss:
			_kill_count()
			PlayerData.score += body.mob_score #adds mob value to the player score
		$AnimationPlayer.play("destroyed_bullet") #queues self free on animation

func _on_Bullet_area_entered(area): #if hits another ---------   ENEMY BULLET:
	if area.is_in_group("enemy_bullet") and !area.is_in_group("boss_laser"):
		PlayerData.shots_hit += 1 #for accuracy calcs
		PlayerData.tec_shot = true #flash on interface
		PlayerData.score += area.bullet_score #adds bullet value to player score
		$AnimationPlayer.play("destroyed_bullet") #queues self free on animation
	if area.is_in_group("boss_laser"):
		$AnimationPlayer.play("destroyed_bullet") #queues self free on animation

func _kill_count():
	kill_count += 1
	if kill_count == 2:
		PlayerData.double_kill = true
	if kill_count == 3:
		PlayerData.triple_kill = true
