extends Control
"""
Controls MAIN MENU: MUSIC and ANIMATION
"""
onready var settings_menu = get_node("Settings")
func _ready():
	$AnimationPlayer.play("fadein")
	yield($AnimationPlayer,"animation_finished")
	$AnimationPlayer.play("MainScreen_loop")
	#mouse mode and cursor
	var cursor = load("res://assets/userinterface/cursor.png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(10,10))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _process(_delta):
	if not $opening_theme.playing:
		$opening_theme.play()

func _on_SettingsButton_button_up():
	settings_menu.visible = not settings_menu.visible
	
func _unhandled_input(_event):
	if Input.is_action_just_pressed("pause"):
		settings_menu.visible = false #closes settings with ESC
