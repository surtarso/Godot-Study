class_name Player
extends KinematicBody2D

## MAKE: EXPLOSION DROP ITEM
## TODO: GIVE CHARGE, ITEM SKILLS LIKE EXPLOSIONS/HEAVY PROJECTILES
## TODO: VIEWPORT CHANGES (scalable? slice of screen?mobile controls?)
## TODO: UI ELEMENTS
## TODO: NEW MOB/BOSS TYPES
## TODO: ADD NEW PLAYER TYPES/SCREEN (bullets, stats)
## TODO: KEYS ASSIGNMENT SETUP SCREEN
## TODO: TOP 10, 3 LETTER SCOREBOARD
## TODO: SUPERNOVA? (blackhole collision)
## TODO: MORE ITEM DROPS (MULTITARGET, BOMBS)
## TODO: FALLING OBSTABLES / PROCEDURAL GENERATION
## TODO: POP-UP ACHIEVS
## TODO: SAVE SYSTEM / PLAYER PROGRESS
export var max_health_:float = 10
export var start_immune_duration_:float = 0.25
export var max_immune_duration_:float = 0.65
export var move_speed:int = 450 #top speed
export var acceleration:float = 0.1
export var friction:float = 0.05 #decelerate speed
export var shoot_rate_:float = 0.35
export var tec_shot_rate:float = 0.15 #speeds up shooting

#normal crit bonus (1) on playerdata.gd:
export var start_crit_chance_:float = 0
export var double_crit_bonus:float = 1.5
export var triple_crit_bonus:float = 2

export (Array, PackedScene) var bullets_array ## in order of power, special bullet must be LAST

onready var _joy_plug = Input.connect("joy_connection_changed",self,"joy_con_changed") #check for joysticks
onready var _tecshot = PlayerData.connect("tec_shot_updated",self,"_update_bonus_hits")
onready var _doublekill = PlayerData.connect("double_kill_updated",self,"_update_bonus_hits")
onready var _triplekill = PlayerData.connect("triple_kill_updated",self,"_update_bonus_hits")
onready var _cheat = Cheat.connect("cheat_detected",self,"cheat_code_used")

onready var bullet_holes:Array = [
	$Sprite/Position2DFront,$Sprite/Position2DLeft,$Sprite/Position2DRight,
	$Sprite/Position2DBack,$Sprite/Position2DBackLeft,$Sprite/Position2DBackRight]
onready var can_shoot:bool = true
onready var can_charge:bool = true
onready var spin_attack:bool = false
onready var multi_gun:bool = false
onready var star_gun:bool = false
onready var immune:bool = false

var velocity:Vector2
var bullet_type:int = 0
var aim_distance:int
var min_shoot_rate:float = 0.20

var mouse_mode = 0 #toggle 0=off 1=on for mouse/joystick aim behavior
var joy_deadzone = 0.15
var joy_sensivity = 0.01

func _ready() -> void:
	Globals.player = self
	#setup player:
	PlayerData.MAX_HEALTH = max_health_
	PlayerData.health = max_health_
	PlayerData.start_immune_duration = start_immune_duration_
	PlayerData.max_immune_duration = max_immune_duration_
	PlayerData.immune_duration = start_immune_duration_
	PlayerData.shoot_rate = shoot_rate_
	PlayerData.crit_chance = start_crit_chance_
	#set mouse cursor:
	var blank_cursor = load("res://assets/blank_16x16.png") #load cursor image
	Input.set_custom_mouse_cursor(blank_cursor) #set cursor image
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED) #confines mouse in window
	#initialize:
	randomize()
	set_process(true)
	set_physics_process(true)
	$Sprite/CPUParticles2D.emitting = true
	$AnimationPlayer.play("default")
	_change_sprite_animation() #set animation
	_set_aim() #move aim to correct distance/position

