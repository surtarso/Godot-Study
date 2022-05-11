extends KinematicBody2D
"""
Controls PLAYER: movement (walk, run, slide, jump), 
				 skills (blow smoke, blink, suit, coffee overdose),
				 camera, animations, mouse cursor and sounds
Depends on PlayerData.gd singleton (autoload)
"""
#main movements sound
onready var idle_sound: AudioStreamPlayer = get_node("Sound/player_idle")
onready var run_sound: AudioStreamPlayer = get_node("Sound/player_run")
onready var landing_sound: AudioStreamPlayer = get_node("Sound/player_land")
onready var landing_particles: CPUParticles2D = get_node("Particles/JumpLandParticles")
onready var jump_timer: Timer = get_node("Timers/coyote_jump") #timer for coyote jumping
onready var jump_sound_array: Array = [$Sound/player_jump1, $Sound/player_jump2] #array of jump sounds
#blink skill
onready var blink_sound: AudioStreamPlayer = get_node("Sound/player_blink")
onready var blink_cooldown: Timer = get_node("Timers/blink_timer") #cooldown for the blink skill
onready var blink_destination: CollisionShape2D = get_node("BlinkDetector/hitbox") #location of blink teleportation
onready var blink_walldetector: RayCast2D = get_node("BlinkDetector/walldetector") #detects if destination is a wall
onready var blink_particles: CPUParticles2D = get_node("Particles/BlinkPuff") #blink particles
#blow smoke skill
onready var player_roach: AnimatedSprite = get_node("Sprite/WeedJoint")
onready var lit_roach_timer: Timer = get_node("Timers/roach_timer") #lit roach duration
onready var smokeblow_particles: CPUParticles2D = get_node("Particles/BlowSmoke") #particles of the smoke blow skill
onready var smokeblow_active: Timer = get_node("Timers/blow_smoke_timer") #time the blow smoke skill is active
onready var smokeblow_raycast: RayCast2D = get_node("BlowRaycasts/BlowsmokeRaycast") #blowsmoke hitbox
onready var smokeblow_sound_array: Array = [$Sound/player_blowsmoke,$Sound/player_blowsmoke1,
											$Sound/Player_blowsmoke2,$Sound/player_blowsmoke3]
#suit skill
onready var suit_active: Timer = get_node("Timers/suit_timer") #time suit effect is active
onready var suit_sound: AudioStreamPlayer = get_node("Sound/player_suit") # suit music
#coffee skill
onready var coffee_active: Timer = get_node("Timers/coffee_timer") #time coffee effect is active
onready var coffee_particles: CPUParticles2D = get_node("Particles/CoffeeSpeed") #particles of coffee overdose
onready var coffee_sound: AudioStreamPlayer = get_node("Sound/player_overdose") #coffee overdose sound
#other
onready var player_joint: AnimatedSprite = get_node("Sprite/WeedJoint") #joint in player mouth
onready var player_sprite: AnimatedSprite = get_node("Sprite") #main character sprite
onready var icon_animation: AnimationPlayer = get_node("ItemUsedAnimation") #itens used gone animation
onready var camera: Camera2D = get_node("Camera2D") #main camera

##constants
const UP_DIRECTION = Vector2.UP #sets the "up direction" to be -y value // "Vector2(0,-1)"
const ACCELERATION = 18.0
const WALK_MAX_SPEED = 90.0 #max speed when walking (shift)
const ORIGINAL_MAX_SPEED = 180.0 #normal max_speed to restore after speed toggles
const COFFEE_MAX_SPEED = 250.0 #max speed on coffee
const BLINK_MAX_DISTANCE = 90 #sets blink destination position and raycast

##variables
var motion = Vector2() # motion related to x,y values - 2D
var enable_wall_jump: bool #disable wall jump afer use
var enable_second_jump: bool #disables second jump after use
var is_jumping: bool #control if jump was activated
var is_sliding: bool #slide after releasing move keys
var max_speed: float = ORIGINAL_MAX_SPEED
var current_speed: float # calculates current speed
var jump_force = 400.0 #jump height vs gravity
var gravity #fall speed
var normal_gravity = 1200.0
var high_gravity = 800.0 #gravity w/ weed
var camera_offset_max = 50.0 # max look up/down distance

func _ready():
	#mouse mode and cursor
	var blank_cursor: Resource = load("res://assets/userinterface/blank_cursor.png") #load blank cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED) #traps mouse inside game window
	Input.set_custom_mouse_cursor(blank_cursor, Input.CURSOR_ARROW,Vector2(8,8)) #set blank cursor
	
	gravity = normal_gravity #sets initial gravity
	randomize() #new random seed when player enters a scene
	#no need to call randomize() anywhere else in project

