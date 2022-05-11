extends TextureProgress
"""
Controls the link between GRAPHICAL interface and cooldown TIMER for SUIT
"""

onready var suit_duration = self.get_parent().get_node("suit_timer")

func _process(_delta):
	self.value = suit_duration.time_left if suit_duration.time_left != 0 else 0