func _process(_delta):
	_get_action_keys()
	if Input.get_connected_joypads().size() > 0: #rotating aim if joypad connected
		var xAxis = Input.get_joy_axis(0,JOY_AXIS_2) #right analog horizontal
		if abs(xAxis) > joy_deadzone: #if moving analog stick
			mouse_mode = 0 #disable mouse mode
			_set_aim() #hide mouse aim
			if xAxis < 0: self.rotate(lerp(xAxis,-joy_sensivity,0.8))
			if xAxis > 0: self.rotate(lerp(xAxis,joy_sensivity,0.8))
	$BlackHoleCdBar.frame = int($ShootSpecialTimer.time_left) if !$ShootSpecialTimer.is_stopped() else 0
	$Sprite/CPUParticles2D2.emitting = true if $BlackHoleCdBar.frame == 0 else false
	PlayerData.immune_time_left = $ImmunityTimer.time_left if immune else 0 #sends value to interface

func _physics_process(_delta):
	if !spin_attack and mouse_mode == 1: look_at(get_global_mouse_position()) #rotate self to mouse position (default behavior)
	if spin_attack: #rotate madly and shooting on spin attack item grab
		self.rotate(0.25)
		_shoot()
	
	var direction = _get_input_axis() #get direction from inputs
	if direction.length() > 0: velocity = lerp(velocity, direction * move_speed, acceleration) #accelerate
	else: velocity = lerp(velocity, Vector2.ZERO, friction) #if moving without keys pressed, decelerate
	
	if !can_charge: velocity = move_and_slide(velocity*1.6) #chage speed on charge
	else: velocity = move_and_slide(velocity) #normal speed (default behavior)

func _get_input_axis():
	var input = Vector2.ZERO
	input.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	input.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	return input.normalized()

func _get_action_keys():
	if Input.is_action_pressed("shoot"): if can_shoot: _shoot()  ##RMB
	if Input.is_action_just_pressed("special"): if $ShootSpecialTimer.is_stopped(): _black_hole()  ##LMB
	if Input.is_action_just_pressed("charge"): if can_charge: _charge()  ##SPACE

func _input(event):
	if event is InputEventMouseMotion:
		mouse_mode = 1
		_set_aim() #sets aim distance

func _set_aim(): #sets aim distance to player
	if mouse_mode == 1:
		$AimSprite.visible = true
		if PlayerData.double_kill and !PlayerData.triple_kill:  #double kill
			aim_distance = 160
			$AimSprite.scale = Vector2(1.2,1.2)
		elif PlayerData.triple_kill: #triple kill
			aim_distance = 192
			$AimSprite.scale = Vector2(1.4,1.4)
		else: #default
			aim_distance = 128
			$AimSprite.scale = Vector2(1,1)
		
		var player_position: Vector2 = (self.global_position - global_position).normalized()
		var player_to_cursor: Vector2 = get_local_mouse_position() - player_position
		var aim_direction: Vector2 = player_to_cursor.normalized()
		var cursor_vector: Vector2 = aim_direction * aim_distance
		var final_position: Vector2 = player_position + cursor_vector
		if !spin_attack: $AimSprite.position = final_position #places aim
	else: 
		if $AimSprite.visible != false: $AimSprite.visible = false
		else: pass

func _charge(): ## SPACE
	if $ChargeCooldown.is_stopped():
		if Input.get_connected_joypads().size() > 0: Input.start_joy_vibration(0,0.1,0.1,0.1)
		can_charge = false ## physics_process:if !can_charge: speed up
		$ChargeTimer.start()
		yield($ChargeTimer,"timeout")
		can_charge = true
		$ChargeCooldown.start()