"""#------------------------ main function - START ------------------"""
func _physics_process(delta):
	motion.y += gravity * delta #apply gravity
	motion.x = current_speed #motion calculation
	## CHARACTER CONTROL
	_movement() # left / right [motion.x]
	_sliding() # slide to idle [motion.x]
	_jumping() # jumps / walljump [motion.y]
	_blink_skill() # blink 
	_blowsmoke_skill() #blow smoke
	_camera_control() # pan up / down [stairs/elevator later on?] !BROKEN BY CAMERA SHAKE!
	## BUFFS
	_has_suit() # invincibility buff [rich mode/godmode]
	_has_coffee_overdose() # speed buff ["4th" coffee]
	## ANIMATIONS
	_animations()
	## APPLIED MOTION RESULT: move_and_slide((motion.x,motion.y) , (0,-1))
	## this fixes jumping 1 frame too late on ledges or ramps (coyote jump) 
	var was_on_floor = is_on_floor() #checks if im on floor before applying movement
	motion = move_and_slide(motion, UP_DIRECTION) #apply movement
	#check if not on floor now but was on floor before move_and_slide() above
	if not is_on_floor() and was_on_floor and not is_jumping: #smoother ledge jump
		jump_timer.start() #coyote timer
	if is_on_floor() and not was_on_floor: #if is on floor, but wasn't the frame before (JUST LANDED)
		landing_sound.play()
		landing_particles.emitting = true
#------------------------ main function - END ---------------------

"""#------------------------ movement function - START -------------------------"""
func _movement():
	if Input.is_action_just_released("RIGHT") or Input.is_action_just_released("LEFT"):
		is_sliding = true # _is_sliding()
			
	if Input.is_action_pressed("RIGHT"):
		is_sliding = false #breaks sliding
		current_speed += ACCELERATION if current_speed < max_speed else 0.0 #accelerate to max speed
		
	elif Input.is_action_pressed("LEFT"):
		is_sliding = false #breaks sliding
		current_speed -= ACCELERATION if current_speed > -max_speed else 0.0 #accelerate to -max speed
		
	else: if current_speed != 0: is_sliding = true #fixes going out of pause menu
	
#------------------ slide to idle
func _sliding(): # decelerate [is_sliding = true]
	if is_sliding:
		if current_speed > 0: current_speed -= ACCELERATION ## slide right
		elif current_speed < 0: current_speed += ACCELERATION ## slide left
		else: is_sliding = false #stop sliding

#----------------- (LAZY) walk mode
func _input(_event):
	if Input.is_action_pressed("WALK"): #shift
		_walking(true) #change speed
	if Input.is_action_just_released("WALK"):
		_walking(false) #restore speed

func _walking(walking:bool):
	if walking:
		player_sprite.get_sprite_frames().set_animation_speed("running", 10.0) #slows run cycle fps
		run_sound.pitch_scale = 0.48 #slows sound to match footsteps
		max_speed = WALK_MAX_SPEED #limits max speed to walk speed
		#-- if over walk speed, go to walk speed
		if current_speed > WALK_MAX_SPEED: current_speed = WALK_MAX_SPEED
		elif current_speed < -WALK_MAX_SPEED: current_speed = -WALK_MAX_SPEED
	else: #restore defaults
		max_speed = ORIGINAL_MAX_SPEED
		player_sprite.get_sprite_frames().set_animation_speed("running", 20.0)
		run_sound.pitch_scale = 0.87
#-------------------------movement function - END ----------------------

"""#------------------------ jump function - START ------------------------"""
#------------JUMP SOUND RANDOMIZER
func _jump_random_sounds() -> AudioStreamPlayer:
	jump_sound_array.shuffle()
	return jump_sound_array[0]
	
func _jumping():
	if is_on_floor(): is_jumping = false #general rule
	###########  JUMPING  ############
	if Input.is_action_just_pressed("JUMP"):
		var jump_sound : = _jump_random_sounds() #pick a random jump sound
		
		if is_on_floor() or not jump_timer.is_stopped(): ##------------------------------------------FIRST JUMP
			motion.y = -jump_force #jump 
			is_jumping = true
			enable_wall_jump = true #enables wall jumping
			enable_second_jump = true #enables second jump [double jump]
			jump_sound.play() #play random jump sound
			jump_timer.stop() #coyote jump timer
			
		elif is_on_wall() and enable_wall_jump: ##------------------WALL JUMPING 
			motion.y = -jump_force #walljump
			enable_wall_jump = false #disables wall jumping
			jump_sound.play() # play random jump sound
			
		elif enable_second_jump and is_jumping: #--------------------SECOND JUMP 
			motion.y = -jump_force #jump again
			enable_second_jump = false #disables second jump [double jump]
			jump_sound.play() # play random jump sound
		
	###########  JUMP PRESSURE  ###########
	#else if not at max jump height after releasing jump key
	elif Input.is_action_just_released("JUMP") and motion.y < 0: 
		##slow down to 0 or jump gets a bit jerky
		motion.y = 0 #stop going up
