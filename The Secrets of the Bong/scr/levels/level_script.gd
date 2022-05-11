extends Node2D

onready var roaches_total = get_node("Roaches").get_child_count()
onready var user_interface = get_node("UserInterface/UserInterface")


func _ready():
	user_interface.total_roaches = roaches_total
	
func _process(_delta):
	_level_ambience() ## LEVEL AMBIENCE
	_level_theme() ## LEVEL THEME
	_suit_music() ## PAUSE THEME FOR SUIT MUSIC

		
func _level_ambience():
	if not $level_ambience.playing:
		$level_ambience.play()
		
func _level_theme():
	if not $level_theme.playing and not PlayerData.has_weed:
		$level_theme.play()
		$weed_theme.stop()
	
	if not $weed_theme.playing and PlayerData.has_weed:
		$weed_theme.play()
		$level_theme.stop()
		
func _suit_music():
	$level_theme.stream_paused = true if PlayerData.has_suit and not PlayerData.has_weed else false
	$weed_theme.stream_paused = true if PlayerData.has_suit and PlayerData.has_weed else false
