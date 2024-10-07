extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Connect Signals
	$VBoxContainer/DeckEditButton.pressed.connect(_on_DeckEditButton_pressed)
	$VBoxContainer/PracticeButton.pressed.connect(_on_PracticeButton_pressed)
	pass # Replace with function body.

func _on_DeckEditButton_pressed():
	'''Switch to Deck Editor Scene'''
	get_tree().change_scene_to_file("res://scenes/deck_builder.tscn")
	
func _on_PracticeButton_pressed():
	'''Switch to Gameplay Scene'''
	get_tree().change_scene_to_file("res://scenes/room_creation.tscn")

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
