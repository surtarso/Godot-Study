extends Node

var chosen_player:int = 0
var MAX_HEALTH:float
var start_immune_duration:float
var max_immune_duration:float

##-----------------SETTERS------------------------
var continues:int = 2
var health: = MAX_HEALTH setget set_health
var score: = 0 setget set_score # score points
var shoot_rate:float setget set_shoot_rate
var crit_chance:float = 0 setget set_crit_chance
var crit_bonus:float = 1 # 1=no crit bonus
var shots_fired: = 0 setget set_shots_fired
var shots_hit: = 0 setget set_shots_hit
var tec_shot: = false setget set_tec_shot
var double_kill: = false setget set_double_kill
var triple_kill: = false setget set_triple_kill
var immune_time_left: = 0.0 setget set_immune_time
var immune_duration: = start_immune_duration setget set_immune_duration

##------ signals to update the interface ---------
signal score_updated
signal shoot_rate_updated
signal crit_chance_updated
signal shots_fired_updated
signal shots_hit_updated
signal tec_shot_updated
signal double_kill_updated
signal triple_kill_updated
signal immune_time_left
signal immune_duration
signal health_updated

##------------------------------------------------

func set_score(value:int):
	score = value
	emit_signal("score_updated",value)

func set_shoot_rate(value:float):
	shoot_rate = value
	emit_signal("shoot_rate_updated",value)

func set_crit_chance(value:float):
	crit_chance = value
	emit_signal("crit_chance_updated",value)

func set_shots_fired(value:int):
	shots_fired = value
	emit_signal("shots_fired_updated",value)

func set_shots_hit(value:int):
	shots_hit = value
	emit_signal("shots_hit_updated",value)

func set_tec_shot(value:bool):
	tec_shot = value
	emit_signal("tec_shot_updated")

func set_double_kill(value:bool):
	double_kill = value
	emit_signal("double_kill_updated")

func set_triple_kill(value:bool):
	triple_kill = value
	emit_signal("triple_kill_updated")

func set_health(value:float):
	health = value
	emit_signal("health_updated",value)

func set_immune_time(value:float):
	immune_time_left = value
	emit_signal("immune_time_left")

func set_immune_duration(value:float):
	immune_duration = value
	emit_signal("immune_duration")

## RESETS ALL VARIABLES TO DEFAULT
func reset():
	score = 0
	shots_fired = 0
	shots_hit = 0
	crit_bonus = 1
	
	immune_time_left = 0
	immune_duration = start_immune_duration
	health = MAX_HEALTH
	double_kill = false
	triple_kill = false
	tec_shot = false
	continues = 3

func _continue(): ## same as reset, without scores/stats
	immune_time_left = 0
	health = MAX_HEALTH
	double_kill = false
	triple_kill = false
	tec_shot = false
	continues -= 1 ## removes a continue
