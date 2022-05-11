extends Control
"""
Controls: USER INTERFACE and PAUSE MENU
CONNECT SIGNALS from PLAYERDATA (PlayerData.gd)
Handles VOLUME and FULLSCREEN settings
GAME OVER funcion and MESSAGES
"""

var arrest_msg_array: Array = ["You were arrested.","Treehugger.","See you in jail.",
								"Glaucoma, Jailcoma.","You fight like a dairy farmer.",
								"Suck it.","See ya, punk.","Hands up, bitch!"]
onready var scene_tree: = get_tree()
#pause related:
var paused: = false setget set_paused
onready var pause_overlay: ColorRect = get_node("PauseOverlay")
onready var pause_title: Label = get_node("PauseOverlay/Title")
onready var pause_menu_retry: = get_node("PauseOverlay/PauseMenu/RetrySceneButton")
onready var settings_menu: Control = get_node("PauseOverlay/Settings")
#level roach count:
onready var total_roaches: int #value comes from Stage.gd (roach child count)
#interface icons:
onready var roach_ui_icon: TextureProgress = get_node("ScoreIcons/roach_bar")
onready var lighter_ui_icon: Sprite = get_node("ScoreIcons/lighter_PHolder")
onready var weed_ui_icon: Sprite = get_node("ScoreIcons/weed_PHolder2")
onready var coffee_ui_icon1: Sprite = get_node("ScoreIcons/coffee_PHolder")
onready var coffee_ui_icon2: Sprite = get_node("ScoreIcons/coffee_PHolder2")
onready var coffee_ui_icon3: Sprite = get_node("ScoreIcons/coffee_PHolder3")
onready var suit_icon: Sprite = get_node("ScoreIcons/suit")
onready var bong_icon: Sprite = get_node("ScoreIcons/bong")
#timer and score
onready var timer: Label = get_node("TimerDisplay")
onready var score: Label = get_node("Score")
#mouse cursors
var cursor: Resource = load("res://assets/userinterface/cursor.png")
var blank_cursor: Resource = load("res://assets/userinterface/blank_cursor.png")

"""------------------------------- READY ------------------------------------"""
func _ready():
	#dont process music and pause it
	self.set_process(false) #dont start processing when ready
	$Sounds/pause_music.stream_paused = true #make sure music is paused
	#retains changes to volume on level reload:
	get_node("PauseOverlay/Settings/MasterSlider").value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	get_node("PauseOverlay/Settings/MusicSlider").value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	get_node("PauseOverlay/Settings/AmbienceSlider").value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience"))
	
	##----Connects PlayerData.gd signals to SELF on update functions:
	var _a = PlayerData.connect("roaches_updated", self, "update_roaches_interface")
	var _b = PlayerData.connect("lighter_updated", self, "update_lighter_interface")
	var _c = PlayerData.connect("weed_updated", self, "update_weed_interface")
	var _d = PlayerData.connect("coffee_updated", self, "update_coffee_interface")
	var _e = PlayerData.connect("arrest_updated", self, "_on_PlayerData_player_arrest")
	var _f = PlayerData.connect("got_suit_updated", self, "update_suit_interface")
	var _g = PlayerData.connect("bong_updated", self, "update_bong_interface")
	var _h = PlayerData.connect("timer_updated", self, "update_timer_interface")
	var _i = PlayerData.connect("score_updated", self, "update_score_interface")
#-------------------------------- READY END ------------------------------------

"""------------------------------- PROCESS: ---------------------------------"""
func _process(_delta):
	#keep pause music in loop
	if not $Sounds/pause_music.playing: $Sounds/pause_music.play()
#-------------------------------- PROCESS END ----------------------------------

"""------------------------------- GETTERS: ---------------------------------"""
func update_score_interface():
	score.text = str(PlayerData.score)
	
func update_timer_interface():
	#show timer to interface
	timer.text = PlayerData.timer_str