#----------------------- jump function - END  ----------------------------

"""#------------------------ skills - START -------------------------------------"""
##----------------- BLINK [2 sec cooldown]
func _blink_skill(): #right mouse button
	if not Input.is_action_just_pressed("BLINK"): return #skip test if unused
	if Input.is_action_just_pressed("BLINK") and current_speed != 0 and blink_cooldown.is_stopped() and not blink_walldetector.is_colliding():
		camera._shake(0.2, 8, 4) # duration, frequency, amplitude
		blink_sound.play()
		blink_particles.emitting = true
		self.global_position = blink_destination.global_position #teleport to hitbox position
		blink_cooldown.start() #2 seconds cooldown

##------------- BLOW SMOKE [requires lighter + roaches OR lighter + weed and bong]
func _blowsmoke_skill(): #left mouse button
	# if player has lighter + roaches OR lighter + weed and bong (CAN BLOW SMOKE)
	if PlayerData.has_lighter and (PlayerData.roaches != 0 or (PlayerData.has_weed and PlayerData.has_bong)):
		# removes 1 roach every 30 seconds
		if lit_roach_timer.is_stopped() and PlayerData.roaches > 0: #if has roaches and timer stopped
			lit_roach_timer.start() #start timer
			
			yield(lit_roach_timer,"timeout") #wait timeout - 30secs
			PlayerData.roaches -= 1 #remove 1 roach
			if icon_animation.is_playing(): yield(icon_animation,"animation_finished")
			icon_animation.play("roach_gone") #fading roach above player head
		
		#active skill
		if Input.is_action_just_pressed("BLOW_SMOKE") and smokeblow_active.is_stopped():
			var blow_sound : = _blowsmoke_random_sounds() #pick a random blowsmoke sound
			smokeblow_raycast.enabled = true #enables raycast collision
			motion.y = -get_local_mouse_position().y*3 #player hops up on use
			smokeblow_particles.emitting = true #start smoke particles
			gravity = high_gravity #reduces gravity while blowing
			blow_sound.play() #play random blow/exhale sound
			smokeblow_active.start() #[.5 sec]
			
			yield(smokeblow_active,"timeout") #[after .5 sec] time enemy can be affected by smoke
			smokeblow_raycast.enabled = false #disable raycast collision
			smokeblow_particles.emitting = false #stop smoke particles\
			gravity = normal_gravity #reset to default gravity
		#fix animation overlaping
		if Input.is_action_just_released("BLOW_SMOKE"):
			smokeblow_particles.emitting = false
		
#blow sound randomizer
func _blowsmoke_random_sounds() -> AudioStreamPlayer:
	smokeblow_sound_array.shuffle()
	return smokeblow_sound_array[0]
##------------------------ skills - END -------------------------------------

"""#-----------------------camera control - start-----------------------------"""
 ## ----------   camera SHAKE broke this
func _camera_control():
	#-- move up/down
	camera.offset.y -= 5.0 if Input.is_action_pressed("UP") and camera.offset.y != -camera_offset_max else 0.0
	camera.offset.y += 5.0 if Input.is_action_pressed("DOWN") and camera.offset.y != camera_offset_max else 0.0
	#-- return to center [0]
	camera.offset.y += 5.0 if not Input.is_action_pressed("UP") and camera.offset.y < 0.0 else 0.0
	camera.offset.y -= 5.0 if not Input.is_action_pressed("DOWN") and camera.offset.y > 0.0 else 0.0
#------------------------camera control - end------------------------------

"""#------------------------- suit mechanics - START-------------------------"""
func _has_suit(): #godmode
	if Input.is_action_just_pressed("SUIT") and PlayerData.got_suit:
		PlayerData.got_suit = false #removes item from interface
		PlayerData.has_suit = true #activates suit effect
		
		if PlayerData.has_suit and suit_active.is_stopped():
			self.set_collision_mask_bit(4,false) #disables enemy collisions
			suit_sound.play()
			suit_active.start()
			
			yield(suit_active,"timeout") ## ~10 secs
			self.set_collision_mask_bit(4,true) #enables enemy collision
			PlayerData.has_suit = false #disables suit effect
			if icon_animation.is_playing(): yield(icon_animation,"animation_finished")
			icon_animation.play("suit_gone")
##----------------------------suit mechanics - END --------------------------

