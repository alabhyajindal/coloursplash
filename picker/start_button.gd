extends Button

# Grouping a Button into a ButtonGroup makes it behave as a radio button. We want to know which button is toggled from the abilities_button_group. This is a hack, the @export exposes this variable in the inspector, where from the dropdown we can select it. This was needed because I couldn't find a way to get a reference to button group programatically
@export var abilities_group: ButtonGroup

# When the start button is pressed, find out what's the selected ability and print it. We are printing it right now, later on we'll use this information to affect the game. Finally, change the scene to the world scene
func _on_pressed():
	var selected_ability = abilities_group.get_pressed_button()
	print(selected_ability)
	get_tree().change_scene_to_file("res://world.tscn")
	
