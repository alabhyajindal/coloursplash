extends Button

@export var abilities_group: ButtonGroup

func _on_pressed():
	var selected_ability = abilities_group.get_pressed_button()
	print(selected_ability)
	get_tree().change_scene_to_file("res://world.tscn")
	