"""------------------------------ SHOOT ------------------------------------"""
func _black_hole(): ## RMB (must be the last on the bullets array)
	if PlayerData.health > 1: ## dont suicide...
		if Input.get_connected_joypads().size() > 0: Input.start_joy_vibration(0,0.6,0.6,0.6)
		var old_bullet = bullet_type #save current bullet
		var old_multigun = multi_gun #save current multi_gun state
		var old_stargun = star_gun
		#set shot:
		bullet_type = bullets_array.size() - 1 #change to black_hole
		multi_gun = false #disable multi_gun
		star_gun = false #disable star_gun
		_shoot() #shoot
		_got_hit(1) #take one damage
		#restore:
		bullet_type = old_bullet #restore previous bullet
		multi_gun = old_multigun #restore previous multi_gun state
		star_gun = old_stargun #restore previous star_gun state
		$ShootSpecialTimer.start() #start cooldown

func _shoot(): ## LMB
	can_shoot = false #disables shooting
	if multi_gun: _add_bullet(3) #add bullets to 3 bullet holes[0,1,2]
	elif star_gun: _add_bullet(6) #add bullets to all bullet holes [0...5]
	else: _add_bullet(1) #add bullet to front bullet hole[0]
	_set_aim()
	_change_sprite_animation()
	$ShootTimer.wait_time = PlayerData.shoot_rate #check/set current shoot_rate
	$ShootTimer.start() #start shoot cooldown
	yield($ShootTimer,"timeout") #wait cooldown to finish
	can_shoot = true #re-enables shooting
	_change_sprite_animation()

"""sets up the bullet acording to player active bonuses"""
func _add_bullet(holes):
	for hole in holes: #add a bullet to each hole
		var bullet = bullets_array[bullet_type].instance() #pick right bullet
		bullet.transform = bullet_holes[hole].global_transform #orient bullet to proper hole
		#account shots fired (for accuracy calcs):
		if bullet_type == 0 or bullet_type == 3: PlayerData.shots_fired += 1 # single bullets
		if bullet_type == 1: PlayerData.shots_fired += 2 #dual bullets
		if bullet_type == 2: PlayerData.shots_fired += 3 #triple bullets
		#add bullet:
		Globals.stage.get_node("PlayerBullets").add_child(bullet)

##------------------------------------------------------------------------------

"""-------------------------- GOT HIT AND DIE ------------------------------"""

func _got_hit(damage):
	if not god_mode:
		if not immune: # cheat-code disabled or shield buff inactive
			##-- GETS HIT:
			if Input.get_connected_joypads().size() > 0: Input.start_joy_vibration(0,0.25,0.25,0.15) #device, weak motor, strong motor, duration
			_bonus_disabler()
			PlayerData.health -= clamp(damage,0,PlayerData.health)
			$Camera2D._shake((damage*100),0.3,300) # new_shake, shake_time, shake_limit
			$AnimationPlayer.play("hit")
			$AnimationPlayer.queue("default")
			##-- DEATH CALL:
			if PlayerData.health == 0:
				_die(true)

""" disables a single bonus everytime player gets hit in order"""
func _bonus_disabler():
	var once = true
	##-----------------------------block 1----------------------------------
	## MULTIGUN/STARGUN - Item Grab:
	if multi_gun or star_gun:
		star_gun = false
		multi_gun = false
	## CRIT BONUS - Triple Kill:
	if PlayerData.triple_kill and PlayerData.double_kill and once:
		PlayerData.triple_kill = false
		PlayerData.crit_bonus = double_crit_bonus
		once = false
	##-----------------------------block 2------------------------------------
	## CRIT BONUS - Double Kill:
	if !PlayerData.triple_kill and PlayerData.double_kill and once:
		PlayerData.double_kill = false
		PlayerData.crit_bonus = 1
	## BULLET TYPE - Item Grab:
	if bullet_type != 0 and once:
		bullet_type -= 1
		once = false
	##----------------------------block 3------------------------------------
	## SPIN ATTACK - Item Grab:
	if spin_attack and once:
		spin_attack = false
		once = false
	## Adjust aim:
	_set_aim()

