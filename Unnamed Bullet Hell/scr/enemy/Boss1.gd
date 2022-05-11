## Boss1.gd
extends RigidBody2D

export var max_health:float = 800
export var drop_help:bool = false
export var can_shoot_lasers:bool = false ## toggles shooting
export var laser_shoot_rate:float ## rate of fire
export var can_shoot_cannons:bool = false ## toggles shooting
export var cannon_shoot_rate:float ## rate of fire
export var can_shoot_spray:bool = false ## toggles shooting
export var spray_shoot_rate:float ## rate of fire
export var spray_delay:float ## delay between spray-hole shots
export (Array, PackedScene) var bullets_array #bullets enemy will use (bullets/EB#.tscn)
export var aim_at_player:bool = true ## shoots at player current position
export var aim_sideways:bool = false
export var move_sideways:bool = false
export (Array, PackedScene) var drop_array #array of item drops
#position2D arrays:
onready var spray_array:Array = [$Sprite/Spray1,$Sprite/Spray2,$Sprite/Spray3,$Sprite/Spray4,
								 $Sprite/Spray5,$Sprite/Spray6,$Sprite/Spray7,$Sprite/Spray8,
								 $Sprite/Spray9,$Sprite/Spray10,$Sprite/Spray11,$Sprite/Spray12]
onready var cannon_array:Array = [$Sprite/Cannon1,$Sprite/Cannon2,$Sprite/Cannon3]
onready var laser_array:Array = [$Sprite/LaserBeam1,$Sprite/LaserBeam2,$Sprite/LaserBeam3,
								 $Sprite/LaserBeam4,$Sprite/LaserBeam5,$Sprite/LaserBeam6,
								 $Sprite/LaserBeam7,$Sprite/LaserBeam8]
onready var health:float = max_health

func _ready():
	Globals.boss = self
	position = Vector2(512,128)
	$AnimationPlayer.play_backwards("die") # lol
	yield($AnimationPlayer,"animation_finished")
	$HealthBar.visible = true
	can_shoot_spray = true
	aim_at_player = true

func _physics_process(_delta):
	$HealthBar.rect_rotation = -self.rotation_degrees
	
	if can_shoot_lasers: _shoot_lasers()
	if can_shoot_cannons: _shoot_cannons()
	if can_shoot_spray: _shoot_spray()
	if aim_at_player: _aim_at_player()
	if aim_sideways: _aim_sideways()
	if move_sideways: _move_sideways()
	if drop_help: _drop_help()
	
	if not aim_at_player:
		self.rotation = lerp_angle(rotation,0,0.02) #correct angle

func _shoot_lasers(): #shoot lasers on interval
	if $LaserCooldown.is_stopped(): #control speed with var laser_shoot_rate
		if not $AnimationPlayer.is_playing():
			$AnimationPlayer.play("laser_load")
			yield($AnimationPlayer,"animation_finished")
			for laser in laser_array.size():
				var bullet = bullets_array[0].instance()
				bullet.transform = laser_array[laser].global_transform
				Globals.stage.add_child(bullet)
			$LaserCooldown.wait_time = laser_shoot_rate
			$LaserCooldown.start()

func _shoot_cannons(): #shoot big cannons on interval
	if $CannonCooldown.is_stopped(): #control speed with var cannon_shoot_rate
		$CannonCooldown.wait_time = cannon_shoot_rate
		for cannon in cannon_array.size():
			var bullet = bullets_array[1].instance()
			bullet.transform = cannon_array[cannon].global_transform
			Globals.stage.add_child(bullet)
		$CannonCooldown.start()

func _shoot_spray(): #shoot top spray on interval
	if $SprayCooldown.is_stopped(): #control speed with var cannon_shoot_rate
		$SprayCooldown.wait_time = spray_shoot_rate
		$SprayDelay.wait_time = spray_delay
		spray_array.shuffle()
		for hole in spray_array.size():
			can_shoot_spray = false
			var bullet = bullets_array[2].instance()
			bullet.transform = spray_array[hole].global_transform
			if Globals.stage != null: Globals.stage.add_child(bullet)
			$SprayDelay.start()
			yield($SprayDelay,"timeout")
			can_shoot_spray = true
		$SprayCooldown.start()

func _aim_at_player():
	if Globals.player != null:
		var aim_dir = (Globals.player.position - self.position).angle() - 1.57
		var current = self.rotation
		$AimPlayerTween.interpolate_property(
			self,"rotation",
			current,aim_dir,
			1.5,Tween.TRANS_LINEAR,Tween.EASE_OUT)
		$AimPlayerTween.start()
		yield($AimPlayerTween,"tween_completed")
		yield($AnimationPlayer,"animation_finished")
	else: pass

func _aim_sideways():
	if Globals.player != null and not $AnimationPlayer.is_playing():
		var aim_dir = Globals.player.global_position.x
		var current = self.global_position.x
		self.position.x = lerp(current,aim_dir,0.01)
	else: pass

func _move_sideways():
	if $SideTimer.is_stopped() and not $AnimationPlayer.is_playing(): #change sideways direction randomly
		$SidewaysTween.interpolate_property(
			self,"position",position,
			Vector2(rand_range(200,800),128),
			1.5,Tween.TRANS_ELASTIC,Tween.EASE_IN_OUT)
		$SidewaysTween.start()
		yield($SidewaysTween,"tween_completed")
		$SideTimer.wait_time = rand_range(1,2)
		$SideTimer.start()

func _drop_help():
	if $DropTimer.is_stopped():
		drop_array.shuffle()
		var drop = drop_array[0].instance()
		drop.position = self.global_position
		if Globals.stage != null: Globals.stage.add_child(drop)
		$DropTimer.start()

func _got_hit(damage): #gets hit by Player Bullet
	health -= clamp(damage,0,health)
	var percent_hp = int((float(health) / max_health) * 100)
	$HealthBar/Tween.interpolate_property(
		$HealthBar, "value", #what
		$HealthBar.value, percent_hp, #from-to
		0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT) #duration-how
	$HealthBar/Tween.start()
	_phase_switcher(percent_hp)

func _phase_switcher(percent_hp):
	#phase 1:
	if percent_hp > 75: #spray -> follow + aim at player
		aim_at_player = true
		aim_sideways = true
		drop_help = true
	#phase 2:
	if percent_hp < 75 and percent_hp > 50: #spray + laser -> random side movement
		can_shoot_lasers = true
		aim_at_player = false
		aim_sideways = false
		move_sideways = true
		drop_help = false
	#phase 3:
	if percent_hp < 50 and percent_hp > 25: #spray + cannon -> random side movement aiming at player
		can_shoot_cannons = true
		can_shoot_lasers = false
		aim_at_player = true
		drop_help = true
	#phase 4:
	if percent_hp < 25: #spray + cannon + laser - > follow + aim at player
		can_shoot_lasers = true
		aim_sideways = true
		move_sideways = false
	
	#----------------------------------- DEATH:
	if percent_hp == 0:
		#disable all AI:
		can_shoot_cannons = false
		can_shoot_lasers = false
		aim_at_player = false
		aim_sideways = false
		move_sideways = false
		drop_help = false
		_die()

func _die():
	$AnimationPlayer.play("die")
	yield($AnimationPlayer,"animation_finished")
	Globals.boss = null
	queue_free()
