extends TextureProgress
"""
Controls the link between GRAPHICAL interface and cooldown TIMER for BLINK
"""

onready var blink_timer = self.get_parent().get_node("blink_timer")

func _process(_delta):
	self.value = blink_timer.time_left if blink_timer.time_left != 0 else 0
