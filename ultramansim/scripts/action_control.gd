extends Control

var action_queue = [] #Array holding all the current actions

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func update_cont_effects(player_game_data, opp_game_data):
	'''
	Takes the game state as input and returns the updated field_mod values based on processing cont effects
	'''
	var player_field_mod = player_game_data['field_mod']
	var opp_field_mod = opp_game_data['field_mod']
	return {"player_field_mod": player_field_mod, "opp_field_mod": opp_field_mod}


func update_actionlist_ui():
	'''Updates the action list with action_queue'''
	$ActionQueue/ActionList.clear()
	var index = 0
	for card in action_queue:
		$ActionQueue/ActionList.add_item("", GlobalData.cards[card].image)
		$ActionQueue/ActionList.set_item_metadata(index, card)
		index += 1
	$ActionQueue/ActionList.queue_redraw()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
