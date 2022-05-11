class_name Enemy
extends RigidBody2D


#stats: 
export var loot_drop_chance:float = 5 #default 5% chance to drop
export var mob_score:int = 10 ## mobs worth in points
export var mob_max_health:float = 5
#"gravity" (Y constant):
export var down_speed:float = 1 ## Y speed constantly
#Y movement:
export var up_bounce:bool = false #bounce on Y axis on a timer
export var up_bounce_speed:float = 4 #speed of bounce
export var up_bounce_rate:float = 1.5 #time between bounces
#X movement:
export var side_bounce:bool = false ## moves sideways on a timer
export var side_bounce_lenght:float = 5 ## lenght random sideways movement
export var side_bounce_rate:float = 2 ## time between direction changes
#enable shooting, shoot rate and bullets:
export var can_shoot:bool = false ## toggles shooting
export var shoot_rate:float = 1.65 ## rate of fire
export (Array, PackedScene) var bullets_array #bullets enemy will use (bullets/EB#.tscn)
#follows player position:
export var aim_at_player:bool = false ## shoots at player current position
#follows player sideways:
export var aim_sideways:bool = false
#rotates aim regularly:
export var aim_spin:bool = false ## spins in place
export var aim_spin_rate:float = 1 ## spin speed and direction
#rotates aim randomly:
export var aim_randomly:bool = false ## aims randomly and shaky
export var aim_random_rate:float = 12 ## how much spinning of random aim
#loot:
export (Array, PackedScene) var drop_array # drops packedscenes
var dup_array #duplicate drop array to modify

var side_speed:float
var bullet_type:int #array number of chosen bullet
var aim_light_energy = 8

onready var health:float = mob_max_health

func _ready():
	bullet_type = 0
	$ShootCooldown.wait_time = rand_range(shoot_rate,shoot_rate+0.8) 
	$ShootCooldown.start()
	$AnimationPlayer.play("default")
	$HealthBar.value = 100

func _physics_process(_delta):
	#shoot:
	if can_shoot: _shoot()
	#movement (none, any or both):
	if side_bounce: _side_bounce()
	if up_bounce: _up_bounce()
	#aims (none or one only):
	if aim_at_player: _aim_at_player()
	if aim_sideways: _aim_sideways()
	if aim_randomly: _aim_randomly()
	if aim_spin: _aim_spin()
	#respawn on screen bottom to top
	if self.global_position.y > Globals.stage.stage_height + 64: # stage bottom
		_respawn_on_top(true)
	#correct healthbar rotation to maintain healthbar static:
	$HealthBar.rect_rotation = -self.rotation_degrees
	#apply movement
	self.position += Vector2(side_speed,down_speed)

""" --------------------------- SHOOT ------------------------------ """
func _shoot(): #shoot Bullets on interval
	$Sprite/aim/Light2D2.energy -= 0.1
	if $ShootCooldown.is_stopped(): #control speed with var shoot_rate
		$Sprite/aim/Light2D2.energy = aim_light_energy
		$ShootCooldown.wait_time = rand_range(shoot_rate,shoot_rate+0.8) 
		var bullet = bullets_array[bullet_type].instance()
		Globals.stage.get_node("EnemyBullets").add_child(bullet)
		bullet.transform = $Sprite/Position2D.global_transform
		$ShootCooldown.start()

""" --------------------------- MOVEMENT ------------------------------ """
func _side_bounce():
	if $SideTimer.is_stopped(): #change sideways direction randomly
		$SideTimer/BounceTween.interpolate_property(
			self,"side_speed",
			self.side_speed,rand_range(-side_bounce_lenght, side_bounce_lenght),
			rand_range(0.5,1),Tween.TRANS_LINEAR,Tween.EASE_IN
		)
		$SideTimer/BounceTween.start()
		$SideTimer.wait_time = rand_range(0.1,side_bounce_rate)
		$SideTimer.start()

func _up_bounce():
	if $UpTimer.is_stopped():
		$UpTimer/Tween.interpolate_property(
			self,"down_speed",
			self.down_speed,rand_range(-up_bounce_speed, up_bounce_speed),
			rand_range(0.6,1),Tween.TRANS_LINEAR,Tween.EASE_IN
		)
		$UpTimer/Tween.start()
		$UpTimer.wait_time = rand_range(0.1,up_bounce_rate)
		$UpTimer.start()

