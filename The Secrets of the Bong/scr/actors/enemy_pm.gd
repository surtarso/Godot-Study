extends KinematicBody2D

#dialogs
onready var speech_array: Array = ["Sucker...","...and a twat.","Bum.","Can you run?",
"You smell!","Don't waste my\n time, faggot."]
#sound library
onready var chase_sound_array: Array = [$Sound/enemy_chase1,$Sound/enemy_chase2,$Sound/enemy_chase3]
onready var hit_sound_array: Array = [$Sound/enemy_hit1,$Sound/enemy_hit2]
#player node reference
onready var player = get_node("../../Player") #get player node to calculate realtime position
## enemy nodes must be inside a parent Enemies NODE within the scene tree

const NEG_Y = Vector2.UP
var motion = Vector2()
var gravity = 1250.0
var follow_direction # follows player position
var patrol_speed = 30.0
var chase_speed = 60.0 # speed if player has weed bonus [leaf] or cop is coked out
var is_bribed = false # has accepted a bribe (coffee) [forever]
var has_snorted = false # cop has snorted coke
var no_search_mode = false #toggles hitbox for player to flee [timed]


func _ready():
	set_physics_process(false) #VisibilityEnabler2D node sets to true/false based on screen visibility
	motion.x = patrol_speed #sets patrol motion speed
	$ChaseColors.play("patrol") # normal colors
	
"""--------------------------------collision control - start ----------------------------"""
#--------------------------PLAYER COLLISION ENTERING
func _on_PlayerDetector_body_entered(_body):
	if not PlayerData.has_suit and not is_bribed and not no_search_mode: #if "godmode" is off, not bribed or resting
		player.camera._shake(0.2,15,8) # duration, frequency, amplitude
		var chance_to_find_roaches = randf() #random float 0 to 1
		var hit_sound = _random_hit_sound() #pick a random hit sound
			
		#if player has weed, arrest unless player has 2 coffees
		if PlayerData.has_weed:
			if PlayerData.coffee < 2: #if player has less than 2 coffee
				PlayerData.arrested += 1 #arrest him ------------------------------------------(GAME OVER)
			else: #player has 2 coffee [max]
				PlayerData.coffee -= 2 #takes 2 coffee from player
				is_bribed = true #become bribed
				PlayerData.has_bribed += 1 #accounts total number of bribes done [for scoreboard]
				player.get_node("ItemUsedAnimation").play("coffee_gone") ###-------------------------- REPLACE WITH SIGNAL TO UI
				hit_sound.play() 
				
		#if player has coffee AND roaches, take coffee [small chance to take roach instead]
		if PlayerData.coffee > 0 and PlayerData.roaches > 0:
			if chance_to_find_roaches < 0.2: ##20% chance guard will take a roach instead of coffee
				#PlayerData.roaches -= 1 #take 1 roach
# warning-ignore:narrowing_conversion
# warning-ignore:integer_division
				PlayerData.roaches = round(PlayerData.roaches/2) # take half the roaches
				no_search_mode = true #gives player time to run [deactivate collisions]
				$Sprite/tookroach.visible = true #guard is smoking a roach
				PlayerData.has_stoned += 1 #accounts number of guards stoned [scoreboard]
				$Sound/enemy_high.play()
			else:
				PlayerData.coffee -= 1 #take one coffee
				is_bribed = true #become bribed
				PlayerData.has_bribed += 1 #accounts total number of bribes done [for scoreboard]
				player.get_node("ItemUsedAnimation").play("coffee_gone") ### --------------------------REPLACE WITH SIGNAL TO UI
				hit_sound.play() #play random hit sound
				_speech_bubble()
				
		#if player has no coffee but has roaches, arrest [small chanche to take roach instead]
		elif PlayerData.coffee == 0 and PlayerData.roaches > 0:# if has NO coffee but HAS roaches
			if chance_to_find_roaches == 1.0: ##10% chance guard will take a roach instead of arrest
				#PlayerData.roaches -= 1 #take 1 roach
