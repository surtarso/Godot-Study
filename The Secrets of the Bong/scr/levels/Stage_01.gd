extends Node2D
"""
Gets TIME the stage STARTED
Turn LIGHTS ON
Counts TOTAL STAGE ROACHES to display on USER INTERFACE
Controls STAGE background MUSIC (AMBIENCE and THEME)
Toggles STAGE MUSIC when PLAYER has SUIT
"""

onready var roaches_total = get_node("Roaches").get_child_count() # children total count
onready var user_interface = get_node("UserInterface/UserInterface")
var time

func _ready():
	time = 0 # resets game timer
	## enables all lights (so they can be disabled on editor for faster workflow)
	var lights_array: Array = [$LightsBuilding1, $LightsBuilding2, $LightsBuilding3,
	$LightsBuilding4, $LightsStreet]
	for light in lights_array:
		light.show()
	## send total stage roaches to UI
	user_interface.total_roaches = roaches_total

func _process(delta):
	time += delta # game timer ticks in seconds
	_time_elapsed() ## LEVEL TIMER
	_level_ambience() ## LEVEL AMBIENCE
	_level_theme() ## LEVEL THEME
	_suit_music() ## PAUSE THEME FOR SUIT MUSIC

func _time_elapsed(): #feeds formatted time to interface
	var seconds = fmod(time, 60)
	var minutes = fmod(time, 3600) / 60
	var ms = fmod(time, 1) * 100
	PlayerData.timer_str = "%02d:%02d.%02d" % [minutes, seconds, ms]
		
func _level_ambience(): # level ambience is always on
	if not $level_ambience.playing:
		$level_ambience.play()
		
func _level_theme(): #plays main theme or weed theme depending on player inventory (playerdata.gd)
	if not $level_theme.playing and not PlayerData.has_weed:
		$level_theme.play()
		$weed_theme.stop()
	
	if not $weed_theme.playing and PlayerData.has_weed:
		$weed_theme.play()
		$level_theme.stop()
		
func _suit_music(): ## pauses level theme for suit music to play (plays on player.gd)
	$level_theme.stream_paused = true if PlayerData.has_suit and not PlayerData.has_weed else false
	$weed_theme.stream_paused = true if PlayerData.has_suit and PlayerData.has_weed else false
