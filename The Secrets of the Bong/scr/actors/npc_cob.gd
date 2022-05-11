extends Area2D

onready var dialog_box: RichTextLabel = get_node("dialog_logic/RichTextLabel")

var dialog:Array = ["A/D = MOVE, SPACE = JUMP\n J = BLINK (or right mouse button)\nPress ENTER to continue.", 
				"Get LIGHTER + ROACH\n Use L to blow smoke (or left mouse button)",
				"SUIT = GODMODE. Press K to use it.\n(or middle mouse button)", 
				"'little COFFEE' + PIG = BRIBED PIG", 
				"LIGHTER + BONG + WEED = WIN"] 
var page = 0

func _ready():
	dialog_box.set_bbcode(dialog[page])
	dialog_box.set_visible_characters(0)
	set_process_unhandled_input(true)
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		if dialog_box.get_visible_characters() > dialog_box.get_total_character_count():
			if page < dialog.size() - 1:
				page += 1
				dialog_box.set_bbcode(dialog[page])
				dialog_box.set_visible_characters(0)
			else: page = -1 ## GAMBIARRA FEIA
		else:
			dialog_box.set_visible_characters(dialog_box.get_total_character_count())

func _on_Timer_timeout():
	dialog_box.set_visible_characters(dialog_box.get_visible_characters() + 1)