# warning-ignore:narrowing_conversion
# warning-ignore:integer_division
				PlayerData.roaches = round(PlayerData.roaches/2) # take half the roaches
				no_search_mode = true #gives player time to flee
				$Sprite/tookroach.visible = true #while guard smokes a roach
				PlayerData.has_stoned += 1 #accounts number of guards stoned [scoreboard]
				$Sound/enemy_high.play()
			else:
				PlayerData.arrested += 1 #player is arrested -------------------------------(GAME OVER)
					
		 # else if player is clean [has no roaches/weed]
		else: 
			if PlayerData.roaches == 0 and not PlayerData.has_weed:
				no_search_mode = true #gives player time to flee before being up to search again
				_speech_bubble()
	
##HIT SOUND RANDOMIZER
func _random_hit_sound() -> AudioStreamPlayer2D:
	hit_sound_array.shuffle() #shuffles the array of chase sounds
	return hit_sound_array[0] #returns the first one to the player
			
#-------------------------CHASE HITBOX 
func _on_PlayerChase_body_entered(_body):  #hitbox behind enemy back
	if not PlayerData.has_suit: #if not godmode
		# FLIP:
		if $FlipTimer.is_stopped():
			motion.x *= -1.0 #flip direction
			$PlayerDetector/hitbox.position.x *= -1.0 #and hitboxes
			$PlayerChase/hitbox.position.x *= -1.0 #so it faces the player
			var chase_sound: = _random_chase_sound() #pick one of the chasing sounds
			chase_sound.play() #and play it [sniffing sound]
			$FlipTimer.start()
	elif PlayerData.has_weed:
		$PlayerChase.set_deferred("monitoring",false)
		
#--------------------CHASE SOUND RANDOMIZER
func _random_chase_sound() -> AudioStreamPlayer2D:
	chase_sound_array.shuffle() #shuffles the array of chase sounds
	return chase_sound_array[0] #returns the first one to the player
##-------------------------collision control  - end-----------------------------------

"""--------------------------physics process - start---------------------------------"""
func _physics_process(delta):
	motion.y += gravity * delta
	_movement() #wall flip and weed chase control [motion.x]
	_player_has_suit() #disables hitboxes when player in god-mode
	_animation_control() #controls sprites, colors and hitbox positions

	motion.y = move_and_slide(motion, NEG_Y).y # maintain gravity
##-------------------------physics process - end-------------------------------

"""-------------------------movement control - START-------------------------------"""
func _movement():
	if player.smokeblow_raycast.get_collider() == self and not no_search_mode:  ## ALL ENEMIES GET STONED WTF!?
		no_search_mode = true #gives player time to run [deactivate collision monitoring]
		PlayerData.has_stoned += 1 #accounts for scoreboard
		$Sprite/stoned.visible = true #guard is stoned
		has_snorted = false #calms big guy down
		
	if PlayerData.has_suit == false: #no godmode
		## ------------------------- NO SEARCH MODE:
		if no_search_mode and $RestTimer.is_stopped(): #gives player 5 seconds to flee before reactivating
			$PlayerChase.set_deferred("monitoring",false)
			$PlayerDetector.set_deferred("monitoring",false)
			$RestTimer.start()
			motion.x = patrol_speed #normalize speed if in weed-chase mode
			
			yield($RestTimer,"timeout") # 5 seconds
			
			$PlayerChase.set_deferred("monitoring",true) #enable chase hitbox on timeout
			$PlayerDetector.set_deferred("monitoring",true) #enables player detector
			no_search_mode = false # player can be searched again
			$Sprite/stoned.visible = false
			$Sprite/tookroach.visible = false
			
		##-------------------------- - BRIBED MODE
		elif is_bribed: #remove collision layers [enemy "DEAD", but no despwn]
			$PlayerChase.set_deferred("monitoring",false)
			$PlayerDetector.set_deferred("monitoring",false)
			motion.x = patrol_speed #normalize speed if in weed-chase mode
			
	if is_on_floor() and is_on_wall() and not PlayerData.has_weed: #if on floor and hits a wall
		motion.x *= -1 #flip direction and hitboxes
		$PlayerDetector/hitbox.position.x *= -1.0
		$PlayerChase/hitbox.position.x *= -1.0
	
	##--------------------- chases coke that player drops on the floor
	elif PlayerData.dropped_coke and $SnortTimer.is_stopped() and not has_snorted: #follows coke
		$PlayerDetector.set_deferred("monitoring",false)
		var coke_area_direction = (PlayerData.current_position - global_position).normalized()
		motion.x = coke_area_direction.x * chase_speed
		$ReachCokeTimer.start()
		#if cop reaches coke
		if round(self.position.x) == round(PlayerData.current_position.x): 
			motion.x = 0
			$Sound/enemy_snort.play()
			$SnortTimer.start()
			
			yield($SnortTimer,"timeout")
			PlayerData.dropped_coke = false #stop chasing coke
			$Sprite/stoned.visible = false #unstoned if stoned
			$RestTimer.emit_signal("timeout") # stops no seach mode timer
			no_search_mode = false #players can be searched again
			has_snorted = true #morphs into badass big
			
			var dir_rand = randf()
			if dir_rand <= 0.5: #50% chance for each direction
				motion.x = chase_speed
			else: motion.x = -chase_speed
			
		yield($ReachCokeTimer,"timeout")
		PlayerData.dropped_coke = false
		if has_snorted == false:
			var dir_rand = randf()
			if dir_rand <= 0.5: #50% chance for each direction
				motion.x = patrol_speed
			else: motion.x = -patrol_speed
		
	##--X---- weed smell endless chase [if player has weed, no suit and guard not bribed or in no search mode]
	elif PlayerData.has_weed and not PlayerData.has_suit and not is_bribed and not no_search_mode: #follows smell if player has weed leaf and no godmode[suit]
		follow_direction = (player.global_position - global_position).normalized() # player global position x,y
		motion.x = follow_direction.x * chase_speed # extracts X direction from global position	
		$PlayerDetector/hitbox.position.x = follow_direction.x #hitbox follows pig face
	
