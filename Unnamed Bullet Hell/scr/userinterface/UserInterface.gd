## UserInterface.gd
extends Control


onready var techit_count:int = 0
onready var doublehit_count:int = 0
onready var triplehit_count:int = 0

onready var _stage_wave_timer = Globals.stage.connect("stage_wave_timer_updated",self,"update_stage_wave_timer")
onready var _score = PlayerData.connect("score_updated",self,"update_score")
onready var _shoot_rate = PlayerData.connect("shoot_rate_updated",self,"update_shoot_rate")
onready var _crit_chance = PlayerData.connect("crit_chance_updated",self,"update_crit_chance")
onready var _shots_fired = PlayerData.connect("shots_fired_updated",self,"update_shots_fired")
onready var _shots_hit = PlayerData.connect("shots_hit_updated",self,"update_shots_hit")
onready var _tec_shot = PlayerData.connect("tec_shot_updated",self,"update_tec_shot")
onready var _double_kill = PlayerData.connect("double_kill_updated",self,"update_double_kill")
onready var _triple_kill = PlayerData.connect("triple_kill_updated",self,"update_triple_kill")
onready var _health = PlayerData.connect("health_updated",self,"update_health")
onready var _immune_time = PlayerData.connect("immune_time_left",self,"update_immune_time_left")
onready var _immune_dur = PlayerData.connect("immune_duration",self,"update_immune_time_left")

var paused: = false setget set_paused

func _ready() -> void:
	Globals.ui = self
	set_process(false)
	$HealthBar.value = 100 #in percentage, 100%
	$HealthLabel.text = "Health: %s%%" % str($HealthBar.value)
	#stage 1:
	$StageNextLabel.visible = true
	$StageNextLabel.text = "STAGE %s" % Globals.stage.stage_number
	$StageNextLabel/Timer.start()
	yield($StageNextLabel/Timer,"timeout")
	$StageNextLabel.visible = false

func _process(_delta):
	$PauseMenu/PauseLabel.text = "You have %s Continues\nGame Over in %s seconds" % [
		PlayerData.continues,int($PauseMenu/ContinueTimer.time_left)]

func update_score(value):
	$ScoreLabel.text = "Score: %s\n\nTec Hits: %s\nDouble Kills: %s\nTriple Kills: %s" % [
		value,techit_count,doublehit_count,triplehit_count]

##------------------ WAVE TIMERS:
func update_stage_wave_timer(value):
	$StageWaveTimerLabel.text = "Next Wave: %s" % int(
		value) if int(value) > 0 else "Next Wave: Incoming"

##------------------- ACCURACY CALCS:
func update_shots_fired(fired):
	$ShotsFiredLabel.text = "Shots Fired: %s" % fired
	_update_accuracy()

func update_shots_hit(hit):
	$ShotsHitLabel.text = "Shots Hit: %s" % hit
	_update_accuracy()

func _update_accuracy():
	if PlayerData.shots_fired != 0:
		$AccuracyLabel.text = "Accuracy: %s%%" % int(round(
			(float(PlayerData.shots_hit) / PlayerData.shots_fired) * 100))

##--------------------- SHOOT POWER:
func update_shoot_rate(value):
	$ShootRateLabel.text = "Shoot Rate: %s" % value

func update_crit_chance(value):
	$CritChanceLabel.text = "Crit Chance: %s%%" % value

##-------------------- BONUS UPDATERS:
func update_tec_shot(): 
	$TecShotLabel.visible = true if PlayerData.tec_shot else false
	if true: techit_count += 1

func update_double_kill():
	$DoubleKillLabel.visible = true if PlayerData.double_kill else false
	if true: doublehit_count += 1

func update_triple_kill():
	$TripleKillLabel.visible = true if PlayerData.triple_kill else false
	if true: triplehit_count += 1

##--------------------- FINAL SCORE CALCS:
func _final_score(): ## final_score = score + ((bonus % of hits) - misses)
	if PlayerData.shots_fired == 0: return 0
	
	var final_score = PlayerData.score + (int(round((float(
		techit_count+doublehit_count*triplehit_count*PlayerData.shots_hit)/PlayerData.shots_fired)*100)) - (
			PlayerData.shots_fired - PlayerData.shots_hit))
	return final_score

