extends Node
""" Detects when the player enters cheat codes.
checks whether the user finished typing a cheat code.
emits a signal which can be used to activate the cheat code. """

# List of cheat codes. Cheat codes should be lower-case, and should not be contained within one another
export (Array, String) var codes := ["iddqd","idkfa","idclip","idspispopd"]

const MAX_LENGTH := 32 # The maximum length of cheat codes.
var _previous_keypresses: String = ""  # Buffer of key strings
signal cheat_detected # Signal emitted when a cheat is entered.

const CODE_KEYS := {  # Dictionary of key scancodes and their alphanumeric representation.
	KEY_SPACE:" ", KEY_APOSTROPHE:"'", KEY_COMMA:",", KEY_MINUS:"-", KEY_PERIOD:".", KEY_SLASH:"/",
	KEY_0:"0", KEY_1:"1", KEY_2:"2", KEY_3:"3", KEY_4:"4", KEY_5:"5", KEY_6:"6", KEY_7:"7", KEY_8:"8", KEY_9:"9",
	KEY_SEMICOLON:";", KEY_EQUAL:"=",

	KEY_A:"a", KEY_B:"b", KEY_C:"c", KEY_D:"d", KEY_E:"e", KEY_F:"f", KEY_G:"g", KEY_H:"h", KEY_I:"i",
	KEY_J:"j", KEY_K:"k", KEY_L:"l", KEY_M:"m", KEY_N:"n", KEY_O:"o", KEY_P:"p", KEY_Q:"q", KEY_R:"r",
	KEY_S:"s", KEY_T:"t", KEY_U:"u", KEY_V:"v", KEY_W:"w", KEY_X:"x", KEY_Y:"y", KEY_Z:"z",

	KEY_BRACELEFT:"[", KEY_BACKSLASH:"\\", KEY_BRACERIGHT:"]", KEY_QUOTELEFT:"`"
}
## Processes an input event, delegating to the appropriate 'key_pressed', 
## 'key_just_pressed', 'key_released','key_just_released' functions.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.scancode in CODE_KEYS:
		var key_string: String = CODE_KEYS[event.scancode]
		if event.pressed and not event.is_echo():
			_key_just_pressed(key_string)

## Called for the first frame when a key is pressed.
##'key_string': single-character alphanumeric representation of the pressed key
func _key_just_pressed(key_string: String) -> void:
	_previous_keypresses += key_string
	# remove the oldest keypresses so the buffer doesn't grow infinitely
	_previous_keypresses = _previous_keypresses.right(_previous_keypresses.length() - MAX_LENGTH)
	for code in codes:
		if code == _previous_keypresses.right(_previous_keypresses.length() - code.length()):
			# Clear the keypress buffer, otherwise a keypress could count towards two different cheats
			_previous_keypresses = ""
			emit_signal("cheat_detected", code)