##--------------------------movement control - END------------------------------

"""--------------------------Player has suit - start------------------------------"""
func _player_has_suit():
		if PlayerData.has_suit:
			self.set_collision_mask_bit(0,false) #disables self collision with player
		else:
			self.set_collision_mask_bit(0,true) #enables self collision with player
##-------------------------Player has suit - end----------------------------------

"""------------------------Animation control - start------------------------------------"""
func _animation_control():
	##----------CHASE COLORS [animation player]
	if PlayerData.has_suit or is_bribed or no_search_mode:
		$ChaseColors.play("patrol")
	if PlayerData.has_weed and not PlayerData.has_suit and not is_bribed and not no_search_mode:
		$ChaseColors.play("siren")
		#TODO: add a visible siren effect here
	##-----------SPRITE ANIMATION
	if motion.x < 0: #left
		$Sprite.flip_h = false
		$Sprite/tookroach.flip_h = false
		$Sprite/tookroach.position = Vector2(-8,9)
		if is_bribed:
			$Sprite.play("bribed")
		elif PlayerData.has_suit and not is_bribed and not no_search_mode:
			$Sprite.play("suit_effect")
		elif has_snorted:
			$Sprite.play("patrol_morph")
		else:
			$Sprite.play("patrol")
			
	elif motion.x > 0: #right
		$Sprite.flip_h = true
		$Sprite/tookroach.flip_h = true
		$Sprite/tookroach.position = Vector2(8,9)
		if is_bribed:
			$Sprite.play("bribed")
		elif PlayerData.has_suit and not is_bribed and not no_search_mode:
			$Sprite.play("suit_effect")
		elif has_snorted:
			$Sprite.play("patrol_morph")
		else:
			$Sprite.play("patrol")
			
	else: #idle
		if PlayerData.dropped_coke and motion.x == 0: #if cop reached coke
			$Sprite.play("snort") #snort it
		else:
			$Sprite.play("idle")
##--------------------------Animation control - end--------------------------------

func _speech_bubble():
	# shuffle speech array
	speech_array.shuffle()
	## use random text to balloon label
	$speech_bubble/Label.text = speech_array[0]
	## toggle balloon visibility
	$speech_bubble.visible = not $speech_bubble.visible
	# start bubble timer
	$SpeechTimer.start()
	yield($SpeechTimer,"timeout")
	# remove balloon after timeout
	$speech_bubble.visible = false
