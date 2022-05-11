extends Node
"""
Singleton (PlayerData.gd)
Controls: PLAYER INVENTORY and BUFFS
Sets: GAME-OVER and RESET
Saves: STATES for ENEMY behavior
SIGNALS: USER INTERFACE (UserInterface.gd)
"""
onready var time_start #stage.gd script sets time the stage started for ENDSCREEN.gd
##------------------LINKS------------------------
var has_bribed: = 0 # accounts for number of bribes done (for score)
var has_stoned: = 0 #accounts number of guards stoned (for score)
var has_suit = false #suit is being used (godmode)
var has_coffee_overdose = false #took too much coffee (speed buff)
var dropped_coke = false #signals enemy that there is coke on the ground
var current_position #saves player current position (for coke drops)

##-----------------SETTERS------------------------
var score: = 0 setget set_score # score points
var roaches: = 0 setget set_roaches # number of roaches
var arrested: = 0 setget set_arrested # GAME OVER
var has_lighter: = false setget set_lighter # has lighter
var has_weed: = false setget set_weed # has weed
var coffee: = 0 setget set_coffee # has coffee
var got_suit: = false setget set_suit # has the item "suit"
var has_bong: = false setget set_bong # has the item "bong"
var timer_str: = "" setget set_timer

##------ signals to update the interface ---------
signal score_updated
signal roaches_updated
signal arrest_updated
signal lighter_updated
signal weed_updated
signal coffee_updated
signal got_suit_updated
signal bong_updated
signal timer_updated
##------------------------------------------------
func set_score(value:int):
	score = value
	emit_signal("score_updated")
	
func set_timer(value: String):
	timer_str = value
	emit_signal("timer_updated")
	
func set_bong(value: bool):
	has_bong = value
	emit_signal("bong_updated")

func set_suit(value: bool):
	got_suit = value
	emit_signal("got_suit_updated")

func set_coffee(value: int):
	coffee = value
	emit_signal("coffee_updated")

func set_weed(value: bool):
	has_weed = value
	emit_signal("weed_updated")

func set_lighter(value: bool):
	has_lighter = value
	emit_signal("lighter_updated")

func set_roaches(value: int):
	roaches = value
	emit_signal("roaches_updated")

func set_arrested(value: int):
	arrested = value
	emit_signal("arrest_updated")

## RESETS GAME AND ALL SCORE
func reset():
	coffee = 0
	roaches = 0
	arrested = 0
	has_bribed = 0
	has_stoned = 0
	has_bong = false
	has_lighter = false
	has_weed = false
	has_suit = false
	got_suit = false
	has_coffee_overdose = false