func _die(value:bool):
	set_process(!value)
	set_physics_process(!value)
	
	if value == true: ## death
		$AnimationPlayer.stop(true)
		$AnimationPlayer.play("die")
		yield($AnimationPlayer,"animation_finished")
		Globals.ui._player_dead() #call user interface
		self.visible = false
	
	if value == false: ## continue
		self.visible = true
		immune = true
		PlayerData._continue()
		$AnimationPlayer.play_backwards("continue")
		yield($AnimationPlayer,"animation_finished")
		$AnimationPlayer.play("default")
		_set_aim()
		immune = false

##-----------------------------------------------------------------------------

""" every time player gets a tec_shot, give a small boost to shoot rate on a timer;
		gets immunity shield on all tecshots, double and triple kill triggers"""

func _update_bonus_hits(): #signal receiver of BOOLEANS
	if PlayerData.tec_shot: if $BonusRateTimer.is_stopped(): _bonus_rate(tec_shot_rate)
	if PlayerData.double_kill: PlayerData.crit_bonus = double_crit_bonus
	if PlayerData.triple_kill: PlayerData.crit_bonus = triple_crit_bonus
	if true: _immune()

func _bonus_rate(value:float): ##hitting a bullet turns to true
	PlayerData.shoot_rate -= value
	$BonusRateTimer.start()
	yield($BonusRateTimer,"timeout")
	PlayerData.shoot_rate += value
	PlayerData.tec_shot = false

func _immune(): 
	immune = true
	$Shield.visible = true
	$ImmunityTimer.wait_time = PlayerData.immune_duration
	$ImmunityTimer.start()
	yield($ImmunityTimer,"timeout")
	immune = false
	$Shield.visible = false

## -------------------------------------------------------------------------------

func _picked_item(name,value):
	## remove artifacts from drop name:
	var replace_array:Array = ["@","0","1","2","3","4","5","6","7","8","9"]
	for i in replace_array.size():
		name = name.replace(replace_array[i],"")
	
	if name == "ShieldDrop": PlayerData.immune_duration += clamp(value, 0, PlayerData.max_immune_duration - PlayerData.immune_duration)
	elif name == "HealthDrop": PlayerData.health += clamp(value, 0, PlayerData.MAX_HEALTH - PlayerData.health)
	elif name == "SpeedDrop":
		if PlayerData.tec_shot: #discount bonus speed
			var current_rate = PlayerData.shoot_rate + tec_shot_rate
			PlayerData.shoot_rate -= clamp(value, 0, current_rate - min_shoot_rate)
		else: PlayerData.shoot_rate -= clamp(value, 0, PlayerData.shoot_rate - min_shoot_rate)
	elif name == "CritDrop": PlayerData.crit_chance += clamp(value, 0, 100 - PlayerData.crit_chance)
	elif name == "DoubleShotDrop": bullet_type = value 
	elif name == "TripleShotDrop": bullet_type = value
	elif name == "MultiGunDrop": # 3 shooting holes
		multi_gun = value 
		$RemoveGunTimer.start()
	elif name == "StarGunDrop": # 6 shooting holes
		multi_gun = !value
		star_gun = value
		$RemoveGunTimer.start()
	elif name == "SpinDrop": _spin_attack(value)
	elif name == "ExplosionDrop": pass
	
	else:print("error: ",name," not properly set") ## debug

func _on_RemoveGunTimer_timeout():
	multi_gun = false
	star_gun = false

func _spin_attack(value):
	spin_attack = value ## _process: if spin_attack: rotate/shoot
	$SpinTimer.start()
	yield($SpinTimer,"timeout")
	spin_attack = !value

func _change_sprite_animation():
	if !can_shoot: $Sprite.play("shoot")
	else: $Sprite.play("default")

##-------------------------------  CHEATS:  --------------------------------------
var god_mode = false
func cheat_code_used(code):
	if code == "iddqd":
		god_mode = !god_mode
	if code == "idkfa": 
		multi_gun = true
		bullet_type = 2
	if code == "idclip": 
		PlayerData.crit_chance = 100
		PlayerData.shoot_rate = 0.20
	if code == "idspispopd":
		spin_attack = !spin_attack