##---------------------- PLAYER BARS:
func update_health(value):
	var percent_hp = int((float(value) / PlayerData.MAX_HEALTH) * 100)
	$HealthBar/Tween.interpolate_property(
		$HealthBar, "value", #what
		$HealthBar.value, percent_hp, #from-to
		0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT) #duration-how
	$HealthBar/Tween.start()
	$HealthLabel.text = "Health: %s%%" % str(percent_hp)

func update_immune_time_left():
	var _current = PlayerData.immune_duration
	var _max = PlayerData.max_immune_duration
	if _current != null:
		var _percent = int((_current / _max) * 100)
		$ImmuneLabel.text = "Shield Power: %s%%" % str(_percent)
	
	$ImmuneBar.value = PlayerData.immune_time_left

##---------------------- PLAYER DEATH:
func _player_dead():
	self.paused = true
	if PlayerData.continues == 0:  ## GAME OVER:
		$PauseMenu/Menu/ContinueButton.visible = false
		$PauseMenu/Menu/RetryButton.grab_focus()
		$PauseMenu/PauseLabel.text = "Game Over\nFinal Score = %s" % _final_score()
	else: ## CONTINUE:
		$PauseMenu/Menu/ContinueButton.visible = true #show continue button
		$PauseMenu/Menu/ContinueButton.grab_focus()
		set_process(true)
		$PauseMenu/ContinueTimer.start() #start continue timer
		yield($PauseMenu/ContinueTimer,"timeout") #if timer ends
		set_process(false)
		PlayerData.continues = 0 #set continues to zero
		_player_dead() #recall this funcion

##----------------------- STAGE CLEAR:

func _stage_clear(stage_time,stage_number,stage_max):
	Globals.player.god_mode = true #prevent player from taking damage post boss death
	#stage clear screen:
	$StageClear/AnimationPlayer.play("stage_clear") #becomes visible
	$StageClear/Label.text = "Stage %s Clear!\n%s\nTotal Score = %s" % [
		stage_number,stage_time,_final_score()]
	yield($StageClear/AnimationPlayer,"animation_finished")
	$StageClear/AnimationPlayer.play_backwards("stage_clear")
	yield($StageClear/AnimationPlayer,"animation_finished")
	
	#show NEXT STAGE:
	stage_number += 1
	if stage_number < stage_max + 1: 
		$StageNextLabel.visible = true
		$StageNextLabel.text = "STAGE %s" % stage_number
		$StageNextLabel/Timer.start()
		yield($StageNextLabel/Timer,"timeout")
		$StageNextLabel.visible = false
		$StageWaveTimerLabel.visible = true
		#RESET STAGE:
		Globals.stage.reset_stage()
		Globals.player.god_mode = false #player return to normal state
	
	#world clear:
	else:
		$StageNextLabel.visible = true
		$StageNextLabel.text = "WORLD CLEAR!"
		$StageClear/AnimationPlayer.play("fadeout")
		yield($StageClear/AnimationPlayer,"animation_finished")
		var _back = get_tree().change_scene("res://scr/userinterface/WorldSelect.tscn")
		##add stuff to go back to world selection screen here

## ---------------------  PAUSE:
func _unhandled_input(_event):
	if Input.is_action_just_pressed("esc") and PlayerData.health != 0:
		self.paused = not paused
		$PauseMenu/Menu/ContinueButton.visible = not visible
		$PauseMenu/Menu/RetryButton.grab_focus()
		$PauseMenu/PauseLabel.text = "Game Paused\nPress ESC to resume."

func set_paused(value: bool):
	paused = value
	get_tree().paused = value
	$PauseMenu.visible = value
	if value == true:
		var cursor = load("res://assets/arrow_16x16.png") #load cursor image
		Input.set_custom_mouse_cursor(cursor) #set cursor image
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if value == false:
		var blank_cursor = load("res://assets/blank_16x16.png") #load cursor image
		Input.set_custom_mouse_cursor(blank_cursor) #set cursor image
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

##----------------------- BUTTONS:
func _on_BackButton_button_up():
	self.paused = !paused
	PlayerData.reset()
	var _world_select = get_tree().change_scene("res://scr/userinterface/WorldSelect.tscn")

func _on_RetryButton_button_up():
	self.paused = false
	PlayerData.reset() #resets score
	var _error = get_tree().reload_current_scene()

func _on_ContinueButton_button_up():
	if Globals.player != null:
		set_process(false)
		$PauseMenu/ContinueTimer.stop()
		self.paused = false
		Globals.player._die(false)
		update_health(PlayerData.MAX_HEALTH)
	else: pass

func _on_Quit_button_up():
	get_tree().quit()
