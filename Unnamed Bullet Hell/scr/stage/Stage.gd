class_name StageLogic
extends Node2D

onready var stage_width = get_viewport_rect().size.x
onready var stage_height = get_viewport_rect().size.y

export var ui_:PackedScene #user interface scene
export(Array, PackedScene) var player_ #player(s) scene(s)
export var background_:PackedScene
export var bg_speed:float = 400
export var stage_number:int = 1 #current stage (start stage)
export var stage_max:int = 3 #max number of stages
export var _separator:String = "--------------------------------"
export var mob_change_time:float = 20.0 #time between regular waves
export var mob_group_time:float = 5.0 #spawns per second during waves
export var mobs_per_spwn:int = 2 #number of mobs to spwn on each spwn count
export var _separator_:String = "--------------------------------"
export var last_wave_mobcount:int = 15 #total number of mobs
export var spawn_rate:float = 1.0 #mobs per second 
export var breathing_time:float  = 10.0 #time after last wave for boss to come
#all enemies in order of waves:
export(Array, PackedScene) var stage1_enemies
export(Array, PackedScene) var stage2_enemies
export(Array, PackedScene) var stage3_enemies
#bosses in order or appearence:
export(Array, PackedScene) var boss_array

onready var all_enemies_array:Array = [stage1_enemies,stage2_enemies,stage3_enemies]
onready var background = background_.instance()
onready var player = player_[PlayerData.chosen_player].instance() #create player instance
onready var ui = ui_.instance() #create ui instance

var time #stage total time
var current_enemy #stage_enemies index position
var current_enemies_array #all_enemies_array index position
var current_boss #boss_array index position
var last_wave:bool #wave timer update toggle
var boss_added:bool #boss is on screen

signal stage_wave_timer_updated

func _ready():
	Globals.stage = self
	#reset settings:
	$ParallaxBackground/ParallaxLayer.modulate = Color(0.18,0.05,0.21,1)
	current_enemies_array = 0 # reset all_enemies_array position
	current_enemy = 0 #reset current_enemies_array position
	current_boss = 0 #reset boss array position
	last_wave = false #not boss time yet
	#add bg:
	$ParallaxBackground/ParallaxLayer.add_child(background)
		#add player:
	player.position = Vector2(stage_width/2, stage_height/1.3)
	$Player.add_child(player)
	#add ui:
	$UICanvasLayer.add_child(ui)
	#start timers:
	time = 0 #reset stage timer
	$WaveTimer.wait_time = mob_change_time #sets wave timers
	$SpawnTimer.wait_time = mob_group_time #sets current_enemy/sec within waves
	$WaveTimer.start()

func _process(delta):
	#stage timer:
	time += delta
	#wave timer switcher:
	var _wave_timer = emit_signal(
		"stage_wave_timer_updated",$LastWaveTimer.get_time_left()) if last_wave else emit_signal(
			"stage_wave_timer_updated",$WaveTimer.get_time_left())
	#enemies timer:
	if $SpawnTimer.is_stopped(): _spwn_enemy() #spwn mobs inside wave timer
	
	#stage clear (Boss remover):
	if boss_added and (Globals.boss == null): #if boss was added but there is no boss
		boss_added = false
		var seconds = fmod(time, 60)
		var minutes = fmod(time, 3600) / 60
		var stage_time = "%02d:%02d" % [minutes, seconds]
		Globals.ui._stage_clear(stage_time,stage_number,stage_max) ## will call reset_stage()
	
	#background movement:
	$ParallaxBackground/ParallaxLayer.motion_offset.x = -player.position.x
	$ParallaxBackground/ParallaxLayer.motion_offset.y += bg_speed * delta

""" MOB SPAWNER: spwns same mobs till wavetimer changes current_enemy type"""
func _spwn_enemy():
	for i in mobs_per_spwn:
		var n = rand_range(0, stage_width)
		var enemy = all_enemies_array[(current_enemies_array)][current_enemy].instance()
		enemy.position = Vector2(n,-16) # above stage
		$Enemies.add_child(enemy)
		$SpawnTimer.start()

""" WAVE CHANGER: climb current_enemies_array till end than call last wave"""
func _on_WaveTimer_timeout(): #changes current_enemy type on wave timer
	#if theres still mobs on current_enemies_array:
	if current_enemy != (all_enemies_array[(current_enemies_array)].size() -1):
		current_enemy += 1 #climb current_enemies_array
		$WaveTimer.start() #keep going with waves untill array ends
	else:
		$SpawnTimer.paused = true #stops _spwn_enemy()
		_last_wave()

"""LAST WAVE: random wave"""
func _last_wave(): #spwn mobcount ammount of random enemies on interval
	last_wave = true ## toggle to change timer display
	$SpawnRateTimer.wait_time = spawn_rate #time between spwns on last wave
	$LastWaveTimer.wait_time = (spawn_rate * last_wave_mobcount + breathing_time) #total wave time
	$LastWaveTimer.start() #start last wave:
	var dup_array = all_enemies_array[(current_enemies_array)].duplicate()
	
	for i in last_wave_mobcount: #number of total mobs desired in last wave
		$SpawnRateTimer.start()
		dup_array.shuffle()
		var enemy = dup_array[current_enemy].instance()
		var n = rand_range(0, stage_width) 
		enemy.position = Vector2(n,-16) # above stage
		add_child(enemy)
		yield($SpawnRateTimer,"timeout")

"""spwns BOSS"""
func _on_LastWaveTimer_timeout():
	var boss = boss_array[current_boss].instance()
	boss.position = Vector2(stage_width/2,128) #screen middle top
	#boss.rotation = 1.57
	$Enemies.add_child(boss)
	boss_added = true

"""resets values for a NEW STAGE:
	changes boss to next boss on boss_array
	changes current_enemies_array to next on all_enemies_array
	increases current_enemy count and spwn frequency"""
func reset_stage():
	stage_number += 1
	#bg modulate:
	$ParallaxBackground/ParallaxLayer/Tween.interpolate_property(
		$ParallaxBackground/ParallaxLayer,"modulate",
		$ParallaxBackground/ParallaxLayer.modulate,
		Color(rand_range(0.05,0.29),rand_range(0.05,0.29),rand_range(0.05,0.29),1),
		1,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT
	)
	$ParallaxBackground/ParallaxLayer/Tween.start()
	yield($ParallaxBackground/ParallaxLayer/Tween,"tween_completed")
	
	#set modifiers:
	mob_group_time -= 1 ## accelerate spawns per second
	mobs_per_spwn += 2 ## increase mobs per spawn_time
	last_wave_mobcount += 10 ## increase last wave density
	
	current_enemies_array += 1 if current_enemies_array < (all_enemies_array.size() - 1) else 0 ## climb all_arrays position
	current_enemy = 0 #reset all_array/stage_enemies position
	current_boss += 1 if current_boss < (boss_array.size() - 1) else 0 ## change boss
	last_wave = false
	
	time = 0 #reset stage timer:
	#start timers:
	$WaveTimer.start()
	
	$SpawnTimer.paused = false
	$SpawnTimer.stop()
	$SpawnTimer.start()