func update_roaches_interface():
	#calculate % of total roaches vs roaches collected
	var missing_roaches:float = PlayerData.roaches - total_roaches
	var missing_percent:float = missing_roaches / total_roaches
	var roach_size = missing_percent*100+100
	
	roach_ui_icon.value = roach_size # regulates size/lengh of roach icon
	
func update_lighter_interface():
# warning-ignore:standalone_ternary
	lighter_ui_icon.show() if PlayerData.has_lighter else lighter_ui_icon.hide()
		
func update_weed_interface():
# warning-ignore:standalone_ternary
	weed_ui_icon.show() if PlayerData.has_weed else weed_ui_icon.hide()
		
func update_coffee_interface():
	if PlayerData.coffee == 0:   # 0 0 0
		coffee_ui_icon1.hide()
		coffee_ui_icon2.hide()
		coffee_ui_icon3.hide()
	elif PlayerData.coffee == 1: # 1 0 0
		coffee_ui_icon1.show()
		coffee_ui_icon2.hide()
		coffee_ui_icon3.hide()
	elif PlayerData.coffee == 2: # 1 1 0
		coffee_ui_icon1.show()
		coffee_ui_icon2.show()
		coffee_ui_icon3.hide()
	elif PlayerData.coffee == 3: # 1 1 1
		coffee_ui_icon1.show()
		coffee_ui_icon2.show()
		coffee_ui_icon3.show()
	else:                        # 1 1 1 !
		$ScoreIcons/coffee_animation.play("overdose")
		
func update_suit_interface():
	var _suit = suit_icon.show() if PlayerData.got_suit else suit_icon.hide()

func update_bong_interface():
	var _bong = bong_icon.show() if PlayerData.has_bong else bong_icon.hide()
#--------------------------------- GETTERS END ---------------------------------

"""-------------------------------- GAME OVER:-------------------------------"""
func _on_PlayerData_player_arrest():
	arrest_msg_array.shuffle() #shuffle arrest messages
	self.paused = true #pause game
	pause_title.text = arrest_msg_array[0] #display random text message
	pause_menu_retry.grab_focus() # get keyboard focus to the "try again" button
	$Sounds/player_gameover.play() #game over police siren
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) #unconfine mouse
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(10,10)) #add a cursor
#--------------------------------- GAME OVER END -------------------------------

"""----------------------------------PAUSE:----------------------------------"""
func _unhandled_input(_event):
	if Input.is_action_just_pressed("pause") and pause_title.text != arrest_msg_array[0]:
		if settings_menu.visible == true:
			settings_menu.visible = false
		else:
			self.set_process(true) #start processing the music loop
			self.paused = not paused #pause mode toggle
			scene_tree.set_input_as_handled() #dont move player while paused
			$Sounds/pause_menu.play() #lighter click entering/exiting pause_menu sound
			#releases mouse on pause menu and changes cursor
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CONFINED: #going in pause mode
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) #make mouse visible (unconfined)
				Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(10,10)) #change cursor
				pause_menu_retry.grab_focus() # get keyboard focus to the "try again" button
				$Sounds/pause_music.stream_paused = false #unpause music
			#confines mouse leaving pause menu and changes cursor
			elif Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE: #going out of pause mode
				Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED) #make mouse confined
				Input.set_custom_mouse_cursor(blank_cursor, Input.CURSOR_ARROW,Vector2(8,8)) #hide cursor (invisible cursor)
				$Sounds/pause_music.stream_paused = true #pause music
				self.set_process(false) #stop processing music loop
			
## -------------------------- PAUSE SETTER:
func set_paused(value: bool):
	paused = value
	scene_tree.paused = value
	pause_overlay.visible = value
#--------------------------------- PAUSE END -----------------------------------

""" -------------------------------SETTINGS:---------------------------------""" 
## SETTINGS BUTTON
func _on_Settings_button_up():
	settings_menu.visible = not settings_menu.visible
	