""" --------------------------- AIM ------------------------------ """
func _aim_spin():
	angular_velocity = lerp_angle(aim_spin_rate,-aim_spin_rate,0.01)

func _aim_at_player():
	if Globals.player != null:
		var aim_dir = (Globals.player.position - self.position).angle() - 1.57
		var current = self.rotation
		self.rotation = lerp_angle(current,aim_dir,0.01)
	else: pass

func _aim_randomly():
	if $AimTimer.is_stopped():
		$AimTimer/Tween.interpolate_property(
			self,"angular_velocity",
			self.angular_velocity,rand_range(-aim_random_rate, aim_random_rate),
			rand_range(0.8,1.2),Tween.TRANS_LINEAR,Tween.EASE_IN_OUT
		)
		$AimTimer/Tween.start()
		$AimTimer.wait_time = rand_range(1, 2)
		$AimTimer.start()

func _aim_sideways():
	if Globals.player != null:
		if aim_at_player == false: self.rotation = lerp_angle(rotation,0,0.02) #correct angle
		var aim_dir = Globals.player.global_position.x
		var current = self.global_position.x
		self.position.x = lerp(current,aim_dir,0.01)
	else: pass

""" ----------------- HIT/DEATH, DROP LOOT, RESPAWN -----------------------"""
func _got_hit(damage): #gets hit by Player Bullet
	health -= clamp(damage,0,health) #dont allow damage to go over max health
	if health > 0: $AnimationPlayer.play("hit")
	## healthbar animation:
	var percent_hp = int((float(health) / mob_max_health) * 100)
	$HealthBar/Tween.interpolate_property(
		$HealthBar, "value", #what
		$HealthBar.value, percent_hp, #from-to
		0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT) #duration-how
	$HealthBar/Tween.start()
	
	 ## DEATH:
	if health == 0:
		var n = randi() % 101 #int between 0 and 100
		if n <= loot_drop_chance: #if something dropped
			dup_array = drop_array.duplicate(true) #hard copy of loot_array
			_drop_item() # drop an item
		$AnimationPlayer.play("death") #removes mob (queue_free on anim)

func _drop_item():
	dup_array.shuffle() #shuffles dup-drop array
	var drop = dup_array[0].instance() #instance a sample for NAME
	drop.position = self.global_position #position it
	
	## check if item is not needed (ITEM FILTER):
	if (drop.name == "HealthDrop" and PlayerData.health == PlayerData.MAX_HEALTH) or ( #dont drop health at full health
		drop.name == "CritDrop" and PlayerData.crit_chance == 100) or ( #dont drop crit at max crit 
			drop.name == "SpeedDrop" and PlayerData.shoot_rate <= Globals.player.min_shoot_rate) or ( #dont drop speed if at min_shoot_rate and correct value if tec_shot active
				drop.name == "SpeedDrop" and PlayerData.tec_shot and (PlayerData.shoot_rate + Globals.player.tec_shot_rate <= Globals.player.min_shoot_rate)) or ( 
					drop.name == "ShieldDrop" and PlayerData.immune_duration >= PlayerData.max_immune_duration) or ( #dont drop shield at max shield
						drop.name == "MultiGunDrop" and Globals.player.multi_gun) or ( #dont drop multigun if already active
							(drop.name == "TripleShotDrop" or drop.name == "DoubleShotDrop") and Globals.player.bullet_type == 2) or ( #dont drop bullets w/ best bullet(triple shot)
								drop.name == "DoubleShotDrop" and Globals.player.bullet_type == 1) or ( #dont drop double shot if its active
									drop.name == "StarGunDrop" and Globals.player.star_gun): #dont drop stargun if already active
		
		dup_array.remove(0) #remove useless item from options
		drop.queue_free() #remove instance of it
		_drop_item() #re-shuffle and filter again
	
	## drop item past item filter:
	else: Globals.stage.get_node("Loot").call_deferred("add_child",drop)

func _respawn_on_top(value:bool):
	if value == true:
		set_physics_process(false)
		can_shoot = false
		$RespwnTimer.start() 
		yield($RespwnTimer,"timeout")
		var n = rand_range(0, Globals.stage.stage_width)
		self.position = Vector2(n,-32) #port to top
		can_shoot = true
		set_physics_process(true)

