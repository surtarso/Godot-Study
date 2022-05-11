extends HSlider

onready var click = get_node("../ambience")

func _on_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"),value)
	click.play()