"""##--------------------------coffee overdose - START -------------------------"""
func _has_coffee_overdose(): ## burst of speed after third coffee [4th coffee]
	if not PlayerData.has_coffee_overdose:
		return
	if PlayerData.has_coffee_overdose and coffee_active.is_stopped(): #dont run while running
		PlayerData.coffee += 1 #gives an extra coffee for the duration
		max_speed = COFFEE_MAX_SPEED #increases max speed
		coffee_particles.emitting = true #show effect
		coffee_sound.play() #play effect sound
		
		coffee_active.start() #start timer
		yield(coffee_active,"timeout") #wait for timer [3 secs]
		
		max_speed = ORIGINAL_MAX_SPEED #restore original max speed
		if current_speed > max_speed: #if faster than current speed
			current_speed = ORIGINAL_MAX_SPEED #go to original max speed
			
		PlayerData.has_coffee_overdose = false #disables effect
		if PlayerData.coffee > 3: #remove extra coffee if player has more than 3 (removes 4th coffee)
			PlayerData.coffee -= 1 ##this allows the 4th coffee to be used as bribe during effect
			if icon_animation.is_playing(): yield(icon_animation,"animation_finished")
			icon_animation.play("coffee_gone")
##------------------------coffee overdose - END -----------------------------

"""------------------------animation control - START -------------------------"""
func _animations():
	#flip sprite
	player_sprite.flip_h = true if current_speed < 0 else false
		#------------------------------------------IDLE
	if current_speed == 0:
		#remove joint in mouth sprite
		player_roach.visible = false
		player_roach.position = Vector2(0,0)
		#blowsmoke mouth positioning
		smokeblow_particles.position = Vector2(0,-25)
		#blink placement
		blink_destination.position = Vector2(0,0)
		blink_walldetector.cast_to = Vector2(0,0)
		blink_walldetector.enabled = false
		#sprite
		if (is_on_floor() and not Input.is_action_pressed("LEFT")) and (is_on_floor() and not Input.is_action_pressed("RIGHT")):
			var _idle = player_sprite.play("idle_suit") if PlayerData.has_suit else player_sprite.play("idle")
		elif is_jumping: 
			var _jump = player_sprite.play("jumping_suit") if PlayerData.has_suit else player_sprite.play("idle_jump")
		#sound
		run_sound.stop() #stop running sound if idle
		if not idle_sound.playing:
			idle_sound.play()
	#-----------------------------------------going RIGHT
	if current_speed > 0:
		#joint in mouth position
		player_roach.flip_h = true
		player_roach.rotation_degrees = -37
		player_roach.position = Vector2(15,-5.5)
		#blowsmoke mouth positioning
		smokeblow_particles.position = Vector2(12,-20)
		#blink placement
		blink_destination.position = Vector2(BLINK_MAX_DISTANCE,0) #adjust blink distance
		blink_walldetector.cast_to = Vector2(BLINK_MAX_DISTANCE,0) #adjust blink wall detector
		blink_walldetector.enabled = true
	#-------------------------------------------going LEFT
	if current_speed < 0:
		#joint in mouth position
		player_roach.flip_h = false
		player_roach.rotation_degrees = 37
		player_roach.position = Vector2(-15,-5.5) 
		#blowsmoke mouth positioning
		smokeblow_particles.position = Vector2(-12,-20)
		#blink placement
		blink_destination.position = Vector2(-BLINK_MAX_DISTANCE,0)
		blink_walldetector.cast_to = Vector2(-BLINK_MAX_DISTANCE,0)
		blink_walldetector.enabled = true
	#-----------------------------------------SLIDING
	if is_sliding:
		#sprite
		var _slide = player_sprite.play("sliding_suit") if PlayerData.has_suit else player_sprite.play("sliding")
		#sound
		run_sound.stop() #stop running sound if sliding
	#------------------------------------------going SIDEWAYS
	if motion.x != 0 and not is_sliding:
		player_joint.visible = true if PlayerData.has_lighter and (PlayerData.roaches != 0 or (PlayerData.has_weed and PlayerData.has_bong)) else false
		#sprite
		if is_on_floor() and not is_on_wall(): 
			var _run = player_sprite.play("running_suit") if PlayerData.has_suit else player_sprite.play("running")
		elif is_jumping: 
			var _jump = player_sprite.play("jumping_suit") if PlayerData.has_suit else player_sprite.play("jumping")
		elif is_jumping and enable_second_jump: 
			var _jump2 = player_sprite.play("jumping_suit") if PlayerData.has_suit else player_sprite.play("jumping")
		#sound
		if not run_sound.playing and not is_jumping:
			run_sound.play()
		idle_sound.stop() #stop idle sound if moving
	#------------------------------------------going UP/DOWN
	if is_jumping:
		idle_sound.stop() #stop idle sound on jump
		run_sound.stop() #stop running sound on jump
##---------------------animation control - END --------------------------------
